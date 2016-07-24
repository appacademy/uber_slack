module UberCommandFormatters
  def ask_for_surge_confirmation(multiplier)
    base = "#{multiplier}x surge is in effect."

    if multiplier >= 2
      [base, "Reply */uber accept #{multiplier}'* to confirm the ride."].join(" ")
    else
      [base, "Reply */uber accept* to confirm the ride"].join(" ")
    end
  end

  def parse_start_and_end_coords(user_input_string, error_message)
    raise FormatError, error_message unless user_input_string.include?(" to ")
    start_addr, end_addr = split_start_and_end_address(user_input_string)
    start_lat, start_lng = resolve_address(start_addr)
    end_lat, end_lng = resolve_address(end_addr)

    raise FormatError, bad_address_error(start_addr) if start_lat.nil?
    raise FormatError, bad_address_error(end_addr) if end_lat.nil?
    [start_lat, start_lng, end_lat, end_lng]
  end

  def split_start_and_end_address(input_str)
    origin_name, destination_name = input_str.split(" to ")

    origin_name.sub!(/^from /, "")

    origin_name = origin_name.strip
    destination_name = destination_name.strip

    [origin_name, destination_name]
  end

  def format_200_ride_request_response(origin, destination, _response)
    ack = ["Got it!", "Roger that.", "OK.", "10-4."].sample

    ["#{ack} We are looking for a driver",
     "to take you from #{origin} to #{destination}."
    ].join(" ")
  end

  def format_response_errors(response_errors)
    response = "The following errors occurred: \n"
    response_errors.each { |error| response << "- *#{error['title']}* \n" }
  end

  def format_products_response(products_response)
    unless products_response['products'] && !products_response['products'].empty?
      return "No Uber products available for that location."
    end
    response = "The following products are available: \n"
    products_response['products'].each do |product|
      response += "- #{product['display_name']}: #{product['description']}"
      response += "(Capacity: #{product['capacity']})\n"
    end
    response
  end

  def format_ride_estimate_response(start_addr, end_addr, ride_estimate_hash)
    duration_secs = ride_estimate_hash["trip"]["duration_estimate"]
    duration_mins = duration_secs / 60

    duration_msg = duration_mins == 1 ? "one minute" : "#{duration_mins} minutes"

    cost = ride_estimate_hash["price"]["display"]
    surge = ride_estimate_hash["price"]["surge_multiplier"]
    surge_msg = surge == 1 ?
      "No surge is currently in effect." :
      "Includes current surge at #{surge}x."

    [
      "Driving from #{start_addr} to #{end_addr} would take",
      "about #{duration_msg} and cost #{cost}.",
      surge_msg
    ].join(" ")
  end

  def bearer_header
    "Bearer #{bearer_token}"
  end

  def invalid_command?(name)
    !self.class::VALID_COMMANDS.include? name
  end

  def resolve_address(address)
    location = Rails.cache.fetch("address: #{address}", expires_in: 1.day) do
      Geocoder.search(address).first
    end

    return [nil, nil] if location.blank?
    location = location.data["geometry"]["location"]
    [location['lat'], location['lng']]
  end

  def bad_address_error(address)
    ["Sorry, we don't know where #{address} is.",
      "Can you try again with a more precise destination address?"
    ].join(" ")
  end

  def trigger_error(_) # No command argument.
    fail
  end
end
