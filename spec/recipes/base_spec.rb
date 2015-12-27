
require 'spec_helper'

describe 'ish::base' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }
end
