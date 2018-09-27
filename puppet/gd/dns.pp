# RDE Puppet DNS config
#
# This subclass defines the configuration for DNS servers
class rde::dns {
  if ($hostname == 'rdeadm1') or ($hostname == 'rdeadm2') {
    package { 'service/network/dns/bind': ensure => present, }

    service { 'dns/server': ensure => 'running', }

    file { '/var/named':
      ensure => 'directory',
      owner  => 'root',
      group  => 'sys',
      mode   => '0755',
      notify => Service['dns/server'],
    }
  }

  if $hostname == 'rdeadm1' {
    file { '/etc/named.conf':
      owner  => 'root',
      group  => 'sys',
      mode   => '0644',
      source => 'puppet:///modules/rde/named.conf.slave',
      notify => Service['dns/server'],
    }
  } elsif $hostname == 'rdeadm2' {
    file { '/etc/named.conf':
      owner  => 'root',
      group  => 'sys',
      mode   => '0644',
      source => 'puppet:///modules/rde/named.conf.master',
      notify => Service['dns/server'],
    }

    file { '/var/named/named.ca':
      owner  => 'root',
      group  => 'sys',
      mode   => '0644',
      source => 'puppet:///modules/rde/named.ca',
      notify => Service['dns/server'],
    }

    file { '/var/named/gddsi.com':
      owner   => 'root',
      group   => 'sys',
      mode    => '0644',
      source  => 'puppet:///modules/rde/gddsi.com',
      require => File["/var/named"],
      notify  => Service['dns/server'],
    }

    file { '/var/named/gd-ms.us':
      owner   => 'root',
      group   => 'sys',
      mode    => '0644',
      source  => 'puppet:///modules/rde/gd-ms.us',
      require => File["/var/named"],
      notify  => Service['dns/server'],
    }

    file { '/var/named/localhost':
      owner   => 'root',
      group   => 'sys',
      mode    => '0644',
      source  => 'puppet:///modules/rde/localhost',
      require => File["/var/named"],
      notify  => Service['dns/server'],
    }

    file { '/var/named/localhost.in-addr.arpa':
      owner   => 'root',
      group   => 'sys',
      mode    => '0644',
      source  => 'puppet:///modules/rde/localhost.in-addr.arpa',
      require => File["/var/named"],
      notify  => Service['dns/server'],
    }

    file { '/var/named/11.240.10.in-addr.arpa':
      owner   => 'root',
      group   => 'sys',
      mode    => '0644',
      source  => 'puppet:///modules/rde/11.240.10.in-addr.arpa',
      require => File["/var/namedb"],
      notify  => Service['dns/server'],
    }

    file { '/var/named/12.100.10.in-addr.arpa':
      owner   => 'root',
      group   => 'sys',
      mode    => '0644',
      source  => 'puppet:///modules/rde/12.100.10.in-addr.arpa',
      require => File["/etc/namedb/master"],
      notify  => Service['dns/server'],
    }

    file { '/var/named/12.240.10.in-addr.arpa':
      owner   => 'root',
      group   => 'sys',
      mode    => '0644',
      source  => 'puppet:///modules/rde/12.240.10.in-addr.arpa',
      require => File["/etc/namedb/master"],
      notify  => Service['dns/server'],
    }

    file { '/var/named/13.100.10.in-addr.arpa':
      owner   => 'root',
      group   => 'sys',
      mode    => '0644',
      source  => 'puppet:///modules/rde/13.100.10.in-addr.arpa',
      require => File["/etc/namedb/master"],
      notify  => Service['dns/server'],
    }

    file { '/var/named/14.100.10.in-addr.arpa':
      owner   => 'root',
      group   => 'sys',
      mode    => '0644',
      source  => 'puppet:///modules/rde/14.100.10.in-addr.arpa',
      require => File["/etc/namedb/master"],
      notify  => Service['dns/server'],
    }
  }
}
