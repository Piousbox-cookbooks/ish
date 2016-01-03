
require 'spec_helper'

describe 'ish::install_mysql' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      # node.set['cookbook']['attribute'] = 'hello'
    end.converge(described_recipe)
  end

  it 'leverages the mysql cookbook' do
    expect(chef_run).to create_mysql_service "default"
    expect(chef_run).to start_mysql_service "default"
  end
  
end
