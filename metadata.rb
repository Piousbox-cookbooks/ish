maintainer        "maintainer"
maintainer_email  "314658@gmail.com"
license           "GNU II"
description       "Installs"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.1.0"

recipe "ish", "Installs"
recipe "ish::db_bootstrap", "Bootstraps db"
recipe "ish::extra", "extra stuff for the OS"

%w{ git sqlite nginx mysql application ruby_build rbenv }.each do |cb|
  depends cb
end

%w{ ubuntu debian }.each do |os|
  supports os
end

# version 0.1.0, mysql gem is installed at all times
