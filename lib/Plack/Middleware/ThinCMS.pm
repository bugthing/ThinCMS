package Plack::Middleware::ThinCMS;

use strict;
use warnings;
use parent 'Plack::Middleware';

use FindBin;
use Plack::MIME;
use Plack::App::File;
use Template;
use Config::Any;
use MongoDB;
use Try::Tiny;
use JSON::XS;
use Plack::Request;

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

    $res = $self->_handle_static($env);
    return $res if ( defined $res && $res->[0] != 404);

    $res = $self->_handle_mongo_api($env);
    return $res if ( defined $res && $res->[0] != 404);

    $res = $self->_handle_tt($env);
    return $res if ( defined $res && $res->[0] != 404);

    return $self->app->($env);
}

sub _handle_mongo_api {
    my $self = shift;
    my $env = shift;

    return unless( $env->{PATH_INFO} =~ s|^/mongodb/|/| );

    my $req = Plack::Request->new($env);

    my $vars = {
        params => $req->query_parameters(),
        method => $req->method(),
        json   => $req->content,
    };
    my $path = $env->{PATH_INFO};
    $path =~ s{^/}{};
    $path =~ s{/$}{};

    my $content;

    if ( $self->_process_mongo_api_request( $vars, $path, \$content ) ) {
        return [
            '200', [ 'Content-Type' => 'application/json' ],
            [$content]
        ];
    } else {
        my $error = "Could not process MongoDB request";
        return [
            '500', [ 'Content-Type' => 'text/html' ],
            [$error]
        ];
    }

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

    my $path_match = qr{\.(gif|png|jpg|swf|ico|mov|mp3|pdf|js|css)$};
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
    $env->{'tt.root'}            = $web->{root};
    $env->{'tt.vars'}->{thincms} = $web;

    # is this a request for thincms admin?
    if ( $env->{PATH_INFO} =~ s|^/thincms/|/| ) {
        # add to env for thincms admin system
        $env->{'tt.root'}     = $FindBin::Bin . '/thincms_public';
        $env->{'thincms.cfg'} = $cfg;
        $env->{'tt.vars'}->{'mongodb_name'} = $web->{mongodb_name};
    }
}

sub _process_mongo_api_request {
    my ( $self, $vars, $path,$content_ref ) = @_;

    my $method = $vars->{method};
    my $params = $vars->{params};

    my $json_obj = $self->json();
    my $connection = $self->mongodb();

    my $data;
    if ( $vars->{json} ) {
        try {
            $data = $json_obj->decode( $vars->{json} );
        } catch {
            warn "MongoDB middleware json decode error: $_"; 
        };
        return 0 unless defined $data;
    }

    my ( $db, $coll, $id, $json, $database, $collection, $oid, $document );

    if ( $path eq 'databases' ) {

        # List databases
        my @dbs = $connection->database_names;

        $json = { rows => \@dbs };
    }
    elsif ( $path =~ m|^(?<database>\w+)/(?<collection>\w+)/(?<id>.+)$| ) {

        # Document specific

        $db   = $+{database};
        $coll = $+{collection};
        $id   = $+{id};

        $database   = $connection->$db;
        $collection = $database->$coll;
        $oid = MongoDB::OID->new(value => $id);

        if ( $method eq 'GET' ) {

            # output doc

            $document = $collection->find_one({ _id => $oid }); 

            $json = $document;
        }
        elsif ( $method eq 'POST' || $method eq 'PUT' ) {

            # update doc

            $collection->update({_id => $oid}, $data, {"upsert" => 1});

            $json = { 'ok' => 1, msg => 'updated document' };
        }
        elsif ( $method eq 'DEL' ) {

            # delete doc

            $collection->remove( {_id => $oid} );

            $json = { 'ok' => 1, msg => 'deleted document' };
        }

    }
    elsif ( $path =~ m|^(?<database>\w+)/(?<collection>\w+)$| ) {

        # Collection specific

        $db   = $+{database};
        $coll = $+{collection};

        $database   = $connection->$db;
        $collection = $database->$coll;

        if ( $method eq 'GET' ) {

            # list docs
            my $cursor = $collection->find();
            my @docs = $cursor->all;

            $json = { rows => \@docs };

        }
        elsif ( $method eq 'POST' || $method eq 'PUT' ) {

            # create doc

            $id = $collection->insert( $data );

            $json = { 'ok' => 1, msg => 'added', _id => $id };

        }
        elsif ( $method eq 'DEL' ) {

            # delete coll

            $collection->drop();

            $json = { 'ok' => 1, msg => 'deleted collection' };
        }
    }
    elsif ( $path =~ m|^(?<database>\w+)$| ) {

        # Database specific

        $db   = $+{database};

        $database   = $connection->$db;

        if ( $method eq 'GET' || $method eq 'POST' || $method eq 'PUT' ) {

            # list colls
            my @colls = $database->collection_names;

            $json = { rows => \@colls };
        }
        elsif ( $method eq 'DEL' ) {

            # delete db

            $database->drop();

            $json = { 'ok' => 1, msg => 'deleted database' };
        }

    }

    # create the json and set into content ref..
    $$content_ref = $json_obj->encode( $json );

    return 1;
}

##
1;
