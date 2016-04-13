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
    # noop for now, handle it here later
    raise e
  end

  # class Request
  #   def

  #   end
  # end

  class Exception
  end
end
