require 'addressable/uri'

BASE_URL = ENV["uber_base_url"]

# Leave out 'products' until user can pick.
VALID_COMMANDS = [
  'ride',
  'estimate',
  'help',
  'accept',
  'share',
  'status',
  'cancel',
  'trigger_error',
  'test_resque'
]

# returned when ride isn't requested in the format '{origin} to {destination}'
RIDE_REQUEST_FORMAT_ERROR = <<-STRING
  To request a ride please use the format */uber ride [origin] to [destination]*.
  For best results, specify a city or zip code.
  Ex: */uber ride 1061 Market Street San Francisco to 55 Music Concourse Dr San Francisco*
STRING

ESTIMATES_FORMAT_ERROR = <<-STRING
  To request estimates for a trip, please use the format */uber [origin] to [destination]*.
  For best results, specify a city or zip code.
  Ex: */uber estimate 1061 Market Street San Francisco to 55 Music Concourse Dr San Francisco*
STRING

UNKNOWN_COMMAND_ERROR = <<-STRING
  Sorry, we didn't quite catch that command.  Try */uber help* for a list.
STRING

# Products is left out
HELP_TEXT = <<-STRING
  Try these commands:
  - ride [origin address] to [destination address]
  - estimate [origin address] to [destination address]
  - share
  - status
  - cancel
  - help
STRING

RIDE_STATUSES = {
  "processing" => "Looking for a driver.",
  "no_drivers_available" => "No drivers were available to pick you up. Try again.",
  "accepted" => "A driver accepted your request and is on their way.",
  "arriving" => "Your driver is arriving now.",
  "in_progress" => "Your ride is in progress.",
  "driver_canceled" => "Your driver canceled.",
  "rider_canceled" => "You canceled the last ride you requested through Slack.",
  "completed" => "You completed the last ride you requested through Slack."
}

class UberCommand

  def initialize bearer_token, user_id, response_url
    @bearer_token = bearer_token
    @user_id = user_id
    @response_url = response_url
  end

  def run user_input_string
    input = user_input_string.split(" ", 2) # Only split on first space.

    return UNKNOWN_COMMAND_ERROR if input.empty?

    command_name = input.first.downcase

    command_argument = input.second.nil? ? "" : input.second.downcase

    return UNKNOWN_COMMAND_ERROR if invalid_command?(command_name) || command_name.nil?

    response = self.send(command_name, command_argument)

    return response
  end

  private

  attr_reader :bearer_token

  def estimate user_input_string
    return ESTIMATES_FORMAT_ERROR unless user_input_string.include?(" to ")

    start_addr, end_addr = parse_start_and_end_address(user_input_string)
    start_lat, start_lng = resolve_address(start_addr)
    end_lat, end_lng = resolve_address(end_addr)

    return ["Sorry, we don't know where #{start_addr} is.",
            "Can you try again with a more precise origin address?"
    ].join(" ") if start_lat.nil?

    return ["Sorry, we don't know where #{end_addr} is.",
            "Can you try again with a more precise destination address?"
    ].join(" ") if end_lat.nil?

    product_id = get_default_product_id_for_lat_lng(start_lat, start_lng)
      return [
        "Sorry, we did not find any Uber products available near #{start_addr}.",
        "Can you try again with a more precise address?"
      ].join(" ") if product_id.nil?

    begin
      ride_estimate_hash = get_ride_estimate(
        start_lat,
        start_lng,
        end_lat,
        end_lng,
        product_id
    )
    rescue
      return [
        "Sorry, we could not get time and price estimates for a trip",
        "from #{start_addr} to #{end_addr}.",
        "Can you try again with more precise addresses?"
      ].join(" ")

    end
    format_ride_estimate_response(start_addr, end_addr, ride_estimate_hash)
  end

  def help _ # No command argument.
    HELP_TEXT
  end

  def share _ # No command argument.
    ride = Ride.where(user_id: @user_id).order(:updated_at).last

    if ride.nil?
      return "Sorry, we couldn't find a ride for you to share."
    end

    request_id = ride.request_id

    begin
      map_response = RestClient.get(
        "#{BASE_URL}/v1/requests/#{request_id}/map",
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
      )
    rescue
      return "Sorry, we weren't able to get the link to share your ride."
    end

    link = JSON.parse(map_response.body)["href"]
    "Use this link to share your ride's progress: #{link}."
  end

  def status _ # No command argument.
    ride = Ride.where(user_id: @user_id).order(:updated_at).last

    if ride.nil?
      return "Sorry, we couldn't find any rides that you requested."
    end

    begin
      status_hash = get_ride_status(ride.request_id)
    rescue
      return "Sorry, we weren't able to get your ride status from Uber."
    end

    ride_status = status_hash["status"]
    eta = status_hash["eta"]
    eta_msg = eta == 1 ? "one minute" : "#{eta} minutes"

    if ["processing", "accepted", "arriving", "in_progress"].include?(ride_status)
      return [RIDE_STATUSES[ride_status], "ETA: #{eta_msg}"].join(" ")
    end

    return RIDE_STATUSES[ride_status]
  end

  def cancel _ # No command argument.
    ride = Ride.where(user_id: @user_id).order(:updated_at).last
    if ride.nil?
      return "Sorry, we couldn't find a ride for you to cancel."
    end

    request_id = ride.request_id

    fail_msg = "Sorry, we were unable to cancel your ride."

    begin
      resp = RestClient.delete(
        "#{BASE_URL}/v1/requests/#{request_id}",
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
      )
    rescue
      return fail_msg
    end

    return "Successfully canceled your ride." if resp.code == 204
    return fail_msg
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

  def accept stated_multiplier
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

    fail_msg = "Sorry but something went wrong. We were unable to request a ride."

    if (Time.now - @ride.updated_at) > 5.minutes
      # TODO: Break out address resolution in #ride so that we can pass lat/lngs directly.
      start_location = "#{@ride.start_latitude}, #{@ride.start_longitude}"
      end_location = "#{@ride.end_latitude}, #{@ride.end_longitude}"
      return ride "#{start_location} to #{end_location}"
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
      rescue
        reply_to_slack(fail_msg)
        return
      end

      if response.code == 200 or response.code == 202
        response_hash = JSON.parse(response.body)

        success_msg = format_200_ride_request_response(
          start_location,
          end_location,
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

  def ride input_str
    return RIDE_REQUEST_FORMAT_ERROR unless input_str.include?(" to ")

    origin_name, destination_name = parse_start_and_end_address(input_str)
    origin_lat, origin_lng = resolve_address origin_name
    destination_lat, destination_lng = resolve_address destination_name

    product_id = get_default_product_id_for_lat_lng(origin_lat, origin_lng)
    return [
      "Sorry, we did not find any Uber products available near '#{origin_name}'.",
      "Can you try again with a more precise address?"
    ].join(" ") if product_id.nil?

    begin
      ride_estimate_hash = get_ride_estimate(
        origin_lat,
        origin_lng,
        destination_lat,
        destination_lng,
        product_id
      )
    rescue
      return [
        "Sorry, we weren't able to request a ride for that trip.",
        "Can you try again with a more precise address?"
      ].join(" ")
    end

    surge_multiplier = ride_estimate_hash["price"]["surge_multiplier"]
    surge_confirmation_id = ride_estimate_hash["price"]["surge_confirmation_id"]

    ride_attrs = {
      user_id: @user_id,
      :start_latitude => origin_lat,
      :start_longitude => origin_lng,
      :end_latitude => destination_lat,
      :end_longitude => destination_lng,
      :product_id => product_id
    }

    if surge_confirmation_id
      ride_attrs['surge_confirmation_id'] = surge_confirmation_id
      ride_attrs['surge_multiplier'] = surge_multiplier
    end

    ride = Ride.create!(ride_attrs)

    if surge_multiplier > 1
      return ask_for_surge_confirmation(surge_multiplier)
    else
      ride_response = request_ride!(
        origin_lat,
        origin_lng,
        destination_lat,
        destination_lng,
        product_id
      )
      if !ride_response["errors"].nil?
        reply_to_slack("We were not able to request a ride from Uber. Please try again.")
      else
        ride.update!(request_id: ride_response['request_id'])  # TODO: Do async.
        success_msg = format_200_ride_request_response(
          origin_name,
          destination_name,
          ride_response
        )
        reply_to_slack(success_msg)
      end
      ""  # Return empty string in case we answer Slack soon enough for response to go through.
    end
  end

  def ask_for_surge_confirmation(multiplier)
    base = "#{multiplier}x surge is in effect."

    if multiplier >= 2
      [base, "Reply */uber accept #{multiplier}'* to confirm the ride."].join(" ")
    else
      [base, "Reply */uber accept* to confirm the ride"].join(" ")
    end
  end

  def request_ride!(start_lat, start_lng, end_lat, end_lng, product_id, surge_confirmation_id = nil)
      body = {
        start_latitude: start_lat,
        start_longitude: start_lng,
        end_latitude: end_lat,
        end_longitude: end_lng,
        product_id: product_id
      }

      body['surge_confirmation_id'] = surge_confirmation_id if surge_confirmation_id

      response = RestClient.post(
        "#{BASE_URL}/v1/requests",
        body.to_json,
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: :json
      )

    JSON.parse(response.body)
  end

  def parse_start_and_end_address(input_str)
    origin_name, destination_name = input_str.split(" to ")

    if origin_name.start_with? "from "
      origin_name = origin_name["from".length..-1]
    end

    origin_name = origin_name.lstrip.rstrip
    destination_name = destination_name.lstrip.rstrip

    [origin_name, destination_name]
  end

  def get_ride_estimate(start_lat, start_lng, end_lat, end_lng, product_id)
    body = {
      "start_latitude" => start_lat,
      "start_longitude" => start_lng,
      "end_latitude" => end_lat,
      "end_longitude" => end_lng,
      "product_id" => product_id
    }

    response = RestClient.post(
      "#{BASE_URL}/v1/requests/estimate",
      body.to_json,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: :json
    )

    JSON.parse(response.body)
  end

  def reply_to_slack(response)
      payload = { text: response }

      RestClient.post(@response_url, payload.to_json)
  end

  def get_default_product_id_for_lat_lng lat, lng
    product_id = Rails.cache.fetch("location: #{lat}/#{lng}", expires_in: 15.minutes) do
      available_products = get_products_for_lat_lng(lat, lng)["products"]
      available_products.empty? ? nil : available_products.first["product_id"]
    end

    product_id
  end

  def get_products_for_lat_lng lat, lng
    uri = Addressable::URI.parse("#{BASE_URL}/v1/products")
    uri.query_values = { 'latitude' => lat, 'longitude' => lng }
    resource = uri.to_s

    result = RestClient.get(
      resource,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
    )

    JSON.parse(result.body)
  end

  def format_200_ride_request_response origin, destination, response
    eta = response['eta'].to_i / 60

    estimate_msg = "less than a minute" if eta == 0
    estimate_msg = "about one minute" if eta == 1
    estimate_msg = "about #{eta} minutes" if eta > 1
    ack = ["Got it!", "Roger that.", "OK.", "10-4."].sample

    ["#{ack} We are looking for a driver",
     "to take you from #{origin} to #{destination}.",
     "Your pickup will be in #{estimate_msg}."
    ].join(" ")
  end

  def format_response_errors response_errors
    response = "The following errors occurred: \n"
    response_errors.each do |error|
      response += "- *#{error['title']}* \n"
    end
  end

  def format_products_response products_response
    unless products_response['products'] && !products_response['products'].empty?
      return "No Uber products available for that location."
    end
    response = "The following products are available: \n"
    products_response['products'].each do |product|
      response += "- #{product['display_name']}: #{product['description']} (Capacity: #{product['capacity']})\n"
    end
    response
  end

  def format_ride_estimate_response(start_addr, end_addr, ride_estimate_hash)
    duration_secs = ride_estimate_hash["trip"]["duration_estimate"]
    duration_mins = duration_secs / 60

    duration_msg = duration_mins == 1 ? "one minute" : "#{duration_mins} minutes"

    cost = ride_estimate_hash["price"]["display"]
    surge = ride_estimate_hash["price"]["surge_multiplier"]
    surge_msg = surge == 1 ? "No surge is currently in effect." : "Includes current surge at #{surge}."

    [
      "Driving from #{start_addr} to #{end_addr} would take",
      "about #{duration_msg} and cost #{cost}.",
      surge_msg
    ].join(" ")
  end

  def bearer_header
    "Bearer #{bearer_token}"
  end

  def invalid_command? name
    !VALID_COMMANDS.include? name
  end

  def resolve_address address
    location = Rails.cache.fetch("address: #{address}", expires_in: 1.day) do
      Geocoder.search(address).first
    end

    if location.blank?
      return [nil, nil]
    else
      location = location.data["geometry"]["location"]
      [location['lat'], location['lng']]
    end
  end

  def trigger_error _ # No command argument.
    fail
  end

  def test_resque input
    Resque.enqueue(TestJob, @response_url, input)
    "Enqueued test."
  end
end
