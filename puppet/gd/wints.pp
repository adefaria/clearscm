# RDE Puppet Windows Terminal config

# This subclass defines the configuration for RDE Windows terminal server. Note that
# this server will have a lot of development tools installed on it as RDE developers
# use these machines to run Windows tools.
#
# Seems like there are a few ways to install Windows packages. One is just using exec.
# The other is just to unzip a file. Finally there's .msi files. I think we can use
# the package resource for .msi's and .exe's. Not as sure about being able to unsip
# applications that are just delivered as a zip file. I need a Windows machine to test
# things on.

class rde::wints {
  $win_software_repo = '\\az251dp2ch2d\Software' # A software repo. Currently on the machine under test but can be on any share
  tag 'ts'

  # ActivePerl: Installs OK
  windows::unzip { "$win_software_repo\\ActivePerl-5.24.3.2404-MSWin32-x64-404865.zip":
    destination => "C:\\",
    creates     => 'C:\Perl',
    tag         => ['activeperl'],
  }

  # PHP
  file { 'C:\PHP':
    ensure => 'directory',
    tag    => ['php'],
  }

  # PHP: Installs OK
  windows::unzip { "$win_software_repo\\PHP-5.6.31\\php-5.6.31-Win32-VC11-x86.zip":
    destination => "C:\\PHP",
    creates     => "C:\\PHP\\bin",
    require     => File['C:\PHP'],
    tag         => ['php'],
  }

  # Ghostscript: Installs OK
  package { 'Ghostscript':
    source          => "$win_software_repo\\Ghostscript-9.0.9\\gs909w64.exe",
    install_options => '/S /NCRC',
    tag             => ['ghostscript'],
  }

  # BeyondCompare: Installs OK
  exec { 'Beyond Compare':
    command => "$win_software_repo\\TPS1166_Beyond_Compare\\beycomp_081407.exe /verysilent /sp-",
    tag     => ['beyondcompare']
  }

  # SecureCRT: Installs OK
  package { 'SecureCRT':
    source          => "$win_software_repo\\TPS1284_SecureCRT_v6.63\\scrt663-x64.exe",
    install_options => '/s /v"/qn"',
    tag             => ['securecrt'],
  }

  # Apache Tomcat: Installs OK
  windows::unzip { "$win_software_repo\\Apache-Tomcat-8.5.11\\apache-tomcat-8.5.11-windows-x64.zip":
    destination => 'C:\Program Files',
    creates     => 'C:\Program Files\apache-tomcat-8.5.11',
    tag         => ['apachetomcat'],
  }

  # DeepBurner: Installs OK
  package { 'DeepBurner':
    source          => "$win_software_repo\\DeepBurner-1.9\\DeepBurner1.exe",
    install_options => '/s',
    tag             => ['deepburner'],
  }

  # GnuWin32: This "install" requires considerable hand configuration and also
  # reaches out to the Internet to download packages. This will not fly behind
  # a firewall and most of the functionality here is already provided in Cygwin.
  # exec { 'GnuWin32':
  # command => "$win_software_repo\\GnuWin32-0.6.21\\GetGnuWin32\\install.bat",
  # creates => "???",
  #}

  # Notepad++: Installs OK
  package { 'Notepad++':
    source          => "$win_software_repo\\Notepad++7.5.6\\npp.7.5.6.Installer.exe",
    install_options => '/S',
    tag             => ['notepadplusplus'],
  }

  # Console2: Installs OK
  windows::unzip { "$win_software_repo\\Console-2.00b148-Beta_64bit.zip":
    destination => 'C:\Program Files',
    creates     => 'C:\Program Files\Console2',
    tag         => 'console2',
  }

  # JDK: Installs OK
  package { 'JDK':
    source          => "$win_software_repo\\jdk-8u172-windows-x64.exe",
    install_options => '/s',
    tag             => 'jdk',
  }

  # Eclipse: Installs OK
  windows::unzip { "$win_software_repo\\Eclipse.zip":
    destination => "C:\\",
    creates     => 'C:\Eclipse',
    tag         => ['eclipse'],
  }

  windows::shortcut { 'C:\Users\All Users\Desktop\Eclipse.lnk':
    target      => 'C:\Eclipse\Eclipse.exe',
    description => 'Eclipse IDE',
    tag         => ['eclipse'],
  }

  # Microsoft SQL Server: I tried installing this but it was too old to run on
  # 2012 R2
  # exec { 'Microsoft SQL Server':
  #  command => "$win_software_repo\\Microsoft-SQL-Server-2005-SP3-Express-Edition\\SQLEXPR64-SP3.exe",
  #  #creates => "???",
  #}

  # Microsoft Visual Studio: Thought this was working. Turns out it doesn't work.
  # Works by hand though :-(
  exec { 'Microsoft Visual Studio':
    command => "$win_software_repo\\TPS0004_Visual_studio_Pro_2010\\Setup\Setup.exe /q /full",
    creates => 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\devenv.exe',
    tag     => ['visualstudio'],
    timeout => 600, # Visual Studio takes some time to install
  }

  exec { 'Console Emulator':
    command => "$win_software_repo\\ConEmu-150813\\ConEmuSetup.150813g.exe /p:x64 /qr",
    creates => 'C:\Program Files\ConEmu',
    tag     => ['conemu'],
  }

  # Putty: Installs OK
  exec { 'Putty':
    command => "$win_software_repo\\TPS1288_PuTTY\\putty-0.63-installer.exe /verysilent /sp-",
    tag     => ['putty'],
  }

  # Python 2.7.13: Installs OK
  package { 'Python 2.7.13':
    source          => "$win_software_repo\\Python-2.7.13\\Windows\\python-2.7.13.amd64.msi",
    install_options => '/qn',
    tag             => ['python2713'],
  }

  # Pythong 3.6.4: Installs OK
  exec { 'Python 3.6.4':
    command => "$win_software_repo\\Python-3.6.4\\python-3.6.4-amd64.exe /quiet InstallAllUsers=1 PrependPath=1",
    tag     => ['python364'],
  }

  # TeraTerm: Installs OK
  package { 'TeraTerm':
    source          => "$win_software_repo\\TeraTerm-4.7.3\\teraterm-4.73.exe",
    install_options => '/verysilent',
    tag             => ['teraterm'],
  }

  # VIM 7.3: Installs OK
  windows::unzip { "$win_software_repo\\VIM-7.3\\MSDOS\\vim73w32.zip":
    destination => 'C:\Program Files',
    creates     => 'C:\Program Files\vim',
    tag         => ['vim'],
  }

  # VNC: Installs OK
  package { 'VNC':
    source          => "$win_software_repo\\VNC-Open-4.1.3\\vnc-4_1_3-x86_win32.exe",
    install_options => '/verysilent',
    tag             => ['vnc'],
  }

  # Microsoft Office: Installs OK
  exec { 'Microsoft Office':
    command => "$win_software_repo\\TPS1293_Office_Standard\\setup.exe /config Standard.WW\config.xml",
    tag     => ['office'],
  }

  # Microsoft Visio: Installs OK
  exec { 'Microsoft Visio':
    command => "$win_software_repo\\TPS0003_Visio_Standard\\x86\\setup.exe /config Visio.WW\config.xml",
    timeout => 600, # Microsoft Visio takes some time to install
    tag     => ['visio'],
  }
}
