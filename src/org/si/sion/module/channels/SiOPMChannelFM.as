//----------------------------------------------------------------------------------------------------
// SiOPM FM channel.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module.channels {
    import org.si.sion.namespaces._sion_internal;
    import org.si.utils.SLLNumber;
    import org.si.utils.SLLint;
    import org.si.sion.module.*;
    
    
    /** FM sound channel. 
     *  <p>
     *  The calculation of this class is based on OPM emulation (refer from sources of mame, fmgen and x68sound).
     *  And it has some extension to simulate other sevral fm sound modules (OPNA, OPLL, OPL2, OPL3, OPX, MA3, MA5, MA7, TSS and DX7).
     *  <ul>
     *    <li>steleo output (from TSS,DX7)</li>
     *    <li>key scale level (from OPL3,OPX,MAx)</li>
     *    <li>phase select (from TSS)</li>
     *    <li>fixed frequency (from MAx)</li>
     *    <li>ssgec (from OPNA)</li>
     *    <li>wave shape select (from OPX,MAx,TSS)</li>
     *    <li>custom wave shape (from MAx)</li>
     *    <li>some more algolisms (from OPLx,OPX,MAx,DX7)</li>
     *    <li>decimal multiple (from p-TSS)</li>
     *    <li>feedback from op1-3 (from DX7)</li>
     *    <li>channel independet LFO (from TSS)</li>
     *    <li>low-pass filter envelop (from MAx)</li>
     *    <li>flexible fm connections (from TSS)</li>
     *    <li>ring modulation (from C64?)</li>
     *  </ul>
     *  </p>
     */
    public class SiOPMChannelFM extends SiOPMChannelBase
    {
    // constants
    //--------------------------------------------------
        static private const PROC_OP1:int = 0;
        static private const PROC_OP2:int = 1;
        static private const PROC_OP3:int = 2;
        static private const PROC_OP4:int = 3;
        static private const PROC_ANA:int = 4;
        static private const PROC_RNG:int = 5;
        static private const PROC_SYN:int = 6;
        static private const PROC_AFM:int = 7;
        static private const PROC_PCM:int = 8;

        
        
        
    // valiables
    //--------------------------------------------------
        /** eg_out threshold to check idling */ static _sion_internal var idlingThreshold:int = 5120; // = 256(resolution)*10(2^10=1024)*2(p/n) = volume<1/1024
        
        // Operators
        /** operators */        public var operator:Vector.<SiOPMOperator>;
        /** active operator */  public var activeOperator:SiOPMOperator;
        
        // Parameters
        /** count */        protected var _operatorCount:int;
        /** algorism */     protected var _algorism:int;
        
        // Processing
        /** process func */ protected var _funcProcessList:Array;
        /** process type */ protected var _funcProcessType:int;
        
        // Pipe
        /** internal pipe0 */ protected var _pipe0:SLLint;
        /** internal pipe1 */ protected var _pipe1:SLLint;
        
        // modulation
        /** am depth */         protected var _am_depth:int;    // = chip.amd<<(ams-1)
        /** am output level */  protected var _am_out:int;
        /** pm depth */         protected var _pm_depth:int;    // = chip.pmd<<(pms-1)
        /** pm output level */  protected var _pm_out:int;
        
        
        // tone generator setting
        /** ENV_TIMER_INITIAL * freq_ratio */  protected var _eg_timer_initial:int;
        /** LFO_TIMER_INITIAL * freq_ratio */  protected var _lfo_timer_initial:int;
        
        /** register map type */
        _sion_internal var registerMapType:int;
        _sion_internal var registerMapChannel:int;
        
        
        
    // toString
    //--------------------------------------------------
        /** Output parameters. */
        public function toString() : String
        {
            var str:String = "SiOPMChannelFM : operatorCount=";
            str += String(_operatorCount) + "\n";
            $("fb ", _inputLevel-6);
            $2("vol", _volumes[0],  "pan", _pan-64);
            if (operator[0]) str += String(operator[0]) + "\n";
            if (operator[1]) str += String(operator[1]) + "\n";
            if (operator[2]) str += String(operator[2]) + "\n";
            if (operator[3]) str += String(operator[3]) + "\n";
            return str;
            function $ (p:String, i:*) : void { str += "  " + p + "=" + String(i) + "\n"; }
            function $2(p:String, i:*, q:String, j:*) : void { str += "  " + p + "=" + String(i) + " / " + q + "=" + String(j) + "\n"; }
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function SiOPMChannelFM(chip:SiOPMModule)
        {
            super(chip);
            
            _funcProcessList = [[_proc1op_loff, _proc2op, _proc3op, _proc4op, _proc2ana, _procring, _procsync, _proc2op, _procpcm_loff], 
                                [_proc1op_lon,  _proc2op, _proc3op, _proc4op, _proc2ana, _procring, _procsync, _proc2op, _procpcm_lon]];
            operator = new Vector.<SiOPMOperator>(4, true);
            operator[0] = _allocFMOperator();
            operator[1] = null;
            operator[2] = null;
            operator[3] = null;
            activeOperator = operator[0];
            
            _operatorCount = 1;
            _funcProcessType = PROC_OP1;
            _funcProcess = _proc1op_loff;
            
            _pipe0 = SLLint.allocRing(1);
            _pipe1 = SLLint.allocRing(1);
            
            initialize(null, 0);
        }
        
        
        
        
    // Chip settings
    //--------------------------------------------------
        /** set chip "PSEUDO" frequency ratio by [%]. 100 means 3.56MHz. This value effects only for envelop and lfo speed. */
        override public function setFrequencyRatio(ratio:int) : void
        {
            _freq_ratio = ratio;
            var r:Number = (ratio!=0) ? (100/ratio) : 1;
            _eg_timer_initial  = int(SiOPMTable.ENV_TIMER_INITIAL * r);
            _lfo_timer_initial = int(SiOPMTable.LFO_TIMER_INITIAL * r);
        }
        
        
        
        
    // LFO settings
    //--------------------------------------------------
        /** initialize low frequency oscillator. and stop lfo
         *  @param waveform LFO waveform. 0=saw, 1=pulse, 2=triangle, 3=noise. -1 to set customized wave table
         *  @param customWaveTable customized wave table, the length is 256 and the values are limited in the range of 0-255. This argument is available when waveform=-1.
         */
        override public function initializeLFO(waveform:int, customWaveTable:Vector.<int>=null) : void
        {
            super.initializeLFO(waveform, customWaveTable);
            _lfoSwitch(false);
            _am_depth = 0;
            _pm_depth = 0;
            _am_out = 0;
            _pm_out = 0;
            if (operator[0]) operator[0].detune2 = 0;
            if (operator[1]) operator[1].detune2 = 0;
            if (operator[2]) operator[2].detune2 = 0;
            if (operator[3]) operator[3].detune2 = 0;
        }
        
        
        /** Amplitude modulation.
         *  @param depth depth = (ams) ? (amd &lt;&lt; (ams-1)) : 0;
         */
        override public function setAmplitudeModulation(depth:int) : void
        {
            _am_depth = depth<<2;
            _am_out = (_lfo_waveTable[_lfo_phase] * _am_depth) >> 7 << 3;
            _lfoSwitch(_pm_depth != 0 || _am_depth > 0);
        }
        
        
        /** Pitch modulation.
         *  @param depth depth = (pms&lt;6) ? (pmd &gt;&gt; (6-pms)) : (pmd &lt;&lt; (pms-5));
         */
        override public function setPitchModulation(depth:int) : void
        {
            _pm_depth = depth;
            _pm_out = (((_lfo_waveTable[_lfo_phase]<<1)-255) * _pm_depth) >> 8;
            _lfoSwitch(_pm_depth != 0 || _am_depth > 0);
            if (_pm_depth == 0) {
                if (operator[0]) operator[0].detune2 = 0;
                if (operator[1]) operator[1].detune2 = 0;
                if (operator[2]) operator[2].detune2 = 0;
                if (operator[3]) operator[3].detune2 = 0;
            }
        }
        
        
        /** @private [protected] lfo on/off */
        protected function _lfoSwitch(sw:Boolean) : void
        {
            _lfo_on = int(sw);
            _funcProcess = _funcProcessList[_lfo_on][_funcProcessType];
            _lfo_timer_step = (sw) ? _lfo_timer_step_ : 0;
        }
        
        
        
        
    // parameter setting
    //--------------------------------------------------
        /** Set by SiOPMChannelParam. 
         *  @param param SiOPMChannelParam.
         *  @param withVolume Set volume when its true.
         *  @param withModulation Set modulation when its true.
         */
        override public function setSiOPMChannelParam(param:SiOPMChannelParam, withVolume:Boolean, withModulation:Boolean=true) : void
        {
            var i:int;
            if (param.opeCount == 0) return;
            
            if (withVolume) {
                var imax:int = SiOPMModule.STREAM_SEND_SIZE;
                for (i=0; i<imax; i++) _volumes[i] = param.volumes[i];
                for (_hasEffectSend=false, i=1; i<imax; i++) if (_volumes[i] > 0) _hasEffectSend = true;
                _pan = param.pan;
            }
            setFrequencyRatio(param.fratio);
            setAlgorism(param.opeCount, param.alg);
            setFeedBack(param.fb, param.fbc);
            if (withModulation) {
                initializeLFO(param.lfoWaveShape);
                _lfo_timer = (param.lfoFreqStep>0) ? 1 : 0;
                _lfo_timer_step_ = _lfo_timer_step = param.lfoFreqStep;
                setAmplitudeModulation(param.amd);
                setPitchModulation(param.pmd);
            }
            filterType = param.filterType;
            setSVFilter(param.cutoff, param.resonance, param.far, param.fdr1, param.fdr2, param.frr, param.fdc1, param.fdc2, param.fsc, param.frc);
            for (i=0; i<_operatorCount; i++) {
                operator[i].setSiOPMOperatorParam(param.operatorParam[i]);
            }
        }
        
        
        /** Get SiOPMChannelParam.
         *  @param param SiOPMChannelParam.
         */
        override public function getSiOPMChannelParam(param:SiOPMChannelParam) : void
        {
            var i:int, imax:int = SiOPMModule.STREAM_SEND_SIZE;
            for (i=0; i<imax; i++) param.volumes[i] = _volumes[i];
            param.pan = _pan;
            param.fratio = _freq_ratio;
            param.opeCount = _operatorCount;
            param.alg = _algorism;
            param.fb = 0;
            param.fbc = 0;
            for (i=0; i<_operatorCount; i++) {
                if (_inPipe == operator[i]._feedPipe) {
                    param.fb = _inputLevel - 6;
                    param.fbc = i;
                    break;
                }
            }
            param.lfoWaveShape = _lfo_waveShape;
            param.lfoFreqStep  = _lfo_timer_step_;
            param.amd = _am_depth;
            param.pmd = _pm_depth;
            for (i=0; i<_operatorCount; i++) {
                operator[i].getSiOPMOperatorParam(param.operatorParam[i]);
            }
        }
        
        
        /** Set sound by 14 basic params. The value of int.MIN_VALUE means not to change.
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
        public function setSiOPMParameters(ar:int, dr:int, sr:int, rr:int, sl:int, tl:int, ksr:int, ksl:int, mul:int, dt1:int, detune:int, ams:int, phase:int, fixNote:int) : void
        {
            var ope:SiOPMOperator = activeOperator;
            if (ar      != int.MIN_VALUE) ope.ar  = ar;
            if (dr      != int.MIN_VALUE) ope.dr  = dr;
            if (sr      != int.MIN_VALUE) ope.sr  = sr;
            if (rr      != int.MIN_VALUE) ope.rr  = rr;
            if (sl      != int.MIN_VALUE) ope.sl  = sl;
            if (tl      != int.MIN_VALUE) ope.tl  = tl;
            if (ksr     != int.MIN_VALUE) ope.ks  = ksr;
            if (ksl     != int.MIN_VALUE) ope.ksl = ksl;
            if (mul     != int.MIN_VALUE) ope.mul = mul;
            if (dt1     != int.MIN_VALUE) ope.dt1 = dt1;
            if (detune  != int.MIN_VALUE) ope.detune = detune;
            if (ams     != int.MIN_VALUE) ope.ams = ams;
            if (phase   != int.MIN_VALUE) ope.keyOnPhase = phase;
            if (fixNote != int.MIN_VALUE) ope.fixedPitchIndex = fixNote<<6;
        }
        
        
        /** Set wave data. 
         *  @param pcmData SiOPMWavePCMTable to set.
         */
        override public function setWaveData(waveData:SiOPMWaveBase) : void
        {
            var pcmData:SiOPMWavePCMData = waveData as SiOPMWavePCMData;
            if (waveData is SiOPMWavePCMTable) pcmData = (waveData as SiOPMWavePCMTable)._siopm_module_internal::_table[60];
            
            if (pcmData && pcmData.wavelet) {
                _updateOperatorCount(1);
                _funcProcessType = PROC_PCM;
                _funcProcess = _funcProcessList[_lfo_on][_funcProcessType];
                activeOperator.setPCMData(pcmData);
                erst = true;
            } else 
            if (waveData is SiOPMWaveTable) {
                var waveTable:SiOPMWaveTable = waveData as SiOPMWaveTable;
                if (waveTable.wavelet) {
                    operator[0].setWaveTable(waveTable);
                    if (operator[1]) operator[1].setWaveTable(waveTable);
                    if (operator[2]) operator[2].setWaveTable(waveTable);
                    if (operator[3]) operator[3].setWaveTable(waveTable);
                }
            }
        }
        
        
        /** set channel number (2nd argument of %) */
        override public function setChannelNumber(channelNum:int) : void 
        {
            _sion_internal::registerMapChannel = channelNum;
        }
        
        
        /** set register */
        override public function setRegister(addr:int, data:int) : void
        {
            switch(_sion_internal::registerMapType) {
            case 0:
                _setByOPMRegister(addr, data);
                break;
            case 1: 
            default:
                _setBy2A03Register(addr, data);
                break;
            }
        }
        
        
        // 2A03 register value
        private function _setBy2A03Register(addr:int, data:int) : void
        {
        }
        
        
        // OPM register value
        private var _pmd:int=0, _amd:int=0;
        private function _setByOPMRegister(addr:int, data:int) : void
        {
            var i:int, v:int, pms:int, ams:int, op:SiOPMOperator, 
                channel:int = _sion_internal::registerMapChannel;
            
            if (addr < 0x20) {  // Module parameter
                switch(addr) {
                case 15: // NOIZE:7 FREQ:4-0 for channel#7
                    if (channel == 7 && _operatorCount==4 && (data & 128) != 0) {
                        operator[3].pgType = SiOPMTable.PG_NOISE_PULSE;
                        operator[3].ptType = SiOPMTable.PT_OPM_NOISE;
                        operator[3].pitchIndex = ((data & 31) << 6) + 2048;
                    }
                    break;
                case 24: // LFO FREQ:7-0 for all 8 channels
                    v = _table.lfo_timerSteps[data];
                    _lfo_timer = (v>0) ? 1 : 0;
                    _lfo_timer_step_ = _lfo_timer_step = v;
                    break;
                case 25: // A(0)/P(1):7 DEPTH:6-0 for all 8 channels
                    if (data & 128) _amd = data & 127;
                    else            _pmd = data & 127;
                    break;
                case 27: // LFO WS:10 for all 8 channels
                    initializeLFO(data & 3);
                    break;
                }
            } else {
                if (channel == (addr&7)) {
                    if (addr < 0x40) {
                        // Channel parameter
                        switch((addr-0x20) >> 3) {
                        case 0: // L:7 R:6 FB:5-3 ALG:2-0
                            v = data >> 6;
                            setAlgorism(4, data & 7);
                            setFeedBack((data >> 3) & 7, 0);
                            _volumes[0] = (v) ? 0.5 : 0;
                            _pan = (v==1) ? 128 : (v==2) ? 0 : 64;
                            break;
                        case 1: // KC:6-0
                            for (i=0; i<4; i++) operator[i].kc = data & 127;
                            break;
                        case 2: // KF:6-0
                            for (i=0; i<4; i++) operator[i].kf = data & 127;
                            break;
                        case 3: // PMS:6-4 AMS:10
                            pms = (data >> 4) & 7;
                            ams = (data     ) & 3;
                            if (data & 128) setPitchModulation((pms<6) ? (_pmd >> (6-pms)) : (_pmd << (pms-5)));
                            else            setAmplitudeModulation((ams>0) ? (_amd << (ams-1)) : 0);
                            break;
                        }
                    } else {
                        // Operator parameter
                        op = operator[[0,2,1,3][(addr >> 3) & 3]]; // [3,1,2,0]
                        switch((addr-0x40) >> 5) {
                        case 0: // DT1:6-4 MUL:3-0
                            op.dt1 = (data >> 4) & 7;
                            op.mul = (data     ) & 15;
                            break;
                        case 1: // TL:6-0
                            op.tl = data & 127;
                            break;
                        case 2: // KS:76 AR:4-0
                            op.ks = (data >> 6) & 3;
                            op.ar = (data & 31) << 1;
                            break;
                        case 3: // AMS:7 DR:4-0
                            op.ams = ((data >> 7) & 1)<<1;
                            op.dr  = (data & 31) << 1;
                            break;
                        case 4: // DT2:76 SR:4-0
                            op.detune = [0, 384, 500, 608][(data >> 6) & 3];
                            op.sr     = (data & 31) << 1;
                            break;
                        case 5: // SL:7-4 RR:3-0
                            op.sl = (data >> 4) & 15;
                            op.rr = (data & 15) << 2;
                            break;
                        }
                    }
                }
            }
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** Set algorism (&#64;al) 
         *  @param cnt Operator count.
         *  @param alg Algolism number of the operator's connection.
         */
        override public function setAlgorism(cnt:int, alg:int) : void
        {
            switch (cnt) {
            case 2:  _algorism2(alg);  break;
            case 3:  _algorism3(alg);  break;
            case 4:  _algorism4(alg);  break;
            case 5:  _analog(alg);     break;
            default: _algorism1(alg);  break;
            }
        }
        
        
        /** Set feedback(&#64;fb). This also initializes the input mode(&#64;i). 
         *  @param fb Feedback level. Ussualy in the range of 0-7.
         *  @param fbc Feedback connection. Operator index which feeds back its output.
         */
        override public function setFeedBack(fb:int, fbc:int) : void
        {
            if (fb > 0) {
                // connect feedback pipe
                if (fbc < 0 || fbc >= _operatorCount) fbc = 0;
                _inPipe = operator[fbc]._feedPipe;
                _inPipe.i = 0;
                _inputLevel = fb + 6;
                _inputMode = INPUT_FEEDBACK;
            } else {
                // no feedback
                _inPipe = _chip.zeroBuffer;
                _inputLevel = 0;
                _inputMode = INPUT_ZERO;
            }
            
        }
        
        
        /** Set parameters (&#64; command). */
        override public function setParameters(param:Vector.<int>) : void
        {
            setSiOPMParameters(param[1],  param[2],  param[3],  param[4],  param[5], 
                               param[6],  param[7],  param[8],  param[9],  param[10], 
                               param[11], param[12], param[13], param[14]);
        }
        
        
        /** pgType and ptType (&#64;) */
        override public function setType(pgType:int, ptType:int) : void
        {
            if (pgType >= SiOPMTable.PG_PCM) {
                var pcm:SiOPMWavePCMTable = _table.getPCMData(pgType-SiOPMTable.PG_PCM);
                // the ptType is set by setWaveData()
                if (pcm) setWaveData(pcm);
            } else {
                activeOperator.pgType = pgType;
                activeOperator.ptType = ptType;
                _funcProcess = _funcProcessList[_lfo_on][_funcProcessType];
            }
        }
        
        
        /** Attack rate */
        override public function setAllAttackRate(ar:int) : void 
        {
            var i:int, ope:SiOPMOperator;
            for (i=0; i<_operatorCount; i++) {
                ope = operator[i];
                if (ope._final) ope.ar = ar;
            }
        }
        
        
        /** Release rate (s) */
        override public function setAllReleaseRate(rr:int) : void 
        {
            var i:int, ope:SiOPMOperator;
            for (i=0; i<_operatorCount; i++) {
                ope = operator[i];
                if (ope._final) ope.rr = rr;
            }
        }
        
        
    // interfaces
    //--------------------------------------------------
        /** pitch = (note &lt;&lt; 6) | (kf &amp; 63) [0,8191] */
        override public function get pitch() : int { return operator[_operatorCount-1].pitchIndex; }
        override public function set pitch(p:int) : void {
            for (var i:int=0; i<_operatorCount; i++) {
                operator[i].pitchIndex = p;
            }
        }
        
        /** active operator index (i) */
        override public function set activeOperatorIndex(i:int) : void {
            var opeIndex:int = (i<0) ? 0 : (i>=_operatorCount) ? (_operatorCount-1) : i;
            activeOperator = operator[opeIndex];
        }
        
        /** release rate (&#64;rr) */
        override public function set rr(i:int) : void { activeOperator.rr = i; }
        
        /** total level (&#64;tl) */
        override public function set tl(i:int) : void { activeOperator.tl = i; }
        
        /** fine multiple (&#64;ml) */
        override public function set fmul(i:int) : void { activeOperator.fmul = i; }
        
        /** phase  (&#64;ph) */
        override public function set phase(i:int) : void { activeOperator.keyOnPhase = i; }
        
        /** detune (&#64;dt) */
        override public function set detune(i:int) : void { activeOperator.detune = i; }
        
        /** fixed pitch (&#64;fx) */
        override public function set fixedPitch(i:int) : void { activeOperator.fixedPitchIndex = i; }
        
        /** ssgec (&#64;se) */
        override public function set ssgec(i:int) : void { activeOperator.ssgec = i; }
        
        /** envelop reset (&#64;er) */
        override public function set erst(b:Boolean) : void {
            for (var i:int=0; i<_operatorCount; i++) operator[i].erst = b;
        }
        
        
        
        
    // volume controls
    //--------------------------------------------------
        /** update all tl offsets of final carriors */
        override public function offsetVolume(expression:int, velocity:int) : void
        {
            var i:int, ope:SiOPMOperator, tl:int, x:int = expression<<1;
            tl = _expressionTable[x] + _veocityTable[velocity];
            for (i=0; i<_operatorCount; i++) {
                ope = operator[i];
                if (ope._final) ope._tlOffset(tl);
                else ope._tlOffset(0);
            }
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Initialize. */
        override public function initialize(prev:SiOPMChannelBase, bufferIndex:int) : void
        {
            // initialize operators
            _updateOperatorCount(1);
            operator[0].initialize();
            _isNoteOn = false;
            _sion_internal::registerMapType = 0
            _sion_internal::registerMapChannel = 0;
            
            // initialize sound channel
            super.initialize(prev, bufferIndex);
        }
        
        
        /** Reset. */
        override public function reset() : void
        {
            // reset all operators
            for (var i:int=0; i<_operatorCount; i++) {
                operator[i].reset();
            }
            _isNoteOn = false;
            _isIdling = true;
        }
        
        
        /** Note on. */
        override public function noteOn() : void
        {
            // operator note on
            for (var i:int=0; i<_operatorCount; i++) {
                operator[i].noteOn();
            }
            _isNoteOn = true;
            _isIdling = false;
            super.noteOn();
        }
        
        
        /** Note off. */
        override public function noteOff() : void
        {
            // operator note off
            for (var i:int=0; i<_operatorCount; i++) {
                operator[i].noteOff();
            }
            _isNoteOn = false;
            super.noteOff();
        }
        
        
        /** Prepare buffering */
        override public function resetChannelBufferStatus() : void
        {
            _bufferIndex = 0;
            
            // check idling flag
            var i:int, ope:SiOPMOperator;
            _isIdling = true;
            for (i=0; i<_operatorCount; i++) {
                ope = operator[i];
                if (ope._final && (ope._eg_out < _sion_internal::idlingThreshold || ope._eg_state == SiOPMOperator.EG_ATTACK)) {
                    _isIdling = false;
                    break;
                }
            }
        }
        
        
        
        
    //====================================================================================================
    // Internal uses
    //====================================================================================================
    // processing operator x1
    //--------------------------------------------------
        // without lfo_update()
        private function _proc1op_loff(len:int) : void
        {
            var t:int, l:int, i:int, n:Number;
            var ope:SiOPMOperator = operator[0],
                log:Vector.<int> = _table.logTable,
                phase_filter:int = SiOPMTable.PHASE_FILTER;

            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // eg_update();
                //----------------------------------------
                ope._eg_timer -= ope._eg_timer_step;
                if (ope._eg_timer < 0) {
                    if (ope._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope._eg_incTable[ope._eg_counter];
                        if (t > 0) {
                            ope._eg_level -= 1 + (ope._eg_level >> t);
                            if (ope._eg_level <= 0) ope._eg_shiftState(ope._eg_nextState[ope._eg_state]);
                        }
                    } else {
                        ope._eg_level += ope._eg_incTable[ope._eg_counter];
                        if (ope._eg_level >= ope._eg_stateShiftLevel) ope._eg_shiftState(ope._eg_nextState[ope._eg_state]);
                    }
                    ope._eg_out = (ope._eg_levelTable[ope._eg_level] + ope._eg_total_level)<<3;
                    ope._eg_counter = (ope._eg_counter+1)&7;
                    ope._eg_timer += _eg_timer_initial;
                }

                // pg_update();
                //----------------------------------------
                ope._phase += ope._phase_step;
                t = ((ope._phase + (ip.i<<_inputLevel)) & phase_filter) >> ope._waveFixedBits;
                l = ope._waveTable[t];
                l += ope._eg_out;
                t = log[l];
                ope._feedPipe.i = t;
                
                // output and increment pointers
                //----------------------------------------
                op.i = t + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }

            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        
        // with lfo_update()
        private function _proc1op_lon(len:int) : void
        {
            var t:int, l:int, i:int, n:Number;
            var ope:SiOPMOperator = operator[0],
                log:Vector.<int> = _table.logTable,
                phase_filter:int = SiOPMTable.PHASE_FILTER;

            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;

            for (i=0; i<len; i++) {
                // lfo_update();
                //----------------------------------------
                _lfo_timer -= _lfo_timer_step;
                if (_lfo_timer < 0) {
                    _lfo_phase = (_lfo_phase+1) & 255;
                    t = _lfo_waveTable[_lfo_phase];
                    _am_out = (t * _am_depth) >> 7 << 3;
                    _pm_out = (((t<<1)-255) * _pm_depth) >> 8;
                    ope.detune2 = _pm_out;
                    _lfo_timer += _lfo_timer_initial;
                }
                
                // eg_update();
                //----------------------------------------
                ope._eg_timer -= ope._eg_timer_step;
                if (ope._eg_timer < 0) {
                    if (ope._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope._eg_incTable[ope._eg_counter];
                        if (t > 0) {
                            ope._eg_level -= 1 + (ope._eg_level >> t);
                            if (ope._eg_level <= 0) ope._eg_shiftState(ope._eg_nextState[ope._eg_state]);
                        }
                    } else {
                        ope._eg_level += ope._eg_incTable[ope._eg_counter];
                        if (ope._eg_level >= ope._eg_stateShiftLevel) ope._eg_shiftState(ope._eg_nextState[ope._eg_state]);
                    }
                    ope._eg_out = (ope._eg_levelTable[ope._eg_level] + ope._eg_total_level)<<3;
                    ope._eg_counter = (ope._eg_counter+1)&7;
                    ope._eg_timer += _eg_timer_initial;
                }

                // pg_update();
                //----------------------------------------
                ope._phase += ope._phase_step;
                t = ((ope._phase + (ip.i<<_inputLevel)) & phase_filter) >> ope._waveFixedBits;
                l = ope._waveTable[t];
                l += ope._eg_out + (_am_out>>ope._ams);
                t = log[l];
                ope._feedPipe.i = t;
                
                // output and increment pointers
                //----------------------------------------
                op.i = t + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        
        
        
    // processing operator x2
    //--------------------------------------------------
        // This inline expansion makes execution faster.
        private function _proc2op(len:int) : void
        {
            var i:int, t:int, l:int, n:Number;
            var phase_filter:int = SiOPMTable.PHASE_FILTER,
                log:Vector.<int> = _table.logTable,
                ope0:SiOPMOperator = operator[0],
                ope1:SiOPMOperator = operator[1];
            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // clear pipes
                //----------------------------------------
                _pipe0.i = 0;

                // lfo
                //----------------------------------------
                _lfo_timer -= _lfo_timer_step;
                if (_lfo_timer < 0) {
                    _lfo_phase = (_lfo_phase+1) & 255;
                    t = _lfo_waveTable[_lfo_phase];
                    _am_out = (t * _am_depth) >> 7 << 3;
                    _pm_out = (((t<<1)-255) * _pm_depth) >> 8;
                    ope0.detune2 = _pm_out;
                    ope1.detune2 = _pm_out;
                    _lfo_timer += _lfo_timer_initial;
                }
                
                // operator[0]
                //----------------------------------------
                // eg_update();
                ope0._eg_timer -= ope0._eg_timer_step;
                if (ope0._eg_timer < 0) {
                    if (ope0._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope0._eg_incTable[ope0._eg_counter];
                        if (t > 0) {
                            ope0._eg_level -= 1 + (ope0._eg_level >> t);
                            if (ope0._eg_level <= 0) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                        }
                    } else {
                        ope0._eg_level += ope0._eg_incTable[ope0._eg_counter];
                        if (ope0._eg_level >= ope0._eg_stateShiftLevel) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                    }
                    ope0._eg_out = (ope0._eg_levelTable[ope0._eg_level] + ope0._eg_total_level)<<3;
                    ope0._eg_counter = (ope0._eg_counter+1)&7;
                    ope0._eg_timer += _eg_timer_initial;
                }
                // pg_update();
                ope0._phase += ope0._phase_step;
                t = ((ope0._phase + (ip.i<<_inputLevel)) & phase_filter) >> ope0._waveFixedBits;
                l = ope0._waveTable[t];
                l += ope0._eg_out + (_am_out>>ope0._ams);
                t = log[l];
                ope0._feedPipe.i = t;
                ope0._outPipe.i  = t + ope0._basePipe.i;

                // operator[1]
                //----------------------------------------
                // eg_update();
                ope1._eg_timer -= ope1._eg_timer_step;
                if (ope1._eg_timer < 0) {
                    if (ope1._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope1._eg_incTable[ope1._eg_counter];
                        if (t > 0) {
                            ope1._eg_level -= 1 + (ope1._eg_level >> t);
                            if (ope1._eg_level <= 0) ope1._eg_shiftState(ope1._eg_nextState[ope1._eg_state]);
                        }
                    } else {
                        ope1._eg_level += ope1._eg_incTable[ope1._eg_counter];
                        if (ope1._eg_level >= ope1._eg_stateShiftLevel) ope1._eg_shiftState(ope1._eg_nextState[ope1._eg_state]);
                    }
                    ope1._eg_out = (ope1._eg_levelTable[ope1._eg_level] + ope1._eg_total_level)<<3;
                    ope1._eg_counter = (ope1._eg_counter+1)&7;
                    ope1._eg_timer += _eg_timer_initial;
                }
                // pg_update();
                ope1._phase += ope1._phase_step;
                t = ((ope1._phase + (ope1._inPipe.i<<ope1._fmShift)) & phase_filter) >> ope1._waveFixedBits;
                l = ope1._waveTable[t];
                l += ope1._eg_out + (_am_out>>ope1._ams);
                t = log[l];
                ope1._feedPipe.i = t;
                ope1._outPipe.i  = t + ope1._basePipe.i;

                // output and increment pointers
                //----------------------------------------
                op.i = _pipe0.i + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        
        
        
    // processing operator x3
    //--------------------------------------------------
        // This inline expansion makes execution faster.
        private function _proc3op(len:int) : void
        {
            var i:int, t:int, l:int, n:Number;
            var phase_filter:int = SiOPMTable.PHASE_FILTER,
                log:Vector.<int> = _table.logTable,
                ope0:SiOPMOperator = operator[0],
                ope1:SiOPMOperator = operator[1],
                ope2:SiOPMOperator = operator[2];
            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // clear pipes
                //----------------------------------------
                _pipe0.i = 0;
                _pipe1.i = 0;

                // lfo
                //----------------------------------------
                _lfo_timer -= _lfo_timer_step;
                if (_lfo_timer < 0) {
                    _lfo_phase = (_lfo_phase+1) & 255;
                    t = _lfo_waveTable[_lfo_phase];
                    _am_out = (t * _am_depth) >> 7 << 3;
                    _pm_out = (((t<<1)-255) * _pm_depth) >> 8;
                    ope0.detune2 = _pm_out;
                    ope1.detune2 = _pm_out;
                    ope2.detune2 = _pm_out;
                    _lfo_timer += _lfo_timer_initial;
                }
                
                // operator[0]
                //----------------------------------------
                // eg_update();
                ope0._eg_timer -= ope0._eg_timer_step;
                if (ope0._eg_timer < 0) {
                    if (ope0._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope0._eg_incTable[ope0._eg_counter];
                        if (t > 0) {
                            ope0._eg_level -= 1 + (ope0._eg_level >> t);
                            if (ope0._eg_level <= 0) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                        }
                    } else {
                        ope0._eg_level += ope0._eg_incTable[ope0._eg_counter];
                        if (ope0._eg_level >= ope0._eg_stateShiftLevel) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                    }
                    ope0._eg_out = (ope0._eg_levelTable[ope0._eg_level] + ope0._eg_total_level)<<3;
                    ope0._eg_counter = (ope0._eg_counter+1)&7;
                    ope0._eg_timer += _eg_timer_initial;
                }
                // pg_update();
                ope0._phase += ope0._phase_step;
                t = ((ope0._phase + (ip.i<<_inputLevel)) & phase_filter) >> ope0._waveFixedBits;
                l = ope0._waveTable[t];
                l += ope0._eg_out + (_am_out>>ope0._ams);
                t = log[l];
                ope0._feedPipe.i = t;
                ope0._outPipe.i  = t + ope0._basePipe.i;

                // operator[1]
                //----------------------------------------
                // eg_update();
                ope1._eg_timer -= ope1._eg_timer_step;
                if (ope1._eg_timer < 0) {
                    if (ope1._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope1._eg_incTable[ope1._eg_counter];
                        if (t > 0) {
                            ope1._eg_level -= 1 + (ope1._eg_level >> t);
                            if (ope1._eg_level <= 0) ope1._eg_shiftState(ope1._eg_nextState[ope1._eg_state]);
                        }
                    } else {
                        ope1._eg_level += ope1._eg_incTable[ope1._eg_counter];
                        if (ope1._eg_level >= ope1._eg_stateShiftLevel) ope1._eg_shiftState(ope1._eg_nextState[ope1._eg_state]);
                    }
                    ope1._eg_out = (ope1._eg_levelTable[ope1._eg_level] + ope1._eg_total_level)<<3;
                    ope1._eg_counter = (ope1._eg_counter+1)&7;
                    ope1._eg_timer += _eg_timer_initial;
                }
                // pg_update();
                ope1._phase += ope1._phase_step;
                t = ((ope1._phase + (ope1._inPipe.i<<ope1._fmShift)) & phase_filter) >> ope1._waveFixedBits;
                l = ope1._waveTable[t];
                l += ope1._eg_out + (_am_out>>ope1._ams);
                t = log[l];
                ope1._feedPipe.i = t;
                ope1._outPipe.i  = t + ope1._basePipe.i;

                // operator[2]
                //----------------------------------------
                // eg_update();
                ope2._eg_timer -= ope2._eg_timer_step;
                if (ope2._eg_timer < 0) {
                    if (ope2._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope2._eg_incTable[ope2._eg_counter];
                        if (t > 0) {
                            ope2._eg_level -= 1 + (ope2._eg_level >> t);
                            if (ope2._eg_level <= 0) ope2._eg_shiftState(ope2._eg_nextState[ope2._eg_state]);
                        }
                    } else {
                        ope2._eg_level += ope2._eg_incTable[ope2._eg_counter];
                        if (ope2._eg_level >= ope2._eg_stateShiftLevel) ope2._eg_shiftState(ope2._eg_nextState[ope2._eg_state]);
                    }
                    ope2._eg_out = (ope2._eg_levelTable[ope2._eg_level] + ope2._eg_total_level)<<3;
                    ope2._eg_counter = (ope2._eg_counter+1)&7;
                    ope2._eg_timer += _eg_timer_initial;
                }
                // pg_update();
                ope2._phase += ope2._phase_step;
                t = ((ope2._phase + (ope2._inPipe.i<<ope2._fmShift)) & phase_filter) >> ope2._waveFixedBits;
                l = ope2._waveTable[t];
                l += ope2._eg_out + (_am_out>>ope2._ams);
                t = log[l];
                ope2._feedPipe.i = t;
                ope2._outPipe.i  = t + ope2._basePipe.i;

                // output and increment pointers
                //----------------------------------------
                op.i = _pipe0.i + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        
        
        
    // processing operator x4
    //--------------------------------------------------
        // This inline expansion makes execution faster.
        private function _proc4op(len:int) : void
        {
            var i:int, t:int, l:int, n:Number;
            var phase_filter:int = SiOPMTable.PHASE_FILTER,
                log:Vector.<int> = _table.logTable,
                ope0:SiOPMOperator = operator[0],
                ope1:SiOPMOperator = operator[1],
                ope2:SiOPMOperator = operator[2],
                ope3:SiOPMOperator = operator[3];
            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // clear pipes
                //----------------------------------------
                _pipe0.i = 0;
                _pipe1.i = 0;

                // lfo
                //----------------------------------------
                _lfo_timer -= _lfo_timer_step;
                if (_lfo_timer < 0) {
                    _lfo_phase = (_lfo_phase+1) & 255;
                    t = _lfo_waveTable[_lfo_phase];
                    _am_out = (t * _am_depth) >> 7 << 3;
                    _pm_out = (((t<<1)-255) * _pm_depth) >> 8;
                    ope0.detune2 = _pm_out;
                    ope1.detune2 = _pm_out;
                    ope2.detune2 = _pm_out;
                    ope3.detune2 = _pm_out;
                    _lfo_timer += _lfo_timer_initial;
                }
                
                // operator[0]
                //----------------------------------------
                // eg_update();
                ope0._eg_timer -= ope0._eg_timer_step;
                if (ope0._eg_timer < 0) {
                    if (ope0._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope0._eg_incTable[ope0._eg_counter];
                        if (t > 0) {
                            ope0._eg_level -= 1 + (ope0._eg_level >> t);
                            if (ope0._eg_level <= 0) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                        }
                    } else {
                        ope0._eg_level += ope0._eg_incTable[ope0._eg_counter];
                        if (ope0._eg_level >= ope0._eg_stateShiftLevel) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                    }
                    ope0._eg_out = (ope0._eg_levelTable[ope0._eg_level] + ope0._eg_total_level)<<3;
                    ope0._eg_counter = (ope0._eg_counter+1)&7;
                    ope0._eg_timer += _eg_timer_initial;
                }
                // pg_update();
                ope0._phase += ope0._phase_step;
                t = ((ope0._phase + (ip.i<<_inputLevel)) & phase_filter) >> ope0._waveFixedBits;
                l = ope0._waveTable[t];
                l += ope0._eg_out + (_am_out>>ope0._ams);
                t = log[l];
                ope0._feedPipe.i = t;
                ope0._outPipe.i  = t + ope0._basePipe.i;

                // operator[1]
                //----------------------------------------
                // eg_update();
                ope1._eg_timer -= ope1._eg_timer_step;
                if (ope1._eg_timer < 0) {
                    if (ope1._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope1._eg_incTable[ope1._eg_counter];
                        if (t > 0) {
                            ope1._eg_level -= 1 + (ope1._eg_level >> t);
                            if (ope1._eg_level <= 0) ope1._eg_shiftState(ope1._eg_nextState[ope1._eg_state]);
                        }
                    } else {
                        ope1._eg_level += ope1._eg_incTable[ope1._eg_counter];
                        if (ope1._eg_level >= ope1._eg_stateShiftLevel) ope1._eg_shiftState(ope1._eg_nextState[ope1._eg_state]);
                    }
                    ope1._eg_out = (ope1._eg_levelTable[ope1._eg_level] + ope1._eg_total_level)<<3;
                    ope1._eg_counter = (ope1._eg_counter+1)&7;
                    ope1._eg_timer += _eg_timer_initial;
                }
                // pg_update();
                ope1._phase += ope1._phase_step;
                t = ((ope1._phase + (ope1._inPipe.i<<ope1._fmShift)) & phase_filter) >> ope1._waveFixedBits;
                l = ope1._waveTable[t];
                l += ope1._eg_out + (_am_out>>ope1._ams);
                t = log[l];
                ope1._feedPipe.i = t;
                ope1._outPipe.i  = t + ope1._basePipe.i;

                // operator[2]
                //----------------------------------------
                // eg_update();
                ope2._eg_timer -= ope2._eg_timer_step;
                if (ope2._eg_timer < 0) {
                    if (ope2._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope2._eg_incTable[ope2._eg_counter];
                        if (t > 0) {
                            ope2._eg_level -= 1 + (ope2._eg_level >> t);
                            if (ope2._eg_level <= 0) ope2._eg_shiftState(ope2._eg_nextState[ope2._eg_state]);
                        }
                    } else {
                        ope2._eg_level += ope2._eg_incTable[ope2._eg_counter];
                        if (ope2._eg_level >= ope2._eg_stateShiftLevel) ope2._eg_shiftState(ope2._eg_nextState[ope2._eg_state]);
                    }
                    ope2._eg_out = (ope2._eg_levelTable[ope2._eg_level] + ope2._eg_total_level)<<3;
                    ope2._eg_counter = (ope2._eg_counter+1)&7;
                    ope2._eg_timer += _eg_timer_initial;
                }
                // pg_update();
                ope2._phase += ope2._phase_step;
                t = ((ope2._phase + (ope2._inPipe.i<<ope2._fmShift)) & phase_filter) >> ope2._waveFixedBits;
                l = ope2._waveTable[t];
                l += ope2._eg_out + (_am_out>>ope2._ams);
                t = log[l];
                ope2._feedPipe.i = t;
                ope2._outPipe.i  = t + ope2._basePipe.i;
                
                // operator[3]
                //----------------------------------------
                // eg_update();
                ope3._eg_timer -= ope3._eg_timer_step;
                if (ope3._eg_timer < 0) {
                    if (ope3._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope3._eg_incTable[ope3._eg_counter];
                        if (t > 0) {
                            ope3._eg_level -= 1 + (ope3._eg_level >> t);
                            if (ope3._eg_level <= 0) ope3._eg_shiftState(ope3._eg_nextState[ope3._eg_state]);
                        }
                    } else {
                        ope3._eg_level += ope3._eg_incTable[ope3._eg_counter];
                        if (ope3._eg_level >= ope3._eg_stateShiftLevel) ope3._eg_shiftState(ope3._eg_nextState[ope3._eg_state]);
                    }
                    ope3._eg_out = (ope3._eg_levelTable[ope3._eg_level] + ope3._eg_total_level)<<3;
                    ope3._eg_counter = (ope3._eg_counter+1)&7;
                    ope3._eg_timer += _eg_timer_initial;
                }
                // pg_update();
                ope3._phase += ope3._phase_step;
                t = ((ope3._phase + (ope3._inPipe.i<<ope3._fmShift)) & phase_filter) >> ope3._waveFixedBits;
                l = ope3._waveTable[t];
                l += ope3._eg_out + (_am_out>>ope3._ams);
                t = log[l];
                ope3._feedPipe.i = t;
                ope3._outPipe.i  = t + ope3._basePipe.i;

                // output and increment pointers
                //----------------------------------------
                op.i = _pipe0.i + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        
        
        
    // processing PCM
    //--------------------------------------------------
        private function _procpcm_loff(len:int) : void
        {
            var t:int, l:int, i:int, n:Number;
            var ope:SiOPMOperator = operator[0],
                log:Vector.<int> = _table.logTable,
                phase_filter:int = SiOPMTable.PHASE_FILTER;

            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // eg_update();
                //----------------------------------------
                ope._eg_timer -= ope._eg_timer_step;
                if (ope._eg_timer < 0) {
                    if (ope._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope._eg_incTable[ope._eg_counter];
                        if (t > 0) {
                            ope._eg_level -= 1 + (ope._eg_level >> t);
                            if (ope._eg_level <= 0) ope._eg_shiftState(ope._eg_nextState[ope._eg_state]);
                        }
                    } else {
                        ope._eg_level += ope._eg_incTable[ope._eg_counter];
                        if (ope._eg_level >= ope._eg_stateShiftLevel) ope._eg_shiftState(ope._eg_nextState[ope._eg_state]);
                    }
                    ope._eg_out = (ope._eg_levelTable[ope._eg_level] + ope._eg_total_level)<<3;
                    ope._eg_counter = (ope._eg_counter+1)&7;
                    ope._eg_timer += _eg_timer_initial;
                }

                // pg_update();
                //----------------------------------------
                ope._phase += ope._phase_step;
                t = (ope._phase + (ip.i<<_inputLevel)) >>> ope._waveFixedBits;
                if (t >= ope._pcm_endPoint) {
                    if (ope._pcm_loopPoint == -1) {
                        ope._eg_shiftState(SiOPMOperator.EG_OFF);
                        ope._eg_out = (ope._eg_levelTable[ope._eg_level] + ope._eg_total_level)<<3;
                        for (;i<len; i++) {
                            op.i = bp.i;
                            ip = ip.next;
                            bp = bp.next;
                            op = op.next;
                        }
                        break;
                    } else {
                        t -=  ope._pcm_endPoint - ope._pcm_loopPoint;
                        ope._phase -= (ope._pcm_endPoint - ope._pcm_loopPoint) << ope._waveFixedBits;
                    }
                }
                l = ope._waveTable[t];
                l += ope._eg_out;
                t = log[l];
                ope._feedPipe.i = t;
                
                // output and increment pointers
                //----------------------------------------
                op.i = t + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        
        private function _procpcm_lon(len:int) : void
        {
            var t:int, l:int, i:int, n:Number;
            var ope:SiOPMOperator = operator[0],
                log:Vector.<int> = _table.logTable,
                phase_filter:int = SiOPMTable.PHASE_FILTER;

            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;

            for (i=0; i<len; i++) {
                // lfo_update();
                //----------------------------------------
                _lfo_timer -= _lfo_timer_step;
                if (_lfo_timer < 0) {
                    _lfo_phase = (_lfo_phase+1) & 255;
                    t = _lfo_waveTable[_lfo_phase];
                    _am_out = (t * _am_depth) >> 7 << 3;
                    _pm_out = (((t<<1)-255) * _pm_depth) >> 8;
                    ope.detune2 = _pm_out;
                    _lfo_timer += _lfo_timer_initial;
                }
                
                // eg_update();
                //----------------------------------------
                ope._eg_timer -= ope._eg_timer_step;
                if (ope._eg_timer < 0) {
                    if (ope._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope._eg_incTable[ope._eg_counter];
                        if (t > 0) {
                            ope._eg_level -= 1 + (ope._eg_level >> t);
                            if (ope._eg_level <= 0) ope._eg_shiftState(ope._eg_nextState[ope._eg_state]);
                        }
                    } else {
                        ope._eg_level += ope._eg_incTable[ope._eg_counter];
                        if (ope._eg_level >= ope._eg_stateShiftLevel) ope._eg_shiftState(ope._eg_nextState[ope._eg_state]);
                    }
                    ope._eg_out = (ope._eg_levelTable[ope._eg_level] + ope._eg_total_level)<<3;
                    ope._eg_counter = (ope._eg_counter+1)&7;
                    ope._eg_timer += _eg_timer_initial;
                }

                // pg_update();
                //----------------------------------------
                ope._phase += ope._phase_step;
                t = (ope._phase + (ip.i<<_inputLevel)) >>> ope._waveFixedBits;
                if (t >= ope._pcm_endPoint) {
                    if (ope._pcm_loopPoint == -1) {
                        ope._eg_shiftState(SiOPMOperator.EG_OFF);
                        ope._eg_out = (ope._eg_levelTable[ope._eg_level] + ope._eg_total_level)<<3;
                        for (;i<len; i++) {
                            op.i = bp.i;
                            ip = ip.next;
                            bp = bp.next;
                            op = op.next;
                        }
                        break;
                    } else {
                        t -=  ope._pcm_endPoint - ope._pcm_loopPoint;
                        ope._phase -= (ope._pcm_endPoint - ope._pcm_loopPoint) << ope._waveFixedBits;
                    }
                }
                l = ope._waveTable[t];
                l += ope._eg_out + (_am_out>>ope._ams);
                t = log[l];
                ope._feedPipe.i = t;
                
                // output and increment pointers
                //----------------------------------------
                op.i = t + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        
        
        
    // analog like processing (w/ ring and sync)
    //--------------------------------------------------
        private function _proc2ana(len:int) : void
        {
            var i:int, t:int, out0:int, out1:int, l:int, n:Number;
            var phase_filter:int = SiOPMTable.PHASE_FILTER,
                log:Vector.<int> = _table.logTable,
                ope0:SiOPMOperator = operator[0],
                ope1:SiOPMOperator = operator[1];
            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // lfo
                //----------------------------------------
                _lfo_timer -= _lfo_timer_step;
                if (_lfo_timer < 0) {
                    _lfo_phase = (_lfo_phase+1) & 255;
                    t = _lfo_waveTable[_lfo_phase];
                    _am_out = (t * _am_depth) >> 7 << 3;
                    _pm_out = (((t<<1)-255) * _pm_depth) >> 8;
                    ope0.detune2 = _pm_out;
                    ope1.detune2 = _pm_out;
                    _lfo_timer += _lfo_timer_initial;
                }
                
                // envelop
                //----------------------------------------
                ope0._eg_timer -= ope0._eg_timer_step;
                if (ope0._eg_timer < 0) {
                    if (ope0._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope0._eg_incTable[ope0._eg_counter];
                        if (t > 0) {
                            ope0._eg_level -= 1 + (ope0._eg_level >> t);
                            if (ope0._eg_level <= 0) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                        }
                    } else {
                        ope0._eg_level += ope0._eg_incTable[ope0._eg_counter];
                        if (ope0._eg_level >= ope0._eg_stateShiftLevel) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                    }
                    ope0._eg_out = (ope0._eg_levelTable[ope0._eg_level] + ope0._eg_total_level)<<3;
                    ope1._eg_out = (ope0._eg_levelTable[ope0._eg_level] + ope1._eg_total_level)<<3;
                    ope0._eg_counter = (ope0._eg_counter+1)&7;
                    ope0._eg_timer += _eg_timer_initial;
                }
                
                // operator[0]
                //----------------------------------------
                ope0._phase += ope0._phase_step;
                t = ((ope0._phase + (ip.i<<_inputLevel)) & phase_filter) >> ope0._waveFixedBits;
                l = ope0._waveTable[t];
                l += ope0._eg_out + (_am_out>>ope0._ams);
                out0 = log[l];

                // operator[1] with op0s envelop and ams
                //----------------------------------------
                ope1._phase += ope1._phase_step;
                t = (ope1._phase & phase_filter) >> ope1._waveFixedBits;
                l = ope1._waveTable[t];
                l += ope1._eg_out + (_am_out>>ope0._ams);
                out1 = log[l];

                // output and increment pointers
                //----------------------------------------
                ope0._feedPipe.i = out0;
                op.i = out0 + out1 + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }

            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        private function _procring(len:int) : void
        {
            var i:int, t:int, out0:int, l:int, n:Number;
            var phase_filter:int = SiOPMTable.PHASE_FILTER,
                log:Vector.<int> = _table.logTable,
                ope0:SiOPMOperator = operator[0],
                ope1:SiOPMOperator = operator[1];
            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // lfo
                //----------------------------------------
                _lfo_timer -= _lfo_timer_step;
                if (_lfo_timer < 0) {
                    _lfo_phase = (_lfo_phase+1) & 255;
                    t = _lfo_waveTable[_lfo_phase];
                    _am_out = (t * _am_depth) >> 7 << 3;
                    _pm_out = (((t<<1)-255) * _pm_depth) >> 8;
                    ope0.detune2 = _pm_out;
                    ope1.detune2 = _pm_out;
                    _lfo_timer += _lfo_timer_initial;
                }
                
                // envelop
                //----------------------------------------
                ope0._eg_timer -= ope0._eg_timer_step;
                if (ope0._eg_timer < 0) {
                    if (ope0._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope0._eg_incTable[ope0._eg_counter];
                        if (t > 0) {
                            ope0._eg_level -= 1 + (ope0._eg_level >> t);
                            if (ope0._eg_level <= 0) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                        }
                    } else {
                        ope0._eg_level += ope0._eg_incTable[ope0._eg_counter];
                        if (ope0._eg_level >= ope0._eg_stateShiftLevel) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                    }
                    ope0._eg_out = (ope0._eg_levelTable[ope0._eg_level] + ope0._eg_total_level)<<3;
                    ope1._eg_out = (ope0._eg_levelTable[ope0._eg_level] + ope1._eg_total_level)<<3;
                    ope0._eg_counter = (ope0._eg_counter+1)&7;
                    ope0._eg_timer += _eg_timer_initial;
                }
                
                // operator[0]
                //----------------------------------------
                ope0._phase += ope0._phase_step;
                t = ((ope0._phase + (ip.i<<_inputLevel)) & phase_filter) >> ope0._waveFixedBits;
                l = ope0._waveTable[t];

                // operator[1] with op0s envelop and ams
                //----------------------------------------
                ope1._phase += ope1._phase_step;
                t = (ope1._phase & phase_filter) >> ope1._waveFixedBits;
                l += ope1._waveTable[t];
                l += ope1._eg_out + (_am_out>>ope0._ams);
                out0 = log[l];

                // output and increment pointers
                //----------------------------------------
                ope0._feedPipe.i = out0;
                op.i = out0 + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        private function _procsync(len:int) : void
        {
            var i:int, t:int, out0:int, out1:int, l:int, n:Number;
            var phase_filter:int = SiOPMTable.PHASE_FILTER,
                log:Vector.<int> = _table.logTable,
                phase_overflow:int = SiOPMTable.PHASE_MAX,
                ope0:SiOPMOperator = operator[0],
                ope1:SiOPMOperator = operator[1];
            
            // buffering
            var ip:SLLint = _inPipe,
                bp:SLLint = _basePipe,
                op:SLLint = _outPipe;
            for (i=0; i<len; i++) {
                // lfo
                //----------------------------------------
                _lfo_timer -= _lfo_timer_step;
                if (_lfo_timer < 0) {
                    _lfo_phase = (_lfo_phase+1) & 255;
                    t = _lfo_waveTable[_lfo_phase];
                    _am_out = (t * _am_depth) >> 7 << 3;
                    _pm_out = (((t<<1)-255) * _pm_depth) >> 8;
                    ope0.detune2 = _pm_out;
                    ope1.detune2 = _pm_out;
                    _lfo_timer += _lfo_timer_initial;
                }
                
                // envelop
                //----------------------------------------
                ope0._eg_timer -= ope0._eg_timer_step;
                if (ope0._eg_timer < 0) {
                    if (ope0._eg_state == SiOPMOperator.EG_ATTACK) {
                        t = ope0._eg_incTable[ope0._eg_counter];
                        if (t > 0) {
                            ope0._eg_level -= 1 + (ope0._eg_level >> t);
                            if (ope0._eg_level <= 0) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                        }
                    } else {
                        ope0._eg_level += ope0._eg_incTable[ope0._eg_counter];
                        if (ope0._eg_level >= ope0._eg_stateShiftLevel) ope0._eg_shiftState(ope0._eg_nextState[ope0._eg_state]);
                    }
                    ope0._eg_out = (ope0._eg_levelTable[ope0._eg_level] + ope0._eg_total_level)<<3;
                    ope1._eg_out = (ope0._eg_levelTable[ope0._eg_level] + ope1._eg_total_level)<<3;
                    ope0._eg_counter = (ope0._eg_counter+1)&7;
                    ope0._eg_timer += _eg_timer_initial;
                }
                
                // operator[0]
                //----------------------------------------
                ope0._phase += ope0._phase_step + (ip.i<<_inputLevel);
                if (ope0._phase & phase_overflow) ope1._phase = ope1._keyon_phase;
                ope0._phase = ope0._phase & phase_filter;

                // operator[1] with op0s envelop and ams
                //----------------------------------------
                ope1._phase += ope1._phase_step;
                t = (ope1._phase & phase_filter) >> ope1._waveFixedBits;
                l = ope1._waveTable[t];
                l += ope1._eg_out + (_am_out>>ope0._ams);
                out0 = log[l];

                // output and increment pointers
                //----------------------------------------
                ope0._feedPipe.i = out0;
                op.i = out0 + bp.i;
                ip = ip.next;
                bp = bp.next;
                op = op.next;
            }
            
            // update pointers
            _inPipe   = ip;
            _basePipe = bp;
            _outPipe  = op;
        }
        
        
        
        
    // internal operations
    //--------------------------------------------------
        /** @private [internal use] Update LFO. This code is only for testing. */
        internal function _lfo_update() : void
        {
            _lfo_timer -= _lfo_timer_step;
            if (_lfo_timer < 0) {
                _lfo_phase = (_lfo_phase+1) & 255;
                _am_out = (_lfo_waveTable[_lfo_phase] * _am_depth) >> 7 << 3;
                _pm_out = (((_lfo_waveTable[_lfo_phase]<<1)-255) * _pm_depth) >> 8;
                if (operator[0]) operator[0].detune2 = _pm_out;
                if (operator[1]) operator[1].detune2 = _pm_out;
                if (operator[2]) operator[2].detune2 = _pm_out;
                if (operator[3]) operator[3].detune2 = _pm_out;
                _lfo_timer += _lfo_timer_initial;
            }
        }
        
        
        // update operator count.
        private function _updateOperatorCount(cnt:int) : void
        {
            var i:int;

            // change operator instances
            if (_operatorCount < cnt) {
                // allocate and initialize new operators
                for (i=_operatorCount; i<cnt; i++) {
                    operator[i] = _allocFMOperator();
                    operator[i].initialize();
                }
            } else 
            if (_operatorCount > cnt) {
                // free old operators
                for (i=cnt; i<_operatorCount; i++) {
                    _freeFMOperator(operator[i]);
                    operator[i] = null;
                }
            } 
            
            // update count
            _operatorCount = cnt;
            _funcProcessType = cnt - 1;
            // select processing function
            _funcProcess = _funcProcessList[_lfo_on][_funcProcessType];
            
            // default active operator is the last one.
            activeOperator = operator[_operatorCount-1];

            // reset feed back
            if (_inputMode == INPUT_FEEDBACK) {
                setFeedBack(0, 0);
            }
        }
        
        
        // alg operator=1
        private function _algorism1(alg:int) : void
        {
            _updateOperatorCount(1);
            _algorism = alg;
            operator[0]._setPipes(_pipe0, null, true);
        }
        
        
        // alg operator=2
        private function _algorism2(alg:int) : void
        {
            _updateOperatorCount(2);
            _algorism = alg;
            switch(_algorism) {
            case 0: // OPL3/MA3:con=0, OPX:con=0, 1(fbc=1)
                // o1(o0)
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0, _pipe0, true);
                break;
            case 1: // OPL3/MA3:con=1, OPX:con=2
                // o0+o1
                operator[0]._setPipes(_pipe0, null, true);
                operator[1]._setPipes(_pipe0, null, true);
                break;
            case 2: // OPX:con=3
                // o0+o1(o0)
                operator[0]._setPipes(_pipe0, null,   true);
                operator[1]._setPipes(_pipe0, _pipe0, true);
                operator[1]._basePipe = _pipe0;
                break;
            default:
                // o0+o1
                operator[0]._setPipes(_pipe0, null, true);
                operator[1]._setPipes(_pipe0, null, true);
                break;
            }
        }
        
        
        // alg operator=3
        private function _algorism3(alg:int) : void
        {
            _updateOperatorCount(3);
            _algorism = alg;
            switch(_algorism) {
            case 0: // OPX:con=0, 1(fbc=1)
                // o2(o1(o0))
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0, _pipe0);
                operator[2]._setPipes(_pipe0, _pipe0, true);
                break;
            case 1: // OPX:con=2
                // o2(o0+o1)
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0);
                operator[2]._setPipes(_pipe0, _pipe0, true);
                break;
            case 2: // OPX:con=3
                // o0+o2(o1)
                operator[0]._setPipes(_pipe0, null,   true);
                operator[1]._setPipes(_pipe1);
                operator[2]._setPipes(_pipe0, _pipe1, true);
                break;
            case 3: // OPX:con=4, 5(fbc=1)
                // o1(o0)+o2
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0, _pipe0, true);
                operator[2]._setPipes(_pipe0, null,   true);
                break;
            case 4:
                // o1(o0)+o2(o0)
                operator[0]._setPipes(_pipe1);
                operator[1]._setPipes(_pipe0, _pipe1, true);
                operator[2]._setPipes(_pipe0, _pipe1, true);
                break;
            case 5: // OPX:con=6
                // o0+o1+o2
                operator[0]._setPipes(_pipe0, null, true);
                operator[1]._setPipes(_pipe0, null, true);
                operator[2]._setPipes(_pipe0, null, true);
                break;
            case 6: // OPX:con=7
                // o0+o1(o0)+o2
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0, _pipe0, true);
                operator[1]._basePipe = _pipe0;
                operator[2]._setPipes(_pipe0, null,   true);
                break;
            default:
                // o0+o1+o2
                operator[0]._setPipes(_pipe0, null, true);
                operator[1]._setPipes(_pipe0, null, true);
                operator[2]._setPipes(_pipe0, null, true);
                break;
            }
        }
        
        
        // alg operator=4
        private function _algorism4(alg:int) : void
        {
            _updateOperatorCount(4);
            _algorism = alg;
            switch(_algorism) {
            case 0: // OPL3:con=0, MA3:con=4, OPX:con=0, 1(fbc=1)
                // o3(o2(o1(o0)))
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0, _pipe0);
                operator[2]._setPipes(_pipe0, _pipe0);
                operator[3]._setPipes(_pipe0, _pipe0, true);
                break;
            case 1: // OPX:con=2
                // o3(o2(o0+o1))
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0);
                operator[2]._setPipes(_pipe0, _pipe0);
                operator[3]._setPipes(_pipe0, _pipe0, true);
                break;
            case 2: // MA3:con=3, OPX:con=3
                // o3(o0+o2(o1))
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe1);
                operator[2]._setPipes(_pipe0, _pipe1);
                operator[3]._setPipes(_pipe0, _pipe0, true);
                break;
            case 3: // OPX:con=4, 5(fbc=1)
                // o3(o1(o0)+o2)
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0, _pipe0);
                operator[2]._setPipes(_pipe0);
                operator[3]._setPipes(_pipe0, _pipe0, true);
                break;
            case 4: // OPL3:con=1, MA3:con=5, OPX:con=6, 7(fbc=1)
                // o1(o0)+o3(o2)
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0, _pipe0, true);
                operator[2]._setPipes(_pipe1);
                operator[3]._setPipes(_pipe0, _pipe1, true);
                break;
            case 5: // OPX:con=12
                // o1(o0)+o2(o0)+o3(o0)
                operator[0]._setPipes(_pipe1);
                operator[1]._setPipes(_pipe0, _pipe1, true);
                operator[2]._setPipes(_pipe0, _pipe1, true);
                operator[3]._setPipes(_pipe0, _pipe1, true);
                break;
            case 6: // OPX:con=10, 11(fbc=1)
                // o1(o0)+o2+o3
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0, _pipe0, true);
                operator[2]._setPipes(_pipe0, null,   true);
                operator[3]._setPipes(_pipe0, null,   true);
                break;
            case 7: // MA3:con=2, OPX:con=15
                // o0+o1+o2+o3
                operator[0]._setPipes(_pipe0, null, true);
                operator[1]._setPipes(_pipe0, null, true);
                operator[2]._setPipes(_pipe0, null, true);
                operator[3]._setPipes(_pipe0, null, true);
                break;
            case 8: // OPL3:con=2, MA3:con=6, OPX:con=8
                // o0+o3(o2(o1))
                operator[0]._setPipes(_pipe0, null,   true);
                operator[1]._setPipes(_pipe1);
                operator[2]._setPipes(_pipe1, _pipe1);
                operator[3]._setPipes(_pipe0, _pipe1, true);
                break;
            case 9: // OPL3:con=3, MA3:con=7, OPX:con=13
                // o0+o2(o1)+o3
                operator[0]._setPipes(_pipe0, null,   true);
                operator[1]._setPipes(_pipe1);
                operator[2]._setPipes(_pipe0, _pipe1, true);
                operator[3]._setPipes(_pipe0, null,   true);
                break;
            case 10: // for DX7 emulation
                // o3(o0+o1+o2)
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0);
                operator[2]._setPipes(_pipe0);
                operator[3]._setPipes(_pipe0, _pipe0, true);
                break;
            case 11: // OPX:con=9
                // o0+o3(o1+o2)
                operator[0]._setPipes(_pipe0, null,   true);
                operator[1]._setPipes(_pipe1);
                operator[2]._setPipes(_pipe1);
                operator[3]._setPipes(_pipe0, _pipe1, true);
                break;
            case 12: // OPX:con=14
                // o0+o1(o0)+o3(o2)
                operator[0]._setPipes(_pipe0);
                operator[1]._setPipes(_pipe0, _pipe0, true);
                operator[1]._basePipe = _pipe0;
                operator[2]._setPipes(_pipe1);
                operator[3]._setPipes(_pipe0, _pipe1, true);
                break;
            default:
                // o0+o1+o2+o3
                operator[0]._setPipes(_pipe0, null, true);
                operator[1]._setPipes(_pipe0, null, true);
                operator[2]._setPipes(_pipe0, null, true);
                operator[3]._setPipes(_pipe0, null, true);
                break;
            }
        }
        
        
        // analog like operation
        private function _analog(alg:int) : void
        {
            _updateOperatorCount(2);
            operator[0]._setPipes(_pipe0, null, true);
            operator[1]._setPipes(_pipe0, null, true);
            
            _algorism = (alg>=0 && alg<=3) ? alg : 0;
            _funcProcessType = PROC_ANA + _algorism;
            _funcProcess = _funcProcessList[_lfo_on][_funcProcessType];
        }
        
        
    // SiOPMOperator factory
    //--------------------------------------------------
        // Free list for SiOPMOperator
        static private var _freeOperators:Vector.<SiOPMOperator> = new Vector.<SiOPMOperator>();        
        
        
        /** @private [internal] Alloc operator instance WITHOUT initializing. Call from SiOPMChannelFM. */
        protected function _allocFMOperator() : SiOPMOperator {
            return _freeOperators.pop() || new SiOPMOperator(_chip);
        }

        
        /** @private [internal] Free operator instance. Call from SiOPMChannelFM. */
        protected function _freeFMOperator(osc:SiOPMOperator) : void {
            _freeOperators.push(osc);
        }
    }
}

