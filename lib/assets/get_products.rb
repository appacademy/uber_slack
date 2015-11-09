class UberCommand

  def initialize (bearer_token)
    @bearer_token = bearer_token
    @rides = {}
  end

  def run user_input_string
    input = user_input_string.split(" ")
    # @start_lat = Geocoder.search("2775 park street, berkeley ca 94702")[0].data["geometry"]["location"]["lat"]
    # @start_lng = Geocoder.search("2775 park street, berkeley ca 94702")[0].data["geometry"]["location"]["lng"]
    command_name = input.first
    address = input.drop(1).join(" ")
    @start_lat = Geocoder.search(address)[0].data["geometry"]["location"]["lat"]
    @start_lng = Geocoder.search(address)[0].data["geometry"]["location"]["lng"]
    response = self.send(command_name)
    # Send back response if command is not valid
    return response
  end

  private
  attr_reader :bearer_token

  def ride
    product_id = get_estimates["products"][0]["product_id"]
    body = {
      "start_latitude" => @start_lat,
      "start_longitude" => @start_lng,
      "product_id" => product_id
    }

    response = RestClient.post(
      "https://sandbox-api.uber.com/v1/requests",
      body.to_json,
      :authorization => "Bearer #{bearer_token}",
      "Content-Type" => :json,
      :accept => 'json'
    )
    return response.body
  end

  def get_estimates
    # get this one out
    # @bearer_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzY29wZXMiOlsicHJvZmlsZSIsImhpc3RvcnlfbGl0ZSIsImhpc3RvcnkiLCJyZXF1ZXN0Il0sInN1YiI6ImJkNjYxMWRiLWM1MGQtNGQyYi04NDNhLWExNWNiOTY4NjI2NyIsImlzcyI6InViZXItdXMxIiwianRpIjoiNzYyZWZkZjEtMzMzOC00MjQzLWIwYWItNTgzZmEzNTZmZDQ2IiwiZXhwIjoxNDQ5NjE5NzMzLCJpYXQiOjE0NDcwMjc3MzIsInVhY3QiOiJjRHJaYzA3MHl3M0pOSWwyRWZ2S2NpNEFONWd2bnQiLCJuYmYiOjE0NDcwMjc2NDIsImF1ZCI6IkI0SzhYTmV5SXE0cXNJMFFxQ044SU5HdjdadG4xWElMIn0.A0qYrArYik0OYP79oTgGZcDkDKRMNoeDF-xm93r-ujJWjY2a5s-1K8hjtSJlwLdTYK6qGWCYF226_XLBLwCk000xPM5pRs0OfObIkGBL8ddyngDSmtzYg0v6Ulo9CXdapNjtVxhWlSp-dBkRfEjNoLRk_hN20Af6wMD5a_Mh4F9J29VnwruynCIQercf_BVP88mm3FQxgH9te2QbA0B5QWEfOusVlnlu8mxP4U8hfvES5G7SW3TB1SvYqhPYHT6f73DUqQKRbDzATz5GMJvhP-B_y4SCrwXuf922qvNkKazR886me2L-ZHk0Mc2GzspJa_Os0fLu2aykpOrgGyJ91g"
    get_estimates_params = {
      'latitude' => @start_lat.to_s,
      'longitude' => @start_lng.to_s
    }
    header = {Authorization: ("Bearer #{bearer_token}"),
              params: get_estimates_params}
    result = RestClient.get("https://sandbox-api.uber.com/v1/products", header)

    JSON.parse(result.body)
  end
end
#
#   def request_uberX
#     product_id = get_estimates["products"][0]["product_id"]
#     body = {
#       "start_latitude" => @start_lat,
#       "start_longitude" => @start_lng,
#       "product_id" => product_id
#     }
#     # headers = {
#     #   "Authorization" => "Bearer #{bearer_token}",
#     #   "Content-Type" => "application/json"
#     # }
#
#     response = RestClient.post(
#       "https://sandbox-api.uber.com/v1/requests",
#       body.to_json,
#       :authorization => "Bearer #{bearer_token}", "Content-Type" => :json, :accept => 'json'
#     )
#     puts response.body
#     # result = RestClient.post("localhost:3000/api/echo", header, body)
#   end
#
#   private
#
#   attr_reader :bearer_token
# end

=begin

class UberCommand
  def initialize bearer_token
    @bearer_token = bearer_token
  end

  def run user_input_string

    input = user_input_string.split(" ")
    command_name = input.first
    response = self.send(command_name)

    return response
  end

  private

  def ride

    return message to user
  end

  def get_estimates
      return message to user+
  end

  attr_reader :bearer_token
=end
