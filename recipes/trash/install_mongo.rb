
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

rbenv_script 'restart mongo' do
  code %{ sudo service mongodb restart }
end
