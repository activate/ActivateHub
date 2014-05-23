class UsersController < ApplicationController
  def show
    @user = User.where(id: params[:format]).first
  end
end
