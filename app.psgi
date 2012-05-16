
=head1 NAME

app.psgi

=head1 DESCRIPTION

Runs the ThinCMS application via Plack (plackup)

=cut

use Plack::Builder;
use FindBin qw($Bin);
use lib "$Bin/lib";

use Plack::Middleware::Auth::Basic;
use Plack::Middleware::ErrorDocument;
use Plack::Middleware::Static;
use Plack::Middleware::MongoDB;

my $root = "$Bin/public/";
$admin_root = "$Bin/thincms_public/";

=head2 builder

Constructs the Plack Application

=cut
 
builder {

    # standard 404 handler
    enable 'ErrorDocument', 404 => "$root/page_not_found.html";

    # mount point for the ThinCMS admin system.
    mount "/thincms" => builder {

        # force authentication on any requests to the thincms front end
        enable "Auth::Basic", authenticator => \&authen_thincms;

        # REST API used by the static front end.
        mount "/mongodb" => Plack::Middleware::MongoDB->new(host => 'localhost', port => 27017),

        # static files that make up the thincms front end
        enable 'Static', 
            root => $admin_root, 
            path => qr{\.(gif|png|jpg|swf|ico|mov|mp3|pdf|js|css|html|htm)$},

    },

    # mount point for the standard TT based site
    mount "/" => builder {

        enable 'Static',
            path => qr{\.(gif|png|jpg|swf|ico|mov|mp3|pdf|js|css)$},
            root => $root,

        # here I should parse the requested path a try to determin any requested
        # MongoDB doc and/or doc-list. TBA

        my $doc  = {};
        my $list = [];
 
        enable 'TemplateToolkit',
            INCLUDE_PATH => $root, 
            vars => { doc => $doc, list => $list },
    };

};

=head2 authen_thincms( $user, $pass )

Checks the passed in creditals and returns a boolean to determin access or not

=cut

sub authen_thincms {
    my( $username, $password ) = @_;
    return $username eq 'admin' && $password eq 'password';
}
