package Reachout::Engine;

use strict;
use warnings;
use utf8;
use Encode qw(encode);
use Net::SMTP;
use MIME::Entity;
use POSIX qw(strftime);
use Sys::Hostname;

use Reachout::Adapters::RockReady;
use Reachout::Adapters::Job;
use Reachout::Adapters::Support;

sub new {
    my ($class, %args) = @_;
    my $self = {
        config   => $args{config},
        policy   => $args{policy},
        state    => $args{state},
        template => $args{template},
    };
    
    $self->{adapters} = {
        rockready_club => Reachout::Adapters::RockReady->new(config => $args{config}),
        personal_job   => Reachout::Adapters::Job->new(config => $args{config}),
        support_vendor => Reachout::Adapters::Support->new(config => $args{config}),
    };
    
    bless $self, $class;
    return $self;
}

sub log_msg {
    my ($self, $msg) = @_;
    my $log_file = $self->{config}->get('log_file') || '/opt/clearscm/reachout/logs/reachout.log';
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime());
    my $line = "[$timestamp] $msg\n";
    
    print $line if $self->{verbose};
    
    if (open my $fh, '>>:utf8', $log_file) {
        print $fh $line;
        close $fh;
    }
}

sub get_adapter {
    my ($self, $template_name) = @_;
    return $self->{adapters}{$template_name} || $self->{adapters}{rockready_club};
}

sub default_subject {
    my ($self, $template_name, $target) = @_;
    my $venue = $target->{venue} || "Your Venue";
    
    if ($template_name eq 'rockready_club') {
        return "Rock Ready Booking Inquiry — $venue";
    } elsif ($template_name eq 'personal_job') {
        return "Senior SCM / DevOps & Infrastructure Leadership Inquiry — Andrew DeFaria";
    } elsif ($template_name eq 'support_vendor') {
        my $issue = $target->{issue} || $target->{subject} || "Response Needed";
        return "Following up: $issue";
    }
    return "Outreach Inquiry from ClearSCM";
}

sub dispatch_target {
    my ($self, $target, %options) = @_;
    my $dry_run      = $options{dry_run} // 0;
    my $force_to     = $options{force_to};
    my $force_att    = $options{force_attempt};
    
    my $id           = $target->{id} || die "Target missing id";
    my $policy_name  = $target->{policy} || $self->{config}->get('default_policy') || 'passive';
    my $tpl_name     = $target->{template} || 'rockready_club';
    
    my $state_entry  = $self->{state}->get_target($id);
    my $current_att  = $force_att || (($state_entry ? $state_entry->{attempts} : 0) + 1);
    
    # Check if target is inactive/completed
    if (!$force_att && $state_entry && $state_entry->{status} && $state_entry->{status} ne 'active') {
        $self->log_msg("Target $id is in status '$state_entry->{status}', skipping.");
        return { success => 0, reason => "status_$state_entry->{status}" };
    }
    
    # Adapter data
    my $adapter = $self->get_adapter($tpl_name);
    my $adapter_vars = $adapter->get_template_vars($target);
    
    # Merge template variables
    my %vars = (
        %$adapter_vars,
        Contact       => $target->{contact} || "Booking Manager",
        Email         => $target->{email},
        Venue         => $target->{venue} || "Venue",
        AttemptNumber => $current_att,
        TicketId      => $target->{ticket_id} || ($adapter_vars->{TicketId} // "REQ-8492"),
        SystemAffected=> $target->{system} || ($adapter_vars->{SystemAffected} // "Production Infrastructure"),
        Severity      => $target->{severity} || "High",
        Issue         => $target->{issue} || $target->{subject} || ($adapter_vars->{Issue} // "Pending Request"),
        Reference     => $target->{ref} || $target->{ticket_id} || ($adapter_vars->{Reference} // ""),
        Message       => $target->{message} || $target->{notes} || ($adapter_vars->{Message} // ""),
    );
    
    # Render paired HTML and Text
    my $rendered = $self->{template}->render($tpl_name, \%vars);
    
    # Subject generation
    my $prefix = $self->{policy}->get_subject_prefix($policy_name, $current_att);
    my $base_subj = $target->{subject} || $self->default_subject($tpl_name, $target);
    my $final_subject = $prefix . $base_subj;
    
    # Exact required From header format
    my $sender = 'Andrew DeFaria <Andrew@DeFaria.com>';
    my $recipient = $target->{email};
    
    if ($force_to) {
        $recipient = $force_to;
    } elsif ($self->{config}->get('mail_sandbox')) {
        my $sandbox_to = $self->{config}->get('test_recipient') || 'Andrew@DeFaria.com';
        $self->log_msg("Sandbox Mode Enabled: Rerouting email from $recipient to $sandbox_to");
        $recipient = $sandbox_to;
    }
    
    my $msg_id = "<rr-$id-$current_att-" . time() . "\@defaria.com>";
    
    $self->log_msg("Preparing Reachout for target '$id' (Attempt $current_att, Policy '$policy_name', Template '$tpl_name', To: $recipient)");
    
    if ($dry_run) {
        $self->log_msg("[DRY-RUN] Would send email to '$recipient' with subject: '$final_subject'");
        return {
            success    => 1,
            dry_run    => 1,
            subject    => $final_subject,
            recipient  => $recipient,
            message_id => $msg_id,
        };
    }
    
    # Construct MIME Entity with exact From and Reply-To headers
    my $entity = MIME::Entity->build(
        Type         => "multipart/alternative",
        From         => $sender,
        'Reply-To'   => $sender,
        To           => $recipient,
        Subject      => do { my $s = $final_subject; $s =~ s/[—–]/--/g; $s },
        'Message-ID' => $msg_id,
        'X-Reachout-ID'     => $id,
        'X-Reachout-Policy' => $policy_name,
        'X-Reachout-Stage'  => $current_att,
        'X-Mailer'          => 'ClearSCM Reachout Subsystem',
    );
    
    if ($current_att > 1 && $state_entry && $state_entry->{history} && @{$state_entry->{history}}) {
        my $prev_msg_id = $state_entry->{history}[-1]{message_id};
        if ($prev_msg_id) {
            $entity->head->add('In-Reply-To', $prev_msg_id);
            $entity->head->add('References', $prev_msg_id);
        }
    }
    
    # Attach plain text
    $entity->attach(
        Type     => "text/plain; charset=utf-8",
        Encoding => "quoted-printable",
        Data     => encode("UTF-8", $rendered->{text}),
    );
    
    # Attach HTML
    $entity->attach(
        Type     => "text/html; charset=utf-8",
        Encoding => "quoted-printable",
        Data     => encode("UTF-8", $rendered->{html}),
    );
    
    # Dispatch via sendmail transport:
    # On cloud (production), dispatch via local sendmail.
    # On earth (staging), dispatch via SSH to cloud sendmail to bypass residential IP RBL blocks on port 25.
    my $raw_msg = encode("UTF-8", $entity->as_string);
    my $is_cloud = (`hostname` =~ /cloud|defaria\.com/);
    my $mail_cmd = $is_cloud ? '/usr/sbin/sendmail -t' : 'ssh cloud /usr/sbin/sendmail -t';
    
    open(my $pipe, '|-', $mail_cmd) or die "Cannot execute '$mail_cmd': $!";
    print $pipe $raw_msg;
    close($pipe) or die "Error running '$mail_cmd': $!";
    
    $self->log_msg("SUCCESS: Dispatched message $msg_id to $recipient");
    
    # Calculate next run and update state
    my $next_run = $self->{policy}->calculate_next_run($policy_name, $current_att, time());
    my $is_abandoned = $self->{policy}->is_abandoned($policy_name, $current_att);
    my $new_status = $is_abandoned ? 'abandoned' : 'active';
    
    $self->{state}->update_attempt(
        $id,
        next_run_epoch => $next_run,
        status         => $new_status,
        message_id     => $msg_id,
        subject        => $final_subject,
        recipient      => $recipient,
    );
    
    return {
        success    => 1,
        subject    => $final_subject,
        recipient  => $recipient,
        message_id => $msg_id,
        next_run   => $next_run,
    };
}

1;
