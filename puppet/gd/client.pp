# RDE Puppet Client config

# This subclass defines the configuration for RDE Clients
class rde::client {
  # Remove any NIS groups
  file_line { 'no_NIS_groups':
    ensure            => 'absent',
    path              => '/etc/passwd',
    line              => '# Remove +',
    match             => '^\+@.*',
    multiple          => 'true',
    match_for_absence => 'true',
    replace           => 'false',
    tag               => 'nis',
  }

  file_line { 'all_users':
    path   => '/etc/passwd',
    ensure => 'present',
    line   => '+',
    tag     => 'nis',
  }
}
