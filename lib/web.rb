require 'sinatra'
require 'json'
require_relative 'heroku_deployer'
require_relative 'deploy_job'

class Web < Sinatra::Application
  before do
    if ENV['DEPLOY_SECRET'].nil? || ENV['DEPLOY_SECRET'].empty?
      halt "Set your DEPLOY_SECRET"
    end

    if ENV['DEPLOY_SSH_KEY'].nil? || ENV['DEPLOY_SSH_KEY'].empty?
      halt "Set your DEPLOY_SSH_KEY"
    end
  end

  get '/' do
    "Hello World!"
  end

  post '/deploy/:app_name/:secret' do |app_name, secret|
    if ENV["#{app_name}_BRANCH"]
      payload = JSON.parse(request.body.read)
      branch = payload["ref"].split("/").last
      logger.info "GitHub branch to monitor : " + ENV["#{app_name}_BRANCH"] + ", push hook on : #{branch}"
      return 'bypass' unless ENV["#{app_name}_BRANCH"] == branch
    end
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

    post '/deploy/gitlab/:app_name/:secret' do |app_name, secret|
    if ENV["#{app_name}_BRANCH"]
      payload = JSON.parse(request.body.read)
      branch = payload["ref"].split("/").last
      logger.info "GitHub branch to monitor : " + ENV["#{app_name}_BRANCH"] + ", push hook on : #{branch}"
      return 'bypass' unless ENV["#{app_name}_BRANCH"] == branch
    end
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
