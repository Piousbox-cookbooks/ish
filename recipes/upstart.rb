
#
# cookbook ish
# recipe upstart
# copyright 2013 Wasya.co
# author Victor Pudeyev <admin@piousbox.com>
#
# descr: starts a service
#

search(:apps) do |app|
  (app["server_roles"] & node.run_list.roles).each do |app_role|
    app["type"][app_role].each do |thing|
      app = data_bag_item("apps", app_role)
      node.run_state[:current_app] = app

      service upstart_script_name do
        provider Chef::Provider::Service::Upstart
        supports :status => true, :restart => true
        action [ :enable, :start ]
      end
    
    end
  end
end

node.run_state.delete(:current_app)

