package ThinCMS;
# ABSTRACT: Think of VHosts, TT, MongoDB and CMS and you have ThinCMS;

use Moose;
use Config::Any;
use Plack::Request;
use Plack::App::File;
use MIME::Base64;
use Encode;
use JSON::XS;
use ThinCMS::MongoAPI;
use Date::Parse;
use Date::Format;
use MongoDB ;
use Try::Tiny;
use FindBin;

use Template;

=head1 NAME

=head1 DESCRIPTION

=head2 ATTRIBUTES

=over

=item cfg_file

This is the only requires attribute to construct this object.

=cut

has cfg_file => (
    is     => 'rw',
    isa    => 'Str',
    required => 1,
);

has env                 => ( is => 'rw', );
has mongodb_database    => ( is => 'rw'); #, isa => 'MongoDB::Database',);
has root                => ( is => 'rw', isa => 'Str',);
has path                => ( is => 'rw', isa => 'Str',);

has json => (
    is     => 'rw',
    isa    => 'JSON::XS',
    default => sub {
        my $json_obj = JSON::XS->new->ascii->pretty->allow_nonref;
        $json_obj->convert_blessed(1);
        return $json_obj;
    }
);
has config => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $cfg = Config::Any->load_files( { files => [ $self->cfg_file() ], use_ext => 1, flatten_to_hash => 1 } );
        ($cfg) =  values %{ $cfg };
        return $cfg;
    }
);

has mongodb => (
    is      => 'rw',
    #isa     => 'MongoDB::Connection',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $host = $self->config->{mongodb}->{host};
        my $port = $self->config->{mongodb}->{port};
        return MongoDB::Connection->new(host => $host, port => $port);
    }
);

=back

=head2 METHODS

=over

=cut

=item vhost_config 

Depending on the HOST requested this returns the appropreate 'web' hash from the config
that matches that HOST. (e.g. only 'demo' web config hash for 'demo.somedomain.com')

=cut

sub vhost_config {
    my $self = shift;

    # look in the config for 'webs', match and store.
    my $web = {};
    foreach ( @{ $self->config->{'webs'} } ) {

        # set default?.
        $web = $_ if ( $_->{default} );

        # match config based on hostname..
        my $search_string = $self->request->uri->host;
        my $match_string  = quotemeta( $_->{host} );
        if ($search_string =~ /$match_string/) {
            $web = $_;
            last;
        }
    }
    return $web;
}

=item request 

=cut

sub request {
    my $self = shift;
    return Plack::Request->new( $self->env );
};

sub is_thincms_request {
    my $self = shift;
    return $self->path =~ m|^/thincms| ? 1 : 0;
}

sub is_mongoapi_request {
    my $self = shift;
    return $self->path =~ m|^/mongodb| ? 1 : 0;
}

=head _shift_path 

Takes the PATH and removes an directory from the start of the path.
Once processed this sets the new path in: L<env> and L<path>, ready for 
processing TT, Static or MongoAPI requests.

=cut

sub _shift_path {
    my $self = shift;
    my @parts = split /\//, $self->env->{PATH_INFO};
    shift @parts;
    shift @parts;
    my $new_path = join('/', @parts);

    $new_path .= '/' if ( -d $self->root . '/' . $new_path );
    $new_path = '/' . $new_path;

    $self->env->{PATH_INFO} = $new_path;

    $self->path( $self->env->{PATH_INFO} );
}

=item process( $env )

Method to be invoked from Plack::Middleware::ThinCMS, looks at $env and handles
accordingly.

=cut

sub process {
    my $self = shift;
    my ( $env ) = @_;

    # set the env to now process the request.
    $self->env( $env );

    my $res = [];

    # connect mongodb
    my $dbname = $self->vhost_config->{mongodb_name};
    $self->mongodb_database( $self->mongodb->$dbname );

    # set path and public root
    $self->root( $self->vhost_config->{root} );
    $self->path( $self->env->{PATH_INFO} );

    # is this a request for thincms admin?
    if ( $self->is_thincms_request ) {
        $self->root( $FindBin::Bin . '/../thincms_public' );
        $self->_shift_path();
        $res = $self->_handle_auth;
        return $res if ( defined $res );
    }

    # is this a mongo api request?
    if ( $self->is_mongoapi_request ) {
        $self->_shift_path();
        $res = $self->_handle_mongo_api;
        return $res if ( defined $res );
    }

    $res = $self->_handle_static;
    return $res if ( defined $res && $res->[0] != 404);

    $res = $self->_handle_tt;

    return $res if defined $res;

    return;
}

=item _handle_static

Handles static content.

B<Returns>

undef    - no static content processed.
ArrayRef - Auth required.

=cut

sub _handle_static {
    my $self = shift;
    if ( $self->path =~ /\.(gif|png|jpg|ico|swf|ico|mov|mp3|pdf|js|css)$/ ) {
        my $file = Plack::App::File->new({ root => $self->root });
        return $file->call($self->env);
    }
    return;
}

=item _handle_mongo_api

Handles MongoDB API request

B<Returns>

ArrayRef - Auth required.

=cut


sub _handle_mongo_api {
    my $self = shift;

    my ($code, $type, $content);

    eval {
        my $data = $self->request->content;

        if ( $data ) {
            try {
                $data = $self->json->utf8->decode( $data );
            } catch {
                warn "JSON decode error: $_";
            };
            return unless defined $data;
        }

        # process the request ..
        my $response_ref = ThinCMS::MongoAPI->process_request(
            mdb_conn => $self->mongodb_database,
            path     => $self->path,
            method   => $self->request->method()  ,
            params   => $self->request->query_parameters(),
            input    => $data,
        );

        $type = 'application/json';
        # .. create the json and set into content ref..
        $content = $self->json->utf8->encode( $response_ref );
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


=item _handle_tt

Handles Template Toolkit request.

B<Returns>

ArrayRef - Auth required.

=cut

sub _handle_tt {
    my $self = shift;

    my ($code, $type, $content);
    eval {
        my $tt = Template->new(
            INCLUDE_PATH => $self->root,
            VARIABLES => {
                mdb         => $self->mongodb_database,
                querystring => $self->request->query_parameters,
                entrytypes  => $self->vhost_config->{entrytypes},
            },
            PLUGINS => {
                ThinCMS => 'ThinCMS::Template::Plugin::ThinCMS',
            },
            FILTERS => {
                date => sub {
                    my ( $src_date_string ) = @_;
                    my $epoch = Date::Parse::str2time( $src_date_string );
                    my $format = $self->vhost_config->{time2str}->{date} || '%Y-%m-%d';
                    return Date::Format::time2str( $format, $epoch );
                },
                time => sub {
                    my ( $src_date_string ) = @_;
                    my $epoch = Date::Parse::str2time( $src_date_string );
                    my $format = $self->vhost_config->{time2str}->{time} || '%H:%M:%S';
                    return Date::Format::time2str( $format, $epoch );
                },
                datetime => sub {
                    my ( $src_date_string ) = @_;
                    my $epoch = Date::Parse::str2time( $src_date_string );
                    my $format = $self->vhost_config->{time2str}->{datetime} || '%Y-%m-%d %H:%M:%S';
                    return Date::Format::time2str( $format, $epoch );
                },
            },
        );

        my $path = $self->path;
        $path =~ s|(.*?/)$|$1/index.html|;
        $path =~ s|^/+||;
        $self->path($path);

        $type = 'text/html';
        $type = Plack::MIME->mime_type($1) if $self->path =~ /(\.\w{1,6})$/;

        if ( $tt->process( $self->path, {}, \$content ) ) {
            $content = Encode::encode('utf8', $content );
        } else {
            die "Template processing error:" . $tt->error();
        }
    };

    if ( $@ ) {
        $code = 404;
        $content = "error processing tt request: $@";
    } else {
        $code = 200;
    }

    return [ $code, [ 'Content-Type' => $type ], [$content] ];
}

=item _handle_auth

Handles authentication if it thinks it needs to.

B<Returns>

undef    - not auth required (already done)
ArrayRef - Auth required.

=cut

sub _handle_auth {
    my $self = shift;
    my $env = shift;

    my $auth = $self->env->{HTTP_AUTHORIZATION};
    if ($auth =~ /^Basic (.*)$/) {
        my($user, $pass) = split /:/, (MIME::Base64::decode($1) || ":");
        $pass = '' unless defined $pass;

        my $cfg_user = $self->vhost_config->{admin_user};
        my $cfg_pass = $self->vhost_config->{admin_pass};

        if ( $user eq $cfg_user && $pass eq $cfg_pass ) {
            $self->env->{REMOTE_USER} = $user;
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

=back

=cut

__PACKAGE__->meta->make_immutable;

1;

__END__
