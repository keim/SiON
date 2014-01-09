//----------------------------------------------------------------------------------------------------
// basic class sfor SiOPM wave data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import flash.media.Sound;
    import flash.events.*;
    
    /** basic class for SiOPM wave data */
    public class SiOPMWaveBase {
        /** module type */
        public var moduleType:int;
        // loading target
        private var _loadingTarget:Sound;
        
        
        /** constructor */
        function SiOPMWaveBase(moduleType:int)
        {
            this.moduleType = moduleType;
        }
        
        
        /** @private listen sound loading events */
        protected function _listenSoundLoadingEvents(sound:Sound) : void 
        {
            if (sound.bytesTotal == 0 || sound.bytesTotal > sound.bytesLoaded) {
                _loadingTarget = sound;
                sound.addEventListener(Event.COMPLETE, _cmp);
                sound.addEventListener(IOErrorEvent.IO_ERROR, _err);
                sound.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _err);
            } else {
                _onSoundLoadingComplete(sound);
            }
        }
        
        
        /** @private */
        protected function get _isSoundLoading() : Boolean { return (_loadingTarget != null); }
        
        
        /** @private complete event handler */
        protected function _onSoundLoadingComplete(sound:Sound) : void
        {
        }
        
        
        // event handlers
        private function _cmp(e:Event) : void {
            _onSoundLoadingComplete(_loadingTarget);
            _removeAllListeners();
        }
        private function _err(e:Event) : void {
            _removeAllListeners();
        }
        private function _removeAllListeners() : void 
        {
            _loadingTarget.removeEventListener(Event.COMPLETE, _cmp);
            _loadingTarget.removeEventListener(IOErrorEvent.IO_ERROR, _err);
            _loadingTarget.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _err);
            _loadingTarget = null;
        }
    }
}

