require 'web'
require 'rack/test'
require 'pry'


describe Web do
  include Rack::Test::Methods

  before do
    ENV["#{test_app}_HEROKU_REPO"] = "heroku-repo"
    ENV["#{test_app}_GIT_REPO"] = "git-repo"
    ENV["#{test_app}_SSH_KEY"] = "private-key"
    ENV['DEPLOY_SSH_KEY'] = 'private-deploy-key'
    ENV["#{test_app}_BRANCH"] = nil
  end

  let(:app) { Web }
  let(:deploy_secret) { 'super_secret' }
  let(:test_app) { 'test_app' }
  let(:correct_path) { "deploy/#{test_app}/#{deploy_secret}" }
  let(:mising_app_path) { "deploy/missing_app/#{deploy_secret}" }

  describe "post to /deploy"
  context 'without a deploy secret' do
    it 'requires a deploy key' do
      ENV['DEPLOY_SECRET'] = nil
      post "/deploy/#{test_app}"
      expect(last_response).to be_ok
      expect(last_response.body).to eq('Set your DEPLOY_SECRET')
    end
  end

  context 'without a deploy ssh key' do
    it 'requires a deploy key' do
      ENV['DEPLOY_SECRET'] = deploy_secret
      ENV['DEPLOY_SSH_KEY'] = nil

      post correct_path
      expect(last_response).to be_ok
      expect(last_response.body).to eq('Set your DEPLOY_SSH_KEY')
    end
  end

  context 'with an incorrect deploy secret' do
    before { ENV['DEPLOY_SECRET'] = 'other_secret' }

    it 'returns maybe' do
      post correct_path
      expect(last_response).to be_ok
      expect(last_response.body).to eq('maybe')
    end

    it 'does not enqueue a job' do
      expect(DeployJob).to receive(:new).never
      post correct_path
    end
  end

  context 'with correct params' do
    before { ENV['DEPLOY_SECRET'] = deploy_secret }

    context 'with a non existent app' do
      it 'returns maybe' do
        expect(DeployJob).to receive(:new).never

        post mising_app_path
        expect(last_response).to be_ok
        expect(last_response.body).to eq('maybe')
      end
    end

    context 'with an existing app' do
      it 'enqueus a job' do
        deploy_job = double()
        expect(deploy_job).to receive(:perform)
        DeployJob.stub(:new => double(async: deploy_job))

        post correct_path
        expect(last_response).to be_ok
        expect(last_response.body).to eq('maybe')
      end
    end

    context 'with a single GitHub source branch to monitor' do
      before { ENV["#{test_app}_BRANCH"] = 'master' }

      context 'with a push from another branch' do
        it 'returns nothing' do
          data = {
              'ref' => 'refs/heads/dev'
          }

          post correct_path, data.to_json, "CONTENT_TYPE" => "application/json"
          expect(last_response).to be_ok
          expect(last_response.body).to eq('bypass')
        end
      end

      context 'with a push from the monitored branch' do
        it 'enqueues a job' do
          deploy_job = double()
          expect(deploy_job).to receive(:perform)
          DeployJob.stub(:new => double(async: deploy_job))
          data = {
              'ref' => 'refs/heads/master'
          }

          post correct_path, data.to_json, "CONTENT_TYPE" => "application/json"
          expect(last_response).to be_ok
          expect(last_response.body).to eq('maybe')
        end
      end
    end
  end
end
