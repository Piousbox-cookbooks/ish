
packages = %w{
 mongodb-server mongodb-clients
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

directory "/data/db" do
  owner "ubuntu"
  group "ubuntu"
  mode 00755
  action :create
  recursive true
end

# replace /etc/mysql/my.conf

template "/etc/mongodb.conf" do
  source "etc/mongodb.conf.erb"
  owner "root"
  group "root"
  mode "0664"

  variables(
    :bind_ip => data_bag_item('utils', 'db_config')['mongodb_ip'],
    :port => data_bag_item('utils', 'db_config')['mongodb_port']
  )
  
end