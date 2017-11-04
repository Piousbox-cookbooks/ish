require 'spec_helper'
describe 'ish::microsites3' do

  let( :chef_run ) do
    stub_data_bag_item("apps", "microsites3").and_return(
      {
        :id => 'microsites3',
        :type => { "microsites3" => [ 'upstream_microsites3' ] },
        :user => { :_default => 'ubuntu' },
        :ruby_version => { :_default => '2.3.1' },
        :revision => { :_default => 'master' },
        :force => { :_default => false },
        :databases => { :mongoid => { 'host' => '127.0.0.1' } },
        :deploy_to => '/abba'
      })

    stub_command("/home/ubuntu/.rbenv/bin/rbenv versions | grep 2.3.1").and_return( true )

    ChefSpec::SoloRunner.new( :platform => 'ubuntu', :version => '16.04' ) do |node|
      node.default[:rbenv] = {
        :global => '2.3.1',
        :rubies => [ '2.3.1' ]
      }
    end.converge( "role[microsites3]" )
  end

  before :each do
    stub_search("apps", "*:*").and_return([{ :id => 'microsites3' }])
  end

  it 'does' do
    # expect( chef_run ).to install_package( 'imagemagick' )
    expect( chef_run ).to create_directory( "/abba/shared" )
  end
end

