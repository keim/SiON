// Voice reference
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
   
    
    /** Voice reference, basic class of all synthesizers. */
    public class VoiceReference
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // valiables
    //----------------------------------------
        /** @private [synthesizer internal] Instance of voice setting */
        _synthesizer_internal var _voice:SiONVoice = null;
        
        /** @private [synthesizer internal] require voice update number */
        _synthesizer_internal var _voiceUpdateNumber:uint;
        
        
        
        
    // properties
    //----------------------------------------
        /** voice setting */
        public function get voice() : SiONVoice { return _voice; }
        public function set voice(v:SiONVoice) : void {
            if (_voice !== v) _voiceUpdateNumber++;
            _voice = v;
        }
            
        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function VoiceReference()
        {
            _voiceUpdateNumber = 0;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** @private [synthesizer internal] register single track */
        public function _registerTrack(track:SiMMLTrack) : void
        {
        }
        
        
        /** @private [synthesizer internal] register prural tracks */
        public function _registerTracks(tracks:Vector.<SiMMLTrack>) : void
        {
        }
        
        
        /** @private [synthesizer internal] unregister tracks */
        public function _unregisterTracks(firstTrack:SiMMLTrack, count:int=1) : void
        {
        }
    }
}


