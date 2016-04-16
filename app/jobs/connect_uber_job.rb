class ConnectUberJob < ActiveJob::Base
  queue_as :auth

  def perform(code)
    # After user has clicked "yes" on Uber OAuth page
    UberAPI.connect_uber(code)
  end
end