require 'sinatra'
require 'data_mapper'

DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/projectdata1.db")

set :sessions, true
set :bind, '0.0.0.0'

class User
	include DataMapper::Resource
	property :id, Serial
	property :userName, String
	property :email, String
	property :password, String
	property :content, String
	property :tweetId, Integer
	property :user_id, Integer
end

class Friend
	include DataMapper::Resource
	property :id ,Serial
	property :first_user, Integer
	property :second_user, Integer
end

class Link
	include DataMapper::Resource
	property :id, Serial
	property :friend1, Integer
	property :friend2, Integer
end

class Tweet
	include DataMapper::Resource
	property :id, Serial
	property :tweetId, Integer
	property :content, String
	property :comment, String
	property :edit, String
	property :require_edit, Boolean
	property :require_comment, Boolean
	property :likecounter, Integer
end

class Message
	include DataMapper::Resource
	property :id, Serial
	property :user_from_id, Integer
	property :user_to_id, Integer
	property :message, String
end

class Pending_msg
	include DataMapper::Resource
	property :id, Serial
	property :user_from_id, Integer
	property :user_to_id, Integer
	property :unread, Integer
end


class Likes
	include DataMapper::Resource
	property :id, Serial
	property :user_id, Integer
	property :tweet_id, Integer
end

DataMapper.finalize
User.auto_upgrade!
Friend.auto_upgrade!
Tweet.auto_upgrade!
Likes.auto_upgrade!
Link.auto_upgrade!
Message.auto_upgrade!
Pending_msg.auto_upgrade!


show = nil
show_frnd = nil
show_all_req = nil
show_my_friends = nil
show_all_comments = nil




get '/' do
	user = nil
	tweets = nil

	if session[:user_id]
		user = User.get(session[:user_id])
		tweets = Tweet.all(:tweetId => user.id)
	else
		redirect '/signin'
	end
	
	tweets_all = Tweet.all
	friends_all = Friend.all(:first_user => session[:user_id])
	user_all = User.all
	req_link = Link.all(:friend2 => session[:user_id])
	all_messages = Message.all
	erb :indextwitter, locals: {:show_all_comments => show_all_comments, :show_my_friends => show_my_friends, :show_all_req => show_all_req, :req_list => req_link,:user => user, :tweets => tweets,:show => show, :all_tweets => tweets_all, :all_friends => friends_all, :all_user => user_all, :show_frnd => show_frnd }
end


get '/signup' do
	erb :signuptwitter
end

post '/register' do
	email = params[:email]
	password = params[:password]
	userName = params[:username]
	user = User.all(:email => email).first
	if user
		redirect '/signup'
	else
		user = User.new
		user.userName = userName
		user.email = email
		user.password = password
		session[:user_id] = user.id
		user.save
		redirect '/'
	end
end

get '/signin' do
	erb :signintwitter
end

post '/signin' do
	email = params[:email]
	password = params[:password]

	user = User.all(:email => email).first

	if user
		if user.password == password
			session[:user_id] = user.id
			redirect '/'
		else

			redirect '/signin'
		
		end

	else
		redirect'/signup'
	end

	redirect '/'
end

post '/add_tweet' do
	tweet = Tweet.new
	user = User.new

	tweet.likecounter = 0
	tweetcontent = params[:content]
	tweet.content = tweetcontent
	tweet.tweetId = session[:user_id]
	tweet.require_edit = false
	tweet.require_comment = false
	tweet.save
	redirect '/'
end

post '/like_tweet' do
	tweet_id = params[:tweet_idindex].to_i
	likes = Likes.all(:tweet_id => tweet_id)
	flag = nil
	likes.each do |like|
		if like.user_id == session[:user_id]
			redirect '/'
		end
	end

		tweet = Tweet.get(tweet_id)
		tweet.likecounter +=1
		tweet.save
		like = Likes.new
		like.user_id = session[:user_id]
		like.tweet_id = tweet_id
		like.save 
		redirect '/'
end


post '/delete_tweet' do
	tweetid = params[:tweet_idindex].to_i
	tweet1 = Tweet.get(tweetid)
	tweet1.destroy
	redirect '/'
end

get '/req_edit' do 
	tweetid = params[:tweet_idindex].to_i
	tweet = Tweet.get(tweetid)
	tweet.require_edit = !tweet.require_edit
	tweet.save
	redirect '/'  
end

post '/edit_tweet' do 

	tweet_id = params[:tweet_idindex].to_i
	tweet = Tweet.get(tweet_id)
	tweet.content = params[:edit_tweet]
	tweet.require_edit = !tweet.require_edit
	tweet.save
	redirect '/'
end

get '/req_comment' do
	tweetid = params[:tweet_idindex].to_i
	tweet = Tweet.get(tweetid)
	tweet.require_comment = ! tweet.require_comment
	tweet.save
	redirect '/'
end

post '/comment_tweet' do
	tweet_id = params[:tweet_idindex].to_i
	tweet = Tweet.get(tweet_id)
	tweet.comment = params[:tweet_comment]
	tweet.require_comment = ! tweet.require_comment
	tweet.save
	redirect '/'
end

post '/find_friends' do
	if show_frnd
		show_frnd = nil
		redirect '/'
	end
	show_frnd = 1
	redirect '/'
end

post '/make_friend' do
	link = Link.new
	link.friend1 = session[:user_id]
	link.friend2 = params[:friend_id]
	link.save
	redirect '/'
end

post '/showall_friend_requests' do
	if show_all_req
		show_all_req = nil
		redirect '/'
	end
	show_all_req = 1
	redirect '/'
end
post '/show_tweet' do
	if show
		show = nil
		redirect '/'
	end
	show = 1
	redirect '/'
end




post '/my_friends' do
	if show_my_friends
		show_my_friends = nil
		redirect '/'
	end
	show_my_friends = 1
	redirect '/'
end

post '/confirm' do 
	link = Link.get(params[:req_id])
	join = Friend.new
	join.first_user = link.friend1
	join.second_user = link.friend2
	join.save
	join = Friend.new
	join.first_user = link.friend2
	join.second_user = link.friend1
	join.save
	link.destroy
	redirect '/'
end

post '/logout' do
	session[:user_id] = nil 
	redirect '/'
end









