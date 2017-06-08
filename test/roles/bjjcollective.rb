
name "bjjcollective"

description "Role bjjcollective. Environments: _default, vm_samsung."

run_list(
  "recipe[ish_apache::install_apache]",
  "recipe[ish::upstream_rails]",
  "recipe[bjjcollective::default]"
)

override_attributes({
                      'rbenv' => {
                        'global' => '2.0.0-p576',
                        'rubies' => [ '2.0.0-p576' ]
                      }
                    })




