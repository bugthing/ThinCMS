package Plack::Middleware::MongoDB;

use strict;
use warnings;
use parent qw( Plack::Component );
use Plack::Request 0.9901;
use MongoDB;
use JSON::XS;
use Try::Tiny;

use Plack::Util::Accessor qw( host port mongodb json);

sub prepare_app {
    my ($self) = @_;

    $self->host("localhost") unless $self->host();
    $self->port(27017)       unless $self->port();

    # create MongoDB connection
    $self->mongodb( MongoDB::Connection->new(host => $self->host(), port => $self->port()) );

    # create JSON encoder
    $self->json( JSON::XS->new->ascii->pretty->allow_nonref );
    $self->json()->convert_blessed(1);
}

sub call {
    my $self = shift;
    my $env  = shift;

    if ( my $res = $self->_handle($env) ) {
        return $res;
    }
    return [ 404, [ 'Content-Type' => 'text/html' ], ['404 Not Found'] ];
}

sub _handle {
    my ( $self, $env ) = @_;

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

    if ( $self->_process_mongo_request( $path, $vars, \$content ) ) {
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

sub _process_mongo_request {
    my ( $self, $path, $vars, $content_ref ) = @_;

    my $connection = $self->mongodb();

    my $method = $vars->{method};
    my $params = $vars->{params};

    my $data;
    if ( $vars->{json} ) {
        try {
            $data = $self->json()->decode( $vars->{json} );
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
    $$content_ref = $self->json()->encode( $json );

    return 1;

}

1;

