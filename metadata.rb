name              "ish"
description       "utility recipes for spawning resources pi-style."
maintainer        "wasya.co"
maintainer_email  "victor@wasya.co"
license           "MIT"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.4.3"

%w{ application git php ish_apache nginx 
    rbenv ruby_rbenv ruby_build 
    sqlite }.each do |cb|
  depends cb
end
depends "mysql", "~> 6.0"

%w{ ubuntu debian }.each do |os|
  supports os
end
