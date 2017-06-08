require 'spec_helper'
describe 'ish::static_site' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new( :platform => 'ubuntu', :version => '16.04' ) do |node|
      node.default[:rbenv] = { :global => '2.0.0-p576',
                               :rubies => [ '2.0.0-p576' ]
                             }
    end.converge("role[static_wasya2]")
  end

  before :each do
    stub_search("apps", "*:*").and_return([{ :id => 'static_wasya2' }])
    stub_search(:apps,  "*:*").and_return([{ :id => 'static_wasya2' }])
    
    stub_command("/usr/sbin/apache2 -t").and_return(true)
    stub_data_bag_item("apps", "static_wasya2").and_return(
      'id' => 'static_wasya2',
      'user' => { "_default" => 'oink' },
      'port' => { "_default" => "3005" },
      'force' => { '_default' => true },
      'type' => { 'static_wasya2' => [ 'static_site' ] },
      # 'packages' => {'a' => '', 'b' => '', 'c' => ''},
      # "databases" => {
      #   "mysql" => {
      #     "_default" => { "adapter" => false }
      #   },
      #   "mongoid" => false
      # },
      'revision' => { "_default" => "master" }
    )
    @deploy_to = "/home/oink/projects/static_wasya2"
    @projects_dir = "/home/oink/projects"
  end

  it 'installs packages' do
    packages = %w{ }
    packages.each do |pkg|
      expect(chef_run).to install_package pkg
    end
  end

  it 'creates all the directories' do
    %w{
/home/oink/projects
      }.each do |dir|
      expect(chef_run).to create_directory dir
    end
  end

  it 'creates deploy-ssh-wrapper' do
    expect(chef_run).to render_file( "#{@projects_dir}/id_deploy" )
    expect(chef_run).to render_file( "#{@projects_dir}/deploy-ssh-wrapper" )
  end

end

