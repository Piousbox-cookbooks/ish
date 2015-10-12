
#
# ish-lib, instead of application:rails
# 20120801
#
#
#
#

app = data_bag_item("apps", 'ish-lib')

rails_env = '_default'
deploy_to = "/home/ubuntu/projects/ish-lib"

node.default[:apps][app['id']][node.chef_environment][:run_migrations] = false

rbenv_script "clone" do
  code %{cd /home/ubuntu/projects/ && git clone git://github.com/computational-arts-corp/ish-lib.git }
  
end