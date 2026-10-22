package Reachout::Config;

use strict;
use warnings;
use Sys::Hostname;

sub new {
    my ($class, %args) = @_;
    my $conf_path = $args{config_file} || '/opt/clearscm/reachout/etc/reachout.conf';
    
    my $self = {
        config_file => $conf_path,
        env_override => $args{env},
        sections    => {},
    };
    bless $self, $class;
    
    $self->_load_config();
    $self->_detect_environment();
    return $self;
}

sub _load_config {
    my ($self) = @_;
    my $file = $self->{config_file};
    return unless -r $file;
    
    open my $fh, '<', $file or die "Cannot read config $file: $!";
    my $current_section = 'general';
    $self->{sections}{$current_section} = {};
    
    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next if $line eq '' || $line =~ /^#/;
        
        if ($line =~ /^\[(\w+)\]$/) {
            $current_section = $1;
            $self->{sections}{$current_section} ||= {};
        } elsif ($line =~ /^([^=]+?)\s*=\s*(.*)$/) {
            my ($key, $val) = ($1, $2);
            $key =~ s/^\s+|\s+$//g;
            $val =~ s/^\s+|\s+$//g;
            $self->{sections}{$current_section}{$key} = $val;
        }
    }
    close $fh;
}

sub _detect_environment {
    my ($self) = @_;
    if ($self->{env_override}) {
        $self->{current_env} = lc($self->{env_override});
        return;
    }
    
    my $host = lc(Sys::Hostname::hostname());
    if ($host eq 'earth' || $host =~ /earth/) {
        $self->{current_env} = 'staging';
    } elsif ($host eq 'cloud' || $host =~ /defaria\.com/ || $host =~ /rockready/) {
        $self->{current_env} = 'production';
    } else {
        $self->{current_env} = 'staging';
    }
}

sub env {
    my ($self) = @_;
    return $self->{current_env};
}

sub set_env {
    my ($self, $env) = @_;
    $self->{current_env} = lc($env);
}

sub get {
    my ($self, $key, $default) = @_;
    my $env = $self->{current_env};
    
    # Check current environment first, then general
    if (exists $self->{sections}{$env}{$key}) {
        return $self->{sections}{$env}{$key};
    }
    if (exists $self->{sections}{general}{$key}) {
        return $self->{sections}{general}{$key};
    }
    return $default;
}

sub get_section {
    my ($self, $section) = @_;
    return $self->{sections}{$section} || {};
}

1;
