
require 'spec_helper'

describe 'ish::ish_hostnames' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['user'] = ENV['USER']
    end.converge(described_recipe)
  end
  
end
