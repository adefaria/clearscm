
=pod

=head1 NAME $RCSfile: JIRA.pm,v $

Minimal module to talk to JIRA and get a few fields

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew.DeFaria@WebPros.com>

=item Revision

$Revision: 1.0 $

=item Created

Monday, April 25 2022

=item Modified

Monday, April 25 2022

=back

=cut

package JIRA;

use strict;
use warnings;

use feature 'say';
use experimental qw(signatures);

use Carp;

use JIRA::REST;

my %findQuery;

sub new ( $class, %opts ) {
    croak "JIRA::new: Username not specified" unless $opts{username};
    croak "JIRA::new: Password not specified" unless $opts{password};
    croak "JIRA::new: Server not specified"   unless $opts{server};

=pod

=head2 new ()

Create a new JIRA object connecting to the JIRA database

Parameters:

=for html <blockquote>

=over

=item $opts{username}

Username to authenticate with

=item $opts{password}

Password to authenticate with

=item $opts{server}

JIRA server to connect to

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $jira

JIRA Object

=back

=for html </blockquote>

=cut

    $opts{URL} = "http://$opts{server}/rest/api/latest";

    $opts{rest} = JIRA::REST->new( $opts{URL}, $opts{username}, $opts{password} );

    #$opts{rest} = JIRA::REST->new( { url => $opts{URL}, anonymous => 1 } );

    return bless \%opts, $class;
}

sub findIssues ( $self, $condition, @fields ) {

=pod

=head2 findIssues ()

Set up a find for JIRA issues based on a condition

Parameters:

=for html <blockquote>

=over

=item $condition

Condition to use. JQL is supported

=item @fields

List of fields to retrieve data for

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item <nothing>

=back

=for html </blockquote>

=cut

    push @fields, '*all' unless @fields;

    $findQuery{jql}        = $condition || '';
    $findQuery{startAt}    = 0;
    $findQuery{maxResults} = 1;
    $findQuery{fields}     = join ',', @fields;

    return;
}    # findIssues

sub getNextIssue ($self) {
    my $result;

=pod

=head2 getNextIssue ()

Get next qualifying issue. Call findIssues first

Parameters:

=for html <blockquote>

=over

=item <none>

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item %issue

Perl hash of the fields in the next JIRA issue

=back

=for html </blockquote>

=cut

    eval { $result = $self->{rest}->GET( '/search/', \%findQuery ) };

    $findQuery{startAt}++;

    # Move id and key into fields
    return unless @{ $result->{issues} };

    $result->{issues}[0]{fields}{id}  = $result->{issues}[0]{id};
    $result->{issues}[0]{fields}{key} = $result->{issues}[0]{key};

    return %{ $result->{issues}[0]{fields} };
}    # getNextIssue

sub status ($self) {
    return $self->{rest}{rest}->responseCode();
}

sub getIssues ( $self, $condition, $start, $max, @fields ) {

=pod

=head2 getIssues ()

Get the @fields of JIRA issues based on a condition. Note that JIRA limits the
amount of entries returned to 1000. You can get fewer. Or you can use $start
to continue from where you've left off. 

Parameters:

=for html <blockquote>

=over

=item $condition

JQL condition to apply

=item $start

Starting point to get issues from

=item $max

Max number of entrist to get

=item @fields

List of fields to retrieve

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item @issues

Perl array of hashes of JIRA issue records

=back

=for html </blockquote>

=cut

    push @fields, '*all' unless @fields;

    my ( $result, %query );

    $query{jql}        = $condition || '';
    $query{startAt}    = $start     || 0;
    $query{maxResults} = $max       || 50;
    $query{fields}     = join ',', @fields;

    eval { $result = $self->{rest}->GET( '/search/', \%query ) };

    # We sometimes get an error here when $result->{issues} is undef.
    # I suspect this is when the number of issues just happens to be
    # an even number like on a $query{maxResults} boundry. So when
    # $result->{issues} is undef we assume it's the last of the issues.
    # (I should really verify this).
    if ( $result->{issues} ) {
        return @{ $result->{issues} };
    }
    else {
        return;
    }    # if
}    # getIssues

sub getIssue ( $self, $issue, @fields ) {

=pod

=head2 getIssue ()

Get individual JIRA issue

Parameters:

=for html <blockquote>

=over

=item $issue

Issue ID

=item @fields

List of fields to retrieve

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item %issue

Perl hash of JIRA issue

=back

=for html </blockquote>

=cut

    my $fields = @fields ? "?fields=" . join ',', @fields : '';

    return $self->{rest}->GET("/issue/$issue$fields");
}    # getIssue

1;
