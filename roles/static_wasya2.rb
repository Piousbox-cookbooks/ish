
name "static_wasya2"
description "A role. Apache2 virtual host for static sites, and a deployed resource of a static site."

run_list(
  'recipe[ish_apache::install_apache]',
  'recipe[php::default]',
  'recipe[ish::static_site]'
)

override_attributes()
