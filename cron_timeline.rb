require 'rubygems'
require 'sinatra'
require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), 'models', 'parse_cron')) 

# get "/" do
#   "Hello from Sinatra on Heroku!"
# end

get "/cron" do
  # cron_jobs = ['*/15  *  *  1 * whoami','*/30  *  *  1 * uname' ]
  # cron_jobs = `crontab -l`
  cron_jobs = File.readlines(File.expand_path(File.join(File.dirname(__FILE__), 'cronfile.txt')))
  hr_window = 2
  erb :cron, :locals => { :json => to_timeline_hash(cron_jobs,hr_window).to_json } 
end 


