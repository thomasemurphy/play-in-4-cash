class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    redirect_to new_session_path
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Welcome! Make your picks below."
    else
      @registration_user = @user
      if @user.errors.where(:email_address, :taken).any?
        flash.now[:account_exists] = true
      end
      render "sessions/new", status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @registration_user = @user
    flash.now[:account_exists] = true
    render "sessions/new", status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
