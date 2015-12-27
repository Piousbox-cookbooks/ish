
#
# cookbook   ish
# recipe     ish-lib
#
# deploy resource 
# Copyright (c) CAC, wasya.co
# 20120801
# 20140623
# 20140705
# 20150608
#

def puts! args, label=""
  puts "+++ +++ #{label}"
  puts args.inspect
end

app = data_bag_item('utils', 'ish_lib')

search(:apps) do |any_app|
  if node.roles.include?( any_app['id'] )
    extra_app = data_bag_item('apps', any_app['id'])
    
    app['owner'] = extra_app['owner']
    homedir = 'root' == app['owner'] ? "/root" : "/home/#{app['owner']}"
    app['deploy_to'] ||= "#{homedir}/projects/ish_lib"

    node.default[:apps][extra_app['id']][node.chef_environment][:run_migrations] = false

    directory app['deploy_to'] do
      owner app['owner']
      group app['owner']
      mode '0755'
      recursive true
    end

    directory "#{app['deploy_to']}/shared" do
      owner app['owner']
      group app['owner']
      mode '0755'
      recursive true
    end

    template "#{app['deploy_to']}/shared/database.yml" do
      owner app['owner']
      group app['woner']
      source "database.yml.erb"
      mode "0664"
      variables({
                })
    end

    %w{ log pids system vendor_bundle }.each do |dir|
      directory "#{app['deploy_to']}/shared/#{dir}" do
        owner app['owner']
        group app['owner']
        mode '0755'
        recursive true
      end
    end

    if app['deploy_key']
      ruby_block "write_key" do
        block do
          f = ::File.open("#{app['deploy_to']}/id_deploy", "w")
          f.print(app["deploy_key"])
          f.close
        end
        not_if do ::File.exists?("#{app['deploy_to']}/id_deploy"); end
      end

      file "#{app['deploy_to']}/id_deploy" do
        owner app['owner']
        group app['owner'] 
        mode '0600'
      end

      template "#{app['deploy_to']}/deploy-ssh-wrapper" do
        source "deploy-ssh-wrapper.erb"
        owner app['owner']
        group app['owner']
        mode "0755"
        variables app.to_hash
      end
    end
    
    ## Then, deploy
    deploy_revision app['id'] do
      revision app['revision'][node.chef_environment]
      repository app['repository']
      user app['owner']
      group app['owner']
      deploy_to app['deploy_to']
      environment 'RAILS_ENV' => app['rack_environment']
      action app['force'][node.chef_environment] ? :force_deploy : :deploy
      ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
      shallow_clone true  
      migrate false
    end
    
    # node.run_state.delete(:current_app)

  end
end

