

gems = %w{ bundler }
gems.each do |gem|
  gem_package gem do
    action :install
  end
end

app = data_bag_item('apps', 'microsites2_resume')

directory app['deploy_to'] do
  action :create
  recursive true
  owner 'ubuntu'
end

## Then, deploy
deploy_revision app['id'] do
  revision app['revision'][node.chef_environment]
  repository app['repository']
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  environment 'RAILS_ENV' => app['rack_environment']
  action :force_deploy # app['force'][node.chef_environment] ? :force_deploy : :deploy
  ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
  shallow_clone true
  migrate false
  before_migrate do
    if app['gems'].has_key?('bundler')
      link "#{release_path}/vendor/bundle" do
        to "#{app['deploy_to']}/shared/vendor_bundle"
      end
      common_groups = %w{development test cucumber staging production}
      execute "bundle install --deployment --without #{(common_groups -([node.chef_environment])).join(' ')}" do
        ignore_failure true
        cwd release_path
      end
    elsif node.chef_environment && app['databases'].has_key?(node.chef_environment)
      execute "(ln -s ../../../shared/database.yml config/database.yml && rake gems:install); rm config/database.yml" do
        ignore_failure true
        cwd release_path
      end
    end
  end
end

rbenv_script "permissions for bundler" do
  code %{ sudo chown ubuntu /usr/local/rbenv -R }
end

rbenv_script "install bundler" do
  code %{ cd #{app['deploy_to']}/current && gem install bundler }
end

rbenv_script 'bundle install' do
  code %{ cd #{app['deploy_to']}/current && bundle install --without development test }
end

# rbenv_script 'recompile bcrypt' do
#   code %{ cd #{app['deploy_to']}/current/vendor/ruby/1.9.1/gems/bcrypt*/ext/mri && ruby extconf.rb && make && make install }
# end

template "#{app['deploy_to']}/shared/unicorn.rb" do
  owner 'ubuntu'
  group 'nogroup'
  source "unicorn.conf.rb.erb"
  mode "0664"
  variables(
            :app => app['id'],
            :port => app['unicorn_port']
            )
end

upstart_script_name = "#{app['id']}-app"
template "/etc/init/#{upstart_script_name}.conf" do
  source "unicorn-upstart.conf.erb"
  owner "root"
  group "root"
  mode "0664"
  variables(
            :app_name       => app['id'],
            :app_root       => "/home/ubuntu/projects/#{app['id']}/current",
            :log_file       => "/home/ubuntu/projects/#{app['id']}/current/log/unicorn.log",
            :unicorn_config => "/home/ubuntu/projects/#{app['id']}/shared/unicorn.rb",
            :unicorn_binary => "bundle exec unicorn_rails",
            :rack_env       => app['rack_environment']
            )
end

template "#{app['deploy_to']}/current/config/initializers/const.rb" do
  owner 'ubuntu'
  group 'nogroup'
  source "qxt/const.rb.erb"
  mode "0664"
end

template "#{app['deploy_to']}/current/config/mongoid.yml" do        
  source "app/config/mongoid_v2.0.yml.erb"
  owner "ubuntu"
  group "ubuntu"
  mode "0664"
  variables(
            :host => data_bag_item('utils', 'db_config')["mongodb_ip"],
            :port => data_bag_item('utils', 'db_config')["mongodb_port"],
            :database => data_bag_item('utils', 'db_config')["mongodb_database"]
            )
end

service upstart_script_name do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true
  action [ :enable, :start ]
end


node.run_state.delete(:current_app)

