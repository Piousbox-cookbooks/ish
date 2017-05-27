require 'spec_helper'
describe 'ish::microsites3' do
  let( :chef_run ) { ChefSpec::SoloRunner.new( :platform => 'ubuntu', :version => '16.04' ).converge( described_recipe ) }

  it 'installs foo' do
    epect( chef_run ).to install_package( 'foo' )
  end
end

