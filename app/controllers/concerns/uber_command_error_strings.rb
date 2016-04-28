BASE_URL = ENV["uber_base_url"]

# Leave out 'products' until user can pick.
VALID_COMMANDS = %w(
  ride
  estimate
  help
  accept
  share
  status
  cancel
  trigger_error
  test_resque
)

# returned when ride isn't requested in the format '{origin} to {destination}'
RIDE_REQUEST_FORMAT_ERROR = <<-STRING
  To request a ride please use the format */uber ride [origin] to [destination]*.
  For best results, specify a city or zip code.
  Ex: */uber ride 1061 Market Street San Francisco to 55 Music Concourse Dr San Francisco*
STRING

ESTIMATES_FORMAT_ERROR = <<-STRING
  To request estimates for a trip, please use the format */uber [origin] to [destination]*.
  For best results, specify a city or zip code.
  Ex: */uber estimate 1061 Market Street San Francisco to 55 Music Concourse Dr San Francisco*
STRING

UNKNOWN_COMMAND_ERROR = <<-STRING
  Sorry, we didn't quite catch that command.  Try */uber help* for a list.
STRING

# Products is left out
HELP_TEXT = <<-STRING
  Try these commands:
  - ride [origin address] to [destination address]
  - estimate [origin address] to [destination address]
  - share
  - status
  - cancel
  - help

  For best results when requesting a ride or estimate, specify a city or zip code.
  Ex: */uber ride 1061 Market Street, San Francisco to 55 Music Concourse Dr, San Francisco*
STRING

RIDE_STATUSES = {
  "processing" => "Looking for a driver.",
  "no_drivers_available" => "No drivers were available to pick you up. Try again.",
  "accepted" => "A driver accepted your request and is on their way.",
  "arriving" => "Your driver is arriving now.",
  "in_progress" => "Your ride is in progress.",
  "driver_canceled" => "Your driver canceled.",
  "rider_canceled" => "You canceled the last ride you requested through Slack.",
  "completed" => "You completed the last ride you requested through Slack."
}
