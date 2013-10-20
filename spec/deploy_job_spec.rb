require 'deploy_job'

describe DeployJob do
  describe '#perform' do
    it 'calls deploy on a new instance of HerokuDeployer' do
      deployer = double()
      expect(deployer).to receive(:deploy)
      expect(HerokuDeployer).to receive(:new).with('test_name'){ deployer }

      DeployJob.new.perform('test_name')
    end
  end
end
