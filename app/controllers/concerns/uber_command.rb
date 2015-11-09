require 'addressable/uri'

BASE_URL = "https://sandbox-api.uber.com/v1"
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


  def products address
    geocoder_location = Geocoder.search(address)[0].data["geometry"]["location"]
    lat, lng = geocoder_location['lat'], geocoder_location['lng']
    get_products_for_lat_lng lat, lng
  end

  def get_products_for_lat_lng lat, lng
    uri = Addressable::URI.parse("#{BASE_URL}/products")
    uri.query_values = { 'latitude' => lat, 'longitude' => lng }
    resource = uri.to_s

    result = RestClient.get(
      resource,
      headers: auth_header,
      authorization: bearer_string,
      "Content-Type" => :json,
      accept: 'json'
    )

    JSON.parse(result.body)
  end

  def bearer_string
    "Bearer #{bearer_token}"
  end

  def invalid_command? name
    VALID_COMMANDS.include? name ? false : true
  end
end
