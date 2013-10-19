require 'sinatra'
require_relative 'heroku_deployer'
require_relative 'deploy_job'

class Web < Sinatra::Application
  before do
    if ENV['DEPLOY_SECRET'].nil? || ENV['DEPLOY_SECRET'].empty?
      halt "Set your DEPLOY_SECRET"
    end
  end

  get '/' do
    "Hello World!"
  end

  post '/deploy/:app_name/:secret' do |app_name, secret|
    if secret == ENV['DEPLOY_SECRET']
      puts "correct secret"
      if HerokuDeployer.exists?(app_name)
        puts "app exists"
        DeployJob.new.async.perform(app_name)
      else
        puts "no app"
      end
    else
      puts "wrong secret"
    end
    "maybe"
  end
end
