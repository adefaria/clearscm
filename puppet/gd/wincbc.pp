# RDE Puppet Windows config

# This subclass defines the configuration for RDE Windows machines
class rde::windows {
  tag 'cbc'

  #$win_software_repo   = '\\az251dp2ch2d\Software' # A software repo. Currently on the machine under test but can be on any share

  # Install Cygwin
  $cyg_setup = "$win_software_repo\\Cygwin-2.9-Win64\\setup-x86_64.exe"
  $cyg_repo = "-L -l $win_software_repo\\Cygwin-2.9-Win64"
  $cyg_categories = "-C Base"
  $cyg_root = 'C:\Cygwin'
  $cyg_install_to = "-R $cyg_root"
  $cyg_pkgs = "-P openssh,cygrunsrv,bzip2,unzip,zip,gcc-core,gcc-G++,git,git-gui,make,vim,vim-common,perl,perl_base,perl-Term-ReadLine-Gnu,perl-Term-ReadKey,php,python2,python3,dos2unix,rlwrap,wget,xorg-server,xorg-server-common,xorg-x11-fonts-dpi100,xauth,xclock,xload,xterm,gnome-terminal,dbus-x11"

  exec { 'Install Cygwin':
    command => "$cyg_setup -q $cyg_repo $cyg_install_to $cyg_categories $cyg_pkgs",
    creates => $cyg_root,
    timeout => 600, # Cygwin takes some time to install
  }

  exec { 'Setup sshd':
    path      => "$cyg_root\\bin",
    command   => "bash /usr/bin/ssh-host-config2 -y -u cyg_server -w 'Ranroot!'",
    creates   => "$cyg_root/etc/sshd_config",
    logoutput => 'on_failure',
  }

  windows::path { "$cyg_root\\bin": }

  windows::unzip { "$win_software_repo\\ProcessExplorer.zip":
    destination => 'C:\Windows\System32',
    creates     => 'C:\Windows\System32\Procexp.exe',
  }

  exec { 'Install Firefox':
    command => "$win_software_repo\\FirefoxInstaller.exe -ms",
    creates => 'C:\Program Files\Mozilla Firefox\firefox.exe',
  }

  exec { 'Install Adobe Reader':
    command => "$win_software_repo\\AcroRdrDC1801120040_en_US.exe /sAll",
    creates => 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe',
  }
}
