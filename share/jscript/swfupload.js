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
            if (!this.options.autoUpload && !this.upload._uploadStarted) return;
            this.control.startUpload.bind(this.control).defer()
        } else {
            if (this.options.autoUpload) return;
            this.upload.setDisabled(1);
            if (!this.upload._uploadStarted) return;
            buttonToggle.call(this, this.upload._uploadStarted = false);
        }
    }

    function queueHandler() {
        var stats = this.control.getStats();
        if (stats.files_queued)
            this.upload.setDisabled(0);
        else
            this.upload.setDisabled(1);
    }

    function uploadStartHandler(event, file) {
        this.upload.setDisabled(0);
    }

    function uploadErrorHandler(event, file, code) {
        var stats = this.control.getStats();
        if (code != SWFUpload.UPLOAD_ERROR.FILE_CANCELLED) return;
        if (stats.files_queued) return;

        buttonToggle.call(this, false);
        this.upload.setDisabled(1);
    }

    function uploadProgressHandler(event, file, complete, total) {
        if (complete/total == 1)
            this.upload.setDisabled(1);
    }

    function buttonToggle(start) {
        this.upload.setLabel(IWL.SWFUpload.messages.buttonLabels[start ? 'stop' : 'start']);
    }

    return {

        _init: function (id, swfoptions) {
            this.options = Object.extend({
                multiple: false,
                autoUpload: false
            }, arguments[2] || {});
            Object.extend(IWL.SWFUpload, {messages: arguments[3]});

            var className = $A(this.classNames()).first();

            // This is fixed in SWFUpload 2.1.0, and should be removed once ported to this version
            if (swfoptions.post_params && Object.isObject(swfoptions.post_params))
                for (var i in swfoptions.post_params)
                    swfoptions.post_params[i] = swfoptions.post_params[i].toString();

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
                this.upload._uploadStarted = false;

                this.upload.signalConnect('click', function() {
                    buttonToggle.call(this, this.upload._uploadStarted = !this.upload._uploadStarted);
                    this.upload._uploadStarted
                      ? this.control.startUpload()
                      : this.control.stopUpload();
                }.bind(this));
                this.signalConnect('iwl:file_queue', queueHandler.bind(this));
                this.signalConnect('iwl:upload_start', uploadStartHandler.bind(this));
                this.signalConnect('iwl:upload_error', uploadErrorHandler.bind(this));
                this.signalConnect('iwl:upload_progress', uploadProgressHandler.bind(this));
            }

            this.browse.signalConnect('click', function() {
                this.options.multiple ? this.control.selectFiles() : this.control.selectFile();
            }.bind(this));
            this.signalConnect('iwl:upload_complete', completeHandler.bind(this));

            if (DetectFlashVer(9, 0, 0))
                document.observe('dom:loaded', function() {
                    this.browse.setDisabled(false);
                }.bind(this));
            else {
                document.observe('dom:loaded', function() {
                    this.emitSignal(this, 'iwl:flash_not_found')
                    var info = new Element('span', {className: 'swfupload_missing_flash_plugin'}).update(IWL.SWFUpload.messages.flashErrors.missingPlugin);
                    info.appendChild(new Element('br'));
                    info.appendChild(new Element('a', {
                        href: 'http://www.adobe.com/go/getflashplayer',
                        target: 'ADOBEFLASH'
                    }).update(IWL.SWFUpload.messages.flashErrors.missingPluginLink));
                    
                    this.insert({after: info});
                }.bind(this));
            }
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
        var id = this.id + '_' + file.id;
        var names = {id: id};
        var className = $A(this.classNames()).first();
        var progress = false, images = [], custom = [];
        this.options.order.each(function(column, i) {
            if (column == 'status') progress = true;
            if (['start', 'stop', 'remove'].include(column))
                images.push(column);
            if (Object.isObject(column)) {
                custom.push(column);
                names['name' + i] = column.name;
            } else {
                names['name' + i] = column;
            }
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
            progress.setText(IWL.SWFUpload.messages.progress.queue);
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
        custom.each(function(column) {
            cell = row.select('.' + className + '_' + column.name)[0];
            var callback = codePointer(column.callback);
            if (Object.isFunction(callback))
                callback(cell, file, this.upload);
        }.bind(this));

        cell = row.select('.' + className + '_name')[0];
        if (cell) cell.update(file.name);
        return this;
    }

    function uploadStartHandler(event, file) {
        var row = this.files[file.id].row;
        if (row.progress)
            row.progress.setText(IWL.SWFUpload.messages.progress.progress).setValue(0);
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
                ([-280, -290].include(code)
                  ? ''
                  : (IWL.SWFUpload.messages.progress.error + ': ')) +
                IWL.SWFUpload.messages.uploadErrors[code]
            );
        if (code == SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED) {
            if (row.startCell)
                cellToggle(row.startCell, true);
            if (row.stopCell)
                cellToggle(row.stopCell, false);
            if (row.progress)
                (function() {
                    row.progress.setText(IWL.SWFUpload.messages.progress.queue);
                }).delay(3);
        } else if (code == SWFUpload.UPLOAD_ERROR.FILE_CANCELLED) {
            row.fade.bind(row, {duration: 1, afterFinish: row.remove.bind(row)}).delay(3);
        }
    }

    function uploadSuccessHandler(event, file) {
        var row = this.files[file.id].row;
        if (row.progress)
            row.progress.setText(IWL.SWFUpload.messages.progress.complete);
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

    function codePointer(string) {
        if (!Object.isString(string)) return;
        return string.split('.').inject(window, function(parent, child) {
            if (!parent || !parent[child]) throw $break;
            return parent[child];
        });
    }

    return {
        /**
         * Toggles the enable upload state per queue file.
         * @param {Object} options The following options are recognized:
         *        fileId: The the file id, corresponding to the file to toggle. If none are specified, all files are toggled.
         *        on: if true, upload will be allowed. Otherwise, upload will be disabled.
         *
         * @returns The object
         * */
        toggleFileUploadState: function() {
            var options = Object.extend({on: false}, arguments[0]), rows = [];
            if (options.fileId) rows.push(this.files[options.fileId].row);
            else rows = $H(this.files).values().pluck('row');
            rows.each(function(row) {
                if (!row.parentNode || !row.startCell) return;
                cellToggle(row.startCell, options.on);
            });
        },

        _preInit: function(id, upload) {
            if (!$(upload) && !document.loaded) {
                document.observe('dom:loaded', this.create.bind(this, id, upload, arguments[2]));
                return false;
            }
            return true;
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

            this.files = {};
            this.upload = upload = $(upload);
            upload.signalConnect('iwl:file_queue', fileQueueHandler.bind(this));
            upload.signalConnect('iwl:upload_start', uploadStartHandler.bind(this));
            upload.signalConnect('iwl:upload_progress', uploadProgressHandler.bind(this));
            upload.signalConnect('iwl:upload_error', uploadErrorHandler.bind(this));
            upload.signalConnect('iwl:upload_success', uploadSuccessHandler.bind(this));

            this.emitSignal('iwl:load');
        }
    }
})());
