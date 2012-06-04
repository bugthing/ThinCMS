package ThinCMS::Template::Plugin::ThinCMS;

###############################################################################
# Required inclusions.
###############################################################################
use Modern::Perl;
use Scalar::Util 'blessed';
our $AUTOLOAD;
use Template::Plugin;
use Data::Page;
use Data::Dumper;
use overload '""'  => sub { 
    $_[0]->{_DOC_ID}
};

use base qw( Template::Plugin );

sub new {
    my ($class, $context, $data, $params) = @_;

    return $class->error('invalid collection name, could not find') unless defined $data;
    my $collection_name = $data;

    my $mdb = $context->{STASH}->{mdb};
    return $class->error('could not get mongodb (mdb) from ThinCMS')
        unless ref $mdb eq 'MongoDB::Database';

    my $collection = $mdb->$collection_name;

    return $class->error('could not get collection from ThinCMS')
        unless ref $collection eq 'MongoDB::Collection';
 
    $params ||= {};
    return $class->error('invalid table parameters, expecting a hash')
        unless ref $params eq 'HASH';

    my $querystring = $context->{STASH}->{querystring} || {};
    return $class->error('could not querystring from ThinCMS variables')
        unless ref $querystring eq 'Hash::MultiValue';

    my $self = bless {
        _COLLECTION_NAME => $collection_name,
        _COLLECTION      => $collection,
        _CURSOR          => undef,
        _FIND_ARG0       => {},
        _FIND_ARG1       => {},
        _FIND_COUNT      => 0,
        _PAGER_PERPAGE   => ( $params->{perpage} || 0 ),
        _PAGER_PAGE      => ( $querystring->{page} || 1 ),
        _DOC_ID          => ( $querystring->{id} || 0 ),
    }, $class;

    $self->_set_cursor;

    return $self;
}

sub _set_cursor {
    my $self = shift;
    $self->{_CURSOR}     = $self->{_COLLECTION}->find( $self->{_FIND_ARG0}, $self->{_FIND_ARG1} );
    $self->{_FIND_COUNT} = $self->{_CURSOR}->count();
    return $self->{_CURSOR};
}

sub _apply_paging {
    my $self = shift;
    if ( $self->pager ) {
        $self->skip( ( ($self->{_PAGER_PAGE} - 1) * $self->{_PAGER_PERPAGE} ) );
        $self->limit( $self->{_PAGER_PERPAGE} );
    }
}

sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';
 
    return $self->$item
        if ($item =~ /^(?:sort|skip|limit|all)$/);

    return $self->error("Can not a ThinCMS action with: $item");
}

sub all {
    my $self = shift;
    $self->_apply_paging();
    my @all = ($self->{_CURSOR}->all, undef);
    return @all;
}
sub sort {
    my $self = shift;
    my ( $args ) = @_;
    $args->{'_datetime_added'} = -1 if ( ! defined $args || ref $args ne 'HASH' );
    $self->{_CURSOR} = $self->{_CURSOR}->sort( $args );
    return $self;
}
sub limit {
    my $self = shift;
    my ( $limit ) = @_;
    $limit = 20 if ( ! defined $limit );
    $self->{_CURSOR} = $self->{_CURSOR}->limit( $limit );
    return $self;
}
sub skip {
    my $self = shift;
    my ( $skip ) = @_;
    $skip = 20 if ( ! defined $skip );
    $self->{_CURSOR} = $self->{_CURSOR}->skip( $skip );
    return $self;
}

sub pager {
    my $self = shift;
    return unless $self->{_PAGER_PERPAGE};

    my $page = Data::Page->new();
    $page->total_entries($self->{_FIND_COUNT});
    $page->entries_per_page($self->{_PAGER_PERPAGE});
    $page->current_page($self->{_PAGER_PAGE});

    return $page;
}

sub doc {
    my $self = shift;
    my ( $find_args ) = @_;

    my $doc;

    if( $find_args && ref $find_args eq 'HASH' ) {
        $self->{_FIND_ARG0} = $find_args;
        $self->_set_cursor();
        $doc = $self->{_CURSOR}->next;
    }elsif($self->{_DOC_ID}) {
        $doc = $self->{_COLLECTION}->find_one({ _id => MongoDB::OID->new(value => $self->{_DOC_ID})})
    }

    return $doc;
}


1;
