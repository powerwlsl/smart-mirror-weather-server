require 'sinatra'
require 'json'
require 'httparty'
require 'redis'
require 'byebug'

class WeatherClient
  DARKSKY_API_KEY = 'your_dark_sky_api_key'

  def self.get_weather(lat, long)
    #get new redis url later
    redis =  Redis.new(url: ENV["REDIS_URL"])
    weather_data = redis.get "weather_#{lat}_#{long}"
    unless weather_data
      darksky_url = "https://api.darksky.net/forecast/#{DARKSKY_API_KEY}/#{lat},#{long}?units=si&lang=ko"
      dark_sky_weather_payload = HTTParty.get(darksky_url, :verify => false)
      redis.set "weather_#{lat}_#{long}", dark_sky_weather_payload.body, ex: 60
      puts "make an api call"
    else
      dark_sky_weather_payload = JSON.parse(weather_data)
    end
    Weather.new(dark_sky_weather_payload)
  end
end

class Weather
  def initialize(darksky_info)
    @darksky_info = darksky_info
  end

  def get_hourly_summary
    @darksky_info["hourly"]["summary"]
  end

  def get_hourly_temp_data
    hourly_data = @darksky_info["hourly"]["data"]
    [hourly_data[0], hourly_data[2], hourly_data[4], hourly_data[6], hourly_data[8], hourly_data[10]].compact
  end

  def get_temp
    @darksky_info["currently"]["temperature"].round
  end

  def get_icon
    @darksky_info["currently"]["icon"]
  end
end

get '/weather' do
  weather = WeatherClient.get_weather(params[:lat], params[:long])
  content_type :json
  { temp: weather.get_temp, summary: weather.get_hourly_summary, hourly_data: weather.get_hourly_temp_data, current_icon: weather.get_icon}.to_json
end