module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Uncomment and configure this if you need to authenticate users
    # identified_by :current_user
    #
    # private
    #   def current_user
    #     @current_user ||= User.find_by(id: cookies.encrypted[:user_id])
    #   end
  end
end
