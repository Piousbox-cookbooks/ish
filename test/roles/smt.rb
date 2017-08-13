
name "smt"

description "this is role smt"

run_list(
  # "recipe[ish::base_rhel]"
)

override_attributes({
  :user => 'root',
  'rbenv' => {
    'rubies' => [ '2.3.1' ]
  },
  'global' => '2.3.1'
})




