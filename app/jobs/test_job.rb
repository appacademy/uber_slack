class TestJob
  @queue = :test

  def self.perform(url, str)
    if str == "fail"
      Rails.logger.info("Running Resque failure test.")
      fail
    end

    reply_to_slack(url, "Received '#{str}'")
    Rails.logger.info("Ran Resque test.")
  end

  def self.reply_to_slack(url, response)
      payload = { text: response }

      RestClient.post(url, payload.to_json)
  end

  def self.on_failure(e, url, response)
    Rails.logger.info("Retrying Resque test.")
    Resque.enqueue(self, url, "failure handled")
    Raven.capture_exception(e)
  end
end
