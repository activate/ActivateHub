class UsersController < ApplicationController

  def params
    @params ||= UntaintedParams.new(super).for(action_name)
  end

  def show
    @user = User.where(id: params[:format]).first
  end

  class UntaintedParams < SimpleDelegator
    def for(action)
      respond_to?("for_#{action}") ? send("for_#{action}") : __getobj__
    end

    def for_show
      permit(:format)
    end
  end

end
