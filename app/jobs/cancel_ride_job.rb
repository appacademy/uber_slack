class CancelRideJob < ActiveJob::Base
  queue_as :ride

  def perform(request_id, bearer_header, slack_url)
    UberAPI.cancel_ride(request_id, bearer_header)
  rescue RestClient::Exception => e
    failure_response = "Sorry, we were unable to cancel your ride."

    RestClient.post(slack_url, failure_response)
    Rollbar.error(e, "UberCommand#cancel")
  else
    response = "Successfully canceled your ride."
    RestClient.post(slack_url, response)
  end
end
