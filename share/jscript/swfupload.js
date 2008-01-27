// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.SWFUpload is a class for creating flash upload widgets
 * @extends IWL.Widget
 * */
IWL.SWFUpload = Object.extend(Object.extend({}, IWL.Widget), (function () {
    var effect_duration = 0.06;

    function completeHandler() {
        var stats = this.control.getStats();
        if (stats.files_queued) {
            this.control.startUpload()
        } else {
            this.stop.fade({
                duration: effect_duration,
                afterFinish: this.upload.appear.bind(this.upload, {duration: effect_duration})
            });
            this.upload.setDisabled(1);
        }
    }

    function queueHandler() {
        var stats = this.control.getStats();
        if (stats.files_queued)
            this.upload.setDisabled(0);
        else
            this.upload.setDisabled(1);
    }

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
                upload_start_handler: 
                    function(file) {
                        this.emitSignal('iwl:upload_start', file);
                        return true;
                    }.bind(this),
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
                    this.upload.fade({
                        duration: effect_duration,
                        afterFinish: this.stop.appear.bind(this.stop, {duration: effect_duration})
                    });
                }.bind(this));
                this.stop.signalConnect('click', function() {
                    this.control.stopUpload();
                    this.stop.fade({
                        duration: effect_duration,
                        afterFinish: this.upload.appear.bind(this.upload, {duration: effect_duration})
                    });
                }.bind(this));
            }

            this.browse.signalConnect('click', function() {
                this.options.multiple ? this.control.selectFiles() : this.control.selectFile();
            }.bind(this));
            this.signalConnect('iwl:upload_complete', completeHandler.bind(this));
            this.signalConnect('iwl:file_queue', queueHandler.bind(this));
        }
    }
})());

/**
 * @class IWL.SWFUpload.Queue is a class for creating a queue for the flash upload widgets
 * @extends IWL.Widget
 * */
IWL.SWFUpload.Queue = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function fileQueueHandler(event, file_queue) {
        this.addFile(file_queue);
    }

    return {
        /**
         * Adds a file to the queue
         * @param file An swfupload file object
         * @returns The object
         * */
        addFile: function(file) {
            var id = this.id + '_' + this.body.rows.length;
            var names = {id: id};
            var className = $A(this.classNames()).first();
            var progress = false;
            this.options.order.each(function(column, i) {
                names['name' + i] = column;
                if (column == 'status') progress = true;
            });
            var html = this.template.evaluate(names);
            this.appendRow(this.body, html);
            var row = $(id);
            var cells;

            row.file = file;
            if (progress) {
                cells = row.select('.' + className + '_status');
                if (cells[0]) {
                    progress = this.progress.cloneNode(true);
                    IWL.ProgressBar.create(progress);
                    cells[0].appendChild(progress);
                    progress.appear({duration: 0.3});
                    progress.id = id + '_progress';
                }
            }
            cells = row.select('.' + className + '_name');
            if (cells[0]) cells[0].update(file.name);
            return this;
        },

        _init: function (id, upload) {
            this.options = Object.extend({
                order: ['name', 'status', 'remove']
            }, arguments[2] || {});
            if (Object.isString(this.options.order))
                this.options.order = this.options.order.evalJSON(1);
            this.progress = $(id + '_progress');

            var className = $A(this.classNames()).first();
            var template = '<tr id="#{id}">';
            this.options.order.length.times(function(i) {
                template += '<td class="' + className + '_#{name' + i + '}"></td>';
            });
            template += '</tr>';
            this.template = new Template(template);
            this.upload = upload;
            upload.signalConnect('iwl:file_queue', fileQueueHandler.bind(this));
        }
    }
})());
