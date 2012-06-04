package ThinCMS::Template;

use Modern::Perl;
use Template;
use Plack::MIME;
use Encode;

sub process_request {
    my ( $class ) = shift;
    my ( %args ) = @_;

    my $root = $args{tt_root};
    my $path = $args{path};
    my $vars = $args{vars};

    $path   .= 'index.html' if $path =~ /\/$/;
    $path   =~ s{^/}{}; 

    $Template::Stash::PRIVATE = undef;
    my $tt = Template->new( INCLUDE_PATH => $root );

    my $content = '';
    my $type    = '';

    $type = 'text/html';

    if ( $tt->process( $path, $vars, \$content ) ) {
        $content = encode('utf8', $content );
        $type = Plack::MIME->mime_type($1) if $path =~ /(\.\w{1,6})$/
    } else {
        $content = "Template processing error:" . $tt->error();
    }

    return $type, $content;

}

1;
