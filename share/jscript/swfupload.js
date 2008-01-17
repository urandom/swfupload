// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.SWFUpload is a class for creating flash upload widgets
 * @extends IWL.Widget
 * */
IWL.SWFUpload = Object.extend(Object.extend({}, IWL.Widget), (function () {
    return {

        _init: function (id, swfoptions) {
            this.options = Object.extend({
                multiple: false,
                autoUpload: false
            }, arguments[2] || {});
            var className = $A(this.classNames()).first();
            this.control = new SWFUpload(Object.extend(swfoptions, {
                swfupload_loaded_handler: this.emitSignal.bind(this, 'iwl:load'),
                file_dialog_start_handler: this.emitSignal.bind(this, 'iwl:file_dialog_start'),
                file_queued_handler: this.emitSignal.bind(this, 'iwl:file_queue'),
                file_queue_error_handler: this.emitSignal.bind(this, 'iwl:file_queue_error'),
                file_dialog_complete_handler: this.emitSignal.bind(this, 'iwl:file_dialog_complete'),
                upload_start_handler: this.emitSignal.bind(this, 'iwl:upload_start'),
                upload_progress_handler: this.emitSignal.bind(this, 'iwl:upload_progress'),
                upload_error_handler: this.emitSignal.bind(this, 'iwl:upload_error'),
                upload_success_handler: this.emitSignal.bind(this, 'iwl:upload_success'),
                upload_complete_handler: this.emitSignal.bind(this, 'iwl:upload_complete')
            }));
            this.browse = this.select('.' + className + '_browse')[0];

            if (this.options.autoUpload) {
                this.signalConnect('iwl:file_dialog_complete', function() {this.control.startUpload()}.bind(this));
            } else {
                this.upload = this.select('.' + className + '_upload')[0];
                this.stop = this.select('.' + className + '_stop')[0];

                this.upload.signalConnect('click', function() {
                    this.control.startUpload();
                    this.upload.hide();
                    this.stop.show();
                }.bind(this));
                this.stop.signalConnect('click', function() {
                    this.control.stopUpload();
                    this.upload.show();
                    this.stop.hide();
                }.bind(this));
            }

            this.browse.signalConnect('click', function() {
                this.options.multiple ? this.control.selectFiles() : this.control.selectFile();
            }.bind(this));
            this.signalConnect('iwl:upload_complete', function () {this.contro.startUpload()}.bind(this));
        }
    }
})());
