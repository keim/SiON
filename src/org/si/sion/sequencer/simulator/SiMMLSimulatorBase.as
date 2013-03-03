//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.channels.SiOPMChannelManager;
    import org.si.sion.module.channels.SiOPMChannelBase;

    
    /** @private Module simulator controls "SiMMLTrack" (not SiOPMChannel) to simulate various modules. */
    public class SiMMLSimulatorBase
    {
    // constants
    //--------------------------------------------------
        /** module type */
        static public const MT_PSG   :int = 0;  // PSG(DCSG)
        static public const MT_APU   :int = 1;  // FC pAPU
        static public const MT_NOISE :int = 2;  // noise wave
        static public const MT_MA3   :int = 3;  // MA3 wave form
        static public const MT_CUSTOM:int = 4;  // SCC / custom wave table
        static public const MT_ALL   :int = 5;  // all pgTypes
        static public const MT_FM    :int = 6;  // FM sound module
        static public const MT_PCM   :int = 7;  // PCM
        static public const MT_PULSE :int = 8;  // pulse wave
        static public const MT_RAMP  :int = 9;  // ramp wave
        static public const MT_SAMPLE:int = 10; // sampler
        static public const MT_KS    :int = 11; // karplus strong
        static public const MT_GB    :int = 12; // gameboy
        static public const MT_VRC6  :int = 13; // vrc6
        static public const MT_SID   :int = 14; // sid
        static public const MT_MAX   :int = 15;
        
        
        
        
    // variables
    //--------------------------------------------------
        /** module type */
        public   var type:int;
        
        protected var _channelType:int;
        protected var _defaultVoiceSet:SiMMLSimulatorVoiceSet;
        protected var _channelVoiceSet:Vector.<SiMMLSimulatorVoiceSet>;
        protected var _isSuitableForFMVoice:Boolean;
        protected var _defaultOpeCount:int;
        
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLSimulatorBase(type:int, channelCount:int, isSuitableForFMVoice:Boolean=true)
        {
            this.type = type;
            this._channelType = SiOPMChannelManager.CT_CHANNEL_FM;
            this._isSuitableForFMVoice = isSuitableForFMVoice;
            this._defaultOpeCount = 1;
            this._channelVoiceSet = new Vector.<SiMMLSimulatorVoiceSet>(channelCount);
            this._defaultVoiceSet = null; 
        }
        
        
        
        
    // tone setting
    //--------------------------------------------------
        /** initialize tone by channel number. 
         *  call from SiMMLTrack::reset()/setChannelModuleType().
         *  call from "%" MML command
         */
        public function initializeTone(track:SiMMLTrack, chNum:int, bufferIndex:int) : int
        {
            // update channel instance
            if (track.channel == null) {
                // create new channel
                track.channel = SiOPMChannelManager.newChannel(_channelType, null, bufferIndex);
            } else 
            if (track.channel.channelType != _channelType) {
                // change channel type
                var prev:SiOPMChannelBase = track.channel;
                track.channel = SiOPMChannelManager.newChannel(_channelType, prev, bufferIndex);
                SiOPMChannelManager.deleteChannel(prev);
            } else {
                // initialize channel
                track.channel.initialize(track.channel, bufferIndex);
                track._resetVolumeOffset();
            }
            
            
            // initialize
            // voiceIndex = chNum except for PSG, APU and analog
            var chNumRestrict:int = chNum;
            var voiceSet:SiMMLSimulatorVoiceSet = _defaultVoiceSet;
            if (0<=chNum && chNum<_channelVoiceSet.length && _channelVoiceSet[chNum]) voiceSet = _channelVoiceSet[chNum];
            else chNumRestrict = 0;
            var voiceIndex:int = voiceSet.initVoiceIndex;
            
            // track setup
            track._channelNumber = (chNum < 0) ? -1 : chNum; // track has channel number include -1.
            track.channel.setChannelNumber(chNumRestrict);   // channel requires restrticted channel number
            track.channel.setAlgorism(_defaultOpeCount, 0);  //
            
            selectTone(track, voiceIndex);
            
            // return voice index
            return (chNum == -1) ? -1 : voiceIndex;
        }
        
        
        /** select tone by tone number. 
         *  call from initializeTone(), SiMMLTrack::setChannelModuleType()/_bufferEnvelop()/_keyOn()/_setChannelParameters().
         *  call from "%" and "&#64;" MML command
         */
        public function selectTone(track:SiMMLTrack, voiceIndex:int) : MMLSequence
        {
            if (voiceIndex == -1) return null;
            
            var chNum:int = track._channelNumber, 
                voiceSet:SiMMLSimulatorVoiceSet = _defaultVoiceSet;
            if (chNum>=0 && chNum<_channelVoiceSet.length && _channelVoiceSet[chNum]) voiceSet = _channelVoiceSet[chNum];
            if (voiceIndex < 0 || voiceIndex >= voiceSet.voices.length) voiceIndex = voiceSet.initVoiceIndex;
            var voice:SiMMLSimulatorVoice = voiceSet.voices[voiceIndex];
            track.channel.setType(voice.pgType, voice.ptType);
            
            return null;
        }
    }
}

