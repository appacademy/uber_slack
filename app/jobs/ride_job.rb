class RideJob
  @queue = :ride

  def self.perform(
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
      Raven.capture_exception(e)
      Resque.enqueue(NotifyFailureJob, e, slack_url)
      return
    end

    begin
      ride.update!(request_id: ride_response['request_id'])
    rescue => e
      Raven.capture_exception(e)
      Resque.enqueue(NotifyFailureJob, e, slack_url)
      return
    end

    Resque.enqueue(
      NotifySuccessJob,
      origin_name,
      destination_name,
      ride_response['eta'],
      slack_url
    )
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

  def self.on_failure(
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
    Resque.enqueue(NotifyFailureJob, exception, slack_url)
  end
end
