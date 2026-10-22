package Reachout::Policy;

use strict;
use warnings;
use JSON::PP;

sub new {
    my ($class, %args) = @_;
    my $file = $args{policies_file} || '/opt/clearscm/reachout/etc/policies.json';
    
    my $self = {
        policies_file => $file,
        policies      => {},
    };
    bless $self, $class;
    $self->_load_policies();
    return $self;
}

sub _load_policies {
    my ($self) = @_;
    my $file = $self->{policies_file};
    if (-r $file) {
        open my $fh, '<', $file or die "Cannot read $file: $!";
        local $/;
        my $content = <$fh>;
        close $fh;
        $self->{policies} = decode_json($content);
    }
}

sub get_policy {
    my ($self, $name) = @_;
    $name ||= 'passive';
    return $self->{policies}{$name} || $self->{policies}{passive};
}

sub max_attempts {
    my ($self, $name) = @_;
    my $p = $self->get_policy($name);
    return $p->{max_attempts} || 4;
}

sub get_subject_prefix {
    my ($self, $name, $attempt) = @_;
    my $p = $self->get_policy($name);
    $attempt ||= 1;
    
    if ($p->{attempts}) {
        for my $att (@{$p->{attempts}}) {
            if ($att->{attempt} == $attempt) {
                return $att->{subject_prefix} || '';
            }
        }
    }
    
    if ($p->{escalation} && $attempt > ($p->{max_attempts} || 4)) {
        return $p->{escalation}{subject_prefix} || 'URGENT REMINDER: ';
    }
    
    return '';
}

sub calculate_next_run {
    my ($self, $name, $completed_attempt, $last_run_epoch) = @_;
    my $p = $self->get_policy($name);
    $last_run_epoch ||= time();
    my $next_attempt = $completed_attempt + 1;
    
    # Check fixed schedule attempts
    if ($p->{attempts}) {
        for my $att (@{$p->{attempts}}) {
            if ($att->{attempt} == $next_attempt) {
                my $days = $att->{offset_days} || 7;
                return $last_run_epoch + ($days * 86400);
            }
        }
    }
    
    # Check escalation (e.g. daily for aggressive policy)
    if ($p->{escalation}) {
        my $days = $p->{escalation}{frequency_days} || 1;
        return $last_run_epoch + ($days * 86400);
    }
    
    return undef; # No further runs (abandon or complete)
}

sub is_abandoned {
    my ($self, $name, $completed_attempt) = @_;
    my $p = $self->get_policy($name);
    if (!$p->{escalation} && $completed_attempt >= ($p->{max_attempts} || 4)) {
        return 1;
    }
    return 0;
}

1;
