require 'spec_helper'
describe 'ish::upstream_rails' do  
  let(:chef_run) do
    ChefSpec::SoloRunner.new( :platform => 'ubuntu', :version => '16.04' ) do |node|
      node.default['rbenv'] = { 'global' => '2.0.0-p576',
                                'rubies' => [ '2.0.0-p576' ]
                              }
    end.converge("role[bjjcollective]")
  end

  before :each do
    stub_search(:apps,  "*:*").and_return([{ :id => 'bjjcollective' }])
    
    stub_command("/usr/sbin/apache2 -t").and_return(true)
    stub_command("/home/ubuntu/.rbenv/bin/rbenv versions | grep 2.0.0-p576").and_return(true)
    
    stub_data_bag_item("apps", "bjjcollective").and_return(
      'id' => 'bjjcollective',
      'owner' => { "_default" => 'oink' },
      'force' => { '_default' => true },
      'type' => { 'bjjcollective' => [ 'upstream_rails' ] },
      'packages' => {'a' => '', 'b' => '', 'c' => ''},
      'revision' => { "_default" => "master" },
      "databases" => {
        "mysql" => {
          "_default" => { "adapter" => false }
        },
        "mongoid" => false
      },
      "listen_port" => {
        "_default" => 9999
      }
    )
    @deploy_to = "/home/oink/projects/bjjcollective"
  end

  it "installs ruby" do
    # @TODO: I probably need serverspec for this
    expect(chef_run).to include_recipe("ish::install_ruby")    
  end

  it 'installs packages' do
    packages = %w{ }
    packages.each do |pkg|
      expect(chef_run).to install_package pkg
    end
  end

  it 'installs bundler' do
    expect(chef_run).to install_gem_package 'bundler'
  end

  it 'creates all the directories' do
    deploy_to = @deploy_to
    %w{ 
/home/oink/projects/bjjcollective/shared
/home/oink/projects/bjjcollective/shared/config
/home/oink/projects/bjjcollective/shared/log
/home/oink/projects/bjjcollective/shared/pids
/home/oink/projects/bjjcollective/current/tmp 
/home/oink/projects/bjjcollective/current/tmp/cache 
/home/oink/projects/bjjcollective/current/tmp/cache/assets
      }.each do |dir|
      expect(chef_run).to create_directory dir
    end
  end

  it 'creates deploy-ssh-wrapper' do
    expect(chef_run).to render_file( "#{@deploy_to}/id_deploy" )
    expect(chef_run).to render_file( "#{@deploy_to}/deploy-ssh-wrapper" )
  end

  it 'deploys revision' do
    ; # @TODO: not implemented
  end
  
  it 'renders init file for s3' do
    ; # this doesn't happen because data bag has no s3_key
  end
  
  it 'renders mongoid config' do
    ; # same thing
  end
  
  it 'renders recaptcha key' do
    ; # same thing
  end
  
  it 'renders mysql config' do
    ; # same thing
  end
  
  it 'renders unicorn file' do
    expect(chef_run).to render_file( "#{@deploy_to}/shared/unicorn.rb" )
  end
  
  it 'renders upstart config' do
    expect(chef_run).to render_file( "/etc/init/bjjcollective-app.conf" )
  end

  it 'enables, starts service' do
    expect(chef_run).to enable_service "bjjcollective-app"
    expect(chef_run).to start_service "bjjcollective-app"
  end

  it 'bundles' do
    ; # @TODO not implemented
  end
  
end

