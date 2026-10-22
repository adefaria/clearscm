package Reachout::Template;

use strict;
use warnings;
use File::Basename;

sub new {
    my ($class, %args) = @_;
    my $template_dir = $args{template_dir} || '/opt/clearscm/reachout/templates';
    my $self = {
        template_dir => $template_dir,
    };
    bless $self, $class;
    return $self;
}

sub render {
    my ($self, $template_name, $vars) = @_;
    my $html_file = "$self->{template_dir}/$template_name.html";
    my $txt_file  = "$self->{template_dir}/$template_name.txt";
    
    my $html_content = "";
    my $txt_content  = "";
    
    if (-r $html_file) {
        open my $fh, '<', $html_file or die "Cannot read $html_file: $!";
        local $/;
        $html_content = <$fh>;
        close $fh;
    }
    
    if (-r $txt_file) {
        open my $fh, '<', $txt_file or die "Cannot read $txt_file: $!";
        local $/;
        $txt_content = <$fh>;
        close $fh;
    }
    
    for my $k (keys %$vars) {
        my $val = defined $vars->{$k} ? $vars->{$k} : "";
        $html_content =~ s/\{\{\s*\Q$k\E\s*\}\}/$val/g;
        $txt_content  =~ s/\{\{\s*\Q$k\E\s*\}\}/$val/g;
    }
    
    # Strip any remaining unreplaced template tokens
    $html_content =~ s/\{\{\s*[\w\.]+\s*\}\}//g;
    $txt_content  =~ s/\{\{\s*[\w\.]+\s*\}\}//g;
    
    return {
        html => $html_content,
        text => $txt_content,
    };
}

1;
