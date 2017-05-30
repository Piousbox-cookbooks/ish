
require 'chefspec'
# require 'chefspec/berkshelf' # trash from way long ago
# require 'chefspec/librarian' # this hangs forever

# ChefSpec::Coverage.start!

def puts! args, label=""
  puts "+++ +++ #{label}"
  puts args.inspect
end

RSpec.configure do |config|
  config.cookbook_path = [ '/home/piousbox/projects/rails-quick-start/cookbooks',
                           '/home/piousbox/projects/rails-quick-start/site-cookbooks' ]

  config.role_path = [ 'test/roles' ]

  # config.environment_path = ''
end
