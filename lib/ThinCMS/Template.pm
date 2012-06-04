package ThinCMS::Template;

use Modern::Perl;

use Template;
use Plack::MIME;
use Encode;
use Data::Pageset;
use Date::Parse qw();
use Date::Format qw();

sub process_request {
    my ( $class ) = shift;
    my ( %args ) = @_;

    my $root   = $args{tt_root};
    my $path   = $args{path};
    my $mdb    = $args{mdb};
    my $qs     = $args{querystring};

    my $vars = $args{vars};

    $path .= 'index.html' if $path =~ /\/$/;
    $path =~ s{^/}{}; 

    $Template::Stash::PRIVATE = undef;
    my $tt = Template->new( 
        INCLUDE_PATH => $root,
        VARIABLES => {
            mdb         => $mdb, # used by the plugin (site specific mongodb database connection)
            querystring => $qs,  # used by the plugin to get page etc. from querystring
        },
        PLUGINS => {
            ThinCMS => 'ThinCMS::Template::Plugin::ThinCMS',
        },
        FILTERS => {
            date => sub {
                my ( $src_date_string ) = @_;
                my $epoch = Date::Parse::str2time( $src_date_string );
                my $format = '%Y-%m-%d';
                return Date::Format::time2str( $format, $epoch );
            },
            time => sub {
                my ( $src_date_string ) = @_;
                my $epoch = Date::Parse::str2time( $src_date_string );
                my $format = '%H:%M:%S';
                return Date::Format::time2str( $format, $epoch );
            },
            datetime => sub {
                my ( $src_date_string ) = @_;
                my $epoch = Date::Parse::str2time( $src_date_string );
                my $format = '%Y-%m-%d %H:%M:%S';
                return Date::Format::time2str( $format, $epoch );
            },
        },
    );

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


sub pager {

    my $total_entries = 0;
    my $entries_per_page = 0 ;
    my $current_page = 0;
    my $pages_per_set = 0;

    my $page_info = Data::Pageset->new({
        'total_entries'       => $total_entries, 
        'entries_per_page'    => $entries_per_page, 
        # Optional, will use defaults otherwise.
        'current_page'        => $current_page,
        'pages_per_set'       => $pages_per_set,
        'mode'                => 'fixed', # default, or 'slide'
    });

}

1;
