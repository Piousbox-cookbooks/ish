
#
# cookbook ish
# recipe   install_ruby
#
# _vp_ 20151227
# since rbenv doesn't work I'll do it myself
#

include_recipe 'ruby_build'
include_recipe 'rbenv'
execute "install_rbenv_version" do
  command "rbenv install #{node[:rbenv][:global]}"
end





=begin
execute "install_ruby_2" do
  command <<-EOL
    apt-add-repository ppa:brightbox/ruby-ng
    apt-get update -y
    apt-get install ruby2.2 -y
EOL
end
=end
