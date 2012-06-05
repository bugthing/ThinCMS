package Plack::Middleware::ThinCMS;
# ABSTRACT: ThinCMS Middleware for use with Plack
# VERSION: 0.1

use strict;
use warnings;
use parent 'Plack::Middleware';

use FindBin;
use ThinCMS;
use Plack::Util::Accessor qw/thincms cfg_file mongodb/;

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

    $self->cfg_file( $FindBin::Bin . '/../config.yml' ) unless $self->cfg_file;

    my %thincms_args;
    $thincms_args{cfg_file} = $self->cfg_file;

    # introducted for testing, allows us to pass our own MongoDB connection.
    if ( $self->mongodb ) {
        $thincms_args{mongodb} = $self->mongodb;
    }

    $self->thincms( ThinCMS->new(%thincms_args) );
}

=item call

This is called on every http request.

=cut

sub call {
    my $self = shift;
    my $env  = shift;

    my $res;

    $res = $self->thincms->process( $env );
    return $res if ( defined $res );

    return $self->app->($env);

}

##
1;
