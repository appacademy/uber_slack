class ErrorsController < ActionController::Base
  def not_found
    if env["REQUEST_PATH"] =~ /api/
      render :status => 404,
             :text => [
               "I'm sorry, something went wrong in our app.",
               "If you need a ride right now, we recommend using the regular app",
               "as we try to figure out what went wrong. Sorry about the",
               "inconvenience!"
             ].join(" ")
    else
      render :text => "404 Not found", :status => 404
    end
  end

  def exception
    if env["REQUEST_PATH"] =~ /api/
      render :status => 404,
             :text => [
               "I'm sorry, there was an error in our app.",
               "If you need a ride right now, we recommend using the regular app",
               "as we try to figure out what went wrong. Sorry about the",
               "inconvenience!"
             ].join(" ")
    else
      render :text => "500 Internal Server Error", :status => 500
    end
  end
end
