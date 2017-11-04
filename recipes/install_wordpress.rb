
#
# cookbook   ish
# recipe     install_mysql
#

# this doesn't work
# _vp_ 20160102
a =<<-EOL
mysql_service 'default' do
  # version '5.7' # _vp_ 20160102 unsupported version?
  bind_address '0.0.0.0'
  port '3306'
  data_dir '/data'
  initial_root_password node['mysql']['server_root_password']
  action [:create, :start]
end
EOL

execute "pre-set password" do
  command "
echo 'mysql-server mysql-server/root_password password #{node['mysql']['server_root_password']}' | debconf-set-selections ; \
echo 'mysql-server mysql-server/root_password_again password #{node['mysql']['server_root_password']}' |debconf-set-selections
"
  action :run
end

package 'mysql-server' do
  action :install
end

execute "adjust bind address" do
  command "sed -i -- 's/127.0.0.1/0.0.0.0/g' my.cnf"
  cwd "/etc/mysql"
end

service 'mysql' do
  action [ :enable, :start ]
end



