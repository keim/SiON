//----------------------------------------------------------------------------------------------------
// SiON Voice data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion {
    import flash.media.Sound;
    import org.si.sion.utils.Translator;
    import org.si.sion.sequencer.SiMMLVoice;
    import org.si.sion.module.ISiOPMWaveInterface;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.SiOPMOperatorParam;
    import org.si.sion.module.SiOPMWaveTable;
    import org.si.sion.module.SiOPMWavePCMData;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMWaveSamplerData;
    import org.si.sion.module.SiOPMWaveSamplerTable;
    
    
    /** SiONVoice class provides all of voice setting parameters of SiON.
     *  @see org.si.sion.module.SiOPMChannelParam
     *  @see org.si.sion.module.SiOPMOperatorParam
     */
    public class SiONVoice extends SiMMLVoice implements ISiOPMWaveInterface
    {
    // constant
    //--------------------------------------------------
        static public const CHIPTYPE_SIOPM:String = "";
        static public const CHIPTYPE_OPL:String = "OPL";
        static public const CHIPTYPE_OPM:String = "OPM";
        static public const CHIPTYPE_OPN:String = "OPN";
        static public const CHIPTYPE_OPX:String = "OPX";
        static public const CHIPTYPE_MA3:String = "MA3";
        static public const CHIPTYPE_PMS_GUITAR:String = "PMSGuitar";
        static public const CHIPTYPE_ANALOG_LIKE:String = "AnalogLike";
        
        
        
        
    // variables
    //--------------------------------------------------
        /** voice name */
        public var name:String;
        
        
        
        
    // constrctor
    //--------------------------------------------------
        /** create new SiONVoice instance with '%' parameters, attack rate, release rate and pitchShift.
         *  @param moduleType Module type. 1st argument of '%'.
         *  @param channelNum Channel number. 2nd argument of '%'.
         *  @param ar Attack rate (0-63).
         *  @param rr Release rate (0-63).
         *  @param dt pitchShift (64=1halftone).
         *  @param con connection type of 2nd operator, -1 sets 1operator voice.
         *  @param ws2 wave shape of 2nd operator.
         *  @param dt2 pitchShift of 2nd operator (64=1halftone).
         */
        function SiONVoice(moduleType:int=5, channelNum:int=0, ar:int=63, rr:int=63, dt:int=0, connectionType:int=-1, ws2:int=0, dt2:int=0)
        {
            super();
            name = "";
            updateTrackParamaters = true;
            
            setModuleType(moduleType, channelNum);
            channelParam.operatorParam[0].ar = ar;
            channelParam.operatorParam[0].rr = rr;
            pitchShift = dt;
            if (connectionType >= 0) {
                channelParam.opeCount = 5;
                channelParam.alg = (connectionType<=2) ? connectionType : 0;
                channelParam.operatorParam[0].setPGType(channelNum);
                channelParam.operatorParam[1].setPGType(ws2);
                channelParam.operatorParam[1].detune = dt2;
            }
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** create clone voice. */
        public function clone() : SiONVoice
        {
            var newVoice:SiONVoice = new SiONVoice();
            newVoice.copyFrom(this);
            newVoice.name = name;
            return newVoice;
        }
        
        
        
        
    // FM parameter setter / getter
    //--------------------------------------------------
        /** Set by #&#64; parameters Array */
        public function set param(args:Array)    : void { Translator.setParam(channelParam, args);    chipType = ""; }
        
        /** Set by #OPL&#64; parameters Array */
        public function set paramOPL(args:Array) : void { Translator.setOPLParam(channelParam, args); chipType = "OPL"; }
        
        /** Set by #OPM&#64; parameters Array */
        public function set paramOPM(args:Array) : void { Translator.setOPMParam(channelParam, args); chipType = "OPM"; }
        
        /** Set by #OPN&#64; parameters Array */
        public function set paramOPN(args:Array) : void { Translator.setOPNParam(channelParam, args); chipType = "OPN"; }
        
        /** Set by #OPX&#64; parameters Array */
        public function set paramOPX(args:Array) : void { Translator.setOPXParam(channelParam, args); chipType = "OPX"; }
        
        /** Set by #MA&#64; parameters Array */
        public function set paramMA3(args:Array) : void { Translator.setMA3Param(channelParam, args); chipType = "MA3"; }
        
        /** Get #AL&#64; parameters by Array */
        public function set paramAL(args:Array) : void { Translator.setALParam(channelParam, args); chipType = "AnalogLike"; }
        
        
        /** Get #&#64; parameters by Array */
        public function get param()    : Array { return Translator.getParam(channelParam); }
        
        /** Get #OPL&#64; parameters by Array */
        public function get paramOPL() : Array { return Translator.getOPLParam(channelParam); }
        
        /** Get #OPM&#64; parameters by Array */
        public function get paramOPM() : Array { return Translator.getOPMParam(channelParam); }
        
        /** Get #OPN&#64; parameters by Array */
        public function get paramOPN() : Array { return Translator.getOPNParam(channelParam); }
        
        /** Get #OPX&#64; parameters by Array */
        public function get paramOPX() : Array { return Translator.getOPXParam(channelParam); }
        
        /** Get #MA&#64; parameters by Array */
        public function get paramMA3() : Array { return Translator.getMA3Param(channelParam); }
        
        /** Get #AL&#64; parameters by Array */
        public function get paramAL() : Array { return Translator.getALParam(channelParam); }
        
        
        /** get FM voice setting MML.
         *  @param index voice number.
         *  @param type chip type. choose string from SiONVoice.CHIPTYPE_* or null to detect automatically.
         *  @param appendPostfixMML append postfix MML of voice settings.
         *  @return mml string of this voice setting.
         */
        public function getMML(index:int, type:String = null, appendPostfixMML:Boolean = true) : String {
            if (type == null) type = chipType;
            var mml:String = ""
            switch (type) {
            case "OPL":        mml = "#OPL@" + String(index) + Translator.mmlOPLParam(channelParam, " ", "\n", name); break;
            case "OPM":        mml = "#OPM@" + String(index) + Translator.mmlOPMParam(channelParam, " ", "\n", name); break;
            case "OPN":        mml = "#OPN@" + String(index) + Translator.mmlOPNParam(channelParam, " ", "\n", name); break;
            case "OPX":        mml = "#OPX@" + String(index) + Translator.mmlOPXParam(channelParam, " ", "\n", name); break;
            case "MA3":        mml = "#MA@"  + String(index) + Translator.mmlMA3Param(channelParam, " ", "\n", name); break;
            case "AnalogLike": mml = "#AL@"  + String(index) + Translator.mmlALParam (channelParam, " ", "\n", name); break;
            default:           mml = "#@"    + String(index) + Translator.mmlParam   (channelParam, " ", "\n", name); break;
            }
            if (appendPostfixMML) {
                var postfix:String = Translator.mmlVoiceSetting(this);
                if (postfix != "") mml += "\n" + postfix;
            }
            return mml + ";";
        }
        
        
        /** set FM voice by MML.
         *  @param mml MML string.
         *  @return voice index number. returns -1 when error.
         */
        public function setByMML(mml:String) : int {
            // separating
            initialize();
            var rexNum:RegExp = new RegExp("(#[A-Z]*@)\\s*(\\d+)\\s*{(.*?)}(.*?);", "ms"),
                rexNam:RegExp = new RegExp("^.*?(//\\s*(.+?))?[\\n\\r]"),
                res:* = rexNum.exec(mml);
            if (res) {
                var cmd:String = String(res[1]),
                    prm:String = String(res[3]),
                    pfx:String = String(res[4]),
                    voiceIndex:int = int(res[2]);
                switch (cmd) {
                case "#@":   { Translator.parseParam   (channelParam, prm); chipType = ""; }break;
                case "#OPL@":{ Translator.parseOPLParam(channelParam, prm); chipType = "OPL"; }break;
                case "#OPM@":{ Translator.parseOPMParam(channelParam, prm); chipType = "OPM"; }break;
                case "#OPN@":{ Translator.parseOPNParam(channelParam, prm); chipType = "OPN"; }break;
                case "#OPX@":{ Translator.parseOPXParam(channelParam, prm); chipType = "OPX"; }break;
                case "#MA@": { Translator.parseMA3Param(channelParam, prm); chipType = "MA3"; }break;
                case "#AL@": { Translator.parseALParam (channelParam, prm); chipType = "AnalogLike"; }break;
                default: return -1;
                }
                Translator.parseVoiceSetting(this, pfx);
                res = rexNam.exec(prm);
                name = (res && res[2]) ? String(res[2]) : "";
                return voiceIndex;
            }
            return -1;
        }
        
        
        
    // Voice setter
    //--------------------------------------------------
        /** initializer */
        override public function initialize() : void
        {
            super.initialize();
            name = "";
            updateTrackParamaters = true;
        }
        
        
        /** Set wave table voice.
         *  @param index wave table number.
         *  @param table wave shape vector ranges in -1 to 1.
         */
        public function setWaveTable(data:Vector.<Number>) : SiOPMWaveTable
        {
            var i:int, imax:int=data.length;
            var table:Vector.<int> = new Vector.<int>(imax);
            for (i=0; i<imax; i++) table[i] = SiOPMTable.calcLogTableIndex(data[i]);
            waveData = SiOPMWaveTable.alloc(table);
            moduleType = 4;
            return waveData as SiOPMWaveTable;
        }
        
        
        /** Set as PCM voice (Sound with pitch shift, LPF envlope).
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound instance is extracted internally.
         *  @param samplingNote sampling data's original note
         *  @return PCM data instance as SiOPMWavePCMData
         *  @see org.si.sion.module.SiOPMWavePCMData
         */
        public function setPCMVoice(data:*, samplingNote:int=69, srcChannelCount:int=2, channelCount:int=0) : SiOPMWavePCMData
        {
            moduleType = 7;
            return (waveData = new SiOPMWavePCMData(data, samplingNote*64, srcChannelCount, channelCount)) as SiOPMWavePCMData;
        }
        
        
        /** Set as Sampler voice (Sound without pitch shift, LPF envlope).
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound is extracted when the length is shorter than 4[sec].
         *  @param ignoreNoteOff flag to ignore note off
         *  @param channelCount channel count of streaming, 1 for monoral, 2 for stereo.
         *  @return MP3 data instance as SiOPMWaveSamplerData
         *  @see org.si.sion.module.SiOPMWaveSamplerData
         */
        public function setMP3Voice(wave:Sound, ignoreNoteOff:Boolean=false, channelCount:int=2) : SiOPMWaveSamplerData
        {
            moduleType = 10;
            return (waveData = new SiOPMWaveSamplerData(wave, ignoreNoteOff, 0, 2, channelCount)) as SiOPMWaveSamplerData;
        }
        
        
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
            if (moduleType != 7 || channelNum != index) waveData = null;
            moduleType = 7;
            channelNum = index;
            var pcmTable:SiOPMWavePCMTable = (waveData as SiOPMWavePCMTable) || new SiOPMWavePCMTable();
            var pcmData:SiOPMWavePCMData   = new SiOPMWavePCMData(data, int(samplingNote*64), srcChannelCount, channelCount);
            pcmTable.setSample(pcmData, keyRangeFrom, keyRangeTo);
            waveData = pcmTable;
            return pcmData;
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
            moduleType = 10;
            var samplerTable:SiOPMWaveSamplerTable = (waveData as SiOPMWaveSamplerTable) || new SiOPMWaveSamplerTable();
            var sampleData:SiOPMWaveSamplerData   = new SiOPMWaveSamplerData(data, ignoreNoteOff, pan, srcChannelCount, channelCount);
            samplerTable.setSample(sampleData, index & (SiOPMTable.NOTE_TABLE_SIZE-1));
            waveData = samplerTable;
            return sampleData;
        }
        
        
        /** Set sampler table 
         *  @param table sampler table class, ussualy get from SiONSoundFont
         *  @return this instance
         *  @see SiONSoundFont
         */
        public function setSamplerTable(table:SiOPMWaveSamplerTable) : SiONVoice
        {
            moduleType = 10;
            waveData = table;
            return this;
        }
        
        
        /** Set as phisical modeling synth guitar voice.
         *  @param ar attack rate of plunk energy
         *  @param dr decay rate of plunk energy
         *  @param tl total level of plunk energy
         *  @param fixedPitch plunk noise pitch
         *  @param ws wave shape of plunk
         *  @param tension sustain rate of the tone
         *  @return this SiONVoice instance
         */
        public function setPMSGuitar(ar:int=48, dr:int=48, tl:int=0, fixedPitch:int=69, ws:int=20, tension:int=8) : SiONVoice
        {
            moduleType = 11;
            channelNum = 1;
            param = [1, 0, 0, ws, ar, dr, 0, 63, 15, tl, 0, 0, 1, 0, 0, 0, 0, fixedPitch];
            pmsTension = tension;
            chipType = "PMSGuitar";
            return this;
        }
        
        
        /** Set as analog like synth voice.
         *  @param connectionType Connection type, 0=normal, 1=ring, 2=sync, 3=fm.
         *  @param ws1 Wave shape for osc1.
         *  @param ws2 Wave shape for osc2.
         *  @param balance balance between osc1 and 2 (-64 - 64). -64 for only osc1, 0 for same volume, 64 for only osc2.
         *  @param vco2pitch pitch difference in osc1 and 2. 64 for 1 halftone.
         *  @return this SiONVoice instance
         */
        public function setAnalogLike(connectionType:int, ws1:int=1, ws2:int=1, balance:int=0, vco2pitch:int=0) : SiONVoice
        {
            channelParam.opeCount = 5;
            channelParam.alg = (connectionType>=0 && connectionType<=3) ? connectionType : 0;
            channelParam.operatorParam[0].setPGType(ws1);
            channelParam.operatorParam[1].setPGType(ws2);

            if (balance > 64) balance = 64;
            else if (balance < -64) balance = -64;

            var tltable:Vector.<int> = SiOPMTable.instance.eg_lv2tlTable;
            channelParam.operatorParam[0].tl = tltable[64-balance];
            channelParam.operatorParam[1].tl = tltable[balance+64];
            
            channelParam.operatorParam[0].detune = 0;
            channelParam.operatorParam[1].detune = vco2pitch;
            
            chipType = "AnalogLike";
            
            return this;
        }
        
        
        
        
    // Optional settings
    //--------------------------------------------------
        /** Set envelop parameters of all operators.
         *  @param ar Attack rate (0-63).
         *  @param dr Decay rate (0-63).
         *  @param sr Sustain rate (0-63).
         *  @param rr Release rate (0-63).
         *  @param sl Sustain level (0-15).
         *  @param tl Total level (0-127).
         */
        public function setEnvelop(ar:int, dr:int, sr:int, rr:int, sl:int, tl:int) : SiONVoice
        {
            for (var i:int=0; i<4; i++) {
                var opp:SiOPMOperatorParam = channelParam.operatorParam[i];
                opp.ar = ar;
                opp.dr = dr;
                opp.sr = sr;
                opp.rr = rr;
                opp.sl = sl;
                opp.tl = tl;
            }
            return this;
        }
        
        
        /** Set filter envelop parameters.
         *  @param filterType filter type (0:Low-pass, 1:Band-pass, 2:High-pass)
         *  @param cutoff filter cutoff (0-128)
         *  @param resonance filter resonance (0-9)
         *  @param far filter attack rate (0-63)
         *  @param fdr1 filter decay rate 1 (0-63)
         *  @param fdr2 filter decay rate 2 (0-63)
         *  @param frr filter release rate (0-63)
         *  @param fdc1 filter decay cutoff 1 (0-128)
         *  @param fdc2 filter decay cutoff 2 (0-128)
         *  @param fsc filter sustain cutoff (0-128)
         *  @param frc filter release cutoff (0-128)
         *  @return this SiONVoice instance
         */
        public function setFilterEnvelop(filterType:int=0, cutoff:int=128, resonance:int=0, far:int=0, fdr1:int=0, fdr2:int=0, frr:int=0, fdc1:int=128, fdc2:int=64, fsc:int=32, frc:int=128) : SiONVoice 
        {
            channelParam.filterType = filterType;
            channelParam.cutoff = cutoff;
            channelParam.resonance = resonance;
            channelParam.far = far;
            channelParam.fdr1 = fdr1;
            channelParam.fdr2 = fdr2;
            channelParam.frr = frr;
            channelParam.fdc1 = fdc1;
            channelParam.fdc2 = fdc2;
            channelParam.fsc = fsc;
            channelParam.frc = frc;
            return this;
        }
        
        
        /** [Pleas use setFilterEnvelop() instead of this function]. Set low pass filter envelop parameters. This function is for compatibility of old versions.
         *  @param cutoff LP filter cutoff (0-128)
         *  @param resonance LP filter resonance (0-9)
         *  @param far LP filter attack rate (0-63)
         *  @param fdr1 LP filter decay rate 1 (0-63)
         *  @param fdr2 LP filter decay rate 2 (0-63)
         *  @param frr LP filter release rate (0-63)
         *  @param fdc1 LP filter decay cutoff 1 (0-128)
         *  @param fdc2 LP filter decay cutoff 2 (0-128)
         *  @param fsc LP filter sustain cutoff (0-128)
         *  @param frc LP filter release cutoff (0-128)
         *  @return this SiONVoice instance
         *  @see setFilterEnvelop()
         */
        public function setLPFEnvelop(cutoff:int=128, resonance:int=0, far:int=0, fdr1:int=0, fdr2:int=0, frr:int=0, fdc1:int=128, fdc2:int=64, fsc:int=32, frc:int=128) : SiONVoice 
        {
            return setFilterEnvelop(0, cutoff, resonance, far, fdr1, fdr2, frr, fdc1, fdc2, fsc, frc);
        }
        
        
        /** Set amplitude modulation parameters (same as "ma" command of MML).
         *  @param depth start modulation depth (same as 1st argument)
         *  @param end_depth end modulation depth (same as 2nd argument)
         *  @param delay changing delay (same as 3rd argument)
         *  @param term changing term (same as 4th argument)
         *  @return this instance
         */
        public function setAmplitudeModulation(depth:int=0, end_depth:int=0, delay:int=0, term:int=0) : SiONVoice 
        {
            channelParam.amd = amDepth = depth;
            amDepthEnd = end_depth;
            amDelay = delay;
            amTerm = term;
            return this;
        }
        
        
        /** Set amplitude modulation parameters (same as "mp" command of MML).
         *  @param depth start modulation depth (same as 1st argument)
         *  @param end_depth end modulation depth (same as 2nd argument)
         *  @param delay changing delay (same as 3rd argument)
         *  @param term changing term (same as 4th argument)
         *  @return this instance
         */
        public function setPitchModulation(depth:int=0, end_depth:int=0, delay:int=0, term:int=0) : SiONVoice 
        {
            channelParam.pmd = pmDepth = depth;
            pmDepthEnd = end_depth;
            pmDelay = delay;
            pmTerm = term;
            return this;
        }
    }
}


