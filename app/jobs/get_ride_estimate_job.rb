class GetRideEstimateJob < ActiveJob::Base
  queue_as :ride

  def perform(start_addr, end_addr, ride_locations, bearer_header, slack_url)

    estimate = UberAPI.get_ride_estimate(ride_locations, bearer_header)
  rescue RestClient::Exception => e
    failure_response = [
      "Sorry, we could not get time and price estimates for that.",
      "Can you try again with more precise addresses?"
    ].join(" ")
    RestClient.post(slack_url, failure_response)
    Rollbar.warning(e, "UberCommand#estimate")
  else
    response = UberCommandFormatters::format_ride_estimate_response(start_addr, end_addr, estimate)
    RestClient.post(slack_url, response)
  end
end
