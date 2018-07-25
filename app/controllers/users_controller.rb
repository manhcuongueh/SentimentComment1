class UsersController < ApplicationController
    def new
        @users = User.all.page(params[:page]).per(10)
    end

    def index    
        @id=params[:id]
        @user = User.find_by_id(@id)
        @posts= @user.posts     
        #array of the number of comment in a post
        @comment_count=[]
        @all_links=[]
        #array of min(each post)
        @min=[]
        #array of max(each post)
        @max=[]
        #array of average(each post)
        @average=[]
        #for loop to find max, min ...
        for i in @posts
            score=[]
            @get_comments = i.comments
            for cm in  @get_comments
                score.push(cm.score)
                @all_links.push(cm)
            end
            @min.push(score.min)
            @max.push(score.max)
            aver=score.inject(0.0) { |sum, el| sum + el } / score.length
            @average.push(aver.round(3))
            @comment_count.push(@get_comments.length)
        end 
        # min, max, average of all comment
        if @all_links.size != 0
            #max
            max_item=@all_links.max_by{|k| k[:score] }
            @max_all_url=@posts.find_by_id(max_item.post_id)
            @max_all_url=@max_all_url['link']
            @max_all=max_item.score
            #min
            min_item=@all_links.min_by{|k| k[:score] }
            @min_all_url=@posts.find_by_id(min_item.post_id)
            @min_all_url=@min_all_url['link']
            @min_all=min_item.score
            #average
            @average_all=@all_links.inject(0.0) { |sum, el| sum + el.score } / @all_links.length
            @average_all=@average_all.round(3)
        else
            #max
            @max_all_url=''
            @max_all=0
            #min
            @min_all_url=''
            @min_all=0
            #average
            @average_all=0
        end

    end
    def all_comments
        @id=params[:id]
        @user = User.find_by_id(@id)
        @posts= @user.posts     
        #array of the number of comment in a post
        @comment_count=[]
        @all_links=[]
        #array of min(each post)
        @min=[]
        #array of max(each post)
        @max=[]
        #array of average(each post)
        @average=[]
        #for loop to find max, min ...
        for i in @posts
            score=[]
            @get_comments = i.comments
            for cm in  @get_comments
                score.push(cm.score)
                @all_links.push(cm)
            end
            @min.push(score.min)
            @max.push(score.max)
            aver=score.inject(0.0) { |sum, el| sum + el } / score.length
            @average.push(aver.round(3))
            @comment_count.push(@get_comments.length)
        end 
        # min, max, average of all comment
        if @all_links.size != 0
            #max
            max_item=@all_links.max_by{|k| k[:score] }
            @max_all_url=@posts.find_by_id(max_item.post_id)
            @max_all_url=@max_all_url['link']
            @max_all=max_item.score
            #min
            min_item=@all_links.min_by{|k| k[:score] }
            @min_all_url=@posts.find_by_id(min_item.post_id)
            @min_all_url=@min_all_url['link']
            @min_all=min_item.score
            #average
            @average_all=@all_links.inject(0.0) { |sum, el| sum + el.score } / @all_links.length
            @average_all=@average_all.round(3)
        else
            #max
            @max_all_url=''
            @max_all=0
            #min
            @min_all_url=''
            @min_all=0
            #average
            @average_all=0
        end
        @all_links = @all_links.sort_by{|k| k[:score] }
        @all_comments=Kaminari.paginate_array(@all_links).page(params[:page]).per(50)
    end

    def show
       #get param
       @id=params[:id]
       @post_id=params[:post_id]
       @type=params[:type]
       #find user 
       @user=User.find_by_id(@id)
       @posts= @user.posts 
       @all_comments=@posts.find_by_id(@post_id).comments
       @comments=@all_comments.page(params[:page]).per(50)
       if @type=="rank"
           sort_comments= @all_comments.sort_by{|k| k[:score] }
           @comments=Kaminari.paginate_array(sort_comments).page(params[:page]).per(50)
       end
    end    
    
    def delete
        @id=params[:id]
        @user = User.find_by_id(@id)
        @user.destroy
        redirect_to root_path
    end
=begin
---------------------------------***********************--------------------------
    This area is the code for crawling data from instagram when clicking submit on homepage
---------------------------------***********************--------------------------
=end
def create
    flash.clear
    #declare dom of posts
    @post_dom=[]
    #Get Instagram Url
    @insta_url=params[:insta_url]
    #remove data of existing account 
    User.find_each { |c| c.destroy if c.username==@insta_url}
    #run chrome
    @@bot = Selenium::WebDriver.for :chrome 
    sleep 1
    @@bot.navigate.to "https://www.instagram.com/#{@insta_url}"
    sleep 1  
    if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div/div/div/div').size >0 
        #Save Instagram account
        @users=User.create(username:  @insta_url)         
        #close login requirement 
        @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/div/section/div/a').click
        
        #scroll down the account page and save dom
        for i in 0..8
            @@bot.action.send_keys(:end).perform
            sleep 1
            #save dom after 8 times press page down button
            if i%4==0
                # elements contain the content of a post
                dom=@@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div/div/div/div')
                for i in dom
                    if i.find_elements(:tag_name,'a').size>0
                        dom=[];
                        dom[0]=i.find_element(:tag_name,'a')['href']
                        dom[1]=i.find_element(:tag_name,'img')['src']
                        @post_dom.push(dom) 
                    end   
                end      
            end 
        end
        #avoid duplicate when save dom
        @post_dom=@post_dom.uniq
        #Get exactly 100 post
        @post_dom=@post_dom[0..99]
        @k=0
        # Instantiates a client
        language = Google::Cloud::Language.new
        for i in 0..@post_dom.length-1   
            @@bot.navigate.to "#{@post_dom[i][0]}"
            #save like, image and date
            date = @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[2]/a/time')['title']
            @post=@users.posts.create(
                link: @post_dom[i][0],
                image: @post_dom[i][1],
                date: date
            )
            #set time to reload, change session
            @start_time= Time.now
            while @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@role="button"]').size > 0 do
                @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a').click
                sleep 0.5
                if (Time.now > @start_time + 60)
                    sleep 3 
                    if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@disabled=""]').size > 0                    
                        if @k==0 
                            @@bot.quit()
                            @@bot = Selenium::WebDriver.for :chrome 
                            @@bot.manage.window.maximize
                            @@bot.navigate.to "https://www.instagram.com/accounts/login/?force_classic_login"
                            sleep 0.5
                            #using username and password to login
                            @@bot.find_element(:id, 'id_username').send_keys 'cuong_manh248'
                            @@bot.find_element(:id, 'id_password').send_keys '24081991'
                            @@bot.find_element(:class, 'button-green').click
                            sleep 0.5
                            @@bot.navigate.to "#{@post_dom[i]}"  
                            @k=1
                            @start_time= Time.now
                        else  
                            @@bot.quit()
                            @@bot = Selenium::WebDriver.for :chrome 
                            @@bot.manage.window.maximize
                            @@bot.navigate.to "#{@post_dom[i]}"
                            sleep 0.5
                            @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/div/section/div/a').click
                            @k=0
                            @start_time= Time.now
                        end
                    else
                        @start_time= Time.now
                    end
                end
             end
                #find comments
                dom_comment=@@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li')
                dom_comment.shift
                #for solving unsupported languages
                @text = "Google, headquartered in Mountain View."
                @username = []
                for d in dom_comment
                    comment=d.find_element(:tag_name, 'span').text
                    comment=comment.gsub(/[!().~`,:;<>?|'"{}\\\/\[\]]/,' ')
                    comment=comment.gsub("\n",' ')
                    if comment.scan(/[a-zA-Z ]/).size==1
                        comment.insert(0,"-")
                    end
                    #for sure each comment is each sentence
                    comment.insert(-1,".")
                    @text << "\n"
                    @text << "\n"
                    @text << comment
                    @username.push(d.find_element(:tag_name, 'a')['title'])
                end
                # Detects the sentiment of the text
                response = language.analyze_sentiment content: @text, type: :PLAIN_TEXT
                # Get document sentiment from response
                sentences = response.sentences
                sentences.shift
                @n=0
                for e in 0..@username.length-1  
                    if !sentences[e].text.content.include? "."
                        @n=@n+1
                    end
                    users_comments=@post.comments.create(
                        username:@username[e],
                        body:sentences[e+@n].text.content,
                        score:sentences[e+@n].sentiment.score
                        )
                end
        end
            @@bot.quit()
            redirect_to index_path(id: @users.id)
    else
        flash[:warning] = "Please enter the valid username!"
        @@bot.quit()
        redirect_to root_path
    end
end
=begin
---------------------------------***********************--------------------------
    This area is code to save data to excel file
---------------------------------***********************--------------------------
=end
    def write_excel
        #get param
        @id=params[:id]
        @type=params[:type]

        @user = User.find_by_id(@id)
        @posts= @user.posts 
        @comments=[]
        #get comments    
        for post in @posts
            @get_comments=post.comments
            for cm in  @get_comments
                @comments.push(cm)
            end
        end
        #generate new Excel file
        workbook = RubyXL::Workbook.new
        worksheet=workbook[0]
        #save information for all post
        if(@type=="single")
            worksheet.add_cell(0, 0, "ID")
            worksheet.add_cell(0, 1, "IMAGE")
            worksheet.add_cell(0, 2, "URL")
            worksheet.add_cell(0, 3, "LOWEST SCORE")
            worksheet.add_cell(0, 4, "HIGHEST SCORE")
            worksheet.add_cell(0, 5, "AVERAGE")
                i=0
                for post in @posts
                    @get_comments=post.comments
                    post_score=[]
                    for cm in  @get_comments
                        post_score.push(cm.score)
                    end
                    @average=post_score.inject(0.0) { |sum, el| sum + el } / post_score.length

                    worksheet.add_cell(i+1, 0, i+1)
                    worksheet.add_cell(i+1, 1, post.image)
                    worksheet.add_cell(i+1, 2, post.link)
                    worksheet.add_cell(i+1, 3, post_score.min)
                    worksheet.add_cell(i+1, 4, post_score.max)
                    worksheet.add_cell(i+1, 5, @average)  
                    i=i+1   
                end
                #name for excel file
                name=@posts.first
                name=name['link']
                name=name.split('=')[-1]
                workbook.write("data/#{name}.xlsx")
                send_file(
                    "#{Rails.root}/data/#{name}.xlsx",
                    filename: "#{name}.xlsx",
                    type: "application/xlsx"
                  )
                #redirect_to index_path(id: @id)
        #save all comments to excel file
        elsif(@type=="all")
            worksheet.add_cell(0, 0, "ID")
            worksheet.add_cell(0, 1, "USERNAME")
            worksheet.add_cell(0, 2, "COMMENT")
            worksheet.add_cell(0, 3, "SCORE")
            i=1
            for comment in @comments
                worksheet.add_cell(i, 0, i)
                worksheet.add_cell(i, 1, comment.username)
                worksheet.add_cell(i, 2, comment.body)
                worksheet.add_cell(i, 3, comment.score)
                i=i+1
            end
            name=@posts.first
            name=name['link']
            name=name.split('=')[-1]
            workbook.write("data/#{name}-all-comments.xlsx")
            send_file(
                "#{Rails.root}/data/#{name}-all-comments.xlsx",
                filename: "#{name}-all-comments.xlsx",
                type: "application/xlsx"
              )
            #redirect_to index_path(id: @id)
        else
            worksheet.add_cell(0, 0, "ID")
            worksheet.add_cell(0, 1, "USERNAME")
            worksheet.add_cell(0, 2, "COMMENT")
            worksheet.add_cell(0, 3, "SCORE")
            comments_sort=@comments.sort_by{|k| k[:score] }
            i=1
            for comment in comments_sort
                worksheet.add_cell(i, 0, i)
                worksheet.add_cell(i, 1, comment.username)
                worksheet.add_cell(i, 2, comment.body)
                worksheet.add_cell(i, 3, comment.score)
                i=i+1
            end
            #name for excel file
            name=@posts.first
            name=name['link']
            name=name.split('=')[-1]
            workbook.write("data/#{name}-all-comments-by-rank.xlsx")
            send_file(
                "#{Rails.root}/data/#{name}-all-comments-by-rank.xlsx",
                filename: "#{name}-all-comments-by-rank.xlsx",
                type: "application/xlsx"
              )
            #redirect_to index_path(id: @id)
        end
                
    end
    #save information for each comment
    def write_single
        #get param
        @id=params[:id]
        @post_id=params[:post_id]
        @type=params[:type]
        #find user 
        @user=User.find_by_id(@id)
        @posts= @user.posts 
        workbook = RubyXL::Workbook.new
            worksheet=workbook[0]
            worksheet.add_cell(0, 0, "ID")
            worksheet.add_cell(0, 1, "USERNAME")
            worksheet.add_cell(0, 2, "COMMENT")
            worksheet.add_cell(0, 3, "SCORE")
        @get_comments=@posts.find_by_id(@post_id).comments
        if @type=="normal"
            i=1
            for comment in  @get_comments
                worksheet.add_cell(i, 0, i)
                worksheet.add_cell(i, 1, comment.username)
                worksheet.add_cell(i, 2, comment.body)
                worksheet.add_cell(i, 3, comment.score)
                i=i+1
            end
            first_post=@posts.first
            name=first_post['link']
            post_no=first_post['id']
            #get name 
            name=name.split('=')[-1]
            #get 
            post_number=(@post_id.to_i - post_no.to_i)+1
            workbook.write("data/#{name}(post#{post_number})-normal.xlsx")
            send_file(
                "#{Rails.root}/data/#{name}(post#{post_number})-normal.xlsx",
                filename: "#{name}(post#{post_number})-normal.xlsx",
                type: "application/xlsx"
              )
            #redirect_to index_path(id: @id)
        else
            comments_sort= @get_comments.sort_by{|k| k[:score] }
            i=1
            for comment in  comments_sort
                worksheet.add_cell(i, 0, i)
                worksheet.add_cell(i, 1, comment.username)
                worksheet.add_cell(i, 2, comment.body)
                worksheet.add_cell(i, 3, comment.score)
                i=i+1
            end
            first_post=@posts.first
            name=first_post['link']
            post_no=first_post['id']
            #get name 
            name=name.split('=')[-1]
            #get 
            post_number=(@post_id.to_i - post_no.to_i)+1
            workbook.write("data/#{name}(post#{post_number})-rank.xlsx")
            send_file(
                "#{Rails.root}/data/#{name}(post#{post_number})-rank.xlsx",
                filename: "#{name}(post#{post_number})-rank.xlsx",
                type: "application/xlsx"
              )
            #redirect_to index_path(id: @id)
        end
    end
end
