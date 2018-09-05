class ApplicationController < ActionController::Base
    before_action :set_page

    def set_page
      @id = params[:id]
      if @id.nil?
        @name=''
      else
        @link_index="index?id=#{@id}"
        @link_index_sort_highest = "index?id=#{@id}&type=highest"
        @link_index_sort_lowest = "index?id=#{@id}&type=lowest"
        @link_comment="comments?id=#{@id}"
      end

    end
end
