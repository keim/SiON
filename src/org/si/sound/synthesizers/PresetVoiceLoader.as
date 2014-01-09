// synthsizer with SiONPresetVoice
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.SiONVoice;
    import org.si.sion.utils.SiONPresetVoice;
    
    
    /** synthsizer with SiONPresetVoice */
    public class PresetVoiceLoader extends VoiceReference
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** current categoly's list */
        protected var _voiceList:Array = null;
        /** current voice number */
        protected var _voiceNumber:int = 0;
        
        
        
    // properties
    //----------------------------------------
        /** load voice from current categoly's voice list */
        public function get voiceNumber() : int {
            return _voiceNumber;
        }
        public function set voiceNumber(i:int) : void {
            if (i < 0) i = 0;
            else if (i >= _voiceList.length) i = _voiceList.length - 1;
            _voiceNumber = i;
            var v:SiONVoice = _voiceList[_voiceNumber];
            if (_voice !== v) _voiceUpdateNumber++;
            _voice = v;
        }
        

        /** maximum value of voiceNumber */
        public function get voiceNumberMax() : int {
            return _voiceList.length;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor, set categoly key to use. */
        function PresetVoiceLoader(categoly:String) {
            var presetVoiceList:SiONPresetVoice = SiONPresetVoice.mutex || new SiONPresetVoice();
            if (!(categoly in presetVoiceList)) throw new Error("PresetVoiceReference; no '" + categoly + "' categolies in SiONPresetVoice.");
            _voiceList = presetVoiceList[categoly];
        }
    }
}

