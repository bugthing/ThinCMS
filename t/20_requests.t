=head1 TEST

This just check things looks ok when rendering a demo ThinCMS app in ./webs/demo/.

=cut

use Modern::Perl;
use FindBin;
use lib $FindBin::Bin . '/lib/';
use Test::More;

use Test::Mock::MongoDB;

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common 'GET';

use_ok 'Plack::Middleware::ThinCMS';

my $cfg_file = "$FindBin::Bin/etc/config.yml";
my $app = builder { enable 'ThinCMS', cfg_file => $cfg_file, mongodb => Test::Mock::MongoDB->new->connection; };

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    diag( $res->content );
    ok( $res->content =~ m|<title>ThinCMS</title>| );
    foreach my $html ( ( q|<div id='id'>4dcd0090ef2c15e030000000</div>|,
                        q|<div id='title'>Test Entry</div>|,
                        q|<div id='date'>2012-09-30</div>|,
                        q|<div id='datetime_added'>2012-11-29T22:32:45</div>|,
                        q|<div id='datetime_updated'>2012-11-29T22:32:45</div>|,
                        q|<div id='datetime_updated_filter_time'>22:32:45</div>|,
                        q|<div id='datetime_updated_filter_date'>29/11/12</div>|,
                        q|<div id='datetime_updated_filter_datetime'>29/11/12 22:32</div>|,
                        q|<div id='content'>This a mock MongoDB Doc</div>|,
                        q|<a href='Blog/index.html?id=4dcd0090ef2c15e030000000'>More</a>|,
                        q|<a href="?page=2">Older thoughts</a>|,
                    ) ) {
        ok( $res->content =~ m|\Q$html\E|, "Checking page for html: $html" );
    }

    my $res = $cb->(GET '/?page=2');
    diag( $res->content );
    foreach my $html ( (q|<div id='id'>4dcd0090ef2c15e030000001</div>|,
                        q|<div id='title'>Test 2nd Entry</div>|,
                        q|<div id='date'>2012-09-30</div>|,
                        q|<div id='datetime_added'>2011-11-29T23:32:45</div>|,
                        q|<div id='datetime_updated'>2011-11-29T23:32:45</div>|,
                        q|<div id='datetime_updated_filter_time'>23:32:45</div>|,
                        q|<div id='datetime_updated_filter_date'>29/11/11</div>|,
                        q|<div id='datetime_updated_filter_datetime'>29/11/11 23:32</div>|,
                        q|<div id='content'>This a mock MongoDB Doc</div>|,
                        q|<a href='Blog/index.html?id=4dcd0090ef2c15e030000001'>More</a>|,
                        q|<a href="?page=1">Newer thoughts</a>|,
                        q|<a href="?page=3">Older thoughts</a>|,
                    ) ) {
        ok( $res->content =~ m|\Q$html\E|, "Checking page for html: $html" );
    }

};

done_testing;

1;
