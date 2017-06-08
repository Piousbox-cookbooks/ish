require 'spec_helper'
describe 'ish::ish_hostnames' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new( :platform => 'ubuntu', :version => '16.04' ) do |node|
      node.set['user'] = ENV['USER']
    end.converge(described_recipe)
  end
  
end
