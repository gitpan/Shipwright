package Shipwright::Source::Directory;
use strict;
use warnings;
use Carp;
use File::Spec::Functions qw/catfile catdir/;
use File::Basename;

use base qw/Shipwright::Source::Base/;

=head2 new

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    my $s     = $self->source;
    $s =~ s{/$}{};    # trim the last / to let cp work as we like
    $self->source($s);
    return $self;
}

=head2 run

=cut

sub run {
    my $self = shift;
    $self->log->info(
        'run source ' . ( $self->name || $self->path ) . ': ' . $self->source );

    $self->_update_version( $self->name || $self->just_name( $self->path ),
        $self->version );

    $self->_update_url( $self->name || $self->just_name( $self->path ),
        'directory:' . $self->source ) unless $self->{_no_update_url};

    my $newer = $self->_cmd; # if we really get something new

    $self->SUPER::run(@_);
    # follow only if --follow and we really added new stuff.
    $self->_follow(
        catfile(
            $self->directory, $self->name || $self->just_name( $self->path )
        )
    ) if $self->follow && $newer;
    return catfile( $self->directory,
        $self->name || $self->just_name( $self->path ) );
}

=head2 path

return the basename of source

=cut

sub path {
    my $self = shift;
    return basename $self->source;
}

sub _cmd {
    my $self = shift;
    my $to =
      catfile( $self->directory,
        $self->name || $self->just_name( $self->path ) );
    return if -e $to;

    return [ 'cp', '-r', $self->source, $to ];
}

1;

__END__

=head1 NAME

Shipwright::Source::Directory - directory source


=head1 DESCRIPTION


=head1 DEPENDENCIES


None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2007 Best Practical Solutions LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
