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

=item B<{name =E<gt> name, callback =E<gt> callback, title =E<gt> title}>

If the element is a hash reference, it will be used in the following way: If a I<title> key is present, its value will be shown in the header. A I<callback> key, with a valid javascript function name must be present. The callback will be executed each time a file is queued. The table cell, file and upload objects will be passed to the callback upon execution. A I<name> key, specifying the name of the column, must also be present.

=back

Default value: I<[name, status, remove]>

=item B<showHeader>

If true, will show the queue header

=back

=head1 SIGNALS

=over 4

=item B<load>

Fires when the widget is loaded.

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

Parameters: B<UPLOAD> - an L<IWL::SWFUpload> widget, or a string, which represents the L<IWL::SWFUpload> widget's ID.

=cut

sub bindToUpload {
    my ($self, $upload) = @_;

    return unless $upload
      && !ref $upload 
      || UNIVERSAL::isa($upload, 'IWL::SWFUpload');
    $self->{__upload} = $upload;

    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;
    my $id   = $self->getId;
    my $progress;

    return $self->_pushFatalError(__"Queue: Missing SWFUpload widget") unless $self->{__upload};
    $self->SUPER::_realize;

    foreach my $column (@{$self->{__queueOptions}{order}}) {
        if (ref $column eq 'HASH' && $column->{name}) {
            $self->{__header}->appendTextHeaderCell($column->{title} || '');
        } elsif ($column eq 'name') {
            $self->{__header}->appendTextHeaderCell(__"Name");
        } elsif ($column eq 'status') {
            $self->{__header}->appendTextHeaderCell(__"Status");
            $progress = 1;
        } elsif (grep {$_ eq $column} qw(start stop remove)) {
            $self->{__header}->appendHeaderCell;
        } else {
            $column = '';
        }
    }
    if ($progress) {
        $self->{__progressBar}->setId($id . '_progress')->setStyle(display => 'none');
        unshift @{$self->{_tailObjects}}, $self->{__progressBar};
    }
    $self->{__queueOptions}{order} = [grep { !(!$_) } @{$self->{__queueOptions}{order}}];
    my $options = toJSON($self->{__queueOptions});
    my $uploadId = ref $self->{__upload}
      ? $self->{__upload}->getId
      : $self->{__upload};
    $self->_appendInitScript("IWL.SWFUpload.Queue.create('$id', '$uploadId', $options)");
    $self->{__header}->setStyle(display => 'none') unless $self->{__queueOptions}{showHeader};
}

# Internal
#
$init = sub {
    my ($self, %args) = @_;
    my $header = IWL::Tree::Row->new;
    my $progress = IWL::ProgressBar->new;
    
    $self->{__queueOptions} = {order => [qw(name status remove)]};
    $self->{__queueOptions}{order} = $args{order} if defined $args{order};
    $self->{__queueOptions}{showHeader} = $args{showHeader} ? 1 : 0;
    delete @args{qw(order showHeader)};

    $self->appendClass('swfupload_queue');
    $args{id} ||= randomize($self->{_defaultClass});

    $self->{__progressBar} = $progress;
    $self->{__header} = $header;
    $self->appendHeader($header);
    $self->requiredJs('base.js', 'dist/swfupload.js', 'swfupload.js');
    $self->_constructorArguments(%args);

    $self->{_customSignals} = {
        load => [],
    };
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
