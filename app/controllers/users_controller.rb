class UsersController < ApplicationController
  layout 'users'
  
  include BHL::Login
  
  # GET /users/new
  def new
    redirect_to :controller => :users, :action => :show, :id => @user.id if is_loggged_in?
    @page_title = I18n.t(:sign_up)
    @user = User.new
  end
  
  # POST /users
  def create
    return redirect_to :controller => :users, :action => :show, :id => @user.id if is_loggged_in?
    @user = User.new(params[:user])
    if @user.valid? && verify_recaptcha
      @user.save
      url = "#{request.host}:#{request.port}/users/activate/#{@user.guid}/#{@user.verification_code}"
      Notifier.user_verification(@user, url)
      log_in(@user)
      flash.now[:notice] = I18n.t(:registration_welcome_message, :real_name => @user.real_name)
      flash.keep
      redirect_to :controller => :users, :action => :show, :id => @user.id
    else
      @page_title = I18n.t(:sign_up)
      @user.errors.add('recaptcha', I18n.t("form_validation_errors_for_attribute_assistive")) unless verify_recaptcha
      render :action => :new
    end
  end
  
  # GET /users/forget_password
  def forgot_password
    return redirect_to :controller => :users, :action => :show, :id => @user.id if is_loggged_in?
    @page_title = I18n.t(:forgot_password_title)
  end

  def change_password
  end

  def edit_profile
  end
  
  # GET /users/activate/:guid/:activation_code
  def activate
    @user = User.find_by_guid_and_verification_code(params[:guid], params[:activation_code])
    if @user.nil?
      flash[:error] = I18n.t(:activation_failed)
      flash.keep
      return redirect_to root_path
    end
    if @user.active
      flash[:error] = I18n.t(:account_already_active)
      flash.keep
      redirect_to root_path
    else
      @user.active = 1
      @user.verified_date = Time.now
      @user.save
      flash.now[:notice] = I18n.t(:account_activated, :real_name => @user.real_name)
      flash.keep
      Notifier.user_activated(@user)
      if is_loggged_in?
        log_out
        log_in(@user) # to make sure everything is loaded properly
      end
      redirect_to root_path
    end
  end
  
  # GET /users/:id
  def show
    @id = params[:id]
    @id = session[:user_id] if @id.nil? 
    return redirect_to root_path if @id.nil?
    @user = User.find_by_id(@id)
    return redirect_to root_path if @user.nil?
    
    @can_edit = @id.to_i == session[:user_id]
    
    @page_title = @user.real_name
  end
  
  # POST /users/recover_password
  def recover_password
    return redirect_to :controller => :users, :action => :show, :id => @user.id if is_loggged_in?
    
    @email = params[:user][:email]
    return redirect_to users_forgot_password_path unless @email
    @user = User.find_by_email(@email)
    
    if @user.nil?
      flash.now[:error] = I18n.t(:user_not_found_by_email_address, :email => @email)
      flash.keep
      redirect_to users_forgot_password_path
    else
      # I am changing activation code, then send an email with a link to reset password
      @user.change_activation_code
      reset_password_url = "#{request.host}:#{request.port}/users/reset_passwpord/#{@user.guid}/#{@user.verification_code}"
      Notifier.user_reset_password_verification(@user, reset_password_url)
      flash.now[:notice] = I18n.t(:recover_password_success)
      flash.keep
      redirect_to :controller => :users, :action => :login
    end
  end
  
  # GET /users/reset_password/:guid/:activation_code
  def reset_password
    @user = User.find_by_guid_and_verification_code(params[:guid], params[:activation_code])
    if @user.nil?
      flash[:error] = I18n.t(:reset_password_failed)
      flash.keep
      return redirect_to root_path
    end
    
    @page_title = I18n.t(:reset_password)
  end
  
  #POST /users/reset_password_action
  def reset_password_action
    # I need to double check
    @user = User.find_by_guid_and_verification_code(params[:user][:guid], params[:user][:activation_code])
    if @user.nil?
      flash[:error] = I18n.t(:reset_password_failed)
      flash.keep
      return redirect_to root_path
    end
    
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    
    if @user.valid? && @user.save
        flash[:notice] = I18n.t(:reset_password_success)
        flash.keep
        redirect_to :controller => :users, :action => :login
    else
      flash[:error] = @user.errors.full_messages.join("<br>")
      flash.keep
      return redirect_to "/users/reset_password/#{params[:user][:guid]}/#{params[:user][:activation_code]}"
    end
  end
  
  # GET /users/logout
  def logout
    log_out
    redirect_to root_path
  end
  
  # GET /users/login
  def login
    return redirect_to :controller => :users, :action => :show, :id => @user.id if is_loggged_in?
    @page_title = I18n.t(:sign_in)
  end
  
  # POST /users/validate
  def validate
    return redirect_to :controller => :users, :action => :show, :id => @user.id if is_loggged_in?
    username = params[:user][:username]
    password = params[:user][:password]
    @user = User.authenticate(username, password)
    
    if @user.nil?
      flash.now[:error] = I18n.t(:sign_in_unsuccessful_error)
      flash.keep
      redirect_to :controller => :users, :action => :login
    else
      log_in(@user)
      flash.now[:notice] = I18n.t(:sign_in_successful_notice)
      flash.keep
      if params[:return_to].blank?
        redirect_to :controller => :users, :action => :show, :id => @user.id
      else
        redirect_to params[:return_to]
      end
    end
  end
  
  # POST /users/update
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
        format.json { respond_with_bip(@user) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(@user) }
      end
    end
  end
end