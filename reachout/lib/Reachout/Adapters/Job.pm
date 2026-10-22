package Reachout::Adapters::Job;

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
    return {
        CandidateName  => "Andrew DeFaria",
        Headline       => "Senior DevOps, SCM, Cloud & AI Infrastructure Architect",
        WebsiteUrl     => "https://defaria.com",
        ResumeUrl      => "https://defaria.com/Resumes/Andrew%20DeFaria%20Resume.html",
        LinkedInUrl    => "https://www.linkedin.com/in/adefaria/",
        GitHubUrl      => "https://github.com/adefaria",
        AvatarUrl      => "https://defaria.com/Images/AndrewDeFaria.jpg",
        BannerUrl      => "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800&auto=format&fit=crop&q=80",
        CoreSkills     => "Release Engineering, CI/CD, Git, ClearCase, Perforce, Linux/UNIX Systems, Cloud Infrastructure, High-Availability Systems, AI Tooling & Automation",
        SenderName     => $self->{config}->get('sender_name') || 'Andrew DeFaria',
        SenderEmail    => $self->{config}->get('sender_email') || 'Andrew@DeFaria.com',
        SenderPhone    => $self->{config}->get('sender_phone') || '(408) 596-4937',
    };
}

1;
