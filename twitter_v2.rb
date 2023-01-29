require 'oauth'
require 'json'
require 'typhoeus'
require 'oauth/request_proxy/typhoeus_request'
require 'pstore'
require 'fileutils'

class TwitterV2
  def initialize
    consumer_key = ENV['TWITTER_CONSUMER_KEY']
    consumer_secret = ENV['TWITTER_CONSUMER_SECRET']

    @create_tweet_url = "https://api.twitter.com/2/tweets"

    FileUtils.mkdir("./tmp") unless File.exist?("./tmp")
    @db = PStore.new("./tmp/access_token")

    @consumer = OAuth::Consumer.new(consumer_key, consumer_secret,
                  :site => 'https://api.twitter.com',
                  :authorize_path => '/oauth/authenticate',
                  :debug_output => false)
  end

  def get_request_token(consumer)
    request_token = consumer.get_request_token()

    return request_token
  end

  def get_user_authorization(request_token)
    puts "Follow this URL to have a user authorize your app: #{request_token.authorize_url()}"
    puts "Enter PIN: "
    pin = gets.strip

    return pin
  end

  def obtain_access_token(consumer, request_token, pin)
    token = request_token.token
    token_secret = request_token.secret
    hash = { :oauth_token => token, :oauth_token_secret => token_secret }
    request_token  = OAuth::RequestToken.from_hash(consumer, hash)

    # Get access token
    access_token = request_token.get_access_token({:oauth_verifier => pin})
    puts
    puts access_token
    puts

    return access_token
  end

  def create_tweet(url, oauth_params, json_payload)
    options = {
      :method => :post,
      headers: {
              "User-Agent": "v2CreateTweetRuby",
              "content-type": "application/json"
      },
      body: JSON.dump(json_payload)
    }
    request = Typhoeus::Request.new(url, options)
    oauth_helper = OAuth::Client::Helper.new(request, oauth_params.merge(:request_uri => url))

    request.options[:headers].merge!({"Authorization" => oauth_helper.header}) # Signs the request
    response = request.run

    return response
  end

  def postTweet(text)
    response = ''
    @db.transaction do
      unless access_token = @db["token"]
        # PIN-based OAuth flow - Step 1
        request_token = get_request_token(@consumer)
        # PIN-based OAuth flow - Step 2
        pin = get_user_authorization(request_token)
        # PIN-based OAuth flow - Step 3
        access_token = obtain_access_token(@consumer, request_token, pin)
        @db["token"] = access_token
      end
      oauth_params = {:consumer => @consumer, :token => access_token}

      json_payload = {"text": text}
      response = create_tweet(@create_tweet_url, oauth_params, json_payload)
    end
    return response
  end
end