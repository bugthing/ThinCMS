
=head1 NAME

app.psgi

=head1 DESCRIPTION

Runs the ThinCMS application via Plack (plackup)

=cut

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Plack::Builder;

=head2 Plack Builder

This is the Plack builder that constructs the paths and middleware used
to serve a ThinCMS based website.

=cut
 
builder {
    mount "/" => builder {
        enable 'ThinCMS';
    };
};
