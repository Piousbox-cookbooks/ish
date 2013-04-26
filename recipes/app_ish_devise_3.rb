data_bag("apps").each do |entry|  
  app = data_bag_item("apps", entry)
  if app['id'] == 'ish_devise_3'
    app_role = 'ish_devise_3'
    app["type"][app_role].each do |thing|
      node.run_state[:current_app] = app
      include_recipe "application::#{thing}"
    end
  end
end
node.run_state.delete(:current_app)
