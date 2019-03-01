# RDE Puppet Windows Domain Controller config

# This subclass defines the configuration for RDE Windows domain controller
class rde::windows::domain_controller {
  tag 'dc'

  install                => 'present',
  installmanagementtools => true,
  restart                => true,
  installflag            => true,
  configure              => 'present',
  configureflag          => true,
  domain                 => 'forest',
  domainname             => 'gddsi.com',
  netbiosdomainname      => 'rde',
  domainlevel            => '6',
  forestlevel            => '6',
  databasepath           => 'c:\windows\ntds',
  logpath                => 'c:\windows\ntds',
  sysvolpath             => 'c:\windows\sysvol',
  installtype            => 'domain',
  dsrmpassword           => '<domain password>',
  installdns             => 'yes',
  localadminpassword     => '<local password>',
}