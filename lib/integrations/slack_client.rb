binding.pry
module SlackClient
  def self.add_to_channel(code)
    slack_auth_params = {
      client_secret: ENV['slack_client_secret'],
      client_id:     ENV['slack_client_id'],
      redirect_uri:  ENV['slack_redirect'],
      code: code
    }

    RestClient.post(ENV['slack_oauth_url'], slack_auth_params)
  rescue RestClient::Exception => e
    raise Exception.new
  end

  class Exception
  end
end
