//----------------------------------------------------------------------------------------------------
// SiOPM channel parameters
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import org.si.sion.sequencer.base.MMLSequence;
    
    
    /** SiOPM Channel Parameters. This is a member of SiONVoice.
     *  @see org.si.sion.SiONVoice
     *  @see org.si.sion.module.SiOPMOperatorParam
     */
    public class SiOPMChannelParam
    {
    // valiables 11 parameters
    //--------------------------------------------------
        /** operator params x4 */
        public var operatorParam:Vector.<SiOPMOperatorParam>;
        
        /** operator count [0,5]. 0 ignores all operators params. 5 sets analog like mode. */
        public var opeCount:int;
        /** algorism [0,15] */
        public var alg:int;
        /** feedback [0,7] */
        public var fb:int;
        /** feedback connection [0,3] */
        public var fbc:int;
        /** envelop frequency ratio */
        public var fratio:int;
        /** LFO wave shape */
        public var lfoWaveShape:int;
        /** LFO frequency */
        public var lfoFreqStep:int;
        
        /** amplitude modulation depth */
        public var amd:int;
        /** pitch modulation depth */
        public var pmd:int;
        /** [extention] master volume [0,1] */
        public var volumes:Vector.<Number>;
        /** [extention] panning */
        public var pan:int;

        /** filter type */
        public var filterType:int;
        /** filter cutoff */
        public var cutoff:int;
        /** filter resonance */
        public var resonance:int;
        /** filter attack rate */
        public var far:int;
        /** filter decay rate 1 */
        public var fdr1:int;
        /** filter decay rate 2 */
        public var fdr2:int;
        /** filter release rate */
        public var frr:int;
        /** filter decay offset 1 */
        public var fdc1:int;
        /** filter decay offset 2 */
        public var fdc2:int;
        /** filter sustain offset */
        public var fsc:int;
        /** filter release offset */
        public var frc:int;
        
        /** Initializing sequence */
        public var initSequence:MMLSequence;
        
        
        /** LFO cycle time */
        public function set lfoFrame(fps:int) : void
        {
            lfoFreqStep = SiOPMTable.LFO_TIMER_INITIAL/(fps*2.882352941176471);
        }
        public function get lfoFrame() : int
        {
            return int(SiOPMTable.LFO_TIMER_INITIAL * 0.346938775510204 / lfoFreqStep);
        }
        
        
        /** constructor */
        function SiOPMChannelParam()
        {
            initSequence = new MMLSequence();
            volumes = new Vector.<Number>(SiOPMModule.STREAM_SEND_SIZE, true);

            operatorParam = new Vector.<SiOPMOperatorParam>(4);
            for (var i:int; i<4; i++) {
                operatorParam[i] = new SiOPMOperatorParam();
            }
            
            initialize();
        }
        
        
        /** initializer */
        public function initialize() : SiOPMChannelParam
        {
            var i:int;
            
            opeCount = 1;
            
            alg = 0;
            fb = 0;
            fbc = 0;
            lfoWaveShape = SiOPMTable.LFO_WAVE_TRIANGLE;
            lfoFreqStep = 12126;    // 12126 = 30frame/100fratio
            amd = 0;
            pmd = 0;
            fratio = 100;
            for (i=1; i<SiOPMModule.STREAM_SEND_SIZE; i++) { volumes[i] = 0; }
            volumes[0] = 0.5;
            pan = 64;
            
            filterType = 0;
            cutoff = 128;
            resonance = 0;
            far = 0;
            fdr1 = 0;
            fdr2 = 0;
            frr = 0;
            fdc1 = 128;
            fdc2 = 64;
            fsc = 32;
            frc = 128;
            
            for (i=0; i<4; i++) { operatorParam[i].initialize(); }
            
            initSequence.free();
            
            return this;
        }
        
        
        /** copier */
        public function copyFrom(org:SiOPMChannelParam) : SiOPMChannelParam
        {
            var i:int;
            
            opeCount = org.opeCount;
            
            alg = org.alg;
            fb = org.fb;
            fbc = org.fbc;
            lfoWaveShape = org.lfoWaveShape;
            lfoFreqStep = org.lfoFreqStep;
            amd = org.amd;
            pmd = org.pmd;
            fratio = org.fratio;
            for (i=0; i<SiOPMModule.STREAM_SEND_SIZE; i++) { volumes[i] = org.volumes[i]; }
            pan = org.pan;
            
            filterType = org.filterType;
            cutoff = org.cutoff;
            resonance = org.resonance;
            far = org.far;
            fdr1 = org.fdr1;
            fdr2 = org.fdr2;
            frr = org.frr;
            fdc1 = org.fdc1;
            fdc2 = org.fdc2;
            fsc = org.fsc;
            frc = org.frc;
            
            for (i=0; i<4; i++) { operatorParam[i].copyFrom(org.operatorParam[i]); }
            
            initSequence.free();
            
            return this;
        }
        
        
        /** information */
        public function toString() : String
        {
            var str:String = "SiOPMChannelParam : opeCount=";
            str += String(opeCount) + "\n";
            $("freq.ratio", fratio);
            $("alg", alg);
            $2("fb ", fb,  "fbc", fbc);
            $2("lws", lfoWaveShape, "lfq", SiOPMTable.LFO_TIMER_INITIAL*0.005782313/lfoFreqStep);
            $2("amd", amd, "pmd", pmd);
            $2("vol", volumes[0],  "pan", pan-64);
            $("filter type", filterType);
            $2("co", cutoff, "res", resonance);
            str += "fenv=" + String(far) + "/" + String(fdr1) + "/"+ String(fdr2) + "/"+ String(frr) + "\n";
            str += "feco=" + String(fdc1) + "/"+ String(fdc2) + "/"+ String(fsc) + "/"+ String(frc) + "\n";
            for (var i:int=0; i<opeCount; i++) {
                str += operatorParam[i].toString() + "\n";
            }
            return str;
            function $ (p:String, i:int) : void { str += "  " + p + "=" + String(i) + "\n"; }
            function $2(p:String, i:int, q:String, j:int) : void { str += "  " + p + "=" + String(i) + " / " + q + "=" + String(j) + "\n"; }
        }
        
        
        /** Set voice by OPM's register value
         *  @param channel pseudo OPM channel number
         *  @param addr register address
         *  @param data register data
         */
        public function setByOPMRegister(channel:int, addr:int, data:int) : SiOPMChannelParam
        {
            var v:int, pms:int, ams:int, opp:SiOPMOperatorParam;
            
            if (addr < 0x20) {  // Module parameter
                switch(addr) {
                case 15: // NOIZE:7 FREQ:4-0 for channel#7
                    if (channel == 7 && (data & 128)) {
                        operatorParam[3].pgType = SiOPMTable.PG_NOISE_PULSE;
                        operatorParam[3].ptType = SiOPMTable.PT_OPM_NOISE;
                        operatorParam[3].fixedPitch = ((data & 31) << 6) + 2048;
                    }
                    break;
                case 24: // LFO FREQ:7-0 for all 8 channels
                    lfoFreqStep = SiOPMTable.instance.lfo_timerSteps[data];
                    break;
                case 25: // A(0)/P(1):7 DEPTH:6-0 for all 8 channels
                    if (data & 128) pmd = data & 127;
                    else            amd = data & 127;
                    break;
                case 27: // LFO WS:10 for all 8 channels
                    lfoWaveShape = data & 3
                    break;
                }
            } else {
                if (channel == (addr&7)) {
                    if (addr < 0x40) {
                        // Channel parameter
                        switch((addr-0x20) >> 3) {
                        case 0: // L:7 R:6 FB:5-3 ALG:2-0
                            v = data >> 6;
                            volumes[0] = (v) ? 0.5 : 0;
                            pan = (v==1) ? 128 : (v==2) ? 0 : 64;
                            fb  = (data >> 3) & 7;
                            alg = (data     ) & 7;
                            break;
                        case 1: // KC:6-0
                            break;
                        case 2: // KF:6-0
                            break;
                        case 3: // PMS:6-4 AMS:10
                            pms = (data >> 4) & 7;
                            ams = (data     ) & 3;
                            //pmd = (pms<6) ? (_pmd >> (6-pms)) : (_pmd << (pms-5));
                            //amd = (ams>0) ? (_amd << (ams-1)) : 0;
                            break;
                        }
                    } else {
                        // Operator parameter
                        opp = operatorParam[[3,1,2,0][(addr >> 3) & 3]]; // [0,2,1,3]?
                        switch((addr-0x40) >> 5) {
                        case 0: // DT1:6-4 MUL:3-0
                            opp.dt1 = (data >> 4) & 7;
                            opp.mul = (data     ) & 15;
                            break;
                        case 1: // TL:6-0
                            opp.tl = data & 127;
                            break;
                        case 2: // KS:76 AR:4-0
                            opp.ksr = (data >> 6) & 3;
                            opp.ar  = (data & 31) << 1;
                            break;
                        case 3: // AMS:7 DR:4-0
                            opp.ams = ((data >> 7) & 1)<<1;
                            opp.dr  = (data & 31) << 1;
                            break;
                        case 4: // DT2:76 SR:4-0
                            opp.detune = [0, 384, 500, 608][(data >> 6) & 3];
                            opp.sr     = (data & 31) << 1;
                            break;
                        case 5: // SL:7-4 RR:3-0
                            opp.sl = (data >> 4) & 15;
                            opp.rr = (data & 15) << 2;
                            break;
                        }
                    }
                }
            }
            return this;
        }
        
        
        /** Set voice by OPNA's register value */
        public function setByOPNARegister(addr:int, data:int) : SiOPMChannelParam {
            throw new Error("SiOPMChannelParam.setByOPNARegister(): Sorry, this function is not available.");
            return this;
        }
    }
}

