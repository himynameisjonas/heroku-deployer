require 'sinatra'
require 'json'
require_relative 'heroku_deployer'
require_relative 'deploy_job'
require 'pry'

class Web < Sinatra::Application
  before do
    if ENV['DEPLOY_SECRET'].nil? || ENV['DEPLOY_SECRET'].empty?
      halt 'Set your DEPLOY_SECRET'
    end

    if ENV['DEPLOY_SSH_KEY'].nil? || ENV['DEPLOY_SSH_KEY'].empty?
      halt 'Set your DEPLOY_SSH_KEY'
    end
  end

  get '/' do
    'Hello World!'
  end

  post '/deploy/:app_name/:secret' do |app_name, secret|
    body = request.body.read
    payload = JSON.parse(body) if valid_json?(body)
    if payload && payload['build_status']
      build_stat = payload['build_status']
    else
      build_stat = 'none' # for github
    end
    if ENV["#{app_name}_BRANCH"]
      branch = payload['ref'].split('/').last
      logger.info 'GitHub branch to monitor : ' +
        ENV["#{app_name}_BRANCH"] +
        ", push hook on : #{branch}"
      return 'bypass' unless ENV["#{app_name}_BRANCH"] == branch
    end
    DeployJob.new.async.perform(app_name) if check_secret(secret) &&
                                             check_app_exist(app_name) &&
                                             build_status(build_stat)
    'maybe'
  end

  def check_secret(secret)
    if secret == ENV['DEPLOY_SECRET']
      logger.info 'correct secret'
      return true
    else
      logger.info 'wrong secret'
      return false
    end
  end

  def check_app_exist(app_name)
    if HerokuDeployer.exists?(app_name)
      logger.info 'app exists'
      return true
    else
      logger.info 'no app'
      return false
    end
  end

  def build_status(build_stat)
    if build_stat == 'success' || build_stat == 'none'
      return true
    else
      logger.info 'build status false'
      return false
    end
  end

  def valid_json?(json)
    begin
      if !(json == "")
        JSON.parse(json)
        return true
      else
        return false
      end
    rescue Exception => e
      return false
    end
  end
end
