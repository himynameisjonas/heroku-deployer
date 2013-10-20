require 'heroku_deployer'

describe HerokuDeployer do
  before do
    ENV['test_app_HEROKU_REPO'] = "heroku-repo"
    ENV['test_app_GIT_REPO'] = "git-repo"
    ENV['test_app_SSH_KEY'] = "private-key"
  end

  describe '.exists?' do
    it 'returns true if all app specific environment variables is set' do
      expect(HerokuDeployer.exists? 'test_app').to be_true
    end

    it 'returns false if heroku_repo is missing' do
      expect(HerokuDeployer.exists? 'test_app').to be_true
      ENV['test_app_HEROKU_REPO'] = nil
      expect(HerokuDeployer.exists? 'test_app').to be_false
    end

    it 'returns false if git_repo is missing' do
      expect(HerokuDeployer.exists? 'test_app').to be_true
      ENV['test_app_GIT_REPO'] = nil
      expect(HerokuDeployer.exists? 'test_app').to be_false
    end

    it 'returns false if ssh_key is missing' do
      expect(HerokuDeployer.exists? 'test_app').to be_true
      ENV['test_app_SSH_KEY'] = nil
      expect(HerokuDeployer.exists? 'test_app').to be_false
    end
  end

  describe '#deploy' do
    let(:deployer) { HerokuDeployer.new('test_app', Logger.new('/dev/null')) }

    describe 'setup' do
      before do
        deployer.stub(:update_local_repository)
        deployer.stub(:push)
      end

      it 'wrapps all calls with a GitSSHWrapper' do
        wrapper = double()
        expect(wrapper).to receive(:set_env)
        expect(GitSSHWrapper).to receive(:with_wrapper).with(private_key: ENV['test_app_SSH_KEY']).and_yield(wrapper)

        deployer.deploy
      end

      it 'removes the folder and retries one time' do
        expect(deployer).to receive(:`).with(/rm -r repos\/\d+/).once
        expect(deployer).to receive(:push).and_raise('failed').twice

        deployer.deploy
      end
    end

    describe '#update_local_repository' do
      before do
        deployer.stub(:`)
      end

      let(:clone_cmd) do
        /git clone #{ENV['test_app_GIT_REPO']} repos\/\d+/
      end
      let(:heroku_remote_cmd) do
        /cd repos\/\d+ && git remote add heroku #{ENV['test_app_HEROKU_REPO']}/
      end

      context 'without an existing local repo' do
        it 'clones the repo' do
          expect(deployer).to receive(:repo_exists?){ false }
          expect(deployer).to receive(:`).with(clone_cmd)
          expect(deployer).to receive(:`).with(heroku_remote_cmd)
          deployer.deploy
        end
      end

      context 'with an existing repo' do
        it 'does not clone a new repo' do
          expect(deployer).to receive(:repo_exists?){ true }
          expect(deployer).to receive(:`).with(clone_cmd).never
          expect(deployer).to receive(:`).with(heroku_remote_cmd).never
          deployer.deploy
        end
      end

      it 'fetches the latest updates from origin' do
        expect(deployer).to receive(:`).with(/cd repos\/\d+ && git fetch && git reset --hard origin\/master/)
        deployer.deploy
      end
    end

    describe '#push' do
      it 'pushes to heroku' do
        deployer.stub(:update_local_repository)
        expect(deployer).to receive(:`).with(/cd repos\/\d+\; git push -f heroku master/)
        deployer.deploy
      end
    end
  end
end
