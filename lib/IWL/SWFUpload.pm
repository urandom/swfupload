#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::SWFUpload;

use strict;

use base 'IWL::Container';

use IWL::Button;
use IWL::JSON 'toJSON';
use IWL::String 'randomize';
use IWL::Config '%IWLConfig';

use vars qw($VERSION);

use Locale::TextDomain qw(org.bloka.iwl.swfupload);

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

=item B<autoUpload>

If true, file uploading starts as soon as the files are selected. An upload and stop buttons are never placed on the page.

=back

The object has the following public properties

=item B<browse>

A browse button, of class L<IWL::Button>. When pressed, it invokes the browser file selector.

=item B<upload>

An upload button, of class L<IWL::Button>. Before the upload button starts, it's action is to start it.

=item B<stop>

A stop upload button, of class L<IWL::Button>. After the upload start, this button can abort the process.

=head1 SIGNALS

=over 4

=item B<load>

Fires when the widget is loaded.

=item B<file_dialog_start>

Fires immediately before the file selector is displayed. Due to the blocking nature of the file selector, the callback might not be executed until the selector is closed.

=item B<file_queue>

Fires when a file is queued. Receives the file object as a second parameter

=item B<file_queue_error>

Fires when an error has occurred while queueing a file. It received the file object, error code and error message as parameters, starting from the second parameters

=item B<file_dialog_complete>

Fires when the file selector is closed, and all the selected files have been processed. It received the number of selected files as a second parameter.

=item B<upload_start>

Fires just before the file is uploaded. It receives the file object as a second parameter.

=item B<upload_progress>

Fires periodically to indicate the upload process. It received the file object, the uploaded bytes, and the total byte count as parameters, starting from the second parameter.
A bug in the Linux Flash Player might prevent this signal from firing more than once.

=item B<upload_error>

Fires when an upload does not complete successfully, or by stopping/cancelling the upload. It receives the file object, error code and error message as parameters, starting from the second parameter.

=item B<upload_success>

Fires when the upload has been completed successfully. Receives the file object and any data returned from the server as parameters, starting from the second parameter.

=item B<upload_complete>

Fires at the end of the upload cycle. When fired, the upload will be fully completed, so that another may start. Receives the file object as a second parameter.

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

    $self->{_options}{multiple} = !(!$bool);
    return $self;
}

=item B<isMultiple>

Returns true if the file selector can pick multiple files

=cut

sub isMultiple {
    return shift->{_options}{multiple};
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
    my $self  = shift;
    my $id    = $self->getId;
    my $class = $self->{_defaultClass};

    $self->SUPER::_realize;
    return $self->_pushFatalError(__"SWFUpload: Upload URL not set!") unless $self->getUploadURL;

    my $swfoptions = toJSON($self->{__SWFOptions});
    my $options = toJSON($self->{_options});
    $self->_appendInitScript("IWL.SWFUpload.create('$id', $swfoptions, $options)");

    unless ($self->{_options}{autoUpload}) {
        $self->{stop}->setStyle(display => 'none');
        $self->appendChild($self->{upload});
        $self->appendChild($self->{stop});
    }
}

sub _setupDefaultClass {
    my $self = shift;
    $self->prependClass($self->{_defaultClass});
    $self->{browse}->prependClass($self->{_defaultClass} . '_browse');
    $self->{upload}->prependClass($self->{_defaultClass} . '_upload');
    $self->{stop}->prependClass($self->{_defaultClass} . '_stop');
}

# Internal
#
$init = sub {
    my ($self, %args) = @_;
    my $browse = IWL::Button->new;
    my $upload = IWL::Button->new;
    my $stop   = IWL::Button->new;
    
    $self->{_options} = {};
    $self->{_options}{multiple}     = $args{multiple} ? 1 : 0;
    $self->{_options}{autoUpload}   = $args{autoUpload} ? 1 : 0;
    delete @args{qw(multiple autoUpload)};

    $browse->setLabel(__"Browse ...");
    $upload->setLabel(__"Upload")->setDisabled(1);
    $stop->setLabel(__"Stop uploading");
    $self->{browse} = $browse;
    $self->{upload} = $upload;
    $self->{stop}   = $stop;
    $self->appendChild($browse);
    $self->{_defaultClass} = 'swfupload';
    $args{id} ||= randomize($self->{_defaultClass});

    $self->{__SWFOptions} = {flash_url => $IWLConfig{JS_DIR} . '/dist/swfupload_f9.swf'};
    $self->requiredJs('base.js', 'dist/swfupload.js', 'swfupload.js');
    $self->_constructorArguments(%args);
    $self->{_customSignals} = {
        load => [],
        file_dialog_start => [],
        file_queue => [],
        file_queue_error => [],
        file_dialog_complete => [],
        upload_start => [],
        upload_progress => [],
        upload_error => [],
        upload_success => [],
        upload_complete => [],
    };

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
