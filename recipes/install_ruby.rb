
#
# cookbook ish
# recipe   install_ruby
#
# _vp_ 20151227
#

include_recipe 'ruby_build'
include_recipe 'rbenv::system'
# include_recipe 'rbenv::system_install'


