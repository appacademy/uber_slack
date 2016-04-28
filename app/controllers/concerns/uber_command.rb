require 'addressable/uri'
require 'uber_command_error_strings'
class FormatError < StandardError; end

class UberCommand
  include UberCommandFormatters

  attr_reader :bearer_token
  def initialize(bearer_token, user_id, response_url)
    @bearer_token = bearer_token
    @user_id = user_id
    @response_url = response_url
  end

  def run(user_input_string)
    input = user_input_string.split(" ", 2) # Only split on first space.

    return UNKNOWN_COMMAND_ERROR if input.empty?

    command_name = input.first.downcase

    command_argument = input.second.nil? ? "" : input.second.downcase

    if invalid_command?(command_name) || command_name.nil?
      return UNKNOWN_COMMAND_ERROR
    end

    begin
      self.send(command_name, command_argument)
    rescue FormatError => e
      return e.message
    end
  end

  private

  def estimate(user_input_string)
    origin_lat, origin_lng, destination_lat, destination_lng =
      parse_start_and_end_coords(user_input_string, ESTIMATES_FORMAT_ERROR)

    product_id = get_default_product_id_for_lat_lng(start_lat, start_lng)
      return [
        "Sorry, we did not find any Uber products available near #{start_addr}.",
        "Can you try again with a more precise address?"
      ].join(" ") if product_id.nil?

    begin
      body = {
        "start_latitude" => origin_lat,
        "start_longitude" => origin_lng,
        "end_latitude" => destination_lat,
        "end_longitude" => destination_lng,
        "product_id" => product_id
      }

      ride_estimate_hash = UberAPI.get_ride_estimate(body, bearer_header)
    rescue => e
      Rollbar.error(e, "UberCommand#estimate")
      return [
        "Sorry, we could not get time and price estimates for a trip",
        "from #{start_addr} to #{end_addr}.",
        "Can you try again with more precise addresses?"
      ].join(" ")
    end
    format_ride_estimate_response(start_addr, end_addr, ride_estimate_hash)
  end

  def help(_) # No command argument.
    HELP_TEXT
  end

  def share(_) # No command argument.
    ride = Ride.where(user_id: @user_id).order(:updated_at).last
    return "Sorry, we couldn't find a ride for you to share." if ride.nil?

    request_id = ride.request_id

    begin
      map_response = RestClient.get(
        "#{BASE_URL}/v1/requests/#{request_id}/map",
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
      )
    rescue RestClient::Exception => e
      Rollbar.error(e, "UberCommand#share")
      return "Sorry, we weren't able to get the link to share your ride."
    end

    link = JSON.parse(map_response.body)["href"]
    "Use this link to share your ride's progress: #{link}."
  end

  def status(_) # No command argument.
    ride = Ride.where(user_id: @user_id).order(:updated_at).last
    return "Sorry, we couldn't find any rides that you requested." if ride.nil?

    begin
      status_hash = get_ride_status(ride.request_id)
    rescue => e
      Rollbar.error(e, "UberCommand#status")
      return "Sorry, we weren't able to get your ride status from Uber."
    end

    ride_status = status_hash["status"]

    eta = status_hash["eta"]
    eta_msg = eta ? "ETA: #{eta} minutes" : nil
    eta_msg = "ETA: one minute" if eta == 1

    if %w(
      processing
      accepted
      arriving
      in_progress
    ).include?(ride_status)
      return [
        "STATUS:",
        RIDE_STATUSES[ride_status],
        eta_msg
      ].compact.join(" ")
    end

    "STATUS: #{RIDE_STATUSES[ride_status]}"
  end

  def cancel(_) # No command argument.
    ride = Ride.where(user_id: @user_id).order(:updated_at).last
    return "Sorry, we couldn't find a ride for you to cancel." if ride.nil?

    request_id = ride.request_id

    fail_msg = "Sorry, we were unable to cancel your ride."

    begin
      UberAPI.cancel_ride(request_id, bearer_header)
      resp = RestClient.delete(
        "#{BASE_URL}/v1/requests/#{request_id}",
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
      )
    rescue RestClient::Exception => e
      Rollbar.error(e, "UberCommand#cancel")
      return fail_msg
    end

    return "Successfully canceled your ride." if resp.code == 204
    fail_msg
  end

  def get_ride_status(request_id)
    resp = RestClient.get(
      "#{BASE_URL}/v1/requests/#{request_id}",
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
    )
    JSON.parse(resp.body)
  end

  def accept(stated_multiplier)
    @ride = Ride.where(user_id: @user_id).order(:updated_at).last

    if @ride.nil?
      return "Sorry, we're not sure which ride you want to confirm. Please try requesting another."
    end

    multiplier = @ride.surge_multiplier
    surge_is_high = multiplier >= 2.0

    if surge_is_high and (stated_multiplier.nil? or stated_multiplier.to_f != multiplier)
      return "That didn't work. Please reply */uber accept #{multiplier}* to confirm the ride."
    end

    if surge_is_high and !stated_multiplier.include?('.')
      return "That didn't work. Please include decimals to confirm #{multiplier}x surge."
    end

    surge_confirmation_id = @ride.surge_confirmation_id
    product_id = @ride.product_id

    start_latitude = @ride.start_latitude
    start_longitude = @ride.start_longitude
    end_latitude = @ride.end_latitude
    end_longitude = @ride.end_longitude
    origin_name = @ride.origin_name
    destination_name = @ride.destination_name

    fail_msg = "Sorry but something went wrong. We were unable to request a ride."

    if (Time.now - @ride.updated_at) > 5.minutes
      # TODO: Break out address resolution in #ride so that we can pass lat/lngs directly.

      return ride "#{origin_name} to #{destination_name}"
    else
      body = {
        "start_latitude" => start_latitude,
        "start_longitude" => start_longitude,
        "end_latitude" => end_latitude,
        "end_longitude" => end_longitude,
        "surge_confirmation_id" => surge_confirmation_id,
        "product_id" => product_id
      }
      begin
        response = RestClient.post(
          "#{BASE_URL}/v1/requests",
          body.to_json,
          authorization: bearer_header,
          "Content-Type" => :json,
          accept: 'json'
        )
      rescue RestClient::Exception => e
        Rollbar.error(e, "UberCommand#accept")
        reply_to_slack(fail_msg)
        return
      end

      if response.code == 200 or response.code == 202
        response_hash = JSON.parse(response.body)

        success_msg = format_200_ride_request_response(
          origin_name,
          destination_name,
          response_hash
        )

        @ride.update!(request_id: response_hash['request_id'])
        reply_to_slack(success_msg)
      else
        reply_to_slack(fail_msg)
      end

      ""
    end
  end

  def ride(user_input_string)
    origin_lat, origin_lng, destination_lat, destination_lng =
      parse_start_and_end_coords(user_input_string, RIDE_REQUEST_FORMAT_ERROR)

    product_id = get_default_product_id_for_lat_lng(origin_lat, origin_lng)
    return [
      "Sorry, we did not find any Uber products available near '#{origin_name}'.",
      "Can you try again with a more precise address?"
    ].join(" ") if product_id.nil?

    body = {
      "start_latitude" => origin_lat,
      "start_longitude" => origin_lng,
      "end_latitude" => destination_lat,
      "end_longitude" => destination_lng,
      "product_id" => product_id
    }

    begin
      ride_estimate_hash = UberAPI.get_ride_estimate(body, bearer_header)
    rescue => e
      Rollbar.error(e, "UberCommand#ride")
      return [
        "Sorry, we weren't able to request a ride for that trip.",
        "Can you try again with a more precise address?"
      ].join(" ")
    end

    surge_multiplier = ride_estimate_hash["price"]["surge_multiplier"]
    surge_confirmation_id = ride_estimate_hash["price"]["surge_confirmation_id"]

    ride_attrs = {
      user_id: @user_id,
      start_latitude: origin_lat,
      start_longitude: origin_lng,
      end_latitude: destination_lat,
      end_longitude: destination_lng,
      origin_name: origin_name,
      destination_name: destination_name,
      product_id: product_id
    }

    if surge_confirmation_id
      ride_attrs['surge_confirmation_id'] = surge_confirmation_id
      ride_attrs['surge_multiplier'] = surge_multiplier
    end

    ride = Ride.create!(ride_attrs)

    return ask_for_surge_confirmation(surge_multiplier) if surge_multiplier > 1

    Resque.enqueue(
      RideJob,
      bearer_header,
      ride,
      origin_lat,
      origin_lng,
      destination_lat,
      destination_lng,
      origin_name,
      destination_name,
      product_id,
      @response_url
    )

    ack = ["Got it!", "Roger that.", "OK.", "10-4."].sample
    "#{ack} Pinging Uber to drive you from #{origin_name} to #{destination_name}..."
  end

  def reply_to_slack(response)
    payload = { text: response }

    RestClient.post(@response_url, payload.to_json)
  end

  def test_resque(input)
    Resque.enqueue(TestJob, @response_url, input)
    "Enqueued test."
  end
end
