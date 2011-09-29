# -*- encoding : utf-8 -*-
class UsersController < ApplicationController
  before_filter :login_required, :only => [ :logout, :update ]

  def index
    if session[:user].nil?
      render :template => 'users/login'
    else
      render :template => 'users/index'
    end
  end

  def logout
    session[:user] = nil
    redirect_to search_path
  end

  #:nocov:
  # We can't run tests on this method, as there's no way to mock the API
  # interaction with the Janrain server.
  def rpx
    data = {}
    RPXNow.user_data(params[:token], :additional => [:name, :email, :verifiedEmail]) { |raw| data = raw['profile'] }
    @user = User.find_or_initialize_with_rpx(data)
    if @user.new_record?
      logger.debug "First time we've seen this user, render the form"
      render :template => 'users/form'
    else
      logger.debug "We've seen this user before, redirect to the datasets page"
      reset_session
      session[:user] = @user
      redirect_to datasets_path(:locale => @user.language)
    end
  end
  #:nocov:

  def create
    @user = User.new
    @user.name = params[:user][:name]
    @user.email = params[:user][:email]
    @user.identifier = params[:user][:identifier]
    @user.language = params[:user][:language]

    logger.debug "Created new user: #{@user.attributes.inspect}"
    logger.debug "User should be valid: #{@user.valid?}"
    
    if @user.save
      reset_session
      session[:user] = @user
      redirect_to datasets_path(:locale => @user.language)
    else
      render :template => 'users/form'
    end
  end

  def update
    user = session[:user]
    if user.update_attributes(params[:user])
      redirect_to users_path(:locale => user.language), :rel => 'external'
    else
      render "index"
    end
  end
end
