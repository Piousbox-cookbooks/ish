
template "/etc/mysql/my.conf" do
  source "etc/mysql/my.conf.erb"
  owner "root"
  group "root"
  mode "0664"

  variables(
    :host => data_bag_item('utils', 'db_config')['mysql_ip']
  )
end

rbenv_script "grant permissions to some node" do
  ips = data_bag_item('utils', 'ish-util')['app_ips']
  ips.each do |ip|
    code %{ 
mysql -u root -e "grant all on *.* to 'root'@'#{ip}'"
mysql -u root -e "flush privileges"
    }
  end
end

rbenv_script "restart mysql" do
  code %{ sudo service mysql restart }
end
