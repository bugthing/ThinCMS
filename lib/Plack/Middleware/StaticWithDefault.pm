package Plack::Middleware::StaticWithDefault;

=head1 NAME

Plack::Middleware::StaticWithDefault

=head1 DESCRIPTION

This is built from the L<Plack::Middleware::Static> and simply adds the behavour
of adding a default file when you request a URL with a trailing slash.

=cut

use strict;
use warnings;
use parent qw/Plack::Middleware::Static/;

use Plack::Util::Accessor qw( index_name );

sub call {
    my $self = shift;
    my $env  = shift;

    # set defaults
    $self->index_name('index.html') unless $self->index_name();

    # if requested url path is empty or ends in a slash..
    my $path = $env->{PATH_INFO};
    $path = $path . $self->index_name() if $path =~ m|/$|;
    $env->{PATH_INFO}  = $path;

    return $self->SUPER::call( $env );
}

##
1;
