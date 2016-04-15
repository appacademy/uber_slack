class NotifyFailureJob
  @queue = :notify_failure

  def self.perform(exception, slack_url)
    payload = {
      text: [
        "Sorry, something went wrong while asking Uber for a ride.",
        "Please check your phone to see your request's status."
      ].join(" ")
    }

    RestClient.post(slack_url, payload.to_json)
  end
end
