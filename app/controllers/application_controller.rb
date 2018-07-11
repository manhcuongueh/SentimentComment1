class ApplicationController < ActionController::Base
    before_action :set_page

    def set_page
      @id = params[:id]
      if @id.nil?
        @link="index"
        @name=''
      else
        @link="index?id=#{@id}"
        user=User.find_by_id(@id)
        @name=user.username
      end

    end
end
