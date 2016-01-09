
require 'spec_helper'

describe 'ish::base_vm' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['cookbook']['attribute'] = 'hello'
    end.converge(described_recipe)
  end

  it 'updates system' do
    expect(chef_run).to run_execute("apt-get update -y")
  end
end
