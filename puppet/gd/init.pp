# RDE Puppet Base config
#
# This is the base class for all machines.
class rde {
  package { 'nis':
    ensure => 'present',
  }

  nis { 'domainname':
    domainname => 'rde',
  }

  file { '/etc/defaultdomain':
    path    => '/etc/defaultdomain',
    owner   => 'root',
    group   => 'sys',
    mode    => '0644',
    content => 'rde',
    notify  => Service['nis/client'],
  }

  service { 'nis/domain':
    ensure   => 'running',
    enable   => 'true',
    provider => 'smf',
    notify   => Service['nis/client'],
  }

  nsswitch { 'nsswitch':
    alias     => 'files nis',
    automount => 'files nis',
    default   => 'files',
    group     => 'files nis',
    host      => 'files dns nis',
    netgroup  => 'files nis',
    password  => 'files nis',
    notify    => [Service['nis/client'], Service['autofs']],
  }

  service { 'nis/client':
    ensure   => 'running',
    enable   => 'true',
    provider => 'smf',
    notify   => Service['autofs'],
  }

  service { 'dns/client':
    ensure   => 'running',
    enable   => 'true',
    provider => 'smf',
  }

  dns { 'dns/client':
    #nameserver => ['10.100.13.21', '10.100.13.22'],
    nameserver => ['10.100.0.10', '10.100.0.30'],
    domain     => 'gddsi.com',
    search     => ['gddsi.com'],
    notify     => [Service['dns/client'], Service['autofs']],
  }

  package { 'ntp':
    ensure => 'present',
  }

  file { 'ntp.conf':
    path   => '/etc/inet/ntp.conf',
    owner  => 'root',
    group  => 'sys',
    mode   => '0444',
    source => 'puppet:///modules/rde/ntp.conf',
    notify => Service['ntp']
  }

  service { 'ntp':
    ensure   => 'running',
    enable   => 'true',
    provider => 'smf',
  }

  service { 'rpc/bind': ensure => 'running', }

  service { 'zones-proxy-client':
    ensure   => 'running',
    enable   => 'true',
    provider => 'smf',
  }

  # I'm not sure if this is needed on clients. It was needed for
  # the NIS server and slave.
  svccfg { 'binding':
    fmri     => 'svc:/network/rpc/bind',
    property => 'config/local_only',
    type     => 'boolean',
    value    => 'false',
  }

  service { 'autofs':
    ensure   => 'running',
    enable   => 'true',
    provider => 'smf',
    notify   => Service['rpc/bind'],
  }

  service { 'sendmail':
    ensure   => 'running',
    enable   => 'true',
    provider => 'smf',
  }

  if ($hostname = 'rdeadm1') {
    file_line { 'sendmail_relay':
      ensure   => 'present',
      path     => '/etc/mail/sendmail.cf',
      line     => 'DSsmtp-west.gd-ms.us.',
      notify   => Service['sendmail'],
    }
  } else {
    file_line { 'sendmail_relay':
      ensure   => 'present',
      path     => '/etc/mail/sendmail.cf',
      line     => 'DSrdeadm1.gddsi.com',
      notify   => Service['sendmail'],
    }
  }

  svccfg { 'sendmail':
    fmri     => 'svc:/network/smtp:sendmail',
    property => 'config/local_only',
    type     => 'boolean',
    value    => 'false',
    notify   => Service['sendmail'],
  }

  file { '/etc/passwd':
    owner => 'root',
    group => 'sys',
    mode  => '0644',
  }

  file { '/etc/group':
    owner => 'root',
    group => 'sys',
    mode  => '0644',
  }

  file { '/etc/shadow':
    owner => 'root',
    group => 'sys',
    mode  => '0400',
  }

  host { 'rdeadm1':
    ensure  => 'present',
    comment => 'NIS Master',
    ip      => '10.100.13.21',
  }

  host { 'rdeadm2':
    ensure  => 'present',
    comment => 'NIS Slave',
    ip      => '10.100.13.22',
  }

  file { 'motd':
    path   => '/etc/motd',
    owner  => 'root',
    group  => 'sys',
    mode   => '0444',
    source => 'puppet:///modules/rde/motd',
  }

  file { 'issue':
    path   => '/etc/issue',
    owner  => 'root',
    group  => 'sys',
    mode   => '0444',
    source => 'puppet:///modules/rde/issue',
  }

  file { 'sudoers':
    path    => '/etc/sudoers.d/admins',
    owner   => 'root',
    group   => 'sys',
    mode    => '0444',
    content => "+ccadms ALL=(ALL) ALL\np2282c ALL=(ALL) NOPASSWD:ALL\nhn06511 ALL=(ALL) NOPASSWD:ALL\n",
  }

  # Add "+" to /etc/group
  file_line { 'groups':
    path   => '/etc/group',
    ensure => 'present',
    line   => '+',
  }

  # Add "+" to /etc/shadow
  file_line { 'shadow':
    path   => '/etc/shadow',
    ensure => 'present',
    line   => '+',
  }

  # Everybody mounts these
  file_line { 'vob_storage',
    ensure    => 'present',
    path      => '/etc/vfstab',
    line      => 'muosrdenas1:/rdevob1    -       /rdevob1        nfs     -       yes     -',
  }
  file_line { 'view_storage',
    ensure    => 'present',
    path      => '/etc/vfstab',
    line      => 'muosrdenas1:/rdeview1   -       /rdeview1       nfs     -       yes     -',
  }

  if ($hostname == 'rdevob1' || $hostname == 'rdevob2') {
    file_line { 'transfer':
      ensure    => 'present',
      path      => '/etc/vfstab',
      line      => 'muosrdenas1:/transfer   -       /transfer       nfs     -       yes     -',
    }
    file_line { 'rdevob2',
      ensure    => 'present',
      path      => '/etc/vfstab',
      line      => 'muosrdenas1:/rdevob2    -       /rdevob2        nfs     -       yes     -',
    }
  }

  if ($hostname == 'rdevob1') {
    file_line { 'export',
      ensure    => 'present',
      path      => '/etc/vfstab',
      line      => 'muosrdenas1:/export     -       /export         nfs     -       yes     -',
    }
  }

  if ($hostname == 'rdevob1') {
    file_line { 'rdeview2',
      ensure    => 'present',
      path      => '/etc/vfstab',
      line      => 'muosrdenas1:/rdeview2   -       /rdeview2       nfs     -       yes     -',
    }
  }

  $std_packages = ['vim', 'gvim', 'tcsh', 'xauth', 'xclock', 'xterm', 'top', 'rdesktop', 'firefox', 'telnet', 'git', 'expect', 'make', 'gcc', 'motif', 'libxp']

  package { $std_packages:
    ensure => 'present',
  }
}
