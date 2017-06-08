require 'spec_helper'
describe 'ish::nmap' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new( :platform => 'ubuntu', :version => '16.04' ) do |node|
      ;
    end.converge(described_recipe)
  end

  it 'updates system' do
    expect(chef_run).to install_package 'nmap'
  end
  
end
