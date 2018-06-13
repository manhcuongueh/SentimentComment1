class UsersController < ApplicationController
    def index    
        @links=Link.all
        @comment_count=[]
        for i in 0..@links.length-1
            count=Comment.where('id = ?', i)
            @comment_count.push(count.length)
        end
       
    end

    def create
        #declare dom of posts
        @post_dom=[]
        #Get Instagram Url
        @insta_url=params[:insta_url]
        #run chrome
        @@bot = Selenium::WebDriver.for :chrome 
        sleep 1
        @@bot.navigate.to "#{@insta_url}"  
        sleep 1    
        @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/section/div/a').click
        #scroll down the account page and save dom
        for i in 0..8
            @@bot.action.send_keys(:end).perform
            sleep 1
            #save dom after 8 times press page down button
            if i%4==0
                # elements contain the content of a post
                dom=@@bot.find_elements(:xpath, '/html/body/span/section/main/div/article/div[1]/div/div/div')
                for i in dom
                    if i.find_elements(:tag_name,'a').size>0
                        dom=i.find_element(:tag_name,'a')['href']
                        @post_dom.push(dom) 
                    end   
                end      
            end 
        end
        #avoid duplicate when save dom
        @post_dom=@post_dom.uniq
        #Get exactly 100 post
        @post_dom=@post_dom[0..99]
        Comment.all.delete_all
        Link.all.delete_all
        @k=0
        # Instantiates a client
        language = Google::Cloud::Language.new
        for i in 0..@post_dom.length-1   
                links=Link.new(
                    id: i ,
                    link: @post_dom[i]
                )
                links.save
                @@bot.navigate.to "#{@post_dom[i]}"
                @start_time= Time.now
                while @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@role="button"]').size > 0 do 
                    @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@role="button"]').click
                    sleep 0.5
                    if Time.now > @start_time + 120
                        sleep 3
                        if @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@disabled]').size > 0 && @k==0
                         
                            @@bot.quit()
                            @@bot = Selenium::WebDriver.for :chrome 
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
                        elsif @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@disabled]').size > 0 && @k==1
                            @@bot.quit()
                            @@bot = Selenium::WebDriver.for :chrome 
                            @@bot.navigate.to "#{@post_dom[i]}"
                            sleep 0.5
                            @@bot.find_element(:xpath, '/html/body/span/section/nav/div[2]/div/div/div[3]/div/section/div/a').click
                            @k=0
                            @start_time= Time.now
                        end
                    end


                 end
    
                #find comments
                dom_comment=@@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li')
                dom_comment.shift
                 
                for d in dom_comment
                    begin
                        comment=d.find_element(:tag_name, 'span').text
                        # Detects the sentiment of the text
                        response = language.analyze_sentiment content: comment, type: :PLAIN_TEXT
                        # Get document sentiment from response
                        sentiment = response.document_sentiment
                        @text_score = sentiment.score
                        comments=Comment.new(
                            id: i ,
                            username:d.find_element(:tag_name, 'a')['title'],
                            body:comment,
                            score:@text_score
                        )
                        comments.save
                        rescue 
                            comments=Comment.new(
                                id: i ,
                                username:d.find_element(:tag_name, 'a')['title'],
                                body:comment,
                                score:1000
                            )
                            comments.save
                    end
                end
    
        end
            @@bot.quit()
            #get data from database
            index
            render 'index'
    end
    def show
        @id=params[:id]
        @comments=Comment.where('id = ?', @id)
        @comments=@comments.sort_by {|comment| comment.score}
    end    
end
