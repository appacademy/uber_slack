class NotifyFailureJob
  @queue = :notify_failure

  def self.perform(exception, slack_url)
    payload = {
      text: [
        "Sorry, something went wrong while asking Uber for a ride.",
        "Use */uber status* to see if the request went through."
      ].join(" ")
    }

    RestClient.post(slack_url, payload.to_json)
    Raven.capture_exception(exception)
  end
end
