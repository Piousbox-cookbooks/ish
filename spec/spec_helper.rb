
require 'chefspec'
# require 'chefspec/berkshelf'
require 'chefspec/librarian'

def puts! args, label=""
  puts "+++ +++ #{label}"
  puts args.inspect
end
