// Pulse Code Modulation Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import flash.media.Sound;
    import org.si.sion.*;
    import org.si.sion.module.*;
    import org.si.sion.sequencer.SiMMLTrack;
    
    
    /** Pulse Code Modulation Synthesizer 
     */
    public class PCMSynth extends IFlashSoundOperator
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        /** PCM table */
        protected var _pcmTable:SiOPMWavePCMTable;
        /** default PCM data */
        protected var _defaultPCMData:SiOPMWavePCMData;
        
        
        
        
    // properties
    //----------------------------------------
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor
         *  @param data wave data, Sound or Vector.&lt;Number&gt; can be set, the Sound is extracted inside.
         *  @param samplingNote sampling data's note, this argument allows decimal number.
         *  @param channelCount channel count of playing PCM.
         */
        function PCMSynth(data:*=null, samplingNote:Number=68, channelCount:int=2)
        {
            _defaultPCMData = new SiOPMWavePCMData(data, int(samplingNote*64), channelCount, 0);
            _pcmTable = new SiOPMWavePCMTable();
            _pcmTable.clear(_defaultPCMData);
            _voice.waveData = _pcmTable;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** Set PCM sample with key range (this feature is not available in currennt version).
         *  @param data wave data, Sound or Vector.&lt;Number&gt; can be set, the Sound is extracted inside.
         *  @param samplingNote sampling data's note, this argument allows decimal number.
         *  @param keyRangeFrom Assigning key range starts from
         *  @param keyRangeTo Assigning key range ends at. -1 to set only at the key of argument "keyRangeFrom".
         *  @param channelCount channel count of this data, 1 for monoral, 2 for stereo
         *  @return assigned SiOPMWavePCMData.
         */
        public function setSample(data:*, samplingNote:Number=68, keyRangeFrom:int=0, keyRangeTo:int=127, channelCount:int=2) : SiOPMWavePCMData
        {
            var pcmData:SiOPMWavePCMData;
            if (keyRangeFrom==0 && keyRangeTo==127) {
                _defaultPCMData.initialize(data, int(samplingNote*64), channelCount, 0);
                pcmData = _defaultPCMData;
            } else {
                pcmData = new SiOPMWavePCMData(data, int(samplingNote*64), channelCount, 0);
            }
            _voiceUpdateNumber++;
            return _pcmTable.setSample(pcmData, keyRangeFrom, keyRangeTo);
        }
    }
}


