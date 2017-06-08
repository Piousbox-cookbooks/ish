require 'spec_helper'
describe 'ish::install_mysql' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new( :platform => 'ubuntu', :version => '16.04' ) do |node|
      # node.set['cookbook']['attribute'] = 'hello'
    end.converge(described_recipe)
  end

  it 'pre-sets password' do
    expect(chef_run).to run_execute "pre-set password"
  end

  it 'installs mysql package' do
    expect(chef_run).to install_package "mysql-server"
  end

  it 'adjusts bind address' do
    expect(chef_run).to run_execute "adjust bind address"
  end

  it 'enables, starts service' do
    expect(chef_run).to enable_service 'mysql'
    expect(chef_run).to start_service 'mysql'
  end
  
end
