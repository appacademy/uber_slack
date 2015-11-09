require 'addressable/uri'

BASE_URL = "https://sandbox-api.uber.com"
VALID_COMMANDS = ['ride', 'products', 'get_eta', 'help', 'accept' ]

class UberCommand

  def initialize bearer_token, user_id = nil
    @user_id = user_id
    @bearer_token = bearer_token
  end

  def run user_input_string
    input = user_input_string.split(" ")
    command_name = input.first

    return "Unknown Command" if invalid_command?(command_name)

    response = self.send(command_name, input.drop(1))
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

  def help
    lines = <<-STRING
    Try these commands:
    - ride [origin address] to [destination address]
    - products [address]
    - help
    STRING
  end

  def accept
    @ride = Ride.new
  end

  def ride input_str
    origin_name, destination_name = input_str.split("to")

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

    parsed_body = JSON.parse(response.body)

    if !parsed_body["errors"]
      return parsed_body
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
        return parsed_body['errors']
      end
    end
  end

  def products address
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
    [location['lat'], location['lng']]
  end

end
