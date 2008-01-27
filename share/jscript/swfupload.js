// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.SWFUpload is a class for creating flash upload widgets
 * @extends IWL.Widget
 * */
IWL.SWFUpload = Object.extend(Object.extend({}, IWL.Widget), (function () {
    var effect_duration = 0.06;

    function completeHandler() {
        if (!this.upload._uploadStarted) return;
        var stats = this.control.getStats();
        if (stats.files_queued) {
            this.control.startUpload()
        } else {
            this.upload._uploadStarted = false;
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
                this.stop.setStyle({display: 'none', visibility: 'visible'});

                this.upload.signalConnect('click', function() {
                    this.control.startUpload();
                    this.upload._uploadStarted = true;
                    this.upload.fade({
                        duration: effect_duration,
                        afterFinish: this.stop.appear.bind(this.stop, {duration: effect_duration})
                    });
                }.bind(this));
                this.stop.signalConnect('click', function() {
                    this.control.stopUpload();
                    this.upload._uploadStarted = false;
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
    var disabled_opacity = 0.2;

    function fileQueueHandler(event, file) {
        var id = this.id + '_' + this.body.rows.length;
        var names = {id: id};
        var className = $A(this.classNames()).first();
        var progress = false, images = [];
        this.options.order.each(function(column, i) {
            names['name' + i] = column;
            if (column == 'status') progress = true;
            if (['start', 'stop', 'remove'].include(column))
                images.push(column);
        });
        var html = this.template.evaluate(names);
        this.appendRow(this.body, html);
        var row = $(id);
        var cell;

        this.files[file.id] = {row: row};
        if (progress) {
            cell = row.select('.' + className + '_status')[0];
            progress = this.progress.cloneNode(true);
            IWL.ProgressBar.create(progress);
            cell.appendChild(progress);
            progress.appear({duration: 0.3});
            progress.id = id + '_progress';
            progress.setText(IWL.SWFUpload.Queue.messages.progress.queue);
            row.progress = progress;
        }
        images.each(function(column) {
            cell = row.select('.' + className + '_' + column)[0];
            var image = new Element('img', {
                src: IWL.Config.IMAGE_DIR + '/queue/' + column + '.' + IWL.Config.ICON_EXT,
                alt: column,
                id: id + '_' + column
            });
            cell.appendChild(image);
            if (column == 'remove') {
                row.removeCell = cell;
                var removeHandler = (function() {
                    this.upload.control.cancelUpload(file.id);
                    row.fade({duration: 1, afterFinish: row.remove.bind(row)});
                }).bind(this);
                cell.handler = removeHandler;
                cellToggle(cell, true);
            } else if (column == 'stop') {
                row.stopCell = cell;
                var stopHandler = (function() {
                    cellToggle(row.stopCell, false);
                    if (row.startCell)
                        cellToggle(row.startCell, true);
                    this.upload.control.stopUpload();
                }).bind(this);
                cell.handler = stopHandler;
                cellToggle(cell, false);
            } else if (column == 'start') {
                row.startCell = cell;
                var startHandler = (function() {
                    cellToggle(row.startCell, false);
                    if (row.stopCell)
                        cellToggle(row.stopCell, true);
                    this.upload.control.startUpload(file.id);
                }).bind(this);
                cell.handler = startHandler;
                cellToggle(cell, true);
            }
        }.bind(this));

        cell = row.select('.' + className + '_name')[0];
        if (cell) cell.update(file.name);
        return this;
    }

    function uploadStartHandler(event, file) {
        var row = this.files[file.id].row;
        if (row.progress)
            row.progress.setText(IWL.SWFUpload.Queue.messages.progress.progress).setValue(0);
        if (row.startCell)
            cellToggle(row.startCell, false);
        if (row.stopCell)
            cellToggle(row.stopCell, true);
    }

    function uploadProgressHandler(event, file, complete, total) {
        var row = this.files[file.id].row;
        if (row.progress)
            row.progress.setValue(complete/total);
    }

    function uploadErrorHandler(event, file, code) {
        var row = this.files[file.id].row;
        if (!row || !row.parentNode) return;
        if (row.progress)
            row.progress.setText(
                IWL.SWFUpload.Queue.messages.progress.error + ': ' +
                IWL.SWFUpload.Queue.messages.uploadErrors[code]
            );
        if (code == SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED) {
            if (row.startCell)
                cellToggle(row.startCell, true);
            if (row.stopCell)
                cellToggle(row.stopCell, false);
            if (row.progress)
                (function() {
                    row.progress.setText(IWL.SWFUpload.Queue.messages.queue);
                }).delay(3);
        }
    }

    function uploadSuccessHandler(event, file) {
        var row = this.files[file.id].row;
        if (row.progress)
            row.progress.setText(IWL.SWFUpload.Queue.messages.progress.complete);
        if (row.stopCell)
            cellToggle(row.stopCell, false);
        if (row.removeCell)
            cellToggle(row.removeCell, false);
    }

    function cellToggle(cell, on) {
        if (on) {
            cell.observe('click', cell.handler);
            cell.setOpacity(1);
        } else {
            cell.stopObserving('click', cell.handler);
            cell.setOpacity(disabled_opacity);
        }
    }

    return {

        _init: function (id, upload) {
            this.options = Object.extend({
                order: ['name', 'status', 'remove']
            }, arguments[2] || {});
            if (Object.isString(this.options.order))
                this.options.order = this.options.order.evalJSON(1);
            Object.extend(IWL.SWFUpload.Queue, {messages: arguments[3]});

            this.progress = $(id + '_progress');

            var className = $A(this.classNames()).first();
            var template = '<tr id="#{id}">';
            this.options.order.length.times(function(i) {
                template += '<td class="' + className + '_#{name' + i + '}"></td>';
            });
            template += '</tr>';
            this.template = new Template(template);

            this.files = {};
            this.upload = upload;
            upload.signalConnect('iwl:file_queue', fileQueueHandler.bind(this));
            upload.signalConnect('iwl:upload_start', uploadStartHandler.bind(this));
            upload.signalConnect('iwl:upload_progress', uploadProgressHandler.bind(this));
            upload.signalConnect('iwl:upload_error', uploadErrorHandler.bind(this));
            upload.signalConnect('iwl:upload_success', uploadSuccessHandler.bind(this));
        }
    }
})());
