class NotifySuccessJob < ActiveJob::Base
  queue_as :notify_success

  def perform(origin, destination, eta, slack_url)
    payload = {
      text: format_200_ride_request_response(origin, destination, eta)
    }

    begin
      RestClient.post(slack_url, payload.to_json)
    rescue => e
      Sidekiq::Client.enqueue(NotifyFailureJob, e, slack_url)
    end
  end

  def format_200_ride_request_response(origin, destination, eta)
    ["Asked Uber for a driver",
     "to take you from #{origin} to #{destination}.",
    ].join(" ")
  end

  def on_failure(exception, origin, destination, eta, slack_url)
    Sidekiq::Client.enqueue(NotifyFailureJob, exception, slack_url)
  end
end
