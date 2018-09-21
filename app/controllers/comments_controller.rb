class CommentsController < ApplicationController
    def comments
        @id=params[:id]
        @user = User.find_by_id(@id) 
        @posts = @user.posts
        @allUserComments = @user.comments   
        @allUserComments = @allUserComments.sort_by{|k| k[:score] }
        @allComments=Kaminari.paginate_array(@allUserComments).page(params[:page]).per(50)
    end
        
    def topComments #sort by number of times
        @id=params[:id]
        @type = params[:type]
        @user = User.find_by_id(@id) 
        @posts = @user.posts
        @comments = @user.comments.to_a
        @comments =@comments.sort_by{|k| k.username}
        t =1
        total = @comments[0].score
        list = []
        for i in 0..@comments.length-2
            if @comments[i].username == @comments[i+1].username
                t = t+1
                total = total + @comments[i+1].score
            else 
                list.push({username: @comments[i].username, comment_times: t, totalScore: total, score: total/t})
                t =1
                total = @comments[i+1].score
            end
        end
        list = list.reject {|k| k[:username] ==@user.username}
        @top_list =list.sort_by{|k| k[:comment_times]}
        @top_list = @top_list.last(50).reverse
        if @type == "highest"
            @top_list =list.sort_by{|k| k[:totalScore]}
            @top_list = @top_list.last(50).reverse
        end
        if @type == "lowest"
            @top_list =list.sort_by{|k| k[:totalScore]}
            @top_list = @top_list.first(50)
        end
    end
    def singleUserComments
        id=params[:id]
        @username = params[:name]
        @user = User.find_by_id(id) 
        @posts = @user.posts
        @Comments = @user.comments.where('username=?', @username)
    end

end
