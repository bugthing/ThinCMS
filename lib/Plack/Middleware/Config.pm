package Plack::Middleware::Config;
use parent qw( Plack::Middleware );
use Plack::Util;
use Plack::Util::Accessor qw( stems );

use Config::Any;
 
sub call {
    my ($self, $env) = @_;

    my $cfg = Config::Any->load_stems( { stems => $self->stems(), use_ext => 1, flatten_to_hash => 1 } );
    $env->{'cfg.cfg'} = $cfg;
    my $response = $self->app->($env);

    $self->response_cb($response, sub { } );

}

1;
