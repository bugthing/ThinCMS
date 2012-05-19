
=head1 NAME

app.psgi

=head1 DESCRIPTION

Runs the ThinCMS application via Plack (plackup)

=cut

use FindBin qw($Bin);
use lib "$Bin/lib";

use Plack::Builder;

=head2 Plack Builder

This is the Plack builder that constructs the paths and middleware used
to serve a ThinCMS based website.

=cut
 
builder {

    # mount point for the 'webs' - TT based sites
    mount "/" => builder {

        # need to add auth to thincms middleware
        #   enable "Plack::Middleware::Auth::Basic", authenticator => \&authen_thincms;

        enable 'ThinCMS';
    };

};

=head2 authen_thincms( $user, $pass )

Checks the passed in creditals and returns a boolean to determin access or not

=cut

sub authen_thincms {
    my( $username, $password ) = @_;
    return $username eq 'admin' && $password eq 'password';
}


