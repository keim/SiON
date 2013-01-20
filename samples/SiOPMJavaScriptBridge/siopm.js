/*
 * original:jsmml by Yuichi Tateno
 * http://coderepos.org/share/wiki/JSMML
 * http://rails2u.com/
 * 
 * Modifyed by keim
 * http://www.yomogi.sakura.ne.jp/~si/
 *
 * The MIT Licence.
 */


// SIOPM object
//------------------------------
SIOPM = function() {};




// version informations
//------------------------------
SIOPM.VERSION = '0.4.0';
SIOPM.SWF_VERSION = 'SWF has not loaded.';
SIOPM.toString = function() { return 'SIOPM_VERSION: ' + SIOPM.VERSION + '/ SWF_VERSION: ' + SIOPM.SWF_VERSION; };




// variables for setting
// - change settings by modifying these variables BEFORE calling initialize().
//------------------------------
SIOPM.urlSWF         = 'siopm.swf';
SIOPM.mmlPlayerDivID = 'siopmPlayerDiv';
SIOPM.mmlPlayerID    = 'siopmPlayer';
SIOPM.mmlPlayer      = undefined;




// variables updated inside.
// - you can check the status by refering these variables.
//------------------------------
// flag ok to use.
SIOPM.loaded = false;
// flag ok to play sound.
SIOPM.compiled = false;
// flag playing sound.
SIOPM.playing = false;
// flag paused.
SIOPM.paused = false;

// progression status of compiling (0,1). this can refer from onCompileProgress().
SIOPM.compileProgress = 0;
// title of the loaded mml data.
SIOPM.title = "";




// callback functions
// - impelement thses functions to handle events.
//------------------------------
// call back when finish initializing.
SIOPM.onLoad = function() {};

// call back while compiling.
SIOPM.onCompileProgress = function() {};

// call back when finish compiling.
SIOPM.onCompileComplete = function() { SIOPM.play(); };

// call back while playing sound.
SIOPM.onStream = function() {};

// call back before the stream starts.
SIOPM.onStreamStart = function() {};

// call back after the stream stops.
SIOPM.onStreamStop = function() {};

// call back after fading in.
SIOPM.onFadeInComplete = function() {};

// call back after fading out.
SIOPM.onFadeOutComplete = function() {};

// call back when error appears.
SIOPM.onError = function() {};




// operations
// - call these functions to operate SiOPM.
//------------------------------
// compile mml string. this calls back onCompileProgress(), onCompileComplete() and onError() inside.
SIOPM.compile = function(_mml) { SIOPM.mmlPlayer._compile(_mml); SIOPM.compiled = false; }

// play sound. call this after compile completed. this calls back onStreamStart(), onSteam() and onError() inside.
SIOPM.play = function() { SIOPM.mmlPlayer._play(); SIOPM.paused = false; }

// stop sound. this calls back onStreamStop() inside.
SIOPM.stop = function() { SIOPM.mmlPlayer._stop(); SIOPM.paused = false; }

// pause sound. you can resume by calling play().
SIOPM.pause = function() { SIOPM.mmlPlayer._pause(); SIOPM.paused = true; }

// translate the TSSCP mml to SiOPM mml.
SIOPM.trans = function(_tss) { return SIOPM.mmlPlayer._trans(_tss); }

// control/refer volume by Number (0,1), you can refer a volume to call this without any arguments.
SIOPM.volume = function() { return SIOPM.mmlPlayer._volume(arguments[0]); }

// control/refer panning by Number (-1,1), you can refer a panning to call this without any arguments.
SIOPM.pan = function() { return SIOPM.mmlPlayer._pan(arguments[0]); }

// control/refer position by Number (unit in milli-second), you can refer the position to call this without any arguments.
SIOPM.position = function() { return SIOPM.mmlPlayer._position(arguments[0]); }

// fade in time (unit in second).
SIOPM.fadeIn = function() { return SIOPM.mmlPlayer._fadeIn(arguments[0]); }

// fade out time (unit in second).
SIOPM.fadeOut = function() { return SIOPM.mmlPlayer._fadeOut(arguments[0]); }

// initialize. call this first of all. ussualy call this in body.onLoad(). this calls back onLoad() when the SiOPM is initialized successfully.
SIOPM.initialize = function() {
    // check swf object
    if (! document.getElementById(SIOPM.mmlPlayerDivID)) {
        // check flash players major version
        if (getFlashPlayerVersion(0) < 10) {
            SIOPM.onError("The SiOPM module is only available on Flash Player 10.");
            return;
        }
        
        // insert swf object
        // create <div> tag
        var swfName = SIOPM.urlSWF + '?' + (new Date()).getTime();
        var div = document.createElement('div');
        div.id = SIOPM.mmlPlayerDivID;
        div.style.display = 'inline';
        div.width = 1;
        div.height = 1;
        document.body.appendChild(div);

        if (navigator.plugins && navigator.mimeTypes && navigator.mimeTypes.length) {
            // ns
            var o = document.createElement('object');
            o.id = SIOPM.mmlPlayerID;
            o.classid = 'clsid:D27CDB6E-AE6D-11cf-96B8-444553540000';
            o.width = 1;
            o.height = 1;
            o.setAttribute('data', swfName);
            o.setAttribute('type', 'application/x-shockwave-flash');
            var p = document.createElement('param');
            p.setAttribute('name', 'allowScriptAccess');
            p.setAttribute('value', 'always');
            o.appendChild(p);
            div.appendChild(o);
        } else {
            // ie
            var object = '<object id="' + SIOPM.mmlPlayerID + '" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="1" height="1">';
            object    += '<param name="movie" value="' + swfName + '" />';
            object    += '<param name="bgcolor" value="#FFFFFF" />';
            object    += '<param name="quality" value="high" />';
            object    += '<param name="allowScriptAccess" value="always" />';
            object    += '</object>';
            div.innerHTML = object;
        }
    }
}

// get Flash player version numbers. argument requires sub numbers.
function getFlashPlayerVersion(subs) {
    return (navigator.plugins && navigator.mimeTypes && navigator.mimeTypes.length) ? 
        navigator.plugins["Shockwave Flash"].description.match(/([0-9]+)/)[subs] : 
        (new ActiveXObject("ShockwaveFlash.ShockwaveFlash")).GetVariable("$version").match(/([0-9]+)/)[subs];
}




//------------------------------------------------------------------------------------------------------------------------
// internal functions
//------------------------------
// callback from siopm.swf
SIOPM._internal_onLoad = function(version) {
    SIOPM.SWF_VERSIOPM = version;
    SIOPM.loaded = true;
    SIOPM.mmlPlayer = document.getElementById(SIOPM.mmlPlayerID);
    SIOPM.onLoad();
}
SIOPM._internal_onCompileProgress = function(progress) {
    SIOPM.compileProgress = progress;
    SIOPM.onCompileProgress();
}
SIOPM._internal_onCompileComplete = function(title) {
    SIOPM.title = title;
    SIOPM.compiled = true;
    SIOPM.compileProgress = 1;
    SIOPM.onCompileComplete();
}
SIOPM._internal_onError = function(message) {
    SIOPM.onError(message);
}
SIOPM._internal_onStream = function() {
    SIOPM.onStream();
}
SIOPM._internal_onStreamStart = function() {
    SIOPM.playing = true;
    SIOPM.onStreamStart();
}
SIOPM._internal_onStreamStop = function() {
    SIOPM.playing = false;
    SIOPM.onStreamStop();
}
SIOPM._internal_onFadeInComplete = function () {
    SIOPM.onFadeInComplete();
}
SIOPM._internal_onFadeOutComplete = function () {
    SIOPM.onFadeOutComplete();
}


