package Reachout::State;

use strict;
use warnings;
use JSON::PP;
use Fcntl qw(:flock);
use POSIX qw(strftime);

sub new {
    my ($class, %args) = @_;
    my $file = $args{state_file} || '/opt/clearscm/reachout/data/reachout_state.json';
    
    my $self = {
        state_file => $file,
        data       => { targets => {} },
    };
    bless $self, $class;
    $self->load();
    return $self;
}

sub load {
    my ($self) = @_;
    my $file = $self->{state_file};
    return unless -f $file && -s $file;
    
    open my $fh, '<:raw', $file or die "Cannot open $file for reading: $!";
    flock($fh, LOCK_SH);
    local $/;
    my $content = <$fh>;
    close $fh;
    
    if ($content) {
        eval {
            $self->{data} = JSON::PP->new->utf8->decode($content);
        };
        if ($@) {
            warn "Error decoding state JSON: $@\n";
            $self->{data} = { targets => {} };
        }
    }
}

sub save {
    my ($self) = @_;
    my $file = $self->{state_file};
    my $json = JSON::PP->new->utf8->pretty->canonical->encode($self->{data});
    
    open my $fh, '>:raw', $file or die "Cannot open $file for writing: $!";
    flock($fh, LOCK_EX);
    print $fh $json;
    close $fh;
}

sub get_target {
    my ($self, $id) = @_;
    return $self->{data}{targets}{$id};
}

sub set_target {
    my ($self, $id, $info) = @_;
    $self->{data}{targets}{$id} = $info;
    $self->save();
}

sub update_attempt {
    my ($self, $id, %params) = @_;
    my $t = $self->{data}{targets}{$id} ||= {
        id       => $id,
        attempts => 0,
        history  => [],
        status   => 'active',
    };
    
    $t->{attempts}++;
    $t->{last_attempt_epoch} = time();
    $t->{last_attempt_date}  = strftime("%Y-%m-%d %H:%M:%S", localtime());
    $t->{next_run_epoch}     = $params{next_run_epoch};
    $t->{next_run_date}      = $params{next_run_epoch} ? strftime("%Y-%m-%d %H:%M:%S", localtime($params{next_run_epoch})) : undef;
    $t->{status}             = $params{status} || $t->{status} || 'active';
    
    push @{$t->{history}}, {
        attempt    => $t->{attempts},
        date       => $t->{last_attempt_date},
        epoch      => $t->{last_attempt_epoch},
        message_id => $params{message_id},
        subject    => $params{subject},
        recipient  => $params{recipient},
    };
    
    $self->save();
    return $t;
}

sub set_status {
    my ($self, $id, $status, $reason) = @_;
    $self->{data}{targets}{$id} ||= { id => $id, attempts => 0, history => [] };
        if (1) {
        $self->{data}{targets}{$id}{status} = $status;
        $self->{data}{targets}{$id}{status_reason} = $reason if $reason;
        $self->{data}{targets}{$id}{updated_date} = strftime("%Y-%m-%d %H:%M:%S", localtime());
        $self->save();
        return 1;
    }
    return 0;
}

sub all_targets {
    my ($self) = @_;
    return $self->{data}{targets} || {};
}

1;
