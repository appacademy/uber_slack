class NotifySuccessJob
  @queue = :notify_success

  def self.perform(origin, destination, eta, slack_url)
    payload = {
      text: self.format_200_ride_request_response(origin, destination, eta)
    }

    begin
      RestClient.post(slack_url, payload.to_json)
    rescue => e
      Raven.capture_exception(e)
      Resque.enqueue(NotifyFailureJob, exception, slack_url)
    end
  end

  def self.format_200_ride_request_response origin, destination, eta
    ["Asked Uber for a driver",
     "to take you from #{origin} to #{destination}.",
    ].join(" ")
  end

  def self.on_failure(exception, origin, destination, eta, slack_url)
    Resque.enqueue(NotifyFailureJob, exception, slack_url)
  end
end
