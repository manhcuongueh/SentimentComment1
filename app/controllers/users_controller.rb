class UsersController < ApplicationController
    def index    
        @links=Link.all
        @all_comment=Comment.all
        #array of the number of comment in a post
        @comment_count=[]
        @score=[]
        #array of min(each post)
        @min=[]
        #array of max(each post)
        @max=[]
        #array of average(each post)
        @average=[]
        #for loop to find max, min ...
        for i in 0..@links.length-1
            @get_comments=Comment.where('id = ?', i)
            for cm in  @get_comments
                @score.push(cm.score)
            end
            @min.push(@score.min)
            @max.push(@score.max)
            aver=@score.inject(0.0) { |sum, el| sum + el } / @score.length
            @average.push(aver.round(3))
            @score.clear
            @comment_count.push(@get_comments.length)
        end 
        # min, max, average of all comment
        #max
        max_item=@all_comment.max_by{|k| k[:score] }
        @max_all_url=Link.find_by_id(max_item.id)
        @max_all_url=@max_all_url['link']
        @max_all=max_item.score
        #min
        min_item=@all_comment.min_by{|k| k[:score] }
        @min_all_url=Link.find_by_id(min_item.id)
        @min_all_url=@min_all_url['link']
        @min_all=min_item.score
        #average
        @average_all=@all_comment.inject(0.0) { |sum, el| sum + el.score } / @all_comment.length
        @average_all=@average_all.round(3)
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
        Comment.all.delete_all
        Link.all.delete_all
        @k=0
        # Instantiates a client
        language = Google::Cloud::Language.new
        for i in 0..@post_dom.length-1   
            @@bot.navigate.to "#{@post_dom[i][0]}"
            #save like, image and date
            date = @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[2]/a/time')['title']
            links=Link.new(
                id: i ,
                link: @post_dom[i][0],
                image: @post_dom[i][1],
                date: date
            )
            links.save
            #set time to reload, change session
            @start_time= Time.now
            while @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@role="button"]').size > 0 do 
                 @@bot.find_element(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@role="button"]').click
                 sleep 0.5
                    if Time.now > @start_time + 120
                        # for solving "load more comments"
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
                            @@bot.navigate.to "#{@post_dom[i][0]}"  
                            @k=1
                            @start_time= Time.now
                        elsif @@bot.find_elements(:xpath, '/html/body/span/section/main/div/div/article/div[2]/div[1]/ul/li[2]/a[@disabled]').size > 0 && @k==1
                            @@bot.quit()
                            @@bot = Selenium::WebDriver.for :chrome 
                            @@bot.navigate.to "#{@post_dom[i][0]}"
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
                    comments=Comment.new(
                        id: i ,
                        username:@username[e],
                        body:sentences[e+@n].text.content,
                        score:sentences[e+@n].sentiment.score
                        )
                        comments.save

                end
        end
            @@bot.quit()
            #get data from database
            redirect_to index_path
    end
    def show
        @id=params[:id]
        @type=params[:type]
        @comments=Comment.where('id = ?', @id)
    end    
    def write_excel
        @links=Link.all
        @all_comment=Comment.all
        @type=params[:type]
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
                @score=[]
                for link in @links
                    @get_comments=Comment.where('id = ?', i)
                    for cm in  @get_comments
                        @score.push(cm.score)
                    end
                    @average=@score.inject(0.0) { |sum, el| sum + el } / @score.length
                    worksheet.add_cell(i+1, 0, link.id)
                    worksheet.add_cell(i+1, 1, link.image)
                    worksheet.add_cell(i+1, 2, link.link)
                    worksheet.add_cell(i+1, 3, @score.min)
                    worksheet.add_cell(i+1, 4, @score.max)
                    worksheet.add_cell(i+1, 5, @average)  
                    i=i+1   
                end
                name=@links.first
                name=name['link']
                name=name.split('=')[-1]
                workbook.write("data/#{name}.xlsx")
                flash[:success] = "You are create excel file (overall type) sucessfully"
                redirect_to index_path
        #save all comments to excel file
        else
            i=0
            for comment in @all_comment
                worksheet.add_cell(i, 0, comment.id)
                worksheet.add_cell(i, 1, comment.username)
                worksheet.add_cell(i, 2, comment.body)
                worksheet.add_cell(i, 3, comment.score)
                i=i+1
            end
            name=@links.first
            name=name['link']
            name=name.split('=')[-1]
            workbook.write("data/#{name}-all-comments.xlsx")
            flash[:success] = "You are create excel file (all comments) sucessfully"
            redirect_to index_path
        end
                
    end
    #save information for each comment
    def write_single
        @id=params[:id]
        workbook = RubyXL::Workbook.new
        worksheet=workbook[0]
        @get_comments=Comment.where('id = ?', @id)
        i=0
        for comment in  @get_comments
            worksheet.add_cell(i, 0, comment.id)
            worksheet.add_cell(i, 1, comment.username)
            worksheet.add_cell(i, 2, comment.body)
            worksheet.add_cell(i, 3, comment.score)
            i=i+1
        end
        @links=Link.all
        name=@links.first
        name=name['link']
        name=name.split('=')[-1]
        post_number=@id.to_i+1
        workbook.write("data/#{name}(post#{post_number}).xlsx")
        flash[:success] = "You are create excel file (post#{post_number}) sucessfully"
        redirect_to index_path
    end
end
