package ThinCMS::MongoAPI;
# ABSTRACT: MongoAPI, handles rest requests with a mongodb connection
# VERSION: 0.1

=head1 NAME
 
MongoAPI - Process a simple MongoDB based API request.

=head1 SYNOPSIS

    my $res = MongoAPI->process_request(
        mdb_conn => MongoDB::Connection->new(),
        method   => 'PUT',
        path     => 'mydb/mycollection/87diusaofiud6fiu3iouwf',
        input    => { name => 'my updated name' },
        params   => {},
    );
=cut

use strict;
use warnings;
use DateTime;
use MongoDB::OID;
use Data::Dumper;

=head2 METHODS

=over

=item process_request( method => 'GET', path => 'mydb/foocoll/ABC123', mdb_conn => $con ( params => {}, input => {} ) )

Takes the main elements of a REST request and processes it in a MongoDB way.

method      : String - GET/POST/PUT/DEL
path        : String - path requested
mdb_conn    : L<MongoDB> intance
params      : HashRef - params
input       : HashRef - input data (eg. the document data for a POST request to a document path)

=cut

sub process_request {
    my ( $class ) = shift;
    my ( %req ) = @_;

    my $method   = $req{method};
    my $param    = $req{params};
    my $path     = $req{path};
    my $input    = $req{input};
    my $database = $req{mdb_conn};
    my $output   = {};

    print "MongoAPI - Request:" . Dumper( \%req ) if ( $ENV{DEBUG} );

    $path =~ s|^/||;
    my ( $coll, $id ) = split(/\//, $path);

    print "MongoAPI - Parts: $coll - $id \n" if ( $ENV{DEBUG} );

    if ( $coll && $id ) {
        # Document specific
        my $collection = $database->$coll;
        my $oid = MongoDB::OID->new(value => $id);
        if ( $method eq 'GET' ) {
            # output doc
            my $document = $collection->find_one({ _id => $oid });
            $output = $document;
        }
        elsif ( $method eq 'PUT' ) {

            # update doc
            
            my $now = DateTime->now;
            $input->{_datetime_updated} = "$now";
            my $document = $collection->find_one({ _id => $oid });
            $input->{_datetime_added} = $document->{_datetime_added};

            $collection->update({_id => $oid}, $input, {"upsert" => 1});
            $output = { 'ok' => 1, msg => 'updated document' };
        }
        elsif ( $method eq 'DEL' ) {
            # delete doc
            $collection->remove( {_id => $oid} );
            $output = { 'ok' => 1, msg => 'deleted document' };
        }
    }
    elsif ( $coll && ! $id ) {
        # Collection specific
        my $collection = $database->$coll;
        if ( $method eq 'GET' ) {
            # list docs
            my $cursor = $collection->find();
            my @docs = $cursor->all;
            $output = { rows => \@docs };
        }
        elsif ( $method eq 'POST' ) {

            # create doc
            my $now = DateTime->now;
            $input->{_datetime_added} = "$now";

            $id = $collection->insert( $input );
            $output = { 'ok' => 1, msg => 'added', _id => $id };
        }
        elsif ( $method eq 'DEL' ) {
            # delete coll
            $collection->drop();
            $output = { 'ok' => 1, msg => 'deleted collection' };
        }
    }
    elsif ( ! $coll && ! $id ) {
        # Database specific
        if ( $method eq 'GET' || $method eq 'POST' || $method eq 'PUT' ) {
            # list colls
            my @colls = $database->collection_names;
            $output = { rows => \@colls };
        }
        elsif ( $method eq 'DEL' ) {
            # delete db
            $database->drop();
            $output = { 'ok' => 1, msg => 'deleted database' };
        }
    }

    print "MongoAPI - Response:" . Dumper( $output ) if ( $ENV{DEBUG} );

    # return the data after processing the request.
    return $output;
}

=back

=cut

##
1;
