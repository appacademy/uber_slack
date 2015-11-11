class RideJob
  @queue = :ride

  def self.perform(
    bearer_header,
    ride,
    origin_lat,
    origin_lng,
    destination_lat,
    destination_lng,
    product_id,
    slack_url
  )
    fail_msg = "We were not able to request a ride from Uber. Please try again."

    begin
      ride_response = self.request_ride!(
        bearer_header,
        origin_lat,
        origin_lng,
        destination_lat,
        destination_lng,
        product_id
      )
    rescue
      self.reply_to_slack(fail_msg)
      return
    end

    if !ride_response["errors"].nil?
      self.reply_to_slack(fail_msg)
      return
    end

    success_msg = self.format_200_ride_request_response(
      origin_name,
      destination_name,
      ride_response
    )
    self.reply_to_slack(slack_url, success_msg)

    ride.update!(request_id: ride_response['request_id'])
  end

  def self.request_ride!(
    bearer_header,
    origin_lat,
    origin_lng,
    destination_lat,
    destination_lng,
    product_id
  )
      body = {
        start_latitude: origin_lat,
        start_longitude: origin_lng,
        end_latitude: destination_lat,
        end_longitude: destination_lng,
        product_id: product_id
      }

      response = RestClient.post(
        "#{BASE_URL}/v1/requests",
        body.to_json,
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
      )

    JSON.parse(response.body)
  end

  def self.reply_to_slack(slack_url, response)
    payload = { text: response }

    RestClient.post(slack_url, payload.to_json)
  end

  def self.format_200_ride_request_response origin, destination, response
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

  def self.on_failure(
    exception,
    bearer_header,
    ride,
    origin_lat,
    origin_lng,
    destination_lat,
    destination_lng,
    product_id,
    slack_url
  )
    Resque.enqueue(NotifyFailureJob, exception, slack_url)
  end
end
