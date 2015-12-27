maintainer        "maintainer"
maintainer_email  "piousbox@gmail.com"
license           "MIT"
description       "Does a bunch of stuff."
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.2.0"

recipe "ish", "Installs"

%w{ git sqlite nginx mysql application ruby_build rbenv }.each do |cb|
  depends cb
end

%w{ ubuntu debian }.each do |os|
  supports os
end
