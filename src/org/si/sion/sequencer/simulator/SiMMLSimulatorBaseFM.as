//----------------------------------------------------------------------------------------------------
// Base class of all FM sound chip simulator
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.sequencer.simulator {
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.sequencer.SiMMLVoice;
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.sequencer.base._sion_sequencer_internal;
    
    
    /** Base class of all FM sound chip simulator */
    public class SiMMLSimulatorBaseFM extends SiMMLSimulatorBase
    {
        function SiMMLSimulatorBaseFM(type:int, channelCount:int)
        {
            super(type, channelCount, new SiMMLSimulatorVoiceSet(512, SiOPMTable.PG_SINE), false);
        }
        
        
        /** @inherite */
        override public function selectTone(track:SiMMLTrack, voiceIndex:int) : MMLSequence
        {
            return _selectFMTone(track, voiceIndex);
        }


        /** @private */
        protected function _selectFMTone(track:SiMMLTrack, voiceIndex:int) : MMLSequence
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
                    track._sion_sequencer_internal::_resetVolumeOffset();
                    return (voice.channelParam.initSequence.isEmpty()) ? null : voice.channelParam.initSequence;
                }
            }

            return null;
        }
    }
}

