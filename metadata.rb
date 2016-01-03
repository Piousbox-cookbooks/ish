name              "ish"
description       "utility recipes for spawning resources pi-style."
maintainer        "wasya.co"
maintainer_email  "victor@wasya.co"
license           "MIT"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.2.1"

recipe "ish", "Installs"

%w{ git sqlite nginx application ruby_build rbenv }.each do |cb|
  depends cb
end
depends "mysql", "~> 6.0"

%w{ ubuntu debian }.each do |os|
  supports os
end
