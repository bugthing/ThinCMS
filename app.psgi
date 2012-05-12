
=head1 NAME

app.psgi

=head1 DESCRIPTION

Runs the ThinCMS application via Plack (plackup)

=cut

use Plack::Builder;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Plack::Middleware::MongoDB;

my $root = "$Bin/public/";
 
builder {

    mount "/mongodb" => Plack::Middleware::MongoDB->new(host => 'localhost', port => 27017),

    mount "/" => builder {
        # Page to show when requested file is missing
        enable 'ErrorDocument', 
	        404 => "$root/page_not_found.html";
 
        # These files can be served directly
        enable 'Static',
            path => qr{\.(gif|png|jpg|swf|ico|mov|mp3|pdf|js|css)$},
            root => $root;
 
        enable 'TemplateToolkit',
            INCLUDE_PATH => $root, 
            pass_through => 1; # delegate missing templates to $app
    };
}
