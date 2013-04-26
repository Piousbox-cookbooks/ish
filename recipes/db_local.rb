
app = data_bag_item("apps", 'ish')
appname = app['id']

#directory "/home/ubuntu/trash" do
#  action :create
#  owner "ubuntu"
#  group "ubuntu"
#  mode "0777"
#end

template "/home/ubuntu/projects/#{appname}/shared/database.yml" do
  source "database_local.yml.erb"
  owner "ubuntu"
  group "nogroup"
  mode 0644
end

template "/home/ubuntu/projects/#{appname}/shared/mongoid.yml" do
  source "mongoid_local.yml.erb"
  owner "ubuntu"
  group "nogroup"
  mode 0644
end