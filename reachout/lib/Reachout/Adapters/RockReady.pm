package Reachout::Adapters::RockReady;

use strict;
use warnings;
use utf8;
use JSON::PP;
use HTTP::Tiny;
use POSIX qw(strftime);

sub new {
    my ($class, %args) = @_;
    my $self = {
        config => $args{config},
    };
    bless $self, $class;
    return $self;
}

sub get_upcoming_shows {
    my ($self, $limit) = @_;
    $limit ||= 5;
    
    my $api_url = $self->{config}->get('prod_api_url') || 'https://rockready.band/wp-json/tribe/events/v1/events';
    if (!$self->{config}->get('pull_from_prod') && $self->{config}->get('rockready_api_url')) {
        $api_url = $self->{config}->get('rockready_api_url');
    }
    
    my $http = HTTP::Tiny->new(
        timeout => 5,
        verify_SSL => 0,
        agent => 'Mozilla/5.0 (compatible; ClearSCMReachout/1.0)'
    );
    
    my $resp = $http->get("$api_url?per_page=$limit");
    my @shows;
    
    if ($resp->{success}) {
        my $data = eval { decode_json($resp->{content}) };
        if ($data && $data->{events} && ref($data->{events}) eq 'ARRAY') {
            for my $ev (@{$data->{events}}) {
                my $title = $ev->{title} || 'Rock Ready';
                $title =~ s/&#8211;/-/g;
                $title =~ s/&#8217;/'/g;
                $title =~ s/&amp;/&/g;
                
                my $v_name = '';
                my $v_city = '';
                if ($ev->{venue} && ref($ev->{venue}) eq 'HASH') {
                    $v_name = $ev->{venue}{venue} || '';
                    $v_city = $ev->{venue}{city} || '';
                }
                
                my $venue_display = $v_name;
                $venue_display .= " - $v_city" if $v_city;
                if (!$venue_display) {
                    $venue_display = $title;
                    $venue_display =~ s/^Rock Ready\s*@?\s*//i;
                }
                
                my $start = $ev->{start_date} || '';
                my $date_str = $start;
                if ($start =~ /^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})/) {
                    my ($y, $m, $d, $h, $min) = ($1, $2, $3, $4, $5);
                    my $hour12 = $h % 12;
                    $hour12 = 12 if $hour12 == 0;
                    my $ampm = $h >= 12 ? 'PM' : 'AM';
                    $date_str = sprintf("%02d/%02d/%d %d:%02d %s", $m, $d, $y, $hour12, $min, $ampm);
                }
                
                push @shows, {
                    title         => $title,
                    venue_display => $venue_display,
                    date          => $date_str,
                    url           => $ev->{url} || 'https://rockready.band',
                };
            }
        }
    }
    
    if (!@shows) {
        push @shows, {
            title         => "Rock Ready @ The Landings",
            venue_display => "The Landings - Carlsbad",
            date          => "Saturday 8:00 PM",
            url           => "https://rockready.band"
        };
    }
    
    return \@shows;
}

sub get_template_vars {
    my ($self, $target) = @_;
    my $shows = $self->get_upcoming_shows(4);
    
    my $html_shows = qq{<table style="width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 14px;">};
    $html_shows .= qq{<tr style="background-color: #2a2a2a; color: #ff5500; text-align: left;"><th style="padding: 8px 12px; border-bottom: 2px solid #ff5500;">Date & Time</th><th style="padding: 8px 12px; border-bottom: 2px solid #ff5500;">Venue</th></tr>};
    
    my $txt_shows = "";
    for my $s (@$shows) {
        $html_shows .= qq{<tr style="border-bottom: 1px solid #333333; color: #e0e0e0;"><td style="padding: 8px 12px; white-space: nowrap;"><strong>$s->{date}</strong></td><td style="padding: 8px 12px;">$s->{venue_display}</td></tr>};
        $txt_shows .= sprintf("  * %s : %s\n", $s->{date}, $s->{venue_display});
    }
    $html_shows .= qq{</table>};
    
    return {
        BandName          => "Rock Ready",
        SiteUrl           => $self->{config}->get('site_url') || 'https://rockready.band',
        PhotoUrl          => 'https://rockready.band/RockReady.band.jpg',
        UpcomingShowsHtml => $html_shows,
        UpcomingShowsTxt  => $txt_shows,
        VideosUrl         => 'https://rockready.band/videos',
        PhotosUrl         => 'https://rockready.band/gallery',
        AudioDemoUrl      => 'https://rockready.band/videos',
        VideoDemoUrl      => 'https://rockready.band/gallery',
        SenderName        => $self->{config}->get('sender_name') || 'Andrew DeFaria',
        SenderEmail       => $self->{config}->get('sender_email') || 'Andrew@DeFaria.com',
        SenderPhone       => $self->{config}->get('sender_phone') || '(408) 596-4937',
    };
}

1;
