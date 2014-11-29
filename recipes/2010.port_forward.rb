


template "/etc/init/port_forward.conf" do
  variables :port_forwards => data_bag_item("utils", "port_forward")['port_forwards']
  source "upstart_port_forward.erb"
end

service 'port_forward' do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true
  action [ :enable, :start ]
end