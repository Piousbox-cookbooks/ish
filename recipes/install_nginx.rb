
execute 'install passenger' do
  command " gem install passenger "
  action :run
end

execute 'run the passenger-nginx bridge installed' do
  command "passenger-install-nginx-module --auto --auto-download --prefix=/opt/nginx"
  action :run
  notifies :create, 'ruby_block[remove_install_nginx]', :immediately
end

ruby_block 'remove_install_nginx' do
  block do
    Chef::Log.info( 'removing expensive recipe ish::install_nginx' )
    node.run_list.remove( 'recipe[ish::install_nginx]' ) if node.run_list.include?( 'recipe[ish::install_nginx]' ) 
  end
  action :nothing
end


