package Reachout::Adapters::Support;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = {
        config => $args{config},
    };
    bless $self, $class;
    return $self;
}

sub get_template_vars {
    my ($self, $target) = @_;
    my $issue = $target->{issue} || $target->{subject} || "Pending Request";
    my $ref   = $target->{ref} || $target->{ticket_id} || "";
    my $msg   = $target->{message} || $target->{notes} || "I wanted to check in on this to see if you have had a chance to review it or if you have any updates.";
    
    return {
        Issue        => $issue,
        Reference    => $ref,
        Message      => $msg,
        WebsiteUrl   => "https://defaria.com",
        SenderName   => $self->{config}->get('sender_name') || 'Andrew DeFaria',
        SenderEmail  => $self->{config}->get('sender_email') || 'Andrew@DeFaria.com',
        SenderPhone  => $self->{config}->get('sender_phone') || '(408) 596-4937',
    };
}

1;
