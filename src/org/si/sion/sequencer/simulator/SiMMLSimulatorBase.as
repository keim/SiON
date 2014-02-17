//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.channels.SiOPMChannelManager;
    import org.si.sion.module.channels.SiOPMChannelBase;
    import org.si.sion.sequencer.base._sion_sequencer_internal;


    /** Base class of all module simulators which control "SiMMLTrack" (not SiOPMChannel) to simulate various modules. */
    public class SiMMLSimulatorBase
    {
    // constants
    //--------------------------------------------------
        /* module type */
        static public const MT_PSG    :int = 0;  // PSG(DCSG)
        static public const MT_APU    :int = 1;  // FC pAPU
        static public const MT_NOISE  :int = 2;  // noise wave
        static public const MT_MA3    :int = 3;  // MA3 wave form
        static public const MT_CUSTOM :int = 4;  // SCC / custom wave table
        static public const MT_ALL    :int = 5;  // all pgTypes
        static public const MT_FM     :int = 6;  // FM sound module
        static public const MT_PCM    :int = 7;  // PCM
        static public const MT_PULSE  :int = 8;  // pulse wave
        static public const MT_RAMP   :int = 9;  // ramp wave
        static public const MT_SAMPLE :int = 10; // sampler
        static public const MT_KS     :int = 11; // karplus strong
        static public const MT_GB     :int = 12; // gameboy
        static public const MT_VRC6   :int = 13; // vrc6
        static public const MT_SID    :int = 14; // sid
        static public const MT_FM_OPM :int = 15; // YM2151
        static public const MT_FM_OPN :int = 16; // YM2203
        static public const MT_FM_OPNA:int = 17; // YM2608
        static public const MT_FM_OPLL:int = 18; // YM2413
        static public const MT_FM_OPL3:int = 19; // YM3812
        static public const MT_FM_MA3 :int = 20; // YMU762
        static public const MT_MAX    :int = 21;

        
        
        
    // variables
    //--------------------------------------------------
        /** module type */
        public var type:int;


        /** Default table converting from MML voice number to SiOPM pgType */
        protected var _defaultVoiceSet:SiMMLSimulatorVoiceSet;
        /** Tables converting from MML voice number to SiOPM pgType for each channel, if the table is different for each channel */
        protected var _channelVoiceSet:Vector.<SiMMLSimulatorVoiceSet>;
        /** This simulator can be used as the FM voice's source wave or not */
        protected var _isSuitableForFMVoice:Boolean;
        /** Default operator count */
        protected var _defaultOpeCount:int;
        
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLSimulatorBase(type:int, channelCount:int, defaultVoiceSet:SiMMLSimulatorVoiceSet, isSuitableForFMVoice:Boolean=true)
        {
            this.type = type;
            this._isSuitableForFMVoice = isSuitableForFMVoice;
            this._defaultOpeCount = 1;
            this._channelVoiceSet = new Vector.<SiMMLSimulatorVoiceSet>(channelCount);
            this._defaultVoiceSet = defaultVoiceSet; 
        }
        
        
        
        
    // tone setting
    //--------------------------------------------------
        /** initialize tone by channel number. 
         *  call from SiMMLTrack::reset()/setChannelModuleType().
         *  call from "%" MML command
         */
        public function initializeTone(track:SiMMLTrack, chNum:int, bufferIndex:int) : int
        {
            // initialize
            var restrictedChNum:int = chNum;
            var voiceSet:SiMMLSimulatorVoiceSet = _defaultVoiceSet;
            if (0<=chNum && chNum<_channelVoiceSet.length && _channelVoiceSet[chNum]) voiceSet = _channelVoiceSet[chNum];
            else restrictedChNum = 0;

            // update channel instance in SiMMLTrack
            _updateChannelInstance(track, bufferIndex, voiceSet);
            
            // track setup
            track._sion_sequencer_internal::_channelNumber = (chNum < 0) ? -1 : chNum; // track has channel number include -1.
            track.channel.setChannelNumber(restrictedChNum);   // channel requires restrticted channel number
            track.channel.setAlgorism(_defaultOpeCount, 0);  //
            
            selectTone(track, voiceSet.initVoiceIndex);
            
            // return voice index
            return (chNum == -1) ? -1 : voiceSet.initVoiceIndex;
        }


        /** select tone by tone number. 
         *  call from initializeTone(), SiMMLTrack::setChannelModuleType()/_bufferEnvelop()/_keyOn()/_setChannelParameters().
         *  call from "%" and "&#64;" MML command
         */
        public function selectTone(track:SiMMLTrack, voiceIndex:int) : MMLSequence
        {
            return _selectSingleWaveTone(track, voiceIndex);
        }


        /** @private */
        protected function _selectSingleWaveTone(track:SiMMLTrack, voiceIndex:int) : MMLSequence
        {
            if (voiceIndex == -1) return null;
            
            var chNum:int = track._sion_sequencer_internal::_channelNumber, 
                voiceSet:SiMMLSimulatorVoiceSet = _defaultVoiceSet;
            if (chNum>=0 && chNum<_channelVoiceSet.length && _channelVoiceSet[chNum]) voiceSet = _channelVoiceSet[chNum];
            if (voiceIndex < 0 || voiceIndex >= voiceSet.voices.length) voiceIndex = voiceSet.initVoiceIndex;
            var voice:SiMMLSimulatorVoice = voiceSet.voices[voiceIndex];
            track.channel.setType(voice.pgType, voice.ptType);
            
            return null;
        }


        /** @private */
        protected function _updateChannelInstance(track:SiMMLTrack, bufferIndex:int, voiceSet:SiMMLSimulatorVoiceSet) : void
        {
            var defaultVoice:SiMMLSimulatorVoice = voiceSet.voices[voiceSet.initVoiceIndex],
                defaultChannelType:int = defaultVoice.channelType;

            // update channel instance
            if (track.channel == null) {
                // create new channel
                track.channel = SiOPMChannelManager.newChannel(defaultChannelType, null, bufferIndex);
            } else 
            if (track.channel.channelType != _channelType) {
                // change channel type
                var prev:SiOPMChannelBase = track.channel;
                track.channel = SiOPMChannelManager.newChannel(defaultChannelType, prev, bufferIndex);
                SiOPMChannelManager.deleteChannel(prev);
            } else {
                // initialize channel
                track.channel.initialize(track.channel, bufferIndex);
                track._sion_sequencer_internal::_resetVolumeOffset();
            }
        }
    }
}

