class NotifySuccessJob < ActiveJob::Base
  queue_as :notify_success

  def perform(origin, destination, eta, slack_url)
    payload = {
      text: format_200_ride_request_response(origin, destination, eta)
    }

    begin
      RestClient.post(slack_url, payload.to_json)
    rescue RestClient::Exception => e
      NotifyFailureJob.handle_exception(e, slack_url)
    end
  end

  def format_200_ride_request_response(origin, destination, _eta)
    ["Asked Uber for a driver",
     "to take you from #{origin} to #{destination}.",
    ].join(" ")
  end

  def on_failure(exception, _origin, _destination, _eta, slack_url)
    NotifyFailureJob.handle_exception(exception, slack_url)
  end
end
