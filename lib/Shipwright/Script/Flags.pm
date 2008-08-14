package Shipwright::Script::Flags;

use strict;
use warnings;
use Carp;

use base qw/App::CLI::Command Class::Accessor::Fast Shipwright::Script/;
__PACKAGE__->mk_accessors(qw/add delete set mandatory/);

use Shipwright;
use List::MoreUtils qw/uniq/;

sub options {
    (
        'a|add=s'    => 'add',
        'd|delete=s' => 'delete',
        's|set=s'    => 'set',
        'mandatory'  => 'mandatory',
    );
}

sub run {
    my $self = shift;
    my $name = shift;

    die "need name arg\n" unless $name;

    if ( $name =~ /^__/ ) {
        print "$name can't start as __\n";
        return;
    }

    my $shipwright = Shipwright->new( repository => $self->repository, );

    my $flags = $shipwright->backend->flags;

    unless ( defined $self->add || defined $self->delete || defined $self->set )
    {

        # show without change
        $self->_show_flags($flags, $name);
        return;
    }

    unless ( 1 == grep { defined $_ } $self->add, $self->delete, $self->set ) {
        die "you should specify one and only one of add, delete and set\n";
    }

    my $list;

    if ( defined $self->add ) {
        $self->add( [ grep { /^[-\w]+$/ } split /,\s*/, $self->add ] );
        $list = [ uniq @{ $self->add }, @{ $flags->{$name} || [] } ];
    }
    elsif ( defined $self->delete ) {
        $self->delete( [ split /,\s*/, $self->delete ] );
        my %seen;    # lookup table
        @seen{ @{ $self->delete } } = ();

        $list = [ grep { !exists $seen{$_} } @{ $flags->{$name} || [] } ];

    }
    elsif ( defined $self->set ) {
        $list = [ grep { /^[-\w]+$/ } split /,\s*/, $self->set ];
    }

    if ( $self->mandatory ) {
        $flags->{__mandatory}{$name} = $list;
    }
    else {
        $flags->{$name} = $list;
    }

    $shipwright->backend->flags($flags);
    $self->_show_flags( $flags, $name );
}

sub _show_flags {
    my $self  = shift;
    my $flags = shift;
    my $name  = shift;

    my $changed;
    $changed = 1 if $self->add || $self->delete || $self->set;

    if ( $self->mandatory ) {
        print "set mandatory flags with success\n" if $changed;
        print "mandatory flags of $name is ";
        if ( @{ $flags->{__mandatory}{$name} || [] } ) {
            print join( ', ', @{ $flags->{__mandatory}{$name} } ) . "\n";
        }
        else {
            print "*nothing*\n";
        }
    }
    else {
        print "set flags with success\n" if $changed;
        print "flags of $name is ";
        if ( @{ $flags->{$name} || [] } ) {
            print join( ', ', @{ $flags->{$name} } ) . "\n";
        }
        else {
            print "*nothing*\n";
        }
    }

}

1;

__END__

=head1 NAME

Shipwright::Script::Flags - Maintain a dist's flags

=head1 SYNOPSIS

 flags -r ... DIST --add FLAG
 flags -r ... DIST --delete FLAG
 flags -r ... --mandatory --set FLAGS LABEL

=head1 OPTIONS

 -r [--repository] REPOSITORY   : specify the repository of our project
 -l [--log-level] LOGLEVEL      : specify the log level
                                  (info, debug, warn, error, or fatal)
 --log-file FILENAME            : specify the log file
 --add, --delete, --set FLAGS   : specify the flags, split by commas
 --mandatory                    : set these flags as being required

=head1 DESCRIPTION

The flags command is used for managing the flags feature of Shipwright. Flags
can be used to group dists in ways which allow a single Shipwright repository
to support multiple variants of binary vessels. For example, if you are
shipping some software that requires a database, your repository can use flags
to allow binary vessels to be built for both MySQL and PostgreSQL from it.

For more information on using flags, see L<Shipwright::Manual::UsingFlags>.