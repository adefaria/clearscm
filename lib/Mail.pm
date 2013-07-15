=pod

=head1 NAME $RCSfile: Mail.pm,v $

A simplified approach to sending email

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.34 $

=item Created

Thu Jan  5 15:15:29 PST 2006

=item Modified

$Date: 2012/09/25 01:34:10 $

=back

=head1 SYNOPSIS

Conveniently send email.

  my $msg = "<h1>The Daily News</h1><p>Today in the news...</p>";

  mail (
    to          => "somebody\@somewhere.com",
    cc          => "sombody_else\@somewhere.com",
    subject     => "Today's News",
    mode        => "html",
    data        => $msg,
  );

  open STATUS_REPORT, "status.html";

  mail (
    to          => "boss\@mycompany.com",
    bcc         => "mysecret\@mailbox.com",
    subject     => "Weekly Status Report",
    data        => STATUS_REPORT,
    footing     => "Another day - Another dollar!"
  );

  close STATUS_REPORT;

=head1 DESCRIPTION

Sending email from Perl scripts is another one of those things that is
often reinvented over and over. Well... This is yet another
reinvention I guess. The goal here is to allow for a simplifed
approach to sending email while still allowing MIME or rich text email
to be sent.

Additionally a multipart (plain text and HTML'ized) email will be send
if mode is set to html. Finally, if attempting to send HTML mail, if
we cannot find the appropriate dependent modules we'll fall back to
plain text only.

=head1 ROUTINES

The following routines are exported:

=cut

package Mail;

use strict;
use warnings;

use base 'Exporter';

use FindBin;
use File::Basename;
use Net::SMTP;

use Display;
use GetConfig;

our @EXPORT = qw (
  mail
);

my ($err, %config);

my $mail_conf = dirname (__FILE__) . '/../etc/mail.conf';
              
if (-r $mail_conf) {
  %config = GetConfig $mail_conf;

  $config{SMTPHOST} = $ENV{SMTPHOST} || $config{SMTPHOST};
  
  $err = "SMTPHOST not defined in $mail_conf nor in the environment variable SMTPHOST"
    unless $config{SMTPHOST};
  
  unless ($err) {
    $config{SMTPFROM} = $ENV{SMTPFROM} || $config{SMTPFROM};

    $err = "SMTPFROM not defined in $mail_conf nor in the environment variable SMTPFROM"
      unless $config{SMTPFROM};
  } # unless
} else {
  $err = "Unable to read mail config file $mail_conf";
} # if

sub mail {
  my (%parms) = @_;

=pod

=head2 mail (<parms>)

Send email. The following OO style arguments are supported:

=begin html

<blockquote>

=end html

=over

=item from

The from email address. If not specified then defaults to $ENV{SMTPFROM}.

=item to

Comma separated list of email addresses to set the mail to. At least
one address must be specified.

=item cc

Comma separated list of email addresses to cc the mail to.

=item bcc

Comma separated list of email addresses to bcc the mail to.

=item subject

Subject line for email (Default: "(no subject)")

=item mode

Mode to send the email as. Values can be "plain", "text/plain",
"html", "text/html".

=item data

Either a scalar that contains the message or a filehandle to an open
file which contains the message. Can contain HTML if mode = HTML.

=item heading

Text to be included at the beginning of the email message. Can
contain HTML if mode = HTML.

=item footing

Text to be included at the end fo the email message. Can contain HTML
if mode = HTML.

=back

=begin html

</blockquote>

=end html

Returns:

=begin html

<blockquote>

=end html

=over

=item Nothing

=back

=begin html

</blockquote>

=end html

=cut

  # If from isn't specified we'll use a default
  my $from = defined $parms{from} ? $parms{from} : $config{SMTPFROM};

  error $err, 1 if $err;
  
  my $me = "Mail::mail";

  # Make arrays for to, cc and bcc
  my (@to, @cc, @bcc);
  @to  = split /, */, $parms{to};
  @cc  = split /, */, $parms{cc}  if defined $parms{cc};
  @bcc = split /, */, $parms{bcc} if defined $parms{bcc};

  error       "$me: You must specify \"to\""        if scalar @to == 0;
  warning     "$me: You should specify \"subject\"" if !defined $parms{subject};

  my $subject = defined $parms{subject} ? $parms{subject} : "(no subject)";

  my $mode;

  if (!defined $parms{mode}) {
    $mode = "text/plain";
  } elsif ($parms{mode} eq "plain" or $parms{mode} eq "text/plain") {
    $mode = "text/plain";
  } elsif ($parms{mode} eq "html") {
    $mode = "text/html";
  } elsif ($parms{mode} eq "html") {
    $mode = "text/html";
    # Make sure we can get our modules...
    eval { require MIME::Entity }
      or error "Unable to find MIME::Entity module", 1;
    eval { require HTML::Parser }
      or error "Unable to find HTML::Parser module", 1;
    eval { require HTML::FormatText }
      or error "Unable to find HTML::FormatText module", 1;
    eval { require HTML::TreeBuilder }
      or error "Unable to find HTML::TreeBuilder module", 1;
  } else {
    error "Mode, ${parms{mode}}, is invalid - should be plain or html", 1;
  } # if

  # Connect to server
  my $smtp = Net::SMTP->new ($config{SMTPHOST})
    or error "Unable to connect to mail server: $config{SMTPHOST}", 1;

  # Address the mail
  $smtp->mail ($from);

  # Who are we sending to...
  $smtp->to  ($_, {SkipBad => 1}) foreach (@to);
  $smtp->cc  ($_, {SkipBad => 1}) foreach (@cc);
  $smtp->bcc ($_, {SkipBad => 1}) foreach (@bcc);

  # Now write the headers
  $smtp->data;
  $smtp->datasend ("From: $from\n");
  $smtp->datasend ("To: $_\n") foreach (@to);
  $smtp->datasend ("Cc: $_\n") foreach (@cc);
  $smtp->datasend ("Subject: $subject\n");
  $smtp->datasend ("Content-Type: $mode\n");
  $smtp->datasend ("\n");

  # If heading is specified then the user wants this stuff before the main
  # message
  my $msgdata = $parms{heading};
  chomp $msgdata if $msgdata;

  # If $parms{data} is a GLOB we'll assume it's a FILE reference.
  if (ref ($parms{data}) eq "GLOB") {
    my @lines;
    my $datafile = $parms{data};

    # Just because it's a file reference doesn't mean that it's a valid file
    # reference!
    unless (eval { @lines = <$datafile> }) {
      error "$me: File passed in to mail is invalid - $!", 1
    } # unless

    $msgdata .= join "", @lines;
  } else {
    $msgdata .= $parms{data};
  } # if

  # If footing is specified then the user wants this stuff after the main
  # message
  $msgdata .= $parms{footing} if defined $parms{footing};

  # if the user requested html mode then convert the message to HTML
  if ($mode eq "multipart") {
    # Create multipart container
    my $container = MIME::Entity->build (
      Type    => "multipart/alternative",
      From    => $from,
      Subject => $subject
    );

    # Create a textual version of the HTML
    my $html = HTML::TreeBuilder->new;
    $html->parse ($msgdata);
    $html->eof;
    my $formatter = HTML::FormatText->new (
      leftmargin      => 0,
      rightmargin     => 80
    );
    my $plain_text = $formatter->format ($html);

    # Create ASCII attachment first
    $container->attach (
      Type     => "text/plain",
      Encoding => "quoted-printable",
      Data     => $plain_text,
    );

    # Create HTML attachment
    $container->attach (
      Type     => "text/html",
      Encoding => "quoted-printable",
      Data     => $msgdata,
    );
    
    $container->smtpsend (Host => $smtp);
  } else {
    # Plain text here
    $smtp->datasend ($msgdata);
  } # if

  # All done
  $smtp->dataend;
  $smtp->quit;
  
  return;
} # mail

1;

=pod

=head2 CONFIGURATION AND ENVIRONMENT

SMTPHOST: Set to the appropriate mail server

SMTPFROM: Set to a from address to be used as a default

=head2 DEPENDENCIES

=head3 Perl Modules

L<Net::SMTP>

L<File::Basename>

=head3 CPAN Modules

(Optionally - i.e. if html email is requested:)

=for html <p><a href="http://search.cpan.org/search?query=MIME::Entity">MIME::Entity</a>

=for html <p><a href="http://search.cpan.org/search?query=HTML::Parser">HTML::Parser</a>

=for html <p><a href="http://search.cpan.org/search?query=HTML::FormatText">HTML::FormatText</a>

=for html <p><a href="http://search.cpan.org/search?query=HTML::TreeBuilder">HTML::TreeBuilder</a>

=head3 ClearSCM Perl Modules

=for html <p><a href="/php/cvs_man.php?file=lib/Display.pm">Display</a></p>

=for html <p><a href="/php/cvs_man.php?file=lib/GetConfig.pm">GetConfig</a></p>

=head2 INCOMPATABILITIES

None yet...

=head2 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria >Andrew@ClearSCM.com>.

=head2 LICENSE AND COPYRIGHT

This Perl Module is freely available; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This Perl Module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License (L<http://www.gnu.org/copyleft/gpl.html>) for more
details.

You should have received a copy of the GNU General Public License
along with this Perl Module; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
reserved.

=cut
