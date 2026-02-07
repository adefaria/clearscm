use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
  NAME               => 'Clearquest',
  AUTHOR             => q{Andrew DeFaria <Andrew@DeFaria.com>},
  VERSION_FROM       => 'lib/Clearquest.pm',
  ABSTRACT_FROM      => 'lib/Clearquest.pm',
  LICENSE            => 'artistic_2',
  PL_FILES           => {},
  MIN_PERL_VERSION   => '5.006',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  BUILD_REQUIRES => {
    'Test::More' => '0',
  },
  PREREQ_PM => {
    'Carp'        => '0',
    'Time::Local' => '0',

    # 'REST'        => '0', # Optional, only if using REST module
    # 'XML::Simple' => '0', # Optional, only if using REST module
  },
  PM => {
    'lib/Clearquest.pm'           => '$(INST_LIB)/Clearquest.pm',
    'lib/Clearquest/Admin.pm'     => '$(INST_LIB)/Clearquest/Admin.pm',
    'lib/Clearquest/Client.pm'    => '$(INST_LIB)/Clearquest/Client.pm',
    'lib/Clearquest/DBService.pm' => '$(INST_LIB)/Clearquest/DBService.pm',
    'lib/Clearquest/LDAP.pm'      => '$(INST_LIB)/Clearquest/LDAP.pm',
    'lib/Clearquest/REST.pm'      => '$(INST_LIB)/Clearquest/REST.pm',
    'lib/Clearquest/Server.pm'    => '$(INST_LIB)/Clearquest/Server.pm',
    'lib/Clearquest/Utils.pm'     => '$(INST_LIB)/Clearquest/Utils.pm',
    'etc/cq.conf'                 => '$(INST_LIB)/Clearquest/cq.conf',
  },
  dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  clean => {FILES    => 'Clearquest-*'},
);
