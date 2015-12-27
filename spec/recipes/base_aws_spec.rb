
require 'spec_helper'

describe 'ish::base_aws' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['cookbook']['attribute'] = 'hello'
    end.converge(described_recipe)
  end

  it 'updates system' do
    expect(chef_run).to run_execute("apt-get update -y")
  end

  it 'installs packages' do
    expect(chef_run).to install_package("emacs")
    expect(chef_run).to install_package("tree")
    expect(chef_run).to install_package("screen")
    expect(chef_run).to install_package("git")
  end

  it 'configures screenrc' do
    expect(chef_run).to create_cookbook_file("screenrc")
  end

  it 'configures emacs' do
    expect(chef_run).to create_cookbook_file("emacs")
  end
  
end
