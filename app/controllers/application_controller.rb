class ApplicationController < ActionController::Base
    before_action :set_page

    def set_page
      @id = params[:id]
      if @id.nil?
        @name=''
      else
        @link_index="index?id=#{@id}"
        #all posts
        @link_index_sort_highest = "index?id=#{@id}&type=highest"
        @link_index_sort_lowest = "index?id=#{@id}&type=lowest"
        #all comments
        @link_comment="comments?id=#{@id}"
        #top
        @link_top="top-fans?id=#{@id}"
        @link_score="top-fans?id=#{@id}&type=highest"
        @link_negative="top-fans?id=#{@id}&type=lowest"
      end

    end
end
