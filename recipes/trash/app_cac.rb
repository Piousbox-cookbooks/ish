
app = data_bag_item( 'apps', 'cac' )
app["type"][app['id']].each do |thing|
  node.run_state[:current_app] = app
  include_recipe "application::#{thing}"
end
node.run_state.delete(:current_app)
