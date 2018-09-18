class UsersController < ApplicationController
    def new
        @users_all = User.all
        #search
        username = params[:username]
        if !username.nil?
        @users_all = @users_all.find_all{|w| w.username.include?(username)}
        end
        #sort search result
         url =  request.fullpath
         if url.include?('username')
             @urlNormal = "?utf8=✓&username=#{username}&commit=Search"
             @urlHighest ="?utf8=✓&username=#{username}&commit=Search&type=highest"
             @urlLowest = "?utf8=✓&username=#{username}&commit=Search&type=lowest"
         else
             @urlNormal = "/"
             @urlHighest = '?type=highest'
             @urlLowest =  '?type=lowest'
         end
        #sort with drop down Average Score
        sort_type = params[:type]
        if (sort_type=="highest")
            @users_all=@users_all.sort_by {|u| u.averageScore*-1}
        end
        if (sort_type=="lowest")
            @users_all=@users_all.sort_by {|u| u.averageScore}
        end
        # paging area
        @users=Kaminari.paginate_array(@users_all).page(params[:page]).per(10)
    end

    def index    
        @id=params[:id]
        sort_type = params[:type]
        @user = User.find_by_id(@id)
        @posts= @user.posts     
        if (sort_type=="highest")
            @posts =  @posts.sort_by {|p| p.averageScore*-1}
        end
        if (sort_type=="lowest")
            @posts =  @posts.sort_by {|p| p.averageScore}
        end
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
       @comments=Kaminari.paginate_array(@all_comments).page(params[:page]).per(50)
       if @type=="rank"
           @all_comments= @all_comments.sort_by{|k| k[:score] }
           @comments=Kaminari.paginate_array(@all_comments).page(params[:page]).per(50)
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
    # kill other chrome process
    system("killall chrome")
    #declare dom of posts
    post_dom=[]
    #Get Instagram Url
    insta_url=params[:insta_url]
    #Get pass
    pass=params[:pass]
    #all comments
    allUserComments = []
    if pass=="parastar"
        #run chrome
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless')
        options.add_argument('--no-sandbox')
        @@bot = Selenium::WebDriver.for :chrome, options: options
        #@@bot = Selenium::WebDriver.for :chrome
        @@bot.manage.window.maximize
        sleep 1
        @@bot.navigate.to "https://www.instagram.com/#{insta_url}"
        sleep 1  
        if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div/div/div/div').size >0 
            #get account_id
            user_id = @@bot.find_element(:xpath, '/html/body/span/section/main/div/header/section/div[1]/h1').text
            #Save Instagram account
            @user=User.new(username:  user_id)         
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
                            post_dom.push(dom) 
                        end   
                    end      
                end 
            end
            #avoid duplicate when save dom
            post_dom=post_dom.uniq
            #Get exactly 100 post
            post_dom=post_dom[0..99]
            k=0
            # Instantiates a client
            language = Google::Cloud::Language.new
            for i in 0..post_dom.length-1   
                @@bot.navigate.to "#{post_dom[i][0]}"
                #save like, image and date
                date = @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[2]/a/time')['title']
                @post=@user.posts.new(
                    link: post_dom[i][0],
                    image: post_dom[i][1],
                    date: date,
                    code: i
                )
                #set time to reload, change session
                start_time= Time.now
                while @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/button').size > 0 do
                    if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/button[@disabled=""]').size > 0
                        sleep 3
                    else
                        @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/button').click
                        sleep 0.5
                    end
                    if (Time.now > start_time + 60)
                        sleep 3 
                        if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/button[@disabled=""]').size > 0                    
                            if k==0 
                                @@bot.quit()
                                options = Selenium::WebDriver::Chrome::Options.new
                                options.add_argument('--headless')
                                options.add_argument('--no-sandbox')
                                @@bot = Selenium::WebDriver.for :chrome, options: options
                                #@@bot = Selenium::WebDriver.for :chrome
                                @@bot.manage.window.maximize
                                @@bot.navigate.to "https://www.instagram.com/accounts/login/?force_classic_login"
                                sleep 0.5
                                #using username and password to login
                                @@bot.find_element(:id, 'id_username').send_keys 'cuong_manh248'
                                @@bot.find_element(:id, 'id_password').send_keys '24081991'
                                @@bot.find_element(:class, 'button-green').click
                                sleep 0.5
                                @@bot.navigate.to "#{post_dom[i][0]}"  
                                k=1
                                start_time= Time.now
                            else  
                                @@bot.quit()
                                options = Selenium::WebDriver::Chrome::Options.new
                                options.add_argument('--headless')
                                options.add_argument('--no-sandbox')
                                @@bot = Selenium::WebDriver.for :chrome, options: options
                                #@@bot = Selenium::WebDriver.for :chrome
                                @@bot.manage.window.maximize
                                @@bot.manage.window.maximize
                                @@bot.navigate.to "#{post_dom[i][0]}"
                                sleep 0.5
                                @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/div/section/div/a').click
                                k=0
                                start_time= Time.now
                            end
                        else
                            start_time= Time.now
                        end
                    end
                end
                    #find comments
                    dom_comment=@@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li')
                    dom_comment.shift
                    #for solving unsupported languages
                    text = "아니요오 내일은 파이톤 제품은 할인이 없어요."
                    @username = []
                    for d in dom_comment
                        comment=d.find_element(:tag_name, 'span').text
                        comment=comment.gsub(/[!().~`,:;<>?|'"{}\\\/\[\]]/,' ')
                        comment=comment.gsub("\n",' ')
                        if comment[/\b[a-zA-Z0-9\p{Hangul}]+\b/].nil?
                            comment=comment[0..29]
                        end
                        if comment.scan(/[a-zA-Z ]/).size==1
                            comment.insert(0,"-")
                        end
                        #for sure each comment is each sentence
                        comment.insert(-1,".")
                        text << "\n"
                        text << "\n"
                        text << comment
                        @username.push(d.find_element(:tag_name, 'a')['title'])
                    end
                    # Detects the sentiment of the text
                    response = language.analyze_sentiment content: text, type: :PLAIN_TEXT
                    # Get document sentiment from response
                    sentences = response.sentences
                    sentences.shift
                    #check is it a sentence 
                    n=0
                    for e in 0..@username.length-1  
                        if !sentences[e].text.content.include? "."
                            n=n+1
                        end
                        users_comment=@post.comments.new(
                            username:@username[e],
                            body:sentences[e+n].text.content,
                            score:sentences[e+n].sentiment.score,
                            code: i
                            )
                    end
                    #find min, max and average score
                    postComments = @post.comments
                    score=[]
                    for cm in  postComments
                        score.push(cm.score)
                        allUserComments.push(cm)
                    end
                    aver=score.inject(0.0) { |sum, el| sum + el } / score.length
                    #get number of comments each post
                    @post.totalComments = postComments.length
                    #set value if there have no comment
                    if @post.totalComments == 0
                        @post.minScore =0
                        @post.maxScore = 0
                        @post.averageScore = 0
                    else
                        @post.minScore =score.min
                        @post.maxScore = score.max
                        @post.averageScore = aver.round(3)
                    end
            end
                #remove data of existing account 
                User.find_each { |c| c.destroy if c.username==user_id}
                #find min, max and average score of all posts
                if allUserComments.size != 0
                    #max
                    maxScoreComments=allUserComments.max_by{|k| k[:score] }
                    maxScoreUrl=@user.posts.find {|p| p.code==maxScoreComments.code}
                    @user.highestUrl=maxScoreUrl.link
                    @user.highestScore = maxScoreComments.score
                    #min
                    minScoreComments=allUserComments.min_by{|k| k[:score] }
                    minScoreUrl=@user.posts.find {|p| p.code==minScoreComments.code}
                    @user.lowestUrl =minScoreUrl.link
                    @user.lowestScore = minScoreComments.score
                    #average
                    averageAll=allUserComments.inject(0.0) { |sum, el| sum + el.score } / allUserComments.length
                    @user.averageScore = averageAll.round(3)
                    @user.totalComment = allUserComments.length
                else
                    #max
                    @user.highestUrl= ''
                    @user.highestScore = 0
                    #min
                    @user.lowestUrl = ''
                    @user.lowestScore = 0
                    #average
                    @user.averageScore = 0
                end
                @user.save
                @@bot.quit()
                redirect_to index_path(id: @user.id)
        else
            flash[:danger] = "Please enter the valid username!"
            @@bot.quit()
            redirect_to root_path
        end
    else
        flash[:danger] = "Please enter the correct secret code!"
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
