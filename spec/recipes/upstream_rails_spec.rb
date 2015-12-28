
require 'spec_helper'

describe 'ish::upstream_rails' do
  
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['cookbook']['attribute'] = 'hello'
      node.default['apache2'] = {}
    end.converge(described_recipe)
  end

  before :each do
    stubbed_apps = [
      { :id => 'one' },
      { :id => 'two' },
      { :id => 'three' }
    ]
    stub_search("apps", "*:*").and_return(stubbed_apps)
  end
  
  it 'installs curl' do
    expect(chef_run).to install_package('curl')
  end
  
end

