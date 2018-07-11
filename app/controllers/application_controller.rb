class ApplicationController < ActionController::Base
    before_action :set_page

    def set_page
      @id = params[:id]
      if @id.nil?
        @name=''
      else
        @link_index="index?id=#{@id}"
        @link_comment="comments?id=#{@id}"
      end

    end
end
