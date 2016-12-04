class VersionsController < ApplicationController

  def params
    @params ||= UntaintedParams.new(super).for(action_name)
  end

  def edit
    @version = PaperTrail::Version.find(params[:id])
    @record = @version.next.try(:reify) || @version.item || @version.reify

    singular = @record.class.name.singularize.underscore
    plural = @record.class.name.pluralize.underscore
    self.instance_variable_set("@#{singular}", @record)

    if request.xhr?
      render :partial => "/#{plural}/form", :locals => { singular.to_sym =>  @record }
    else
      render "#{plural}/edit", :locals => { singular.to_sym =>  @record }
    end
  end

  class UntaintedParams < SimpleDelegator
    def for(action)
      respond_to?("for_#{action}") ? send("for_#{action}") : __getobj__
    end

    def for_edit
      permit(:id)
    end
  end

end
