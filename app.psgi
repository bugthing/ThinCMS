
=head1 NAME

app.psgi

=head1 DESCRIPTION

Runs the ThinCMS application via Plack (plackup)

=cut

use FindBin qw($Bin);
use lib "$Bin/lib";

use Plack::Builder;
use Plack::Middleware::Auth::Basic;
use Plack::Middleware::StaticWithDefault;
use Plack::Middleware::MongoDB;

# Important vars

# ..mongodb related..
my $mdb_host   = "localhost";
my $mdb_port   = 27017;
my $mdb_dbname = "testdb"; # for use with non-api mongodb calls
my $mdb_conn   = MongoDB::Connection->new(host => $mdb_host, port => $mdb_port);

# ..plack related..
my $root       = "$Bin/public/";
my $admin_root = "$Bin/thincms_public/";

=head2 Plack Builder

This is the Plack builder that constructs the paths and middleware used
to serve a ThinCMS based website.

=cut
 
builder {

    # TBA - need middleware to load in config!
    # TBA - need to parse domain and configure accordingly

    # mount point for the ThinCMS admin system.
    mount "/thincms" => builder {

        # force authentication on any requests to anything in this mount.
        enable "Plack::Middleware::Auth::Basic", authenticator => \&authen_thincms;

        # MongoDB backed REST API used by the static front end.
        mount "/mongodb" => Plack::Middleware::MongoDB->new(mongodb => $mdb_conn),

        # static files make up the whole thincms front end
        mount "/" => builder { enable 'Plack::Middleware::StaticWithDefault', root => $admin_root, path => qr/.*/; };
    };

    # mount point for the standard TT based site
    mount "/" => builder {

        # stuff to serve up as static content (images, css, etc.)
        enable 'Plack::Middleware::StaticWithDefault',
            path => qr{\.(gif|png|jpg|swf|ico|mov|mp3|pdf|js|css)$},
            root => $root,

        # here I should parse the requested path a try to determin any requested
        # MongoDB doc and/or doc-list. TBA

        my $mdb = $mdb_conn->$mdb_dbname;

        my $doc  = {};
        my $list = [];
 
        enable 'TemplateToolkit',
            INCLUDE_PATH => $root, 
            vars => { 
                mdb => $mdb,
                doc => $doc, 
                list => $list ,
            },
    };

};

=head2 authen_thincms( $user, $pass )

Checks the passed in creditals and returns a boolean to determin access or not

=cut

sub authen_thincms {
    my( $username, $password ) = @_;
    return $username eq 'admin' && $password eq 'password';
}


