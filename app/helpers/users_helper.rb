module UsersHelper
  def logged_in?
    session[:user_id].nil? ? false : true
  end
end