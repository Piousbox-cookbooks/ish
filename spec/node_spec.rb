
require 'spec_helper'
require 'fileutils'

describe 'default' do

  before :each do
    @packages = [ 'npm' ]
    @deploy_to = "/home/ubuntu/projects/node_exampler"
    @app_id = "node_exampler"

    if File.directory?( @deploy_to ) || File.exist?( @deploy_to )
      %x[ sudo rm #{@deploy_to} -rf ]
    end

    # purge packages
    @packages.each do |p|
      if is_installed( p )
        %x[ sudo apt-get purge #{p} -y ]
      end
    end

    if File.exist?( "/etc/init/#{@app_id}-app" )
      %x[ sudo rm /etc/init/#{@app_id}-app ]
    end
  end

  it 'sanity' do
    false.should eql false
  end

  it 'deploys the resource' do
    # puts! 'Running Chef'
    # output = %x[ sudo chef-client ]
    # puts output
    system "sudo chef-client"

    # wrapper files
    req_files = [ '', 'id_deploy', 'deploy-ssh-wrapper' ]
    req_files.each do |f|
      File.exist?( "#{@deploy_to}/#{f}" ).should eql true
    end

    # installed packages
    @packages.each do |p|
      is_installed( p ).should eql true
    end

    # verify deployoment of resource
    File.exist?( "#{@deploy_to}/current/config/database.yml").should eql true

    # upstart file must be present
    File.exist?( "/etc/init/#{@app_id}-app.conf" ).should eql true

    # correct db config should be up there
    ( ( %x[ cat #{@deploy_to}/current/models/db_configuration.js | grep production ] ).length > 0 ).should eql true

    # upstart service should be running
    ( ( %x[ service node_exampler-app status | grep running ] ).length > 0 ).should eql true
  end

end

# 
# check if a package (name=p) is installed
#
def is_installed( p )
  return ( %x[ dpkg -s #{p} | grep "not installed" ] ).length == 0
end

