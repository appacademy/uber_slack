require 'addressable/uri'

BASE_URL = "https://sandbox-api.uber.com"
VALID_COMMANDS = ['ride', 'products']

class UberCommand

  def initialize bearer_token
    @bearer_token = bearer_token
  end

  def run user_input_string
    input = user_input_string.split(" ")
    command_name = input.first

    return "Unknown command" if invalid_command? command_name

    response = self.send(command_name, input.drop(1))
    # Send back response if command is not valid
    return response
  end

  private

  attr_reader :bearer_token

  def help
    lines = <<-STRING
      Try these commands:
      - ride [origin address] to [destination address]
      - products [address]
      - help
    STRING
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

    return response.body
  end

  def products address
    geocoder_location = Geocoder.search(address)[0].data["geometry"]["location"]
    lat, lng = geocoder_location['lat'], geocoder_location['lng']
    get_products_for_lat_lng lat, lng
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

  def bearer_header
    "Bearer #{bearer_token}"
  end

  def invalid_command? name
    VALID_COMMANDS.includes? name ? false : true
  end

  def resolve_address address
    location = Geocoder.search(address)[0].data["geometry"]["location"]
    [location['lat'], location['lng']]
  end

end
