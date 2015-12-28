
name "bjjcollective"

description "Role bjjcollective. Environments: _default, vm_samsung."

run_list(
  "recipe[ish_apache::install_apache]",
  "recipe[ish::upstream_rails]"
)

override_attributes({ 'balanced_site_trash' => { 'name' => '',
                                                 'user' => 'oink',
                                                 'domains' => [ 'a', 'b', 'c' ],
                                                 'port' => ''
                                               },
                      :rbenv => {
                        :global => '2.0.0-p576',
                        :rubies => [ '2.0.0-p576' ]
                      }
                    })




