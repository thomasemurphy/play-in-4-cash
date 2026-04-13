class AccountsController < ApplicationController
  before_action :require_authentication

  def edit
  end

  def update
    if Current.user.update(account_params)
      redirect_to edit_account_path, notice: "Display name updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:user).permit(:display_name)
  end
end
