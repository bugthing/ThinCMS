package Plack::Middleware::ThinCMS;

use strict;
use warnings;
use parent 'Plack::Middleware';

use FindBin;
use Plack::MIME;
use Plack::App::File;
use Plack::Request;

use Config::Any;
use Try::Tiny;
use JSON::XS;
use MIME::Base64;
use MongoDB;
use Template;
use MongoAPI;

use Plack::Util::Accessor qw/cfg_file cfg mongodb json/;

sub prepare_app {
    my ($self) = @_;

    # load config
    $self->cfg_file( $FindBin::Bin . '/config.yml');
    my $cfg = Config::Any->load_files( { files => [ $self->cfg_file() ], use_ext => 1, flatten_to_hash => 1 } );
    ($cfg) =  values %{ $cfg };
    $self->cfg( $cfg );

    # connect to mongo
    my $host = $cfg->{mongodb}->{host};
    my $port = $cfg->{mongodb}->{port};
    $self->mongodb( MongoDB::Connection->new(host => $host, port => $port) );

    # build json object
    my $json_obj = JSON::XS->new->ascii->pretty->allow_nonref;
    $json_obj->convert_blessed(1);
    $self->json( $json_obj );

}

sub call {
    my $self = shift;
    my $env  = shift;

    $self->_set_config( $env );

    my $res;

    $res = $self->_handle_auth($env);
    return $res if ( defined $res );

    $res = $self->_handle_static($env);
    return $res if ( defined $res && $res->[0] != 404);

    $res = $self->_handle_mongo_api($env);
    return $res if ( defined $res && $res->[0] != 404);

    $res = $self->_handle_tt($env);
    return $res if ( defined $res && $res->[0] != 404);

    return $self->app->($env);
}

sub _set_config{
    my $self = shift;
    my ( $env ) = @_;

    my $cfg = $self->cfg();

    # look in the config for 'webs', match and store.
    my $web = {};
    foreach ( @{ $cfg->{'webs'} } ) {
        $web = $_ if ( $_->{default} );
        # TBA - match config based on hostname..
        if ( $web->{host} ) {
        }
    }

    # set env (for tt/static processing)
    my $mdb_name = $web->{mongodb_name};
    $env->{'tt.root'}            = $web->{root};
    $env->{'tt.vars'}->{thincms} = $web;
    $env->{'tt.vars'}->{mdb}     = $self->mongodb()->$mdb_name;

    # is this a request for thincms admin?
    if ( $env->{PATH_INFO} =~ s|^/thincms/|/| ) {
        # add to env for thincms admin system
        $env->{'thincms.cfg'} = $cfg;
        $env->{'tt.root'}     = $FindBin::Bin . '/thincms_public';
        $env->{'tt.vars'}->{'mongodb_name'} = $web->{mongodb_name};
    }
}


sub _handle_auth {
    my $self = shift;
    my $env = shift;

    # only do auth when this is a thincms type request
    return unless exists $env->{'thincms.cfg'};

    my $auth = $env->{HTTP_AUTHORIZATION};
    if ($auth =~ /^Basic (.*)$/) {
        my($user, $pass) = split /:/, (MIME::Base64::decode($1) || ":");
        $pass = '' unless defined $pass;

        my $cfg_user = $env->{'tt.vars'}->{thincms}->{admin_user};
        my $cfg_pass = $env->{'tt.vars'}->{thincms}->{admin_pass};

        if ( $user eq $cfg_user && $pass eq $cfg_pass ) {
            $env->{REMOTE_USER} = $user;
            return;
        }
    }

    my $body = 'Authorization required';
    return [ 401,
        [ 'Content-Type' => 'text/plain',
          'Content-Length' => length $body,
          'WWW-Authenticate' => 'Basic realm="restricted area"',
        ],
        [ $body ],
    ];

}

sub _handle_mongo_api {
    my $self = shift;
    my $env = shift;

    return unless $env->{PATH_INFO} =~ s|/mongodb/||;

    my ($code, $type, $content);
    eval { 
        $self->_process_mongo_api_request( $env, \$type, \$content );
    };
    if ( $@ ) {
        $code = 404;
        $type = 'text/html';
        $content = "error processing mongo api request: $@";
    } else {
        $code = 200;
        $type = 'application/json';
    }

    return [ $code, [ 'Content-Type' => $type ], [$content] ];

}

sub _handle_tt {
    my $self = shift;
    my $env = shift;

    my ($code, $type, $content);
    my $req = Plack::Request->new($env);
    eval { 
        $self->_process_tt( $env, \$type, \$content );
    };
    if ( $@ ) {
        $code = 404;
        $type = 'text/html';
        $content = "error processing vhost template: $@";
    } else {
        $code = 200;
        $type = 'text/html';
    }

    return [ $code, [ 'Content-Type' => $type ], [$content] ];
}

sub _handle_static {
    my $self = shift;
    my $env = shift;

    my $path_match = qr{\.(gif|png|jpg|ico|swf|ico|mov|mp3|pdf|js|css)$};
    my $path = $env->{PATH_INFO};

    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_) : $_ =~ $path_match;
        return unless $matched;
    }

    my $root = $env->{'tt.root'};

    $self->{file} ||= Plack::App::File->new({ root => $root });
    local $env->{PATH_INFO} = $path; 
    return $self->{file}->call($env);
}

sub _process_tt{
    my $self = shift;
    my ( $env, $type, $content ) = @_;

    my $root = $env->{'tt.root'};

    my $tt = Template->new( INCLUDE_PATH => $root );

    my $path = $env->{PATH_INFO} || '/';
    $path   .= 'index.html' if $path =~ /\/$/;
    $path   =~ s{^/}{}; 

    my $vars = $env->{'tt.vars'};

    ${ $type } = 'text/html';

    if ( $tt->process( $path, $vars, $content ) ) {
        ${ $type } = Plack::MIME->mime_type($1) if $path =~ /(\.\w{1,6})$/
    } else {
        ${ $content } = "Template processing error:" . $tt->error();
    }
}

sub _process_mongo_api_request {
    my ( $self, $env, $type_ref, $content_ref ) = @_;

    my $json_obj = $self->json();
    my $req = Plack::Request->new($env);

    my $data = $req->content;
    if ( $data ) {
        try {
            $data = $json_obj->decode( $data );
        } catch {
            warn "JSON decode error: $_"; 
        };
        return 0 unless defined $data;
    }

    my $path = $env->{PATH_INFO};
    $path =~ s{^/}{};
    $path =~ s{/$}{};

    # process the request ..
    my $response_ref = MongoAPI->process_request( 
        mdb_conn => $self->mongodb(),
        method   => $req->method()  , 
        params   => $req->query_parameters(),
        path     => $path           ,
        input    => $data           ,
    );

    $$type_ref = 'application/json';
    # .. create the json and set into content ref..
    $$content_ref = $json_obj->encode( $response_ref );

    return 1;
}

##
1;