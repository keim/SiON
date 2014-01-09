//----------------------------------------------------------------------------------------------------
// Event for FlashSoundPlayer
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.events {
    import flash.events.*;
    import flash.media.Sound;
    import org.si.sion.*;
    import org.si.sion.effector.*;
    import org.si.sion.module.SiOPMStream;
    import org.si.sound.namespaces._sound_object_internal;
    
    
    /** FlashSoundPlayerEvent is dispatched by FlashSoundPlayer. @see org.si.sound.FlashSoundPlayer */
    public class FlashSoundPlayerEvent extends Event
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // constants
    //----------------------------------------
        /** Complete all loading sounds */
        public static const COMPLETE:String = 'fspComplete';
        
        
        
        
    // properties
    //----------------------------------------
        /** Target sound */
        public function get sound() : Sound { return _sound; }
        /** keyRangeFrom */
        public function get keyRangeFrom() : int { return _keyRangeFrom; }
        /** keyRangeTo */
        public function get keyRangeTo() : int { return _keyRangeTo; }
        
        
        /**@private*/ _sound_object_internal var _sound:Sound;
        /**@private*/ _sound_object_internal var _onComplete:Function;
        /**@private*/ _sound_object_internal var _onError:Function;
        /**@private*/ _sound_object_internal var _keyRangeFrom:int;
        /**@private*/ _sound_object_internal var _keyRangeTo:int;
        /**@private*/ _sound_object_internal var _startPoint:int;
        /**@private*/ _sound_object_internal var _endPoint:int;
        /**@private*/ _sound_object_internal var _loopPoint:int;
        
        
        
        
    // functions
    //----------------------------------------
        /** @private */
        function FlashSoundPlayerEvent(sound:Sound, onComplete:Function, onError:Function, keyRangeFrom:int, keyRangeTo:int, startPoint:int, endPoint:int, loopPoint:int) {
            super(COMPLETE, false, false);
            this._sound = sound;
            this._onComplete = onComplete;
            this._onError = onError;
            this._keyRangeFrom = keyRangeFrom;
            this._keyRangeTo = keyRangeTo;
            this._startPoint = startPoint;
            this._endPoint = endPoint;
            this._loopPoint = loopPoint;
            _sound.addEventListener(Event.COMPLETE, _handleComplete);
            _sound.addEventListener(IOErrorEvent.IO_ERROR, _handleError);
        }
        
        
        private function _handleComplete(e:Event) : void {
            _sound.removeEventListener(Event.COMPLETE, _handleComplete);
            _sound.removeEventListener(IOErrorEvent.IO_ERROR, _handleError);
            _onComplete(this);
        }
        
        
        private function _handleError(e:Event) : void {
            _sound.removeEventListener(Event.COMPLETE, _handleComplete);
            _sound.removeEventListener(IOErrorEvent.IO_ERROR, _handleError);
            _onError(this);
        }
    }
}



