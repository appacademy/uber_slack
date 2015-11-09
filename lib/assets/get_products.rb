require 'addressable/uri'

BASE_URL = "https://sandbox-api.uber.com"
VALID_COMMANDS = ['ride', 'products']

class UberCommand

  def initialize bearer_token, user_id = nil
    @user_id = user_id
    @bearer_token = bearer_token
  end

  def run user_input_string
    input = user_input_string.split(" ")
    command_name = input.first

    return "Unknown command" if invalid_command? command_name

    response = self.send(command_name, input.drop(1).join(" "))
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

  def accept
    @ride = Ride.where(user_id: @user_id).order(:updated_at).last
    if (Time.now - @ride.updated_at) > 5.minutes
      @ride.delete!
      return ride "1061 Market Street, San Francisco, CA to 1 Mandor Dr, San Francisco, CA"
    else
      return ride "1061 Market Street, San Francisco, CA to 1 Mandor Dr, San Francisco, CA", @ride.surge_confirmation_id
    end
  end

  def ride input_str, surge_id = nil
    origin_name, destination_name = input_str.split(" to ")

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

    debugger
    body["surge_confirmation_id"] = surge_id if surge_id

    # debugger
    begin
      response = RestClient.post(
      "#{BASE_URL}/v1/requests",
      body.to_json,
      authorization: bearer_header,
      "Content-Type" => :json,
      accept: 'json'
      )


      parsed_body = JSON.parse(response.body)
      return parsed_body
    rescue RestClient::Conflict => e
      if @user_id
        # surge = make request and get surge in price
        uri = Addressable::URI.parse("#{BASE_URL}/v1/estimates/price")
        uri.query_values = body
        resource = uri.to_s

        response = RestClient.get(
        resource,
        authorization: bearer_header,
        "Content-Type" => :json,
        accept: 'json'
        )

        parsed_response = JSON.parse(response.body)
        surge_multiplier = parsed_response["prices"].select{ |product| product["product_id"] == product_id }[0]["surge_multiplier"]
        # debugger
        Ride.create(user_id: @user_id, surge_confirmation_id: JSON.parse(e.response)["meta"]["surge_confirmation"]["surge_confirmation_id"])
        return "Surge in price: Price has increased with #{surge_multiplier}"
      else
        return "error: no user ID"
      end
    end
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
    VALID_COMMANDS.include? name ? false : true
  end

  def resolve_address address
    location = Geocoder.search(address)[0].data["geometry"]["location"]
    [location['lat'], location['lng']]
  end

end
