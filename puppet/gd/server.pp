# RDE Puppet Server config

# This subclass defines the configuration for RDE Servers
class rde::server {
  # Remove any naked '+''s
  file_line { 'all_users':
    ensure            => 'absent',
    path              => '/etc/passwd',
    line              => '# Remove +',
    match             => '^\+$',
    match_for_absence => 'true',
    replace           => 'false',
    tag               => 'nis',
  }

  # Make sure only members of the ccadms netgroup can log in
  file_line { 'server_users':
    path    => '/etc/passwd',
    ensure  => 'present',
    line    => '+@ccadms',
    tag     => 'nis',
  }
}
