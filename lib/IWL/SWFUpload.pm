#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::SWFUpload;

use strict;

use base 'IWL::Widget';

use vars qw($VERSION);

$VERSION = '0.1';

=head1 NAME

IWL::SWFUpload - a file upload widget using the flash swfupload library

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::SWFUpload>

=head1 DESCRIPTION

The SWFUpload widget is a widget for upload files. It uses the flashh swfupload library in order to achieve true multi-upload functionality

=head1 CONSTRUCTOR

IWL::SWFUpload->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new;

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=cut

# Protected
#
sub _realize {
    my $self   = shift;
    my $id     = $self->getId;

    $self->SUPER::_realize;
}

# Internal
#
sub __init {
    my ($self, %args) = @_;

    return $self;
}

1;

=head1 AUTHOR

  Viktor Kojouharov

=head1 Website

L<http://code.google.com/p/iwl>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
