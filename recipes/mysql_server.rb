
# replace /etc/mysql/my.conf

template "/etc/mysql/my.conf" do
  source "etc/mysql/my.conf.erb"
  owner "root"
  group "root"
  mode "0664"
  variables(
    :host => data_bag_item('utils', 'db_config')['mysql_ip']
  )
end

template "/etc/mysql/my.cnf" do
  source "etc/mysql/my.conf.erb"
  owner "root"
  group "root"
  mode "0664"
  variables(
    :host => data_bag_item('utils', 'db_config')['mysql_ip']
  )
end

gem_package 'mysql' do
  action :install
end
