//----------------------------------------------------------------------------------------------------
// class for SiMML sequencer setting
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.simulator {
    import org.si.sion.sequencer.base.MMLSequence;
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.channels.SiOPMChannelManager;
    import org.si.sion.module.channels.SiOPMChannelBase;

    
    /** @private Module simulator controls "SiMMLTrack" (not SiOPMChannel) to simulate various modules. */
    public class SiMMLModuleSimulatorBase
    {
    // constants
    //--------------------------------------------------
        static public const SELECT_TONE_NOP   :int = 0;
        static public const SELECT_TONE_NORMAL:int = 1;
        static public const SELECT_TONE_FM    :int = 2;

        
        
        
    // variables
    //--------------------------------------------------
        public   var type:int;
        internal var _selectToneType:int;
        internal var _pgTypeList:Vector.<int>;
        internal var _ptTypeList:Vector.<int>;
        internal var _initVoiceIndex:int;
        internal var _voiceIndexTable:Vector.<int>;
        internal var _channelType:int;
        internal var _isSuitableForFMVoice:Boolean;
        internal var _defaultOpeCount:int;
        private  var _table:SiOPMTable;
        
        
        
        
    // constructor
    //--------------------------------------------------
        function SiMMLModuleSimulatorBase(type:int, offset:int, length:int, step:int, channelCount:int)
        {
            var i:int, idx:int;
            _table = SiOPMTable.instance;
            _pgTypeList = new Vector.<int>(length, true);
            _ptTypeList = new Vector.<int>(length, true);
            for (i=0, idx=offset; i<length; i++, idx+=step) {
                _pgTypeList[i] = idx;
                _ptTypeList[i] = _table.getWaveTable(idx).defaultPTType;
            }
            _voiceIndexTable = new Vector.<int>(channelCount, true);
            for (i=0; i<channelCount; i++) { _voiceIndexTable[i] = i; }
            
            this._initVoiceIndex = 0;
            this.type = type;
            _channelType = SiOPMChannelManager.CT_CHANNEL_FM;
            _selectToneType = SELECT_TONE_NORMAL;
            _defaultOpeCount = 1;
            _isSuitableForFMVoice = true;
        }
        
        
        
        
    // tone setting
    //--------------------------------------------------
        /** initialize tone by channel number. 
         *  call from SiMMLTrack::reset()/setChannelModuleType().
         *  call from "%" MML command
         */
        internal function initializeTone(track:SiMMLTrack, chNum:int, bufferIndex:int) : int
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
            var voiceIndex:int = _initVoiceIndex; 
            var chNumRestrict:int = chNum;
            if (0<=chNum && chNum<_voiceIndexTable.length) voiceIndex = _voiceIndexTable[chNum];
            else chNumRestrict = 0;
            // track has channel number include -1.
            track._channelNumber = (chNum < 0) ? -1 : chNum;
            // channel requires restrticted channel number
            track.channel.setChannelNumber(chNumRestrict);
            track.channel.setAlgorism(_defaultOpeCount, 0);
            selectTone(track, voiceIndex);
            
            // return voice index
            return (chNum == -1) ? -1 : voiceIndex;
        }
        
        
        /** select tone by tone number. 
         *  call from initializeTone(), SiMMLTrack::setChannelModuleType()/_bufferEnvelop()/_keyOn()/_setChannelParameters().
         *  call from "%" and "&#64;" MML command
         */
        internal function selectTone(track:SiMMLTrack, voiceIndex:int) : MMLSequence
        {
            if (voiceIndex == -1) return null;
            
            var voice:SiMMLVoice, pcmTable:SiOPMWavePCMTable;
            
            switch (_selectToneType) {
            case SELECT_TONE_NORMAL:
                if (voiceIndex <0 || voiceIndex >=_pgTypeList.length) voiceIndex = _initVoiceIndex;
                track.channel.setType(_pgTypeList[voiceIndex], _ptTypeList[voiceIndex]);
                break;
            case SELECT_TONE_FM: // %6
                if (voiceIndex<0 || voiceIndex>=SiMMLTable.VOICE_MAX) voiceIndex=0;
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
                break;
            default:
                break;
            }
            return null;
        }
    }
}

