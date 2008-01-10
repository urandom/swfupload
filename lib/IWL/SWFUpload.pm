#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::SWFUpload;

use strict;

use base 'IWL::Button';

use IWL::JSON 'toJSON';
use IWL::Config '%IWLConfig';

use vars qw($VERSION);

use Locale::TextDomain qw(org.bloka.iwl);

$VERSION = '0.1';

my $init;

=head1 NAME

IWL::SWFUpload - a file upload widget using the flash swfupload library

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Button> -> L<IWL::SWFUpload>

=head1 DESCRIPTION

The SWFUpload widget is a widget for upload files. It uses the flash swfupload library in order to achieve true multi-upload functionality. Visually, it's equivalent to a form's [Browse ...] button.

=head1 CONSTRUCTOR

IWL::SWFUpload->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<multiple>

If true, the invoked file selector can pick multiple files. Defaults to I<false>

=item B<bindToSignal> => B<NAME>

Binds the button to invoke the file selector when the given signal is emitted. Defaults to I<click>

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(%args);

    $init->($self, %args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setMultiple> (B<BOOL>)

Sets whether the widget's file selector can pick multiple files

Parameters: B<BOOL> - if true, the selector can pick multiple files.

=cut

sub setMultiple {
    my ($self, $bool) = @_;

    $self->{_uploadOptions}{multiple} = !(!$bool);
    return $self;
}

=item B<isMultiple>

Returns true if the file selector can pick multiple files

=cut

sub isMultiple {
    return shift->{_uploadOptions}{multiple};
}

=item B<bindToSignal> (B<SIGNAL>)

Binds the file selection to a button signal. See L<IWL::Button> for supported signals.

Parameters: B<SIGNAL> - the signal to bind to

=cut

sub bindToSignal {
    my ($self, $signal) = @_;

    $self->{_uploadOptions}{bindToSignal} = $signal;
    return $self;
}

=item B<setUploadURL> (B<URL>)

Sets the upload script to call

Parameters: B<URL> - the url to call on file upload

=cut

sub setUploadURL {
    my ($self, $url) = @_;

    $self->{__SWFOptions}{upload_url} = $url;

    return $self;
}

=item B<getUploadURL>

Returns the url of the upload script

=cut

sub getUploadURL {
    return shift->{__SWFOptions}{upload_url};
}

=item B<setPostParams> (B<%PARAMS>)

Sets additional post parameters to pass to the script

Parameters: B<%PARAMS> - a hash of parameters

=cut

sub setPostParams {
    my ($self, %params) = @_;

    $self->{__SWFOptions}{post_params} = {%params};

    return $self;
}

=item B<getPostParams>

Returns the post parameters

=cut

sub getPostParams {
    return %{shift->{__SWFOptions}{post_params}};
}

=item B<setFileTypes> (B<TYPES>, B<DESCRIPTION>)

Sets the allowed file types for upload.

Parameters: B<TYPES> - the allowed types. A semicolor separater string of glob patterns. See glob(3). B<DESCRIPTION> - a description, which is displayed in the file selector

=cut

sub setFileTypes {
    my ($self, $types, $description) = @_;

    $self->{__SWFOptions}{file_types} = $types;
    $self->{__SWFOptions}{file_types_description} = $description;

    return $self;
}

=item B<getFileTypes>

Returns the allowed file types and the description.

=cut

sub getFileTypes {
    my $self = shift;
    return $self->{__SWFOptions}{file_types}, $self->{__SWFOptions}{file_types_description};
}

=item B<setFileSizeLimit> (B<LIMIT>)

Sets the maximum size of the files to be uploaded.

Parameters: B<LIMIT> - the size limit, in I<KB>, unless a unit is specified. Examples:
  147483648 B, 2097152, 2097152KB, 2048 MB, 2 GB

=cut

sub setFileSizeLimit {
    my ($self, $limit) = @_;

    $self->{__SWFOptions}{file_size_limit} = $limit;

    return $self;
}

=item B<getFileSizeLimit>

Returns the maximum size of the files to be uploaded

=cut

sub getFileSizeLimit {
    return shift->{__SWFOptions}{file_size_limit};
}

=item B<setFileUploadLimit> (B<LIMIT>)

Sets the maximum number of files that can be uploaded

Parameters: B<LIMIT> - the number of files to be uploaded, or I<0> for unlimited uploading.

=cut

sub setFileUploadLimit {
    my ($self, $limit) = @_;

    $self->{__SWFOptions}{file_upload_limit} = $limit;

    return $self;
}

=item B<getFileUploadLimit>

Returns the maximum files that can be uploaded

=cut

sub getFileUploadLimit {
    return shift->{__SWFOptions}{file_upload_limit};
}

=item B<setFileQueueLimit> (B<LIMIT>)

Sets the maximum number of files that can be queued

Parameters: B<LIMIT> - the limit number. I<0> for an unlimited queue

=cut

sub setFileQueueLimit {
    my ($self, $limit) = @_;

    $self->{__SWFOptions}{file_queue_limit} = $limit;

    return $self;
}

=item B<getFileQueueLimit>

Returns the maximum number of files that can be queued

=cut

sub getFileQueueLimit {
    return shift->{__SWFOptions}{file_queue_limit};
}

# Protected
#
sub _realize {
    my $self   = shift;
    my $id     = $self->getId;

    $self->SUPER::_realize;
    $self->signalConnect($self->{_uploadOptions}{bindToSignal} =>
          'this.control.' . (
            $self->{_uploadOptions}{multiple} ? 'selectFiles' : 'selectFile'
          ) . '()');

    my $options = toJSON($self->{__SWFOptions});
    $self->_appendInitScript("\$('$id').control = new SWFUpload($options)");
}

# Internal
#
$init = sub {
    my ($self, %args) = @_;
    
    $self->{_uploadOptions} = {};
    $self->{_uploadOptions}{multiple}     = $args{multiple} ? 1 : 0;
    $self->{_uploadOptions}{bindToSignal} = $args{bindToSignal} || 'click';
    delete @args{qw(multiple bindToSignal)};

    $self->{__SWFOptions} = {flash_url => $IWLConfig{JS_DIR} . '/dist/swfupload_f9.swf'};
    $self->setLabel(__ "Browse ...");
    $self->requiredJs('base.js', 'dist/swfupload.js');

    return $self;
};

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
