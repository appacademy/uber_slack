class GetRideStatusJob < ActiveJob::Base
  queue_as :ride

  def perform(request_id, slack_url)

    status_hash = UberAPI.get_ride_status(request_id)
  rescue RestClient::Exception => e
    failure_response = "Sorry, we weren't able to get your ride status from Uber."

    RestClient.post(slack_url, failure_response)
    Rollbar.warning(e, "UberCommand#status")
  else
    ride_status = status_hash["status"]

    eta = status_hash["eta"]
    eta_msg = eta ? "ETA: #{eta} minutes" : nil
    eta_msg = "ETA: one minute" if eta == 1

    response =
    if %w(
      processing
      accepted
      arriving
      in_progress
    ).include?(ride_status)
      [
        "STATUS:",
        SlackResponse::Messages::RIDE_STATUSES[ride_status],
        eta_msg
      ].compact.join(" ")
    else
      "STATUS: #{SlackResponse::Messages::RIDE_STATUSES[ride_status]}"
    end

    RestClient.post(slack_url, response)
  end
end
