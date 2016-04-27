class RideJob < ActiveJob::Base
  queue_as :ride

  def perform(
    bearer_header,
    ride_hash,
    origin_lat,
    origin_lng,
    destination_lat,
    destination_lng,
    origin_name,
    destination_name,
    product_id,
    slack_url
  )

    begin
      ride_response = self.request_ride!(
        bearer_header,
        origin_lat,
        origin_lng,
        destination_lat,
        destination_lng,
        product_id
      )
    rescue => e
      NotifyFailureJob.perform_later(e, slack_url)
      return
    end

    NotifySuccessJob.perform_later(
      origin_name,
      destination_name,
      ride_response['eta'],
      slack_url
    )

    begin
      ride = Ride.find(ride_hash['id'])
      ride.update!(request_id: ride_response['request_id'])
    rescue => e
      NotifyFailureJob.perform_later(e, slack_url)
      return
    end
  end

  def request_ride!(
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
        "#{ENV["uber_base_url"]}/v1/requests",
        body.to_json,
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
      )

    JSON.parse(response.body)
  end

  def on_failure(
    exception,
    bearer_header,
    ride,
    origin_lat,
    origin_lng,
    destination_lat,
    destination_lng,
    origin_name,
    destination_name,
    product_id,
    slack_url
  )
    NotifyFailureJob.perform_later(exception, slack_url)
  end
end
