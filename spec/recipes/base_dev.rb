
require 'spec_helper'

describe 'ish::base_dev' do
  let( :chef_run ) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'installs emacs' do
    expect( chef_run ).to install_package( 'emacs' )
  end

end

