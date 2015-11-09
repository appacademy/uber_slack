require 'addressable/uri'

BASE_URL = "https://sandbox-api.uber.com"

VALID_COMMANDS = ['ride', 'products', 'get_eta', 'help', 'accept' ]

# returned when ride isn't requested in the format '{origin} to {destination}'
RIDE_REQUEST_FORMAT_ERROR = <<-STRING
  To request a ride please use the format */uber ride [origin] to [destination]*.
  For best results, specify a city or zip code.
  Ex: */uber ride 1061 Market Street San Francisco to 405 Howard St*
STRING

PRODUCTS_REQUEST_FORMAT_ERROR = <<-STRING
  To see a list of products please use the format */uber products [address]*.
  For best results, specify a city or zip code.
  Ex: */uber products 1061 Market Street San Francisco
STRING

UNKNOWN_COMMAND_ERROR = <<-STRING
  Sorry, we didn't quite catch that command.  Try */uber help* for a list.
STRING

HELP_TEXT = <<-STRING
  Try these commands:
  - ride [origin address] to [destination address]
  - products [address]
  - help
  - get_eta
STRING

class UberCommand

  def initialize bearer_token, user_id = nil
    @user_id = user_id
    @bearer_token = bearer_token
  end

  def run user_input_string
    input = user_input_string.split(" ")
<<<<<<< HEAD
    command_name = input.first.downcase

=======
    command_name = input.first
    command_argument = input.drop(1)
>>>>>>> 19c6d7838d165937967fe9932cbb4390a19c2f2f
    return UNKNOWN_COMMAND_ERROR if invalid_command? command_name || command_name.nil?

    response = self.send(command_name, command_argument)
    # Send back response if command is not valid
    return response
  end

  private

  attr_reader :bearer_token

  def get_eta address
    lat, lng = resolve_address(address)
    uri = Addressable::URI.parse("#{BASE_URL}/v1/estimates/time")
    uri.query_values = { 'start_latitude' => lat, 'start_longitude' => lng }

    resource = uri.to_s

    result = RestClient.get(
    resource,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
    )

    seconds = JSON.parse(result)
    # seconds = JSON.parse(result)['times'].first['estimate']
    #
    # if seconds < 60
    #   return "Your car is arriving in less than a minute"
    # else
    #   minutes = seconds/60 #Rounding down by a minute
    #   return "Your car is arriving in #{minutes} minutes"
    # end
  end

  def ride_request_details request_id
    uri = Addressable::URI.parse("#{BASE_URL}/v1/requests/#{request_id}")
    uri.query_values = { 'request_id' => request_id }
    resource = uri.to_s

    result = RestClient.get(
      resource,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
    )

    JSON.parse(result)
  end

  def cancel_ride request_id
    uri = Addressable::URI.parse("#{BASE_URL}/v1/requests/#{request_id}")
    # uri.query_values = { 'request_id' => request_id }
    resource = uri.to_s

    result = RestClient.delete(
      resource,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
    )

    "Ride Cancelled" if result
  end

  # def ride_request_map request_id
  #   uri = Addressable::URI.parse("#{BASE_URL}/v1/requests/#{request_id}/map")
  #   uri.query_values = { 'request_id' => request_id }
  #   resource = uri.to_s
  #
  #   result = RestClient.get(
  #     resource,
  #     authorization: bearer_header,
  #     "Content-Type" => :json,
  #     accept: 'json'
  #   )
  #
  #   JSON.parse(result)
  # end
  #
  # def ride_request_receipt request_id
  #   uri = Addressable::URI.parse("#{BASE_URL}/v1/requests/#{request_id}/receipt")
  #   uri.query_values = { 'request_id' => request_id }
  #   resource = uri.to_s
  #
  #   result = RestClient.get(
  #     resource,
  #     authorization: bearer_header,
  #     "Content-Type" => :json,
  #     accept: 'json'
  #   )
  #
  #   JSON.parse(result)
  # end

  def help(args = nil)   # accept and ignore extra args after help
    HELP_TEXT
  end

  def accept
    @ride = Ride.new
  end

  def ride input_arr
    split_input = input_arr.split("to")
    return RIDE_REQUEST_FORMAT_ERROR unless split_input.length == 2
    origin_name, destination_name = split_input

    origin_lat, origin_lng = resolve_address origin_name
    destination_lat, destination_lng = resolve_address destination_name

    available_products = get_products_for_lat_lng(origin_lat, origin_lng)
    product_id = available_products["products"].first["product_id"]

    body = {
      "start_latitude" => origin_lat,
      "start_longitude" => origin_lng,
      "end_latitude" => destination_lat,
      "end_longitude" => destination_lng,
      "product_id" => product_id
    }

    response = RestClient.post(
      "#{BASE_URL}/v1/requests",
      body.to_json,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
    )

    if response.code == 500
      return "Please enter a valid address. Be as specific as possible (e.g. include city)."
    end

    parsed_body = JSON.parse(response.body)

    if !parsed_body["errors"]
      return format_200_ride_request_response parsed_body
    elsif parsed_body["errors"]["code"] == "surge"
      if @user_id
        # surge = make request and get surge in price
        response = RestClient.get(
        "#{BASE_URL}/v1/estimates/price",
          body.to_json,
          authorization: bearer_header,
          "Content-Type" => :json,
          accept: 'json'
        )

        surge_multiplier = response.prices.select{ |product| product.product_id = product_id }.surge_multiplier
        Ride.create(user_id: @user_id, surge_confirmation_id: response.meta.surge_confirmation.surge_confirmation_id)
        return "Surge in price: Price has increased with #{surge_multiplier}"
      else
        return format_response_errors parsed_body['errors']
      end
    end
  end

  def products address
    if address.nil? || address == "" || address == "products"
      return "Please type in an address with your command ('/uber products [address]')."
    end
    lat, lng = resolve_address(address)
    format_products_response(get_products_for_lat_lng lat, lng)
  end

  def get_products_for_lat_lng lat, lng
    uri = Addressable::URI.parse("#{BASE_URL}/v1/products")
    uri.query_values = { 'latitude' => lat, 'longitude' => lng }
    resource = uri.to_s

    result = RestClient.get(
    resource,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
    )

    JSON.parse(result.body)
  end

  def format_200_ride_request_response response
    eta = response['eta'].to_i / 60
    "Thanks!  A driver will be on their way soon. We expect them to arrive in #{eta} minutes."
  end

  def format_response_errors response_errors
    response = "The following errors occurred: \n"
    response_errors.each do |error|
      response += "- *#{error['title']}* \n"
    end
  end

  def format_products_response products_response
    unless products_response['products'] && !products_response['products'].empty?
      return "No Uber products available for that location."
    end
    response = "The following products are available: \n"
    products_response['products'].each do |product|
      response += "- #{product['display_name']}: #{product['description']} (Capacity: #{product['capacity']})\n"
    end
    response
  end

  def bearer_header
    "Bearer #{bearer_token}"
  end

  def invalid_command? name
    # VALID_COMMANDS.include? name ? false : true
    !VALID_COMMANDS.include? name
  end

  def resolve_address address
    location = Geocoder.search(address.join(" "))[0].data["geometry"]["location"]
    if location.nil?
      return "Please enter a valid address. Be as specific as possible (e.g. include city)."
    end
    [location['lat'], location['lng']]
  end

end
