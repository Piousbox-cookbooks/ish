
require 'spec_helper'

describe 'ish::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'installs foo' do
    expect(chef_run).to do_nothing
  end
end
