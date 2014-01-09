// Analog "LIKE" Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.SiOPMOperatorParam;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.channels.SiOPMChannelFM;
    import org.si.sound.SoundObject;
    
    
    /** Analog "LIKE" Synthesizer 
     */
    public class AnalogSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // constants
    //----------------------------------------
        /** nromal connection */
        static public const CONNECT_NORMAL:int = 0;
        /** ring connection */
        static public const CONNECT_RING:int = 1;
        /** sync connection */
        static public const CONNECT_SYNC:int = 2;
        
        /** wave shape number of saw wave */
        static public const SAW:int = SiOPMTable.PG_SAW_UP;
        /** wave shape number of square wave */
        static public const SQUARE:int = SiOPMTable.PG_SQUARE;
        /** wave shape number of triangle wave */
        static public const TRIANGLE:int = SiOPMTable.PG_TRIANGLE;
        /** wave shape number of sine wave */
        static public const SINE:int = SiOPMTable.PG_SINE;
        /** wave shape number of noise wave */
        static public const NOISE:int = SiOPMTable.PG_NOISE;
        
        
        
        
    // variables
    //----------------------------------------
        /** @private [protected] operator parameter for op0 */
        protected var _opp0:SiOPMOperatorParam;
        /** @private [protected] operator parameter for op1 */
        protected var _opp1:SiOPMOperatorParam;
        /** @private [protected] mixing balance of 2 oscillators.*/
        protected var _intBalance:int;
        
        
        
    // properties
    //----------------------------------------
        /** connection algorism of 2 oscillators */
        public function get con() : int { return _voice.channelParam.alg; }
        public function set con(c:int) : void {
            _voice.channelParam.alg = (c<0 || c>2) ? 0 : c;
            _voiceUpdateNumber++;
        }
        
        
        /** wave shape of 1st oscillator */
        public function get ws1() : int { return _opp0.pgType; }
        public function set ws1(ws:int) : void {
            _opp0.pgType = ws & SiOPMTable.PG_FILTER;
            _opp0.ptType = (ws == NOISE) ? SiOPMTable.PT_PCM : SiOPMTable.PT_OPM;
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    ch.operator[0].pgType = _opp0.pgType;
                    ch.operator[0].ptType = _opp0.ptType;
                }
            }
        }
        
        
        /** wave shape of 2nd oscillator */
        public function get ws2() : int { return _opp1.pgType; }
        public function set ws2(ws:int) : void {
            _opp1.pgType = ws & SiOPMTable.PG_FILTER;
            _opp1.ptType = (ws == NOISE) ? SiOPMTable.PT_PCM : SiOPMTable.PT_OPM;
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    ch.operator[1].pgType = _opp1.pgType;
                    ch.operator[1].ptType = _opp1.ptType;
                }
            }
        }
        
        
        /** mixing balance of 2 oscillators (0-1), 0=1st only, 0.5=same volume, 1=2nd only. */
        public function get balance() : Number { return (_intBalance+64) * 0.0078125; }
        public function set balance(b:Number) : void {
            _intBalance = int(b * 128) - 64;
            if (_intBalance > 64) _intBalance = 64;
            else if (_intBalance < -64) _intBalance = -64;
            var tltable:Vector.<int> = SiOPMTable.instance.eg_lv2tlTable;
            _opp0.tl = tltable[64-_intBalance];
            _opp1.tl = tltable[_intBalance+64];
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    ch.operator[0].tl = _opp0.tl;
                    ch.operator[1].tl = _opp1.tl;
                }
            }
        }
        
        
        /** pitch difference in osc1 and 2. 1 = halftone. */
        public function get vco2pitch() : Number { return (_opp1.detune - _opp0.detune) * 0.015625; }
        public function set vco2pitch(p:Number) : void {
            _opp1.detune = _opp0.detune + int(p * 64);
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    ch.operator[1].detune = _opp1.detune;
                }
            }
        }
        
        
        
        /** VCA attack time [0-1], This value is not linear. */
        override public function get attackTime() : Number { return (_opp0.ar > 48) ? 0 : (1 - _opp0.ar * 0.020833333333333332); }
        override public function set attackTime(n:Number) : void {
            _opp0.ar = (n == 0) ? 63 : ((1 - n) * 48);
            _voiceUpdateNumber++;
        }
        
        /** VCA decay time [0-1], This value is not linear. */
        public function get decayTime() : Number { return (_opp0.dr > 48) ? 0 : (1 - _opp0.dr * 0.020833333333333332); }
        public function set decayTime(n:Number) : void {
            _opp0.dr = (n == 0) ? 63 : ((1 - n) * 48);
            _voiceUpdateNumber++;
        }
        
        /** VCA sustain level [0-1], This value is not linear. */
        public function get sustainLevel() : Number { return (_opp0.sl==15) ? 0 : (1 - _opp0.sl * 0.06666666666666666); }
        public function set sustainLevel(n:Number) : void {
            _opp0.sl = (n == 0) ? 15 : ((1 - n) * 15);
            _voiceUpdateNumber++;
        }
        
        /** VCA release time [0-1], This value is not linear. */
        override public function get releaseTime() : Number { return (_opp0.rr > 48) ? 0 : (1 - _opp0.rr * 0.020833333333333332); }
        override public function set releaseTime(n:Number) : void {
            _opp0.rr = (n == 0) ? 63 : ((1 - n) * 48);
            _voiceUpdateNumber++;
        }
        
        
        /** @private */
        override public function get cutoff() : Number { return _voice.channelParam.fdc2 * 0.0078125; }
        override public function set cutoff(n:Number) : void {
            _voice.channelParam.fdc2 = n * 128;
            _voiceUpdateNumber++;
        }
        
        
        /** VCF attack time [0-1], This value is not linear. */
        public function get vcfAttackTime() : Number { return(1 - _voice.channelParam.far * 0.015873015873015872); }
        public function set vcfAttackTime(n:Number) : void { 
            _voice.channelParam.far =(1 - n) * 63;
            _voiceUpdateNumber++;
        }
        
        
        /** VCF decay time [0-1], This value is not linear. */
        public function get vcfDecayTime() : Number { return (1 - _voice.channelParam.fdr1 * 0.015873015873015872); }
        public function set vcfDecayTime(n:Number) : void { 
            _voice.channelParam.fdr1 = (1 - n) * 63;
            _voiceUpdateNumber++;
        }
        
        
        /** VCF peak cutoff [0-1]. */
        public function get vcfPeakCutoff() : Number { return _voice.channelParam.fdc1 * 0.0078125; }
        public function set vcfPeakCutoff(n:Number) : void { 
            _voice.channelParam.fdc1 = n * 128;
            _voiceUpdateNumber++;
        }
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param connectionType Connection type, 0=normal, 1=ring, 2=sync.
         *  @param ws1 Wave shape for osc1.
         *  @param ws2 Wave shape for osc2.
         *  @param balance mixing balance of 2 osccilators (0-1), 0=1st only, 0.5=same volume, 1=2nd only.
         *  @param vco2pitch pitch difference in osc1 and 2. 1 for halftone.
         */
        function AnalogSynth(connectionType:int=0, ws1:int=1, ws2:int=1, balance:Number=0.5, vco2pitch:Number=0.1)
        {
            super();
            _intBalance = int(balance * 128) - 64;
            if (_intBalance > 64) _intBalance = 64;
            else if (_intBalance < -64) _intBalance = -64;
            _voice.setAnalogLike(connectionType, ws1, ws2, _intBalance, vco2pitch*64);
            _opp0 = _voice.channelParam.operatorParam[0];
            _opp1 = _voice.channelParam.operatorParam[1];
            _voice.channelParam.cutoff = 0;
            _voice.channelParam.far = 63;
            _voice.channelParam.fdr1 = 63;
            _voice.channelParam.fdc1 = 128;
            _voice.channelParam.fdc2 = 128;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** set VCA envelope. This provide basic ADSR envelop.
         *  @param attackTime attack time [0-1]. This value is not linear.
         *  @param decayTime decay time [0-1]. This value is not linear.
         *  @param sustainLevel sustain level [0-1]. This value is not linear.
         *  @param releaseTime release time [0-1]. This value is not linear.
         *  @return this instance
         */
        public function setVCAEnvelop(attackTime:Number, decayTime:Number, sustainLevel:Number, releaseTime:Number) : AnalogSynth
        {
            _opp0.ar = (attackTime == 0) ? 63 : ((1 - attackTime) * 48);
            _opp0.dr = (decayTime == 0) ? 63 : ((1 - decayTime) * 48);
            _opp0.sr = 0;
            _opp0.rr = (releaseTime == 0) ? 63 : ((1 - releaseTime) * 48);
            _opp0.sl = (1 - sustainLevel) * 15;
            _voiceUpdateNumber++;
            return this;
        }
        
        
        /** set VCF envelope, This is a simplification of BasicSynth.setLPFEnvelop().
         *  @param cutoff cutoff frequency[0-1].
         *  @param resonanse resonanse[0-1].
         *  @param attackTime attack time [0-1]. This value is not linear.
         *  @param decayTime decay time [0-1]. This value is not linear.
         *  @param peakCutoff 
         *  @return this instance
         */
        public function setVCFEnvelop(cutoff:Number=1, resonance:Number=0, attackTime:Number=0, decayTime:Number=0, peakCutoff:Number=1) : AnalogSynth
        {
            setLPFEnvelop(0, resonance, ((1 - attackTime) * 63), ((1 - decayTime) * 63), 0, 0, peakCutoff, cutoff, cutoff, cutoff);
            return this;
        }
    }
}


