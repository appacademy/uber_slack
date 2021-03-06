class NotifyFailureJob < ActiveJob::Base
  queue_as :notify_failure

  def perform(slack_url)
    payload = {
      text: [
        "Sorry, something went wrong while asking Uber for a ride.",
        "Please check your phone to see your request's status."
      ].join(" ")
    }

    RestClient.post(slack_url, payload.to_json)
  end

  def self.handle_exception(exception, slack_url)
    Rollbar.error(exception)
    perform_later(slack_url)
  end
end
