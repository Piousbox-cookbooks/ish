
require 'spec_helper'

describe 'ish::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }
end
