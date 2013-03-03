//----------------------------------------------------------------------------------------------------
// class for Single operator of SiOPM wavelet
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.sion.sequencer.base.MMLSequence;
    
    
    /** @private */
    public class SiMMLModuleSimulatorFM extends SiMMLSimulatorBase
    {
        function SiMMLModuleSimulatorFM()
        {
            super(MT_FM, 1, false);
            this._defaultVoiceSet = new SiMMLSimulatorVoiceSet(1, SiOPMTable.PG_SINE);
        }
        
        
        override public function selectTone(track:SiMMLTrack, voiceIndex:int) : MMLSequence
        {
            if (voiceIndex == -1) return null;
            
            var voice:SiMMLVoice;
            
            if (voiceIndex<0 || voiceIndex>=SiMMLTable.VOICE_MAX) voiceIndex = 0;
            voice = SiMMLTable.instance.getSiMMLVoice(voiceIndex);
            if (voice) {
                if (voice.updateTrackParamaters) {
                    voice.updateTrackVoice(track);
                    return null;
                } else {
                    // this module changes only channel params, not track params.
                    track.channel.setSiOPMChannelParam(voice.channelParam, false, false);
                    track._resetVolumeOffset();
                    return (voice.channelParam.initSequence.isEmpty()) ? null : voice.channelParam.initSequence;
                }
            }

            return null;
        }
    }
}

