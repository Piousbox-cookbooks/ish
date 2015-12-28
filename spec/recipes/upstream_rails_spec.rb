
require 'spec_helper'

describe 'ish::upstream_rails' do
  
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.default[:rbenv] = { :global => '2.0.0-p576',
                               :rubies => [ '2.0.0-p576' ]
                             }
    end.converge("role[bjjcollective]")
  end

  before :all do
    stub_search("apps", "*:*").and_return([{ :id => 'bjjcollective' }])
    stub_search(:apps,  "*:*").and_return([{ :id => 'bjjcollective' }])
    stub_command("/usr/sbin/apache2 -t").and_return(true)
    stub_data_bag_item("apps", "bjjcollective").and_return(
      :id => 'bjjcollective',
      :owner => 'oink',
      :force => { 'vm_samsung' => false } # action for deploy_revision is deploy, not force_deploy
    )
    @deploy_to = "/home/oink/projects/bjjcollective"
  end

  it "installs ruby" do
    # @TODO: I probably need serverspec for this
    expect(chef_run).to include_recipe("ish::insall_ruby")    
  end

  it 'installs curl' do
    expect(chef_run).to install_package('curl')
  end

  it 'installs bundler' do
    expect(chef_run).to install_gem_package 'bundler'
  end

  it 'creates all the directories' do
    %w{ #{@deploy_to}/shared/config
#{@deploy_to}/shared
  #{@deploy_to}/shared/log 
  #{@deploy_to}/shared/pids
#{@deploy_to}/current/tmp 
  #{@deploy_to}/current/tmp/cache 
    #{@deploy_to}/current/tmp/cache/assets
      }.each do |dir|
      expect(chef_run).to create_directory dir
    end
  end

  it 'creates deploy-ssh-wrapper' do
    expect(chef_run).to render_file( "#{@deploy_to}/id_deploy" )
    expect(chef_run).to render_file( "#{@deploy_to}/deploy-ssh-wrapper" )
  end

  it 'deploys revision' do
    expect(chef_run).to deploy_deploy_revision 'bjjcollective'
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
  
end

