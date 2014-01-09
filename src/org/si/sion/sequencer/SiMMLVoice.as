//----------------------------------------------------------------------------------------------------
// Voice data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.sion.module.channels.*;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.SiOPMWaveBase;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMWavePCMData;
    import org.si.sion.module.SiOPMWaveTable;
    import org.si.sion.module.SiOPMWaveSamplerTable;
    import org.si.sion.namespaces._sion_internal;
    import org.si.sion.sequencer.base._sion_sequencer_internal;
    
    
    /** Voice data. This includes SiOPMChannelParam.
     *  @see org.si.sion.module.SiOPMChannelParam
     *  @see org.si.sion.module.SiOPMOperatorParam
     */
    public class SiMMLVoice
    {
    // variables
    //--------------------------------------------------
        /** chip type */
        public var chipType:String;
        
        /** update track paramaters, false to update only channel params. @default false(SiMMLVoice), true(SiONVoice) */
        public var updateTrackParamaters:Boolean;
        /** update volume, velocity, expression and panning when the voice is set. @default false(ignore volume settings) */
        public var updateVolumes:Boolean;
        
        /** module type, 1st argument of '%'. @default 0 */
        public var moduleType:int;
        /** channel number, 2nd argument of '%'. @default 0 */
        public var channelNum:int;
        /** tone number, 1st argument of '&#64;'. -1;do nothing. @default -1 */
        public var toneNum:int;
        /** preferable note. -1;no preferable note. @default -1 */
        public var preferableNote:int;
        
        /** parameters for FM sound channel. */
        public var channelParam:SiOPMChannelParam;
        /** wave data. @default null */
        public var waveData:SiOPMWaveBase;
        /** PMS guitar tension @default 8 */
        public var pmsTension:int;
        
        
        
        /** default gate time (same as "q" command * 0.125), set Number.NaN to ignore. @default Number.NaN */
        public var defaultGateTime:Number;
        /** [Not implemented in current version] default absolute gate time (same as 1st argument of "@q" command), set -1 to ignore. @default -1 */
        public var defaultGateTicks:int;
        /** [Not implemented in current version] default key on delay (same as 2nd argument "@q" command), set -1 to ignore. @default -1 */
        public var defaultKeyOnDelayTicks:int;
        /** track pitch shift (same as "k" command). @default 0 */
        public var pitchShift:int;
        /** track key transpose (same as "kt" command). @default 0 */
        public var noteShift:int;
        /** portament. @default 0 */
        public var portament:int;
        /** release sweep. 2nd argument of '&#64;rr' and 's'. @default 0 */
        public var releaseSweep:int;
        
        
        /** velocity @default 256 */
        public var velocity:int;
        /** expression @default 128 */
        public var expression:int;
        /** velocity table mode (same as 1st argument of "%v" command). @default 0 */
        public var velocityMode:int;
        /** velocity table mode (same as 2nd argument of "%v" command). @default 0 */
        public var vcommandShift:int;
        /** expression table mode (same as "%x" command). @default 0 */
        public var expressionMode:int;
        
        
        /** amplitude modulation depth. 1st argument of 'ma'. @default 0 */
        public var amDepth:int;
        /** amplitude modulation depth after changing. 2nd argument of 'ma'. @default 0 */
        public var amDepthEnd:int;
        /** amplitude modulation changing delay. 3rd argument of 'ma'. @default 0 */
        public var amDelay:int;
        /** amplitude modulation changing term. 4th argument of 'ma'. @default 0 */
        public var amTerm:int;
        /** pitch modulation depth. 1st argument of 'mp'. @default 0 */
        public var pmDepth:int;
        /** pitch modulation depth after changing. 2nd argument of 'mp'. @default 0 */
        public var pmDepthEnd:int;
        /** pitch modulation changing delay. 3rd argument of 'mp'. @default 0 */
        public var pmDelay:int;
        /** pitch modulation changing term. 4th argument of 'mp'. @default 0 */
        public var pmTerm:int;
        
        
        /** note on tone envelop table. 1st argument of '&#64;&#64;' @default null */
        public var noteOnToneEnvelop:SiMMLEnvelopTable;
        /** note on amplitude envelop table. 1st argument of 'na' @default null */
        public var noteOnAmplitudeEnvelop:SiMMLEnvelopTable;
        /** note on filter envelop table. 1st argument of 'nf' @default null */
        public var noteOnFilterEnvelop:SiMMLEnvelopTable;
        /** note on pitch envelop table. 1st argument of 'np' @default null */
        public var noteOnPitchEnvelop:SiMMLEnvelopTable;
        /** note on note envelop table. 1st argument of 'nt' @default null */
        public var noteOnNoteEnvelop:SiMMLEnvelopTable;
        /** note off tone envelop table. 1st argument of '_&#64;&#64;' @default null */
        public var noteOffToneEnvelop:SiMMLEnvelopTable;
        /** note off amplitude envelop table. 1st argument of '_na' @default null */
        public var noteOffAmplitudeEnvelop:SiMMLEnvelopTable;
        /** note off filter envelop table. 1st argument of '_nf' @default null */
        public var noteOffFilterEnvelop:SiMMLEnvelopTable;
        /** note off pitch envelop table. 1st argument of '_np' @default null */
        public var noteOffPitchEnvelop:SiMMLEnvelopTable;
        /** note off note envelop table. 1st argument of '_nt' @default null */
        public var noteOffNoteEnvelop:SiMMLEnvelopTable;
        
        
        /** note on tone envelop tablestep. 2nd argument of '&#64;&#64;' @default 1 */
        public var noteOnToneEnvelopStep:int;
        /** note on amplitude envelop tablestep. 2nd argument of 'na' @default 1 */
        public var noteOnAmplitudeEnvelopStep:int;
        /** note on filter envelop tablestep. 2nd argument of 'nf' @default 1 */
        public var noteOnFilterEnvelopStep:int;
        /** note on pitch envelop tablestep. 2nd argument of 'np' @default 1 */
        public var noteOnPitchEnvelopStep:int;
        /** note on note envelop tablestep. 2nd argument of 'nt' @default 1 */
        public var noteOnNoteEnvelopStep:int;
        /** note off tone envelop tablestep. 2nd argument of '_&#64;&#64;' @default 1 */
        public var noteOffToneEnvelopStep:int;
        /** note off amplitude envelop tablestep. 2nd argument of '_na' @default 1 */
        public var noteOffAmplitudeEnvelopStep:int;
        /** note off filter envelop tablestep. 2nd argument of '_nf' @default 1 */
        public var noteOffFilterEnvelopStep:int;
        /** note off pitch envelop tablestep. 2nd argument of '_np' @default 1 */
        public var noteOffPitchEnvelopStep:int;
        /** note off note envelop tablestep. 2nd argument of '_nt' @default 1 */
        public var noteOffNoteEnvelopStep:int;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** FM voice flag */
        public function get isFMVoice() : Boolean { return (moduleType == 6); }
        
        /** PCM voice flag */
        public function get isPCMVoice() : Boolean { return (waveData is SiOPMWavePCMTable || waveData is SiOPMWavePCMData); }
        
        /** Sampler voice flag */
        public function get isSamplerVoice() : Boolean { return (waveData is SiOPMWaveSamplerTable); }
        
        /** wave table voice flag */
        public function get isWaveTableVoice() : Boolean { return (waveData is SiOPMWaveTable); }
        
        /** @private [sion internal] suitability to register in %6 voices */
        _sion_internal function get _isSuitableForFMVoice() : Boolean {
            return updateTrackParamaters || (SiMMLTable.isSuitableForFMVoice(moduleType) && waveData == null);
        }
        
        
        /** set moduleType, channelNum, toneNum and 0th operator's pgType simultaneously.
         *  @param moduleType Channel module type
         *  @param channelNum Channel number. For %2-11, this value is same as 1st argument of '_&#64;'.
         *  @param toneNum Tone number. Ussualy, this argument is used only in %0;PSG and %1;APU.
         */
        public function setModuleType(moduleType:int, channelNum:int=0, toneNum:int=-1) : void
        {
            this.moduleType = moduleType;
            this.channelNum = channelNum;
            this.toneNum    = toneNum;
            var pgType:int = SiMMLTable.getPGType(moduleType, channelNum, toneNum);
            if (pgType != -1) channelParam.operatorParam[0].setPGType(pgType);
        }
        
        
        
        
    // constrctor
    //--------------------------------------------------
        /** constructor. */
        function SiMMLVoice()
        {
            channelParam = new SiOPMChannelParam();
            initialize();
        }
        
        
        
        
    // setting
    //--------------------------------------------------
        /** update track's voice paramters */
        public function updateTrackVoice(track:SiMMLTrack) : SiMMLTrack
        {
            // synthesizer modules
            switch (moduleType) {
            case 6:  // Registered FM voice (%6)
                track.setChannelModuleType(6, channelNum);
                break;
            case 11: // PMS Guitar (%11)
                track.setChannelModuleType(11, 1);
                track.channel.setSiOPMChannelParam(channelParam, false);
                track.channel.setAllReleaseRate(pmsTension);
                if (isPCMVoice) track.channel.setWaveData(waveData);
                break;
            default: // other sound modules
                if (waveData) {
                    // voice with wave data
                    track.setChannelModuleType(waveData.moduleType, -1);
                    track.channel.setSiOPMChannelParam(channelParam, updateVolumes);
                    track.channel.setWaveData(waveData);
                } else {
                    track.setChannelModuleType(moduleType, channelNum, toneNum);
                    track.channel.setSiOPMChannelParam(channelParam, updateVolumes);
                }
                break;
            }
            
            // track settings
            //if (defaultKeyOnDelayTicks  > 0) track.defaultKeyOnDelayTicks = defaultKeyOnDelayTicks -> samplecount;
            //if (defaultGateTicks > 0) track.quantCount = defaultGateTicks -> samplecount;
            if (!isNaN(defaultGateTime)) track.quantRatio = defaultGateTime;
            track.pitchShift = pitchShift;
            track.noteShift = noteShift;
            track._sion_sequencer_internal::_vcommandShift = vcommandShift;
            track.velocityMode = velocityMode;
            track.expressionMode = expressionMode;
            if (updateVolumes) {
                track.velocity = velocity;
                track.expression = expression;
            }
            
            track.setPortament(portament);
            track.setReleaseSweep(releaseSweep);
            track.setModulationEnvelop(false, amDepth, amDepthEnd, amDelay, amTerm);
            track.setModulationEnvelop(true,  pmDepth, pmDepthEnd, pmDelay, pmTerm);
            {
            track.setToneEnvelop(1, noteOnToneEnvelop, noteOnToneEnvelopStep);
            track.setAmplitudeEnvelop(1, noteOnAmplitudeEnvelop, noteOnAmplitudeEnvelopStep);
            track.setFilterEnvelop(1, noteOnFilterEnvelop, noteOnFilterEnvelopStep);
            track.setPitchEnvelop(1, noteOnPitchEnvelop, noteOnPitchEnvelopStep);
            track.setNoteEnvelop(1, noteOnNoteEnvelop, noteOnNoteEnvelopStep);
            track.setToneEnvelop(0, noteOffToneEnvelop, noteOffToneEnvelopStep);
            track.setAmplitudeEnvelop(0, noteOffAmplitudeEnvelop, noteOffAmplitudeEnvelopStep);
            track.setFilterEnvelop(0, noteOffFilterEnvelop, noteOffFilterEnvelopStep);
            track.setPitchEnvelop(0, noteOffPitchEnvelop, noteOffPitchEnvelopStep);
            track.setNoteEnvelop(0, noteOffNoteEnvelop, noteOffNoteEnvelopStep);
            }
            return track;
        }
        
        
        /** [NOT RECOMENDED] this function is only for compatibility of previous versions */
        public function setTrackVoice(track:SiMMLTrack) : SiMMLTrack { 
            return updateTrackVoice(track); 
        }

        
        
        
    // operation
    //--------------------------------------------------
        /** initializer */
        public function initialize() : void
        {
            chipType = "";
            
            updateTrackParamaters = false;
            updateVolumes = false;
            
            moduleType = 5;
            channelNum = -1;
            toneNum = -1;
            preferableNote = -1;
            
            channelParam.initialize();
            waveData = null;
            pmsTension = 8;
            
            defaultGateTime = Number.NaN;
            defaultGateTicks = -1;
            defaultKeyOnDelayTicks = -1;
            pitchShift = 0;
            noteShift = 0;
            portament = 0;
            releaseSweep = 0;
            
            velocity = 256;
            expression = 128;
            vcommandShift = 4;
            velocityMode = 0;
            expressionMode = 0;
            
            amDepth = 0;
            amDepthEnd = 0;
            amDelay = 0;
            amTerm = 0;
            pmDepth = 0;
            pmDepthEnd = 0;
            pmDelay = 0;
            pmTerm = 0;

            noteOnToneEnvelop = null;
            noteOnAmplitudeEnvelop = null;
            noteOnFilterEnvelop = null;
            noteOnPitchEnvelop = null;
            noteOnNoteEnvelop = null;
            noteOffToneEnvelop = null;
            noteOffAmplitudeEnvelop = null;
            noteOffFilterEnvelop = null;
            noteOffPitchEnvelop = null;
            noteOffNoteEnvelop = null;
            
            noteOnToneEnvelopStep = 1;
            noteOnAmplitudeEnvelopStep = 1;
            noteOnFilterEnvelopStep = 1;
            noteOnPitchEnvelopStep = 1;
            noteOnNoteEnvelopStep = 1;
            noteOffToneEnvelopStep = 1;
            noteOffAmplitudeEnvelopStep = 1;
            noteOffFilterEnvelopStep = 1;
            noteOffPitchEnvelopStep = 1;
            noteOffNoteEnvelopStep = 1;
        }
        
        
        /** copy all parameters */
        public function copyFrom(src:SiMMLVoice) : void
        {
            chipType = src.chipType;

            updateTrackParamaters = src.updateTrackParamaters;
            updateVolumes = src.updateVolumes;
            
            moduleType = src.moduleType;
            channelNum = src.channelNum;
            toneNum = src.toneNum;
            preferableNote = src.preferableNote;
            channelParam.copyFrom(src.channelParam);
            
            waveData = src.waveData;
            pmsTension = src.pmsTension;
            
            defaultGateTime = src.defaultGateTime;
            defaultGateTicks = src.defaultGateTicks;
            defaultKeyOnDelayTicks = src.defaultKeyOnDelayTicks;
            pitchShift = src.pitchShift;
            noteShift = src.noteShift;
            portament = src.portament;
            releaseSweep = src.releaseSweep;
            
            velocity = src.velocity;
            expression = src.expression;
            vcommandShift = src.vcommandShift;
            velocityMode = src.velocityMode;
            expressionMode = src.expressionMode;
            
            amDepth = src.amDepth;
            amDepthEnd = src.amDepthEnd;
            amDelay = src.amDelay;
            amTerm = src.amTerm;
            pmDepth = src.pmDepth;
            pmDepthEnd = src.pmDepthEnd;
            pmDelay = src.pmDelay;
            pmTerm = src.pmTerm;
            
            if (src.noteOnToneEnvelop)  noteOnToneEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOnToneEnvelop);
            if (src.noteOnAmplitudeEnvelop) noteOnAmplitudeEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOnAmplitudeEnvelop);
            if (src.noteOnFilterEnvelop) noteOnFilterEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOnFilterEnvelop);
            if (src.noteOnPitchEnvelop) noteOnPitchEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOnPitchEnvelop);
            if (src.noteOnNoteEnvelop) noteOnNoteEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOnNoteEnvelop);
            if (src.noteOffToneEnvelop) noteOffToneEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOffToneEnvelop);
            if (src.noteOffAmplitudeEnvelop) noteOffAmplitudeEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOffAmplitudeEnvelop);
            if (src.noteOffFilterEnvelop) noteOffFilterEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOffFilterEnvelop);
            if (src.noteOffPitchEnvelop) noteOffPitchEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOffPitchEnvelop);
            if (src.noteOffNoteEnvelop) noteOffNoteEnvelop = new SiMMLEnvelopTable().copyFrom(src.noteOffNoteEnvelop);
            
            noteOnToneEnvelopStep = src.noteOnToneEnvelopStep;
            noteOnAmplitudeEnvelopStep = src.noteOnAmplitudeEnvelopStep;
            noteOnFilterEnvelopStep = src.noteOnFilterEnvelopStep;
            noteOnPitchEnvelopStep = src.noteOnPitchEnvelopStep;
            noteOnNoteEnvelopStep = src.noteOnNoteEnvelopStep;
            noteOffToneEnvelopStep = src.noteOffToneEnvelopStep;
            noteOffAmplitudeEnvelopStep = src.noteOffAmplitudeEnvelopStep;
            noteOffFilterEnvelopStep = src.noteOffFilterEnvelopStep;
            noteOffPitchEnvelopStep = src.noteOffPitchEnvelopStep;
            noteOffNoteEnvelopStep = src.noteOffNoteEnvelopStep;
        }
        
        
        /** @private [sion internal] set as blank pcm voice */
        _sion_internal function _newBlankPCMVoice(channelNum:int) : SiMMLVoice {
            var pcmTable:SiOPMWavePCMTable = new SiOPMWavePCMTable();
            this.moduleType = 7;
            this.channelNum = channelNum;
            this.waveData = pcmTable;
            return this;
        }
    }
}


