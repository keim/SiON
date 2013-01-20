// Operator instance of FMSynth
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.module.SiOPMOperatorParam;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
    
    
    /** Operator instance of FMSynth */
    public class FMSynthOperator
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // variables
    //----------------------------------------
        private var _owner:FMSynth;
        private var _opeIndex:int;
        private var _param:SiOPMOperatorParam;
        
        
        
        
    // properties
    //----------------------------------------
        /** WS; wave shape [0-512]. */
        public function get ws() : int { return _param.pgType; }
        public function set ws(i:int) : void {
            if (_param.pgType == i || i<0 || i>511) return;
            _param.setPGType(i);
            _owner._voiceUpdateNumber++;
        }
        
        
        /** AR; attack rate [0-63]. */
        public function get ar() : int { return _param.ar; }
        public function set ar(i:int) : void {
            if (_param.ar == i || i<0 || i>63) return;
            _param.ar = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** DR; decay rate [0-63]. */
        public function get dr() : int { return _param.dr; }
        public function set dr(i:int) : void {
            if (_param.dr == i || i<0 || i>63) return;
            _param.dr = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** SR; sustain rate [0-63]. */
        public function get sr() : int { return _param.sr; }
        public function set sr(i:int) : void {
            if (_param.sr == i || i<0 || i>63) return;
            _param.sr = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** RR; release rate [0-63]. */
        public function get rr() : int { return _param.rr; }
        public function set rr(i:int) : void {
            if (_param.rr == i || i<0 || i>63) return;
            _param.rr = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** SL; sustain level [0-15]. */
        public function get sl() : int { return _param.sl; }
        public function set sl(i:int) : void {
            if (_param.sl == i || i<0 || i>15) return;
            _param.sl = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** TL; total level [0-127]. */
        public function get tl() : int { return _param.tl; }
        public function set tl(i:int) : void {
            if (_param.tl == i || i<0 || i>127) return;
            _param.tl = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** KSR; sustain level [0-3]. */
        public function get ksr() : int { return _param.ksr; }
        public function set ksr(i:int) : void {
            if (_param.ksr == i || i<0 || i>3) return;
            _param.ksr = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** KSL; total level [0-3]. */
        public function get ksl() : int { return _param.ksl; }
        public function set ksl(i:int) : void {
            if (_param.ksl == i || i<0 || i>3) return;
            _param.ksl = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** MUL; multiple [0-15]. */
        public function get mul() : int { return _param.mul; }
        public function set mul(i:int) : void {
            if (_param.mul == i || i<0 || i>15) return;
            _param.mul = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** DT1; detune 1 (OPM/OPNA) [0-7]. */
        public function get dt1() : int { return _param.dt1; }
        public function set dt1(i:int) : void {
            if (_param.dt1 == i || i<0 || i>7) return;
            _param.dt1 = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** DT2; detune 2 (OPM) [0-3]. */
        public function get dt2() : int { 
                 if (_param.detune <= 100) return 0;   // 0
            else if (_param.detune <= 420) return 1;   // 384
            else if (_param.detune <= 550) return 2;   // 500
            return 3;                                  // 608
        }
        public function set dt2(i:int) : void {
            var dt2table:Array = [0, 384, 500, 608];
            if (_param.detune == i || i<0 || i>3) return;
            _param.detune = dt2table[i];
            _owner._voiceUpdateNumber++;
        }
        
        
        /** DET; detune (64 for 1halftone). */
        public function get det() : int { return _param.detune; }
        public function set det(i:int) : void {
            if (_param.detune == i) return;
            _param.detune = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** AMS; Amp modulation shift [0-3]. */
        public function get ams() : int { return _param.ams; }
        public function set ams(i:int) : void {
            if (_param.ams == i || i<0 || i>3) return;
            _param.ams = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** PH; Key on phase [0-255]. */
        public function get ph() : int { return _param.phase; }
        public function set ph(i:int) : void {
            if (_param.phase == i || i<0 || i>255) return;
            _param.phase = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** FN; fixed note [0-127]. */
        public function get fn() : int { return _param.fixedPitch>>6; }
        public function set fn(i:int) : void {
            var fp:int = i<<6;
            if (_param.fixedPitch == fp || i<0 || i>127) return;
            _param.fixedPitch = fp;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** mute; mute [t/f]. */
        public function get mute() : Boolean { return _param.mute; }
        public function set mute(b:Boolean) : void {
            if (_param.mute == b) return;
            _param.mute = b;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** SSGEC; SSG type envelop control [0-17]. */
        public function get ssgec() : int { return _param.ssgec; }
        public function set ssgec(i:int) : void {
            if (_param.ssgec == i || i<0 || i>17) return;
            _param.ssgec = i;
            _owner._voiceUpdateNumber++;
        }
        
        
        /** ERST; envelop reset on attack [t/f]. */
        public function get erst() : Boolean { return _param.erst; }
        public function set erst(b:Boolean) : void {
            if (_param.erst == b) return;
            _param.erst = b;
            _owner._voiceUpdateNumber++;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** Constructor, But you cannot create new instance of this class. */
        function FMSynthOperator(owner:FMSynth, opeIndex:int)
        {
            _owner = owner;
            _opeIndex = opeIndex;
            _param = owner.voice.channelParam.operatorParam[opeIndex];
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** Set all 15 FM parameters. The value of int.MIN_VALUE does not change.
         *  @param ar Attack rate [0-63].
         *  @param dr Decay rate [0-63].
         *  @param sr Sustain rate [0-63].
         *  @param rr Release rate [0-63].
         *  @param sl Sustain level [0-15].
         *  @param tl Total level [0-127].
         *  @param ksr Key scaling [0-3].
         *  @param ksl key scale level [0-3].
         *  @param mul Multiple [0-15].
         *  @param dt1 Detune 1 [0-7]. 
         *  @param detune Detune.
         *  @param ams Amplitude modulation shift [0-3].
         *  @param phase Phase [0-255].
         *  @param fixNote Fixed note number [0-127].
         */
        public function setAllParameters(ws:int, ar:int, dr:int, sr:int, rr:int, sl:int, tl:int, ksr:int, ksl:int, mul:int, dt1:int, detune:int, ams:int, phase:int, fixNote:int) : void
        {
            if (ws      != int.MIN_VALUE) _param.setPGType(ws&511);
            if (ar      != int.MIN_VALUE) _param.ar  = ar&63;
            if (dr      != int.MIN_VALUE) _param.dr  = dr&63;
            if (sr      != int.MIN_VALUE) _param.sr  = sr&63;
            if (rr      != int.MIN_VALUE) _param.rr  = rr&63;
            if (sl      != int.MIN_VALUE) _param.sl  = sl&15;
            if (tl      != int.MIN_VALUE) _param.tl  = tl&127;
            if (ksr     != int.MIN_VALUE) _param.ksr = ksr&3;
            if (ksl     != int.MIN_VALUE) _param.ksl = ksl&3;
            if (mul     != int.MIN_VALUE) _param.mul = mul&15;
            if (dt1     != int.MIN_VALUE) _param.dt1 = dt1&7;
            if (detune  != int.MIN_VALUE) _param.detune = detune;
            if (ams     != int.MIN_VALUE) _param.ams = ams&3;
            if (phase   != int.MIN_VALUE) _param.phase = phase&255;
            if (fixNote != int.MIN_VALUE) _param.fixedPitch = (fixNote&127)<<6;
            _owner._voiceUpdateNumber++;
        }
    }
}


