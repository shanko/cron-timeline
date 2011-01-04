require 'rubygems'
require 'sinatra'
require 'json'
require 'models/parse_cron'

get "/cron" do
  # cron_jobs = ['*/15  *  *  1 * whoami','*/30  *  *  1 * uname' ]
  # cron_jobs = `crontab -l`
  cron_jobs = File.readlines("cronfile.txt")
  hr_window = 2
  erb :cron, :locals => { :json => to_timeline_hash(cron_jobs,hr_window).to_json } 
end 


