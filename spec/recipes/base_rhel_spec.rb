require 'spec_helper'
describe 'ish::base_aws' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new( :platform => 'centos', :version => '6.7' ) do |node| # no rhel/7.3, instead centos/6.7
      node.set['cookbook']['attribute'] = 'hello'
    end.converge(described_recipe)
  end

  it 'installs packages' do
    %w( emacs tree screen git ).each do |pkg|
      expect(chef_run).to install_package pkg
    end
  end

  it 'configures screenrc' do
    expect(chef_run).to create_cookbook_file("screenrc")
  end

  it 'configures emacs' do
    expect(chef_run).to create_cookbook_file("emacs")
  end
  
end
