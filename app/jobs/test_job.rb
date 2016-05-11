class TestJob < ActiveJob::Base
  queue_as :test

  def perform(url, str)
    if str == "fail"
      Rollbar.info("Running Sidekiq failure test.")
      fail
    end

    reply_to_slack(url, "Received '#{str}'")
    Rollbar.info("Ran Sidekiq test.")
  end

  def reply_to_slack(url, response)
    payload = { text: response }

    RestClient.post(url, payload.to_json)
  end

  def on_failure(e, url, response)
    Rollbar.info("Retrying Sidekiq test.")
    perform_later(url, "failure handled")
  end
end
