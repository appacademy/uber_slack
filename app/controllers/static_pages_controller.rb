class StaticPagesController < ApplicationController
  def root
  end

  def user_success
  end

  def privacy_policy
  end

  def admin_success
  end

  def added_to_slack
  end

  def join_slack_team
    @user = User.new
  end

  def slack_success
  end

  def slack_resent
  end

  def slack_fail
  end
end
