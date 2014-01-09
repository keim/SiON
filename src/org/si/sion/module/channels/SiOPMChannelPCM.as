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
    
    
    /** PCM channel
     */
    public class SiOPMChannelPCM extends SiOPMChannelBase
    {
    // valiables
    //--------------------------------------------------
        /** eg_out threshold to check idling */ static _sion_internal var idlingThreshold:int = 5120; // = 256(resolution)*10(2^10=1024)*2(p/n) = volume<1/1024
        
        // Operators
        /** operator for layer0 */  public var operator:SiOPMOperator;
        
        // Parameters
        /** pcm table */         protected var _pcmTable:SiOPMWavePCMTable;
        /** for stereo filter */ protected var _filterVriables2:Vector.<Number>;

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
        
        // pitch shift for sampling point
        private var _samplePitchShift:int;
        // volunme of current note
        private var _sampleVolume:Number;
        // pan of current note
        private var _samplePan:int;
        // output pipe for stereo
        private var _outPipe2:SLLint
        // waveFixedBits for PCM
        static private const PCM_waveFixedBits:int = 11; // <= Should be 11, This is adhoc solution !
        
        
        
        
    // toString
    //--------------------------------------------------
        /** Output parameters. */
        public function toString() : String
        {
            var str:String = "SiOPMChannelPCM : \n";
            $2("vol", _volumes[0],  "pan", _pan-64);
            str += String(operator) + "\n";
            return str;
            function $ (p:String, i:*) : void { str += "  " + p + "=" + String(i) + "\n"; }
            function $2(p:String, i:*, q:String, j:*) : void { str += "  " + p + "=" + String(i) + " / " + q + "=" + String(j) + "\n"; }
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function SiOPMChannelPCM(chip:SiOPMModule)
        {
            super(chip);
            
            operator = new SiOPMOperator(chip);
            _filterVriables2 = new Vector.<Number>(3, true);
            
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
            _pcmTable = null;
            operator.detune2 = 0;
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
                operator.detune2 = 0;
            }
        }
        
        
        /** @private [protected] lfo on/off */
        protected function _lfoSwitch(sw:Boolean) : void
        {
            _lfo_on = int(sw);
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
            //setFeedBack(param.fb, param.fbc);
            if (withModulation) {
                initializeLFO(param.lfoWaveShape);
                _lfo_timer = (param.lfoFreqStep>0) ? 1 : 0;
                _lfo_timer_step_ = _lfo_timer_step = param.lfoFreqStep;
                setAmplitudeModulation(param.amd);
                setPitchModulation(param.pmd);
            }
            filterType = param.filterType;
            setSVFilter(param.cutoff, param.resonance, param.far, param.fdr1, param.fdr2, param.frr, param.fdc1, param.fdc2, param.fsc, param.frc);
            operator.setSiOPMOperatorParam(param.operatorParam[0]);
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
            param.opeCount = 1;
            param.alg = 0;
            param.fb = 0;
            param.fbc = 0;
            param.lfoWaveShape = _lfo_waveShape;
            param.lfoFreqStep  = _lfo_timer_step_;
            param.amd = _am_depth;
            param.pmd = _pm_depth;
            operator.getSiOPMOperatorParam(param.operatorParam[0]);
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
            var ope:SiOPMOperator = operator;
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
        
        
        /** Set wave data. (called from setType())
         *  @param pcmData SiOPMWavePCMTable to set.
         */
        override public function setWaveData(waveData:SiOPMWaveBase) : void
        {
            var pcm:SiOPMWavePCMData;
            if (waveData is SiOPMWavePCMTable) {
                _pcmTable = waveData as SiOPMWavePCMTable;
                pcm = _pcmTable._siopm_module_internal::_table[60];
            } else {
                _pcmTable = null;
                pcm = waveData as SiOPMWavePCMData;
            }
            if (pcm) _samplePitchShift = pcm.samplingPitch - 4416;
            operator.setPCMData(pcm);
        }
        
        
        /** set channel number (2nd argument of %) */
        override public function setChannelNumber(channelNum:int) : void 
        {
            _sion_internal::registerMapChannel = channelNum;
        }
        
        
        /** set register */
        override public function setRegister(addr:int, data:int) : void
        {
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** Set algorism (&#64;al) 
         *  @param cnt Operator count.
         *  @param alg Algolism number of the operator's connection.
         */
        override public function setAlgorism(cnt:int, alg:int) : void
        {
        }
        
        
        /** Set feedback(&#64;fb). Do nothing. 
         *  @param fb Feedback level. Ussualy in the range of 0-7.
         *  @param fbc Feedback connection. Operator index which feeds back its output.
         */
        override public function setFeedBack(fb:int, fbc:int) : void
        {
        }
        
        
        /** Set parameters (&#64; command). */
        override public function setParameters(param:Vector.<int>) : void
        {
            setSiOPMParameters(param[1],  param[2],  param[3],  param[4],  param[5], 
                               param[6],  param[7],  param[8],  param[9],  param[10], 
                               param[11], param[12], param[13], param[14]);
        }
        
        
        /** pgType and ptType (&#64;). call from SiMMLChannelSetting.selectTone() */
        override public function setType(pgType:int, ptType:int) : void
        {
            var pcmTable:SiOPMWavePCMTable = _table.getPCMData(pgType);
            if (pcmTable) {
                setWaveData(pcmTable);
            } else {
                _samplePitchShift = 0;
                operator.setPCMData(null);
            }
        }
        
        
        /** Attack rate */
        override public function setAllAttackRate(ar:int) : void 
        {
            operator.ar = ar;
        }
        
        
        /** Release rate (s) */
        override public function setAllReleaseRate(rr:int) : void 
        {
            operator.rr = rr;
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** pitch = (note &lt;&lt; 6) | (kf &amp; 63) [0,8191] */
        override public function get pitch() : int { return operator.pitchIndex + _samplePitchShift; }
        override public function set pitch(p:int) : void {
            if (_pcmTable) {
                var note:int = p>>6;
                var pcm:SiOPMWavePCMData = _pcmTable._siopm_module_internal::_table[note];
                if (pcm) {
                    _samplePitchShift = pcm.samplingPitch - 4416; //69*64
                    _sampleVolume = _pcmTable._siopm_module_internal::_volumeTable[note];
                    _samplePan = _pcmTable._siopm_module_internal::_panTable[note];
                }
                operator.setPCMData(pcm);
            }
            operator.pitchIndex = p - _samplePitchShift;
        }
        
        /** active operator index (i) */
        override public function set activeOperatorIndex(i:int) : void {
        }
        
        /** release rate (&#64;rr) */
        override public function set rr(i:int) : void { operator.rr = i; }
        
        /** total level (&#64;tl) */
        override public function set tl(i:int) : void { operator.tl = i; }
        
        /** fine multiple (&#64;ml) */
        override public function set fmul(i:int) : void { operator.fmul = i; }
        
        /** phase  (&#64;ph) */
        override public function set phase(i:int) : void { operator.keyOnPhase = i; }
        
        /** detune (&#64;dt) */
        override public function set detune(i:int) : void { operator.detune = i; }
        
        /** fixed pitch (&#64;fx) */
        override public function set fixedPitch(i:int) : void { operator.fixedPitchIndex = i; }
        
        /** ssgec (&#64;se) */
        override public function set ssgec(i:int) : void { operator.ssgec = i; }
        
        /** envelop reset (&#64;er) */
        override public function set erst(b:Boolean) : void { operator.erst = b; }
        
        
        
        
    // volume controls
    //--------------------------------------------------
        /** update all tl offsets of final carriors */
        override public function offsetVolume(expression:int, velocity:int) : void
        {
            var i:int, ope:SiOPMOperator, tl:int, x:int = expression<<1;
            tl = _expressionTable[x] + _veocityTable[velocity];
            operator._tlOffset(tl);
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Initialize. */
        override public function initialize(prev:SiOPMChannelBase, bufferIndex:int) : void
        {
            // initialize operators
            operator.initialize();
            _isNoteOn = false;
            _sion_internal::registerMapType = 0
            _sion_internal::registerMapChannel = 0;
            _outPipe2 = _chip.getPipe(3, bufferIndex);
            _filterVriables2[0] = _filterVriables2[1] = _filterVriables2[2] = 0;
            _samplePitchShift = 0;
            _sampleVolume = 1;
            _samplePan = 0;
            
            // initialize sound channel
            super.initialize(prev, bufferIndex);
        }
        
        
        /** Reset. */
        override public function reset() : void
        {
            // reset all operators
            operator.reset();
            _isNoteOn = false;
            _isIdling = true;
        }
        
        
        /** Note on. */
        override public function noteOn() : void
        {
            // operator note on
            operator.noteOn();
            _isNoteOn = true;
            _isIdling = false;
            super.noteOn();
        }
        
        
        /** Note off. */
        override public function noteOff() : void
        {
            // operator note off
            operator.noteOff();
            _isNoteOn = false;
            super.noteOff();
        }
        
        
        /** Prepare buffering */
        override public function resetChannelBufferStatus() : void
        {
            _bufferIndex = 0;
            
            // check idling flag
            _isIdling = operator._eg_out > _sion_internal::idlingThreshold && operator._eg_state != SiOPMOperator.EG_ATTACK;
        }
        
        
        /** Buffering */
        override public function buffer(len:int) : void
        {
            if (_isIdling) {
                _nop(len);
            } else {
                _proc(len, operator, false, true);
            }
            _bufferIndex += len;
        }
        
        

        /** No process (default functor of _funcProcess). */
        override protected function _nop(len:int) : void
        {
            // rotate output buffer
            _outPipe  = _chip.getPipe(4, (_bufferIndex + len) & (_chip.bufferLength-1));
            _outPipe2 = _chip.getPipe(3, (_bufferIndex + len) & (_chip.bufferLength-1));
        }
        
        
        
        
    //====================================================================================================
    // Internal uses
    //====================================================================================================
    // process 1 operator
    //--------------------------------------------------
        private function _proc(len:int, ope:SiOPMOperator, mix:Boolean, finalOutput:Boolean) : void
        {
            var t:int, l:int, i:int, n:Number;
            var log:Vector.<int> = _table.logTable,
                phase_filter:int = SiOPMTable.PHASE_FILTER,
                op:SLLint = _outPipe, op2:SLLint = _outPipe2,
                bp:SLLint = _outPipe, bp2:SLLint = _outPipe2;
            if (!mix) bp = bp2 = _chip.zeroBuffer;

            if (ope._pcm_channels == 1) {
                // MONORAL
                //----------------------------------------
                if (ope._pcm_endPoint > 0) {
                    // buffering
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
                        t = ope._phase >>> PCM_waveFixedBits;
                        if (t >= ope._pcm_endPoint) {
                            if (ope._pcm_loopPoint == -1) {
                                ope._eg_shiftState(SiOPMOperator.EG_OFF);
                                ope._eg_out = (ope._eg_levelTable[ope._eg_level] + ope._eg_total_level)<<3;
                                for (;i<len; i++) {
                                    op.i = 0;
                                    op = op.next;
                                }
                                break;
                            } else {
                                t -=  ope._pcm_endPoint - ope._pcm_loopPoint;
                                ope._phase -= (ope._pcm_endPoint - ope._pcm_loopPoint) << PCM_waveFixedBits;
                            }
                        }
                        l = ope._waveTable[t];
                        l += ope._eg_out + (_am_out>>ope._ams);
                        
                        // output and increment pointers
                        //----------------------------------------
                        op.i = log[l] + bp.i;
                        op = op.next;
                        bp = bp.next;
                    }
                } else {
                    // no operation
                    for (i=0; i<len; i++) {
                        op.i = bp.i;
                        op = op.next;
                        bp = bp.next;
                    }
                }
                
                if (finalOutput) {
                    // streaming
                    if (!_mute) _mwrite(_outPipe, len);
                    // update pointers
                    _outPipe = op;
                }
            } else {
                // STEREO
                //----------------------------------------
                if (ope._pcm_endPoint > 0) {
                    // buffering
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
                        t = ope._phase >>> PCM_waveFixedBits;
                        if (t >= ope._pcm_endPoint) {
                            if (ope._pcm_loopPoint == -1) {
                                ope._eg_shiftState(SiOPMOperator.EG_OFF);
                                ope._eg_out = (ope._eg_levelTable[ope._eg_level] + ope._eg_total_level)<<3;
                                for (;i<len; i++) {
                                    op.i = 0;
                                    op2.i = 0;
                                    op  = op.next;
                                    op2 = op2.next;
                                }
                                break;
                            } else {
                                t -=  ope._pcm_endPoint - ope._pcm_loopPoint;
                                ope._phase -= (ope._pcm_endPoint - ope._pcm_loopPoint) << PCM_waveFixedBits;
                            }
                        }
                        
                        // output and increment pointers
                        //----------------------------------------
                        // left
                        t <<= 1;
                        l = ope._waveTable[t];
                        l += ope._eg_out + (_am_out>>ope._ams);
                        op.i = bp.i;
                        op.i += log[l];
                        op = op.next;
                        bp = bp.next;
                        // right
                        t++;
                        l = ope._waveTable[t];
                        l += ope._eg_out + (_am_out>>ope._ams);
                        op2.i = bp2.i;
                        op2.i += log[l];
                        op2 = op2.next;
                        bp2 = bp2.next;
                    }
                } else {
                    // no operation
                    for (i=0; i<len; i++) {
                        op.i = bp.i;
                        op = op.next;
                        bp = bp.next;
                        op2.i = bp2.i;
                        op2 = op2.next;
                        bp2 = bp2.next;
                    }
                }
                
                if (finalOutput) {
                    // streaming
                    if (!_mute) _swrite(_outPipe, _outPipe2, len);
                    // update pointers
                    _outPipe = op;
                    _outPipe2 = op2;
                }
            }
        }
        
        
        // monoral stream writing with filtering
        private function _mwrite(input:SLLint, len:int) : void 
        {
            var i:int, stream:SiOPMStream, vol:Number = _sampleVolume * _chip.pcmVolume, pan:int = _pan + _samplePan;
            if (pan < 0) pan = 0;
            else if (pan > 128) pan = 128;
            
            if (_filterOn) _applySVFilter(input, len);
            if (_hasEffectSend) {
                for (i=0; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                    if (_volumes[i]>0) {
                        stream = _streams[i] || _chip.streamSlot[i];
                        if (stream) stream.write(input, _bufferIndex, len, _volumes[i] * vol, pan);
                    }
                }
            } else {
                stream = _streams[0] || _chip.outputStream;
                stream.write(input, _bufferIndex, len, _volumes[0] * vol, pan);
            }
        }
        
        
        // stereo stream writing with filtering
        private function _swrite(inputL:SLLint, inputR:SLLint, len:int) : void 
        {
            var i:int, stream:SiOPMStream, vol:Number = _sampleVolume * _chip.pcmVolume, pan:int = _pan + _samplePan;
            if (pan < 0) pan = 0;
            else if (pan > 128) pan = 128;
            
            if (_filterOn) {
                _applySVFilter(inputL, len, _filterVriables);
                _applySVFilter(inputR, len, _filterVriables2);
            }
            if (_hasEffectSend) {
                for (i=0; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                    if (_volumes[i]>0) {
                        stream = _streams[i] || _chip.streamSlot[i];
                        if (stream) stream.writeStereo(inputL, inputR, _bufferIndex, len, _volumes[i] * vol, pan);
                    }
                }
            } else {
                stream = _streams[0] || _chip.outputStream;
                stream.writeStereo(inputL, inputR, _bufferIndex, len, _volumes[0] * vol, pan);
            }
        }
    }
}

