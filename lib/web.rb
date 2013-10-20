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
      logger.info "correct secret"
      if HerokuDeployer.exists?(app_name)
        logger.info "app exists"
        DeployJob.new.async.perform(app_name)
      else
        logger.info "no app"
      end
    else
      logger.info "wrong secret"
    end
    "maybe"
  end
end
