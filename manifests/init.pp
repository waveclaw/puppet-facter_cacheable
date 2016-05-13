# == Class: facter_cacheable
#
# Placeholder for the facter libaries and puppet feature
#
# === Parameters
#
# [*none*]
#   This class takes no paramters.
#
# === Variables
#
# [*::osfamily*]
#  Warn on unsupported operatingsytems
#
class facter_cacheable {
  if $::osfamily == 'Microsoft' {
    fail("${::operatingsystem} is not supported.")
  }
}
