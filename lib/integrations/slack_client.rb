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

  def self.invite(email, first_name)
    post_url  = "https://uber-on-slack.slack.com/api/users.admin.invite?"
    post_url += "t=#{ENV['slack_invite_bot']}"
    post_url += "&token=#{ENV['slack_team_token']}"
    params = {
      email: email,
      first_name: first_name,
      set_active: true,
      _attempts: 1
    }

    RestClient.post(post_url, params)
  rescue RestClient::Exception => e
    Rollbar.error(e)
  end

  # class Request
  #   def

  #   end
  # end

  class Exception
  end
end
