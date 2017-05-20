source 'https://supermarket.chef.io'

metadata

cookbook 'application'
cookbook 'git'
cookbook 'php'
cookbook 'ish_apache'
cookbook 'nginx'
cookbook 'rbenv'
cookbook 'ruby_env'
cookbook 'ruby_build'
cookbook 'mysql'

group :integration do
  cookbook 'apt', '~> 2.9.2'
  cookbook 'yum', '~> 3.8.2'
  cookbook 'zypper', '~> 0.2.1'
  cookbook 'pacman', '~> 1.1.1'
  cookbook 'fqdn', :git => 'https://github.com/drpebcak/fqdn-cookbook.git'
end

# cookbook 'ish_test', :path => 'test/fixtures/cookbooks/ish_test'
