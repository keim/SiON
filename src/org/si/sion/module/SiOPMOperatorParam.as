//----------------------------------------------------------------------------------------------------
// SiOPM operator parameters
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    /** OPM Parameters. This is a member of SiOPMChannelParam. 
     *  @see org.si.sion.SiONVoice
     *  @see org.si.sion.module.SiOPMChannelParam
     */
    public class SiOPMOperatorParam
    {
    // valiables
    //--------------------------------------------------
        /** [extension] Pulse generator type [0,511] */
        public var pgType:int;
        /** [extension] Pitch table type [0,7] */
        public var ptType:int;
        
        /** Attack rate [0,63] */
        public var ar:int;
        /** Decay rate [0,63] */
        public var dr:int;
        /** Sustain rate [0,63] */
        public var sr:int;
        /** Release rate [0,63] */
        public var rr:int;
        /** Sustain level [0,15] */
        public var sl:int;
        /** [extension] Total level [0,127] */
        public var tl:int;
        
        /** Key scaling rate [0,3] */
        public var ksr:int;
        /** [extension] Key scaling level [0,3] */
        public var ksl:int;
        
        /** [extension] Fine multiple [0,...] */
        public var fmul:int;
        /** dt1 [0,7]  */
        public var dt1:int;
        /** detune */
        public var detune:int;
        
        /** Amp modulation shift [0-3] */
        public var ams:int;
        /** [extension] Initiail phase [0,255]. The value of 255 sets no phase reset. */
        public var phase:int;
        /** [extension] Fixed pitch. 0 means pitch is not fixed. */
        public var fixedPitch:int;
        
        /** mute */
        public var mute:Boolean;
        /** SSG type envelop control */
        public var ssgec:int;
        /** [extension] Frequency modulation level [0,7]. 5 is standard modulation. */
        public var modLevel:int;
        /** envelop reset on attack */
        public var erst:Boolean;
        
        
        /** multiple [0,15] */
        public function set mul(m:int) : void { fmul = (m) ? (m<<7) : 64; }
        public function get mul() : int { return (fmul>>7)&15; }
        
        /** set pgType and ptType */
        public function setPGType(type:int) : void
        {
            pgType = type & 511;
            ptType = SiOPMTable.instance.getWaveTable(pgType).defaultPTType;
        }
        
        
        /** constructor */
        function SiOPMOperatorParam()
        {
            initialize();
        }
        
        
        /** intialize all parameters. */
        public function initialize() : void
        {
            pgType = SiOPMTable.PG_SINE;
            ptType = SiOPMTable.PT_OPM;
            ar = 63;
            dr = 0;
            sr = 0;
            rr = 63;
            sl = 0;
            tl = 0;
            ksr = 1;
            ksl = 0;
            fmul = 128;
            dt1 = 0;
            detune = 0;
            ams = 0;
            phase = 0;
            fixedPitch = 0;
            mute = false;
            ssgec = 0;
            modLevel = 5;
            erst = false;
        }
        
        
        /** copy all parameters. */
        public function copyFrom(org:SiOPMOperatorParam) : void
        {
            pgType = org.pgType;
            ptType = org.ptType;
            ar = org.ar;
            dr = org.dr;
            sr = org.sr;
            rr = org.rr;
            sl = org.sl;
            tl = org.tl;
            ksr = org.ksr;
            ksl = org.ksl;
            fmul = org.fmul;
            dt1 = org.dt1;
            detune = org.detune;
            ams = org.ams;
            phase = org.phase;
            fixedPitch = org.fixedPitch;
            mute = org.mute;
            ssgec = org.ssgec;
            modLevel = org.modLevel;
            erst = org.erst;
        }
        
        
        /** all parameters in 1line. */
        public function toString() : String
        {
            var str:String = "SiOPMOperatorParam : "
            str += String(pgType) + "(";
            str += String(ptType) + ") : ";
            str += String(ar) + "/";
            str += String(dr) + "/";
            str += String(sr) + "/";
            str += String(rr) + "/";
            str += String(sl) + "/";
            str += String(tl) + " : ";
            str += String(ksr) + "/";
            str += String(ksl) + " : ";
            str += String(fmul) + "/";
            str += String(dt1) + "/";
            str += String(detune) + " : ";
            str += String(ams) + "/";
            str += String(phase)  + "/";
            str += String(fixedPitch) + " : ";
            str += String(ssgec) + "/";
            str += String(mute) + "/";
            str += String(erst);
            return str;
        }
    }
}

