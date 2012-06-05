package Test::Mock::MongoDB;

use Moose;

has '_docs' => ( is => 'ro', default => sub { 
        [
            {
                _datetime_added   => '2012-11-29T22:32:45',
                _datetime_updated => '2012-11-29T22:32:45',
                _id               => MongoDB::OID->new(value => "4dcd0090ef2c15e030000000"),
                title             => 'Test Entry',
                content           => 'This a mock MongoDB Doc',
                date              => '2012-09-30',
            },
            {
                _datetime_added   => '2011-11-29T23:32:45',
                _datetime_updated => '2011-11-29T23:32:45',
                _id               => MongoDB::OID->new(value => "4dcd0090ef2c15e030000001"),
                title             => 'Test 2nd Entry',
                content           => 'This a mock MongoDB Doc',
                date              => '2012-09-30',
            },
            {
                _datetime_added   => '2010-11-29T03:39:45',
                _datetime_updated => '2011-01-29T05:02:45',
                _id               => MongoDB::OID->new(value => "4dcd0090ef2c15e030000002"),
                title             => 'Test 3rd Entry',
                content           => 'This a mock MongoDB Doc',
                date              => '1987-09-30',
            },
        ];
} );

sub connection {
    my $self = shift;
    return Test::Mock::MongoDB::Connection->new( mockmongo => $self );
}

package Test::Mock::MongoDB::Connection;
use Moose;
has 'mockmongo' => ( is => 'ro', isa => 'Test::Mock::MongoDB' );
has '_db'  => ( is => 'ro', lazy => 1, default => sub { Test::Mock::MongoDB::Database->new( _docs => $_[0]->mockmongo->_docs ) } );
has 'demo' => ( is => 'ro', lazy => 1, default => sub { $_[0]->_db } );

package Test::Mock::MongoDB::Database;
use Moose;
has '_docs'  => ( is => 'rw', lazy => 1, default => sub { [] } );

has 'name'  => ( is => 'ro', lazy => 1, default => sub { 'demo' } );
has 'Pages' => ( is => 'ro', lazy => 1, default => sub { Test::Mock::MongoDB::Collection->new( _docs => $_[0]->_docs ) } );
has 'Blog'  => ( is => 'ro', lazy => 1, default => sub { Test::Mock::MongoDB::Collection->new( _docs => $_[0]->_docs ) } );

package Test::Mock::MongoDB::Collection;
use Moose;
use MongoDB::OID;
has 'count'  => ( is => 'ro', lazy => 1, default => sub { scalar @{ $_[0]->_docs } } );
has '_curr'  => ( is => 'rw', lazy => 1, default => sub { 0 }  );
has '_skip'  => ( is => 'rw', lazy => 1, default => sub { 0 }  );
has '_limit' => ( is => 'rw', lazy => 1, default => sub { 0 }  );
has '_docs'  => ( is => 'rw', lazy => 1, default => sub { [] } );

sub find {
    my $self = shift;
    return $self;
}
sub skip {
    my $self = shift;
    my ( $skip_numb ) = @_;
    $self->_skip($skip_numb);
    return $self;
}
sub limit {
    my $self = shift;
    my ( $limit_numb ) = @_;
    $self->_limit($limit_numb);
    return $self;
}

sub next {
    my $self = shift;
    return $self->_docs->[ $self->_curr ];
}
sub all {
    my $self = shift;
    my @ret;
    if ( $self->_limit ) {
        my $from = $self->_skip;
        my $to   = $self->_skip + ( $self->_limit - 1);
        @ret = @{ $self->_docs }[ $from .. $to];
    }
    else {
        @ret = @{ $self->_docs };
    }
    return @ret;
}

1;
