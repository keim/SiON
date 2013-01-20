//----------------------------------------------------------------------------------------------------
// SiON data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion {
    import flash.media.Sound;
    import org.si.sion.sequencer.SiMMLVoice;
    import org.si.sion.sequencer.SiMMLData;
    import org.si.sion.sequencer.SiMMLEnvelopTable;
    import org.si.sion.sequencer.SiMMLEnvelopTable;
    import org.si.sion.utils.SiONUtil;
    import org.si.sion.module.ISiOPMWaveInterface;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMWavePCMData;
    import org.si.sion.module.SiOPMWaveSamplerTable;
    import org.si.sion.module.SiOPMWaveSamplerData;
    import org.si.sion.namespaces._sion_internal;

    
    /** The SiONData class provides musical score (and voice settings) data of SiON.
     */
    public class SiONData extends SiMMLData implements ISiOPMWaveInterface
    {
    // valiables
    //----------------------------------------
        
        
        
        
    // constructor
    //----------------------------------------
        function SiONData()
        {
        }
        
        
        
        
    // setter
    //----------------------------------------
        /** Set PCM wave data rederd by %7.
         *  @param index PCM data number.
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound instance is extracted internally, the maximum length to extract is SiOPMWavePCMData.maxSampleLengthFromSound[samples].
         *  @param samplingNote Sampling wave's original note number, this allows decimal number
         *  @param keyRangeFrom Assigning key range starts from (not implemented in current version)
         *  @param keyRangeTo Assigning key range ends at (not implemented in current version)
         *  @param srcChannelCount channel count of source data, 1 for monoral, 2 for stereo.
         *  @param channelCount channel count of this data, 1 for monoral, 2 for stereo, 0 sets same with srcChannelCount.
         *  @see #org.si.sion.module.SiOPMWavePCMData.maxSampleLengthFromSound
         *  @see #org.si.sion.SiONDriver.render()
         */
        public function setPCMWave(index:int, data:*, samplingNote:Number=69, keyRangeFrom:int=0, keyRangeTo:int=127, srcChannelCount:int=2, channelCount:int=0) : SiOPMWavePCMData
        {
            var pcmTable:SiOPMWavePCMTable = _sion_internal::_getPCMVoice(index).waveData as SiOPMWavePCMTable
            return (pcmTable) ? pcmTable.setSample(new SiOPMWavePCMData(data, int(samplingNote*64), srcChannelCount, channelCount), keyRangeFrom, keyRangeTo) : null;
        }
        
        
        /** Set sampler wave data refered by %10.
         *  @param index note number. 0-127 for bank0, 128-255 for bank1.
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound is extracted when the length is shorter than SiOPMWaveSamplerData.extractThreshold[msec].
         *  @param ignoreNoteOff True to set ignoring note off.
         *  @param pan pan of this sample [-64 - 64].
         *  @param srcChannelCount channel count of source data, 1 for monoral, 2 for stereo.
         *  @param channelCount channel count of this data, 1 for monoral, 2 for stereo, 0 sets same with srcChannelCount.
         *  @return created data instance
         *  @see #org.si.sion.module.SiOPMWaveSamplerData.extractThreshold
         *  @see #org.si.sion.SiONDriver.render()
         */
        public function setSamplerWave(index:int, data:*, ignoreNoteOff:Boolean=false, pan:int=0, srcChannelCount:int=2, channelCount:int=0) : SiOPMWaveSamplerData
        {
            var bank:int = (index>>SiOPMTable.NOTE_BITS) & (SiOPMTable.SAMPLER_TABLE_MAX-1);
            return samplerTables[bank].setSample(new SiOPMWaveSamplerData(data, ignoreNoteOff, pan, srcChannelCount, channelCount), index & (SiOPMTable.NOTE_TABLE_SIZE-1));
        }
        

        /** Set pcm voice 
         *  @param index PCM data number.
         *  @param voice pcm voice to set, ussualy from SiONSoundFont
         *  @return cloned internal voice data
         */
        public function setPCMVoice(index:int, voice:SiONVoice) : void
        {
            pcmVoices[index & (pcmVoices.length-1)] = voice;
        }
        
        
        /** Set sampler table 
         *  @param bank bank number
         *  @param table sampler table class, ussualy from SiONSoundFont
         *  @see SiONSoundFont
         */
        public function setSamplerTable(bank:int, table:SiOPMWaveSamplerTable) : void
        {
            samplerTables[bank & (samplerTables.length-1)] = table;
        }
        
        
        /** [NOT RECOMMENDED] This function is for a compatibility with previous versions, please use setPCMWave instead of this function. @see #setPCMWave(). */
        public function setPCMData(index:int, data:Vector.<Number>, samplingOctave:int=5, keyRangeFrom:int=0, keyRangeTo:int=127, isSourceDataStereo:Boolean=false) : SiOPMWavePCMData
        {
            return setPCMWave(index, data, samplingOctave*12+8, keyRangeFrom, keyRangeTo, (isSourceDataStereo)?2:1);
        }
        
        
        /** [NOT RECOMMENDED] This function is for a compatibility with previous versions, please use setPCMWave instead of this function. @see #setPCMWave(). */
        public function setPCMSound(index:int, sound:Sound, samplingOctave:int=5, keyRangeFrom:int=0, keyRangeTo:int=127) : SiOPMWavePCMData
        {
            return setPCMWave(index, sound, samplingOctave*12+8, keyRangeFrom, keyRangeTo, 1, 0);
        }
        
        
        /** [NOT RECOMMENDED] This function is for a compatibility with previous versions, please use setSamplerWave instead of this function. @see #setSamplerWave(). */
        public function setSamplerData(index:int, data:Vector.<Number>, ignoreNoteOff:Boolean=false, channelCount:int=1) : SiOPMWaveSamplerData
        {
            return setSamplerWave(index, data, ignoreNoteOff, 0, channelCount);
        }
        
        
        /** [NOT RECOMMENDED] This function is for a compatibility with previous versions, please use setSamplerWave instead of this function. @see #setSamplerWave(). */
        public function setSamplerSound(index:int, sound:Sound, ignoreNoteOff:Boolean=false, channelCount:int=2) : SiOPMWaveSamplerData
        {
            return setSamplerWave(index, sound, ignoreNoteOff, 0, channelCount);
        }
    }
}

