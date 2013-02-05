//----------------------------------------------------------------------------------------------------
// SiOPM Karplus-Strong algorism with FM synth.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module.channels {
    import org.si.utils.SLLNumber;
    import org.si.utils.SLLint;
    import org.si.sion.module.*;
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.sion.sequencer.SiMMLVoice;
    
    
    /** Karplus-Strong algorism with FM synth. */
    public class SiOPMChannelKS extends SiOPMChannelFM
    {
    // valiables
    //--------------------------------------------------
        private var KS_BUFFER_SIZE:int = 5400;     // 5394 = sampling count of MIDI note number=0
        
        private var KS_SEED_DEFAULT:int = 0;
        private var KS_SEED_FM:int = 1;
        private var KS_SEED_PCM:int = 2;
        
        
        
    // valiables
    //--------------------------------------------------
        private var _ks_delayBuffer:Vector.<int>;   // delay buffer
        private var _ks_delayBufferIndex:Number;    // delay buffer index
        private var _ks_pitchIndex:int;             // pitch index
        private var _ks_decay_lpf:Number;           // lpf decay
        private var _ks_decay:Number;               // decay
        private var _ks_mute_decay_lpf:Number;      // lpf decay @mute
        private var _ks_mute_decay:Number;          // decay @mute
        
        private var _output:Number;                 // output
        private var _decay_lpf:Number;              // lpf decay
        private var _decay:Number;                  // decay
        private var _expression:Number;             // expression
        
        private var _ks_seedType:int;               // seed type
        private var _ks_seedIndex:int;              // seed index
        
        
        
    // toString
    //--------------------------------------------------
        /** Output parameters. */
        override public function toString() : String
        {
            var str:String = "SiOPMChannelKS : operatorCount=";
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
        function SiOPMChannelKS(chip:SiOPMModule)
        {
            super(chip);
            _ks_delayBuffer = new Vector.<int>(KS_BUFFER_SIZE);
        }
        
        
        
        
    // LFO settings
    //--------------------------------------------------
        /** @private */
        override protected function _lfoSwitch(sw:Boolean) : void
        {
            _lfo_on = 0;
        }
        
        
        
        
    // parameter setting
    //--------------------------------------------------
        /** Set Karplus Strong parameters
         *  @param ar attack rate of plunk energy
         *  @param dr decay rate of plunk energy
         *  @param tl total level of plunk energy
         *  @param fixedPitch plunk noise pitch
         *  @param ws wave shape of plunk
         *  @param tension sustain rate of the tone
         */
        public function setKarplusStrongParam(ar:int=48, dr:int=48, tl:int=0, fixedPitch:int=0, ws:int=SiOPMTable.PG_NOISE_PINK, tension:int=8) : void
        {
            _ks_seedType = KS_SEED_DEFAULT;
            setAlgorism(1, 0);
            setFeedBack(0, 0);
            setSiOPMParameters(ar, dr, 0, 63, 15, tl, 0, 0, 1, 0, 0, 0, 0, fixedPitch);
            activeOperator.pgType = ws;
            activeOperator.ptType = _table.getWaveTable(activeOperator.pgType).defaultPTType;
            setAllReleaseRate(tension);
        }
        
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** Set parameters (&#64; commands 2nd-15th args.). (&#64;alg,ar,dr,tl,fix,ws)
         */
        override public function setParameters(param:Vector.<int>) : void
        {
            _ks_seedType = (param[0] == int.MIN_VALUE) ? 0 : param[0];
            _ks_seedIndex =(param[1] == int.MIN_VALUE) ? 0 : param[1];
            
            switch (_ks_seedType) {
            case KS_SEED_FM:
                if (_ks_seedIndex>=0 && _ks_seedIndex<SiMMLTable.VOICE_MAX) {
                    var voice:SiMMLVoice = SiMMLTable.instance.getSiMMLVoice(_ks_seedIndex);
                    if (voice) setSiOPMChannelParam(voice.channelParam, false);
                }
                break;
            case KS_SEED_PCM:
                if (_ks_seedIndex>=0 && _ks_seedIndex<SiOPMTable.PCM_DATA_MAX) {
                    var pcm:SiOPMWavePCMTable = _table.getPCMData(_ks_seedIndex);
                    if (pcm) setWaveData(pcm);
                }
                break;
            default:
                _ks_seedType = KS_SEED_DEFAULT;
                //setAlgorism(1, 0);
                //setFeedBack(0, 0);
                setSiOPMParameters(param[1], param[2], 0, 63, 15, param[3], 0, 0, 1, 0, 0, 0, 0, param[4]);
                activeOperator.pgType = (param[5] == int.MIN_VALUE) ? SiOPMTable.PG_NOISE_PINK : param[5];
                activeOperator.ptType = _table.getWaveTable(activeOperator.pgType).defaultPTType;
                break;
            }
        }
        
        
        /** pgType and ptType (&#64; commands 1st arg except for %6,7) */
        override public function setType(pgType:int, ptType:int) : void
        {
            _ks_seedType = pgType;
            _ks_seedIndex = 0;
        }
        
        
        /** Attack rate */
        override public function setAllAttackRate(ar:int) : void 
        {
            var ope:SiOPMOperator = operator[0];
            ope.ar = ar;
            ope.dr = (ar>48) ? 48 : ar;
            ope.tl = (ar>48) ? 0 : (48-ar);
        }
        
        
        /** Release rate (s) */
        override public function setAllReleaseRate(rr:int) : void 
        {
            _ks_decay_lpf = 1 - rr * 0.015625; // 1/64
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** pitch = (note &lt;&lt; 6) | (kf &amp; 63) [0,8191] */
        override public function get pitch() : int { return _ks_pitchIndex; }
        override public function set pitch(p:int) : void {
            _ks_pitchIndex = p;
        }
        
        /** release rate (&#64;rr) */
        override public function set rr(i:int) : void {
            _ks_decay_lpf = 1 - i * 0.015625; // 1/64
        }
        
        /** fixed pitch (&#64;fx) */
        override public function set fixedPitch(i:int) : void { 
            for (var i:int=0; i<_operatorCount; i++) operator[i].fixedPitchIndex = i;
        }
        
        
        
        
    // volume controls
    //--------------------------------------------------
        /** update all tl offsets of final carriors */
        override public function offsetVolume(expression:int, velocity:int) : void
        {
            _expression = expression * 0.0078125;
            super.offsetVolume(128, velocity);
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Initialize. */
        override public function initialize(prev:SiOPMChannelBase, bufferIndex:int) : void
        {
            _ks_delayBufferIndex = 0;
            _ks_pitchIndex = 0;
            _ks_decay_lpf = 0.875;
            _ks_decay = 0.98;
            _ks_mute_decay_lpf = 0.5;
            _ks_mute_decay = 0.75;
            
            _output = 0;
            _decay_lpf = _ks_mute_decay_lpf;
            _decay     = _ks_mute_decay;
            _expression = 1;
            
            super.initialize(prev, bufferIndex);
            
            _ks_seedType = 0;
            _ks_seedIndex = 0;
            setSiOPMParameters(48, 48, 0, 63, 15, 0, 0, 0, 1, 0, 0, 0, -1, 0);
            activeOperator.pgType = SiOPMTable.PG_NOISE_PINK;
            activeOperator.ptType = SiOPMTable.PT_PCM;
        }
        
        
        /** Reset. */
        override public function reset() : void
        {
            for (var i:int =0; i<KS_BUFFER_SIZE; i++) _ks_delayBuffer[i] = 0;
            super.reset();
        }
        
        
        /** Note on. */
        override public function noteOn() : void
        {
            _output    = 0;
            for (var i:int =0; i<KS_BUFFER_SIZE; i++) _ks_delayBuffer[i] *= 0.3;
            _decay_lpf = _ks_decay_lpf;
            _decay     = _ks_decay;
            
            super.noteOn();
        }
        
        
        /** Note off. */
        override public function noteOff() : void
        {
            _decay_lpf = _ks_mute_decay_lpf;
            _decay     = _ks_mute_decay;
        }
        
        
        /** Prepare buffering */
        override public function resetChannelBufferStatus() : void
        {
            _bufferIndex = 0;
            _isIdling = false;
        }
        
        
        
        /** Buffering */
        override public function buffer(len:int) : void
        {
            var i:int, stream:SiOPMStream;
            
            if (_isIdling) {
                // idling process
                _nop(len);
            } else {
                // preserve _outPipe
                var monoOut:SLLint = _outPipe;
                
                // processing (update _outPipe inside)
                _funcProcess(len);
                
                // ring modulation
                if (_ringPipe) _applyRingModulation(monoOut, len);
                
                // Karplus-Strong algorism
                _applyKarplusStrong(monoOut, len);
                
                // State variable filter
                if (_filterOn) _applySVFilter(monoOut, len);
                
                // standard output
                if (_outputMode == OUTPUT_STANDARD && !_mute) {
                    if (_hasEffectSend) {
                        for (i=0; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                            if (_volumes[i]>0) {
                                stream = _streams[i] || _chip.streamSlot[i];
                                if (stream) stream.write(monoOut, _bufferIndex, len, _volumes[i]*_expression, _pan);
                            }
                        }
                    } else {
                        stream = _streams[0] || _chip.outputStream;
                        stream.write(monoOut, _bufferIndex, len, _volumes[0]*_expression, _pan);
                    }
                }
            }
            
            // update buffer index
            _bufferIndex += len;
        }
        
        
        // Karplus-Strong algorism
        private function _applyKarplusStrong(pointer:SLLint, len:int) : void
        {
            var i:int, t:int, indexMax:Number, tmax:int = SiOPMTable.PITCH_TABLE_SIZE-1;
            t = _ks_pitchIndex + operator[0]._pitchIndexShift + _pm_out;
            if (t<0) t=0;
            else if (t>tmax) t=tmax;
            indexMax = _table.pitchWaveLength[t];
            
            for (i=0; i<len; i++) {
                // lfo_update();
                _lfo_timer -= _lfo_timer_step;
                if (_lfo_timer < 0) {
                    _lfo_phase = (_lfo_phase+1) & 255;
                    t = _lfo_waveTable[_lfo_phase];
                    //_am_out = (t * _am_depth) >> 7 << 3;
                    _pm_out = (((t<<1)-255) * _pm_depth) >> 8;
                    t = _ks_pitchIndex + operator[0]._pitchIndexShift + _pm_out;
                    if (t<0) t=0;
                    else if (t>tmax) t=tmax;
                    indexMax = _table.pitchWaveLength[t];
                    _lfo_timer += _lfo_timer_initial;
                }
                
                // ks_update();
                if (++_ks_delayBufferIndex >= indexMax) _ks_delayBufferIndex %= indexMax;
                _output *= _decay;
                t = int(_ks_delayBufferIndex);
                _output += (_ks_delayBuffer[t] - _output) * _decay_lpf + pointer.i;
                _ks_delayBuffer[t] = _output;
                pointer.i = int(_output);
                pointer = pointer.next;
            }
        }
    }
}

