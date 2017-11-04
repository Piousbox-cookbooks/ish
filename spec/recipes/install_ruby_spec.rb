require 'spec_helper'
describe 'ish::install_ruby' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new( :platform => 'ubuntu', :version => '16.04' ) do |node|
      ;
    end.converge(described_recipe)
  end

  before :all do
    ;
  end

  # @TODO I need to use serverspec for this one.
  
end
