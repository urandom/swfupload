/*
	Cookie Plug-in
	
	This plug in automatically gets all the cookies for this site and adds them to the post_params, as SWFUploadCookie.
	Cookies are loaded only on initialization.  The refreshCookies function can be called to update the post_params.
	The cookies will override the post param with the same name.
*/

var SWFUpload;
if (typeof(SWFUpload) === "function") {
    SWFUpload.prototype.initSettings = function (old_initSettings) {
        return function (init_settings) {
            if (typeof(old_initSettings) === "function") {
                old_initSettings.call(this, init_settings);
            }

            this.refreshCookies(false);	// The false parameter must be sent since SWFUpload has not initialzed at this point
        };
    }(SWFUpload.prototype.initSettings);
	
    // refreshes the post_params and updates SWFUpload.  The send_to_flash parameters is optional and defaults to True
    SWFUpload.prototype.refreshCookies = function (send_to_flash) {
        if (send_to_flash !== false) send_to_flash = true;

        // Get the post_params object
        var post_params = this.getSetting('post_params');
        var url = this.getSetting('upload_url');

        post_params['SWFUploadCookie'] = document.cookie;

        if (send_to_flash) {
            this.setUploadURL(url + (url.indexOf('?') == -1 ? '?' : '&') + 'SWFUploadCookie=' + encodeURIComponent(document.cookie));
            this.setPostParams(post_params);
        } else {
            this.settings.upload_url = url + (url.indexOf('?') == -1 ? '?' : '&') + 'SWFUploadCookie=' + encodeURIComponent(document.cookie);
        }
    };
}
