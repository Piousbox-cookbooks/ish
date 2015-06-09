
app = data_bag_item("apps", 'ish')
appname = app['id']

template "/home/ubuntu/projects/#{appname}/shared/database.yml" do
  source "database_local.yml.erb"
  owner app['owner']
  group app['group']
  mode 0644
end

template "/home/ubuntu/projects/#{appname}/shared/mongoid.yml" do
  source "mongoid_local.yml.erb"
  owner app['owner']
  group app['group']
  mode 0644
end
