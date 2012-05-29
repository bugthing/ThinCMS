package Plack::Middleware::ThinCMS;
# ABSTRACT: ThinCMS Middleware for use with Plack
# VERSION: 0.1

use strict;
use warnings;
use parent 'Plack::Middleware';

use FindBin;
use Plack::MIME;
use Plack::App::File;
use Plack::Request;
use Encode;
use Config::Any;
use Try::Tiny;
use JSON::XS;
use MIME::Base64;
use MongoDB;
use MongoDB::OID;
use Template;
use ThinCMS::MongoAPI;
use Data::Dumper;
use List::Util qw//;

use Plack::Util::Accessor qw/cfg_file cfg mongodb json req/;

=head1 NAME

Plack::Middleware::ThinCMS - Handles 

=head1 DESCRIPTION

A little bit of L<Plack::Middleware> that does the server side stuff to 
serve a ThinCMS based site.

=head2 PLACK HOOKS

=over

=item prepare_app

This is called when a Plack based app starts up.

=cut

sub prepare_app {
    my ($self) = @_;

    # load config file
    my $conf_file = $FindBin::Bin . '/../config.yml';
    die "Could find config: $conf_file " unless -r $conf_file;
    $self->cfg_file( $conf_file );

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

=item call

This is called on every http request.

=cut

sub call {
    my $self = shift;
    my $env  = shift;

    # set request in object..
    $self->req( Plack::Request->new($env) );

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

=back

=head2 PRIVATE METHODS

=over

=item _set_config

Reads the config and pokes things into the $env for this perticular request domain and path

Most importantly it sets:
  tt.root - path to load files from (either static or tt based)
  tt.vars - hash ref passed to tt when processing templates
              - sets ->{thincms} key within hash, this has the value of appropreate
                 'web:' section of config.
              - sets ->{cmd} key within hash, this is the appropreate mongo database object

.. if this is determined to be a thincms request:
  thincmscfg - hashref of whole configuration file
  tt.root    - this changed to point the thincms_public dir
  tt.vars    - 
                 - sets ->{mongodb_name} sets the dbname this thincms session should use

=cut

sub _set_config{
    my $self = shift;
    my ( $env ) = @_;

    my $cfg = $self->cfg();
    my $req = $self->req();

    # look in the config for 'webs', match and store.
    my $web = {};
    foreach ( @{ $cfg->{'webs'} } ) {

        # set default?.
        $web = $_ if ( $_->{default} );

        # match config based on hostname..
        my $search_string = $req->uri->host;
        my $match_string  = quotemeta( $_->{host} );
        if ($search_string =~ /$match_string/) {
            $web = $_;
            last;
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
        $env->{'tt.root'}     = $FindBin::Bin . '/../thincms_public';
        $env->{'tt.vars'}->{'mongodb_name'} = $web->{mongodb_name};
    }
}

=item _handle_auth

Handles authentication if it thinks it needs to.

=cut

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

=item _handle_static 

Processes a static file if it thinks it needs to.

=cut

sub _handle_static {
    my $self = shift;
    my $env = shift;

    my $path = $env->{PATH_INFO};

    if ( $path =~ /\.(gif|png|jpg|ico|swf|ico|mov|mp3|pdf|js|css)$/ ) {
        my $root = $env->{'tt.root'};
        my $file = Plack::App::File->new({ root => $root });
        return $file->call($env);
    }

    return;
}

=item _handle_mongo_api 

Processes a mongo api request if it thinks this is one.

=cut

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

=item  _handle_tt 

Processes a TemplateToolkit type request

=cut

sub _handle_tt {
    my $self = shift;
    my $env = shift;

    my ($code, $type, $content);
    my $req = $self->req();
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


sub _process_tt{
    my $self = shift;
    my ( $env, $type, $content ) = @_;

    my $root = $env->{'tt.root'};
    my $vars = $env->{'tt.vars'};

    my $path = $env->{PATH_INFO} || '/';
    $path   .= 'index.html' if $path =~ /\/$/;
    $path   =~ s{^/}{}; 

    ## strip out any possible /collection/ID or /collection/
    #my $mdb  = $vars->{mdb};
    #my @path_parts = split /\//, $root;
    #if ( scalar @path_parts  >= 2 ) {
    #    # try to match collection..
    #    my $collection_name = shift @path_parts;
    #    my @coll_names = $mdb->collection_names;
    #    if ( List::Util::first { $_ eq $collection_name } @coll_names ) {
    #        # matched a collection! :)
    #        
    #        if ( scalar @path_parts  >= 2 ) {
    #            my $collection  = $mdb->$collection_name;
    #            # try to match document..
    #            my $id = shift @path_parts;
    #            if ( my $document = $collection->find_one({ '_id' => MongoDB::OID->new(value => $id) }) ) {
    #                # matched a document! :)
    #                # add the list to the vars.
    #                $vars->{doc} = $document;
    #            }
    #            else {
    #                # put unmatched document id back ..
    #                unshift @path_parts, $id;
    #                # add the list to the vars.
    #                $vars->{doc_list} = $collection->find->all();
    #            }
    #        }
    #    }
    #    else {
    #        # put unmatched collection name back ..
    #        unshift @path_parts, $collection_name;
    #    }
    #}
    ## put the path back together..
    #$path = join('/', @path_parts);

    my $tt = Template->new( INCLUDE_PATH => $root );

    ${ $type } = 'text/html';

    if ( $tt->process( $path, $vars, $content ) ) {
        ${ $content } = encode('utf8', ${ $content } );
        ${ $type } = Plack::MIME->mime_type($1) if $path =~ /(\.\w{1,6})$/
    } else {
        ${ $content } = "Template processing error:" . $tt->error();
    }
}

sub _process_mongo_api_request {
    my ( $self, $env, $type_ref, $content_ref ) = @_;

    my $json_obj = $self->json();
    my $req = $self->req();

    my $data = $req->content;

    if ( $data ) {
        try {
            $data = $json_obj->utf8->decode( $data );
        } catch {
            warn "JSON decode error: $_"; 
        };
        return 0 unless defined $data;
    }

    my $path = $env->{PATH_INFO};
    $path =~ s{^/}{};
    $path =~ s{/$}{};

    # process the request ..
    my $response_ref = ThinCMS::MongoAPI->process_request( 
        mdb_conn => $self->mongodb(),
        method   => $req->method()  , 
        params   => $req->query_parameters(),
        path     => $path           ,
        input    => $data           ,
    );

    $$type_ref = 'application/json';
    # .. create the json and set into content ref..
    $$content_ref = $json_obj->utf8->encode( $response_ref );

    return 1;
}

=back

=cut

##
1;
