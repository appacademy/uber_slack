class AdminConstraint
  def matches?(request)
    return true
    session_token = request.path_parameters[:token]
    return false unless session_token
    user = User.find_by(session_token: session_token)
    user && user.admin?
  end
end
