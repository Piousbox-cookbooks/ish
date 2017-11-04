
name "microsites3"

description "this is role microsites3"

run_list(
  "recipe[ish::microsites3]"
)

override_attributes({
  :user => 'ubuntu',
  'rbenv' => {
    'rubies' => [ '2.3.1' ]
  },
  'global' => '2.3.1'
})




