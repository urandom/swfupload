#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::SWFUpload::Queue;

use strict;

use base 'IWL::Tree';

use IWL::Tree::Row;
use IWL::ProgressBar;

use IWL::JSON 'toJSON';
use IWL::String 'randomize';

use Locale::TextDomain qw(org.bloka.iwl.swfupload);

my $init;

=head1 NAME

IWL::SWFUpload::Queue - a file queue for the L<IWL::SWFUpload> widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Tree> -> L<IWL::SWFUpload::Queue>

=head1 DESCRIPTION

The Queue widget stores the queued files for an L<IWL::SWFUpload> widget. It also allows for removing of individual files from the queue, as well as progress indication for each file.

=head1 CONSTRUCTOR

IWL::SWFUpload->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<order>

Describes the column order, as well as what colums are visible. The sytax is an array reference. Possible values are: 

=over 8

=item B<name>

The file name

=item B<status>

The status of the upload

=item B<start>

An image, which will start the upload of the file when clicked

=item B<stop>

An image, which will stop the upload of the file when clicked

=item B<remove>

An image, which will remove the file when clicked

=back

Default value: I<[name, status, remove]>

=item B<showHeader>

If true, will show the queue header

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(list => 1);

    $init->($self, %args);

    return $self;
}

=head1 METHODS

=over 4

=item B<bindToUpload> (B<UPLOAD>)

Binds the queue to the given upload widget.

Parameters: B<UPLOAD> - an L<IWL::SWFUpload> widget

=cut

sub bindToUpload {
    my ($self, $upload) = @_;

    return unless UNIVERSAL::isa($upload, 'IWL::SWFUpload');
    $self->{__upload} = $upload;

    return $self;
}

# Protected
#
sub _realize {
    my $self  = shift;
    my $id    = $self->getId;

    return $self->_pushFatalError(__"Queue: Missing SWFUpload widget") unless $self->{__upload};
    $self->SUPER::_realize;

    my $options = toJSON($self->{_options});
    $self->_appendInitScript("IWL.SWFUpload.Queue.create('$id', \$('$self->{__upload}'), $options)");
    $self->{__header}->setStyle(display => 'none') unless $self->{_options}{showHeader};
    foreach my $column (@{$self->{_options}{order}}) {
        if ($column eq 'name') {
            $self->{__header}->appendTextHeaderCell(__"Name");
        } elsif ($column eq 'status') {
            $self->{__header}->appendTextHeaderCell(__"Status");
        } else {
            $self->{__header}->appendHeaderCell;
        }
    }
}

# Internal
#
$init = sub {
    my ($self, %args) = @_;
    my $header = IWL::Tree::Row->new;
    
    $self->{_options} = {order => [qw(name status remove)]};
    $self->{_options}{order} = $args{order} if defined $args{order};
    $self->{_options}{showHeader} = $args{showHeader} ? 1 : 0;
    delete @args{qw(order showHeader)};

    $self->appendClass('swfupload_queue');
    $args{id} ||= randomize($self->{_defaultClass});

    $self->{__header} = $header;
    $self->appendHeader($header);
    $self->_constructorArguments(%args);

    return $self;
};

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
