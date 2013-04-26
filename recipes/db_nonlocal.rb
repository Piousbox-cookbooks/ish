

# iterate over apps databag and set up each app
data_bag("apps").each do |entry|
  app = data_bag_item("apps", entry)
  appname = app['id']
  deploy_to = app['deploy_to']

  (app["server_roles"] & node.run_list.roles).each do |app_role|

    template "#{deploy_to}/shared/database.yml" do
      source "app/config/database_remote.yml.erb"
      owner "ubuntu"
      group "ubuntu"
      mode "0664"

      variables(
        :host => data_bag_item('utils', 'db_config')['mysql_ip'],
        :database => 'showv'
      )
    end

    # and constants
#    rbenv_script "mkdir environments" do
#      code %{ cd #{deploy_to} && mkdir -p current/config/environments }
#    end
    
    template "#{deploy_to}/current/config/environments/production.rb" do
      source "#{appname}/config/environments/production.rb.erb"
      owner "ubuntu"
      group "ubuntu"
      mode "0664"
    
    end
    
    template "#{deploy_to}/current/config/initializers/const.rb" do
      source "app/config/initializers/const.rb.erb"
      owner "ubuntu"
      group "ubuntu"
      mode "0664"
      
      variables(
        :fb_id => app['FB_ID_3001'],
        :fb_se => app['FB_SE_3001'],
        :s3_access => app['s3_access'],
        :s3_secret => app['s3_secret']
      )
    end

  end
end

