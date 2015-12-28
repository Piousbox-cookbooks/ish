
require 'spec_helper'

describe 'ish::install_ruby' do
  
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      ;
    end.converge(described_recipe)
  end

  before :all do
    ;
  end

  it 'installs ruby 2' do
    expect(chef_run).to run_execute "install_ruby_2"
  end

  # @TODO I need to use serverspec for this one.
  
end
