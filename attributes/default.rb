

default['ish']['branch']          = "HEAD"
default['ish']['migrate']         = true
default['ish']['migrate_command'] = "rake db:migrate"
default['ish']['revision']     = "HEAD"
default['ish']['action']       = "nothing"
default['ish']['edge']         = false
default['ish']['environment']  = chef_environment =~ /_default/ ? "production" : chef_environment