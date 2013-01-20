//----------------------------------------------------------------------------------------------------
// SiOPM sound channel base class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module.channels {
    import org.si.utils.SLLint;
    import org.si.utils.SLLNumber;
    import org.si.sion.module.*;
    
    
    /** SiOPM sound channel base class. <br/>
     *  The SiOPM sound channels generate wave data and write it into streaming buffer.
     */
    public class SiOPMChannelBase
    {
    // constants
    //--------------------------------------------------
        /** standard output */ static public const OUTPUT_STANDARD:int = 0;
        /** overwrite pipe  */ static public const OUTPUT_OVERWRITE:int = 1;
        /** add to pipe     */ static public const OUTPUT_ADD:int = 2;
        
        /** no input from pipe  */ static public const INPUT_ZERO:int = 0;
        /** input from pipe     */ static public const INPUT_PIPE:int = 1;
        /** input from feedback */ static public const INPUT_FEEDBACK:int = 2;
        
        /** low pass filter */  static public const FILTER_LP:int = 0;
        /** band pass filter */ static public const FILTER_BP:int = 1;
        /** high pass filter */ static public const FILTER_HP:int = 2;
        
        // LPF envelop status
        static private const EG_ATTACK:int = 0;
        static private const EG_DECAY1:int = 1;
        static private const EG_DECAY2:int = 2;
        static private const EG_SUSTAIN:int = 3;
        static private const EG_RELEASE:int = 4;
        static private const EG_OFF:int = 5;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** table */
        protected var _table:SiOPMTable;
        /** chip */
        protected var _chip:SiOPMModule;
        /** functor to process */
        protected var _funcProcess:Function = _nop;
        /** note on flag */
        protected var _isNoteOn:Boolean;
        
        // Pipe buffer
        /** buffering index */  protected var _bufferIndex:int;
        /** input level */      protected var _inputLevel:int;
        /** ringmod level */    protected var _ringmodLevel:Number;
        /** input level */      protected var _inputMode:int;
        /** output mode */      protected var _outputMode:int;
        /** in pipe */          protected var _inPipe  :SLLint;
        /** ringmod pipe */     protected var _ringPipe:SLLint;
        /** base pipe */        protected var _basePipe:SLLint;
        /** out pipe */         protected var _outPipe :SLLint;
        
        // volume and stream
        /** stream */           protected var _streams:Vector.<SiOPMStream>;
        /** volume */           protected var _volumes:Vector.<Number>;
        /** idling flag */      protected var _isIdling:Boolean;
        /** pan */              protected var _pan:int;
        /** effect send flag */ protected var _hasEffectSend:Boolean;
        /** mute */             protected var _mute:Boolean;
        /** veocity table */    protected var _veocityTable:Vector.<int>;
        /** expression table */ protected var _expressionTable:Vector.<int>;
        
        // LPFilter
        /** filter switch */    protected var _filterOn:Boolean;
        /** filter type */      protected var _filterType:int;
        /** cutoff frequency */ protected var _cutoff:int;
        /** cutoff frequency */ protected var _cutoff_offset:int;
        /** resonance */        protected var _resonance:Number;
        /** filter Variables */ protected var _filterVriables:Vector.<Number>;
        /** eg step residue */  protected var _prevStepRemain:int;
        /** eg step */          protected var _filter_eg_step:int;
        /** eg phase shift l.*/ protected var _filter_eg_next:int;
        /** eg direction */     protected var _filter_eg_cutoff_inc:int;
        /** eg state */         protected var _filter_eg_state:int;
        /** eg rate */          protected var _filter_eg_time:Vector.<int>;
        /** eg level */         protected var _filter_eg_cutoff:Vector.<int>;
        
        // Low frequency oscillator
        /** frequency ratio */  protected var _freq_ratio:int;
        /** lfo switch */       protected var _lfo_on:int;
        /** lfo timer */        protected var _lfo_timer:int;
        /** lfo timer step */   protected var _lfo_timer_step:int;
        /** lfo step buffer */  protected var _lfo_timer_step_:int;
        /** lfo phase */        protected var _lfo_phase:int;
        /** lfo wave table */   protected var _lfo_waveTable:Vector.<int>;
        /** lfo wave shape */   protected var _lfo_waveShape:int;
        

        
        
    // constructor
    //--------------------------------------------------
        /** Constructor @param chip Managing SiOPMModule. */
        function SiOPMChannelBase(chip:SiOPMModule)
        {
            _table = SiOPMTable.instance;
            _chip = chip;
            _isFree = true;
            
            _filterVriables = new Vector.<Number>(3, true);
            _streams = new Vector.<SiOPMStream>(SiOPMModule.STREAM_SEND_SIZE, true);
            _volumes = new Vector.<Number>(SiOPMModule.STREAM_SEND_SIZE, true);
            _filter_eg_time   = new Vector.<int>(6, true);
            _filter_eg_cutoff = new Vector.<int>(6, true);
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** Set by SiOPMChannelParam. */
        public function setSiOPMChannelParam(param:SiOPMChannelParam, withVolume:Boolean, withModulation:Boolean=true) : void {}
        /** Get SiOPMChannelParam. */
        public function getSiOPMChannelParam(param:SiOPMChannelParam) : void {}
        /** Set wave data. */
        public function setWaveData(waveData:SiOPMWaveBase) : void {}
        
        /** channel number (2nd argument of %) */
        public function setChannelNumber(channelNum:int) : void {}
        /** algorism (&#64;al) */
        public function setAlgorism(cnt:int, alg:int) : void {}
        /** feedback (&#64;fb) */
        public function setFeedBack(fb:int, fbc:int) : void {}
        /** parameters (&#64; call from SiMMLTrack._setChannelParameters()) */
        public function setParameters(param:Vector.<int>) : void {}
        /** pgType and ptType (&#64; call from SiMMLChannelSetting.selectTone()/initializeTone()) */
        public function setType(pgType:int, ptType:int) : void {}
        /** Attack rate */
        public function setAllAttackRate(ar:int) : void {}
        /** Release rate (s) */
        public function setAllReleaseRate(rr:int) : void {}
        
        /** Master volume (0-128) */
        public function get masterVolume() : int { return _volumes[0]*128; }
        public function set masterVolume(v:int) : void {
            v = (v<0) ? 0 : (v>128) ? 128 : v;
            _volumes[0] = v * 0.0078125;     // 0.0078125 = 1/128
        }
        
        /** Pan (-64-64 left=-64, center=0, right=64).<br/>
         *  [left volume]  = cos((pan+64)/128*PI*0.5) * volume;<br/>
         *  [right volume] = sin((pan+64)/128*PI*0.5) * volume;
         */
        public function get pan() : int { return _pan-64; }
        public function set pan(p:int) : void {
            _pan = (p<-64) ? 0 : (p>64) ? 128 : (p+64);
        }
        
        /** Mute */
        public function get mute() : Boolean { return _mute; }
        public function set mute(m:Boolean) : void {
            _mute = m;
        }
        
        
        /** active operator index (i). */
        public function set activeOperatorIndex(i:int) : void { }
        /** Release rate (&#64;rr) */
        public function set rr(r:int) : void {}
        /** total level (&#64;tl)  */
        public function set tl(i:int) : void {}
        /** fine multiple (&#64;ml)  */
        public function set fmul(i:int) : void {}
        /** phase (&#64;ph) */
        public function set phase(i:int) : void {}
        /** detune (&#64;dt) */
        public function set detune(i:int) : void {}
        /** fixed pitch (&#64;fx) */
        public function set fixedPitch(i:int) : void {}
        /** ssgec (&#64;se) */
        public function set ssgec(i:int) : void {}
        /** envelop reset (&#64;er) */
        public function set erst(b:Boolean) : void {}
        
        /** pitch */
        public function get pitch()      : int  { return 0; }
        public function set pitch(i:int) : void {}
        
        /** buffer index */
        public function get bufferIndex() : int { return _bufferIndex; }
        
        /** is this channel note on ? */
        public function get isNoteOn() : Boolean { return _isNoteOn; }
        
        /** Is idling ? */
        public function get isIdling() : Boolean { return _isIdling; }
        
        /** Is filter active ? */
        public function get isFilterActive() : Boolean { return _filterOn; }
        
        
        /** filter mode */
        public function get filterType() : int { return _filterType; }
        public function set filterType(mode:int) : void
        {
            _filterType = (mode<0 || mode>2) ? 0 : mode;
        }
        
        
        
        
    // volume control
    //--------------------------------------------------
        /** set all stream send levels by Vector.&lt;int&gt;.
         *  @param param Vector.&lt;int&gt;(8) of all volumes[0-128].
         */
        public function setAllStreamSendLevels(param:Vector.<int>) : void
        {
            var i:int, imax:int = SiOPMModule.STREAM_SEND_SIZE, v:int;
            for (i=0; i<imax; i++) {
                v = param[i];
                _volumes[i] = (v != int.MIN_VALUE) ? (v * 0.0078125) : 0;
            }
            for (_hasEffectSend=false, i=1; i<imax; i++) {
                if (_volumes[i] > 0) _hasEffectSend = true;
            }
        }
        
        
        /** set stream buffer.
         *  @param streamNum stream number[0-7]. The streamNum of 0 means master stream.
         *  @param stream stream buffer instance. Set null to set as default.
         */
        public function setStreamBuffer(streamNum:int, stream:SiOPMStream = null) : void
        {
            _streams[streamNum] = stream;
        }
        
        
        /** set stream send.
         *  @param streamNum stream number[0-7]. The streamNum of 0 means master volume.
         *  @param volume send level[0-1].
         */
        public function setStreamSend(streamNum:int, volume:Number) : void
        {
            _volumes[streamNum] = volume;
            if (streamNum == 0) return;
            if (volume > 0) _hasEffectSend = true;
            else {
                var i:int, imax:int = SiOPMModule.STREAM_SEND_SIZE;
                for (_hasEffectSend=false, i=1; i<imax; i++) {
                    if (_volumes[i] > 0) _hasEffectSend = true;
                }
            }
        }
        

        /** get stream send.
         *  @param streamNum stream number[0-7]. The streamNum of 0 means master volume.
         *  @return send level[0-1].
         */ 
        public function getStreamSend(streamNum:int) : Number
        {
            return _volumes[streamNum];
        }        
        
        
        /** offset volume, controled by SiMMLTrack. */
        public function offsetVolume(expression:int, velocity:int) : void
        {
        }
        
        
        
        
    // LFO control
    //--------------------------------------------------
        /** set chip "PSEUDO" frequency ratio by [%] (&#64;clock). */
        public function setFrequencyRatio(ratio:int) : void
        {
            _freq_ratio = ratio;
        }
        
        
        /** initialize LFO (&#64;lfo). 
         *  @param waveform waveform number, -1 to set customized wave table
         *  @param customWaveTable customized wave table, the length is 256 and the values are limited in the range of 0-255. This argument is available when waveform=-1.
         */
        public function initializeLFO(waveform:int, customWaveTable:Vector.<int>=null) : void
        {
            if (waveform == -1 && customWaveTable && customWaveTable.length == 256) {
                _lfo_waveShape = -1;
                _lfo_waveTable = customWaveTable;
            } else {
                _lfo_waveShape = (0<=waveform && waveform<=SiOPMTable.LFO_WAVE_MAX) ? waveform : SiOPMTable.LFO_WAVE_TRIANGLE;
                _lfo_waveTable = _table.lfo_waveTables[_lfo_waveShape];
            }
            _lfo_timer = 1;
            _lfo_timer_step_ = _lfo_timer_step = 0;
            _lfo_phase = 0;
        }
        
        
        /** set LFO cycle time (&#64;lfo). */
        public function setLFOCycleTime(ms:Number) : void
        {
            _lfo_timer = 0;
            // 0.17294117647058824 = 44100/(1000*255)
            _lfo_timer_step_ = _lfo_timer_step = (SiOPMTable.LFO_TIMER_INITIAL/(ms*0.17294117647058824)) << _table.sampleRatePitchShift;
            
            //set OPM LFO frequency
            //_lfo_timer = 0;
            //_lfo_timer_step_ = _lfo_timer_step = _table.lfo_timerSteps[freq & 255];
        }
        
        
        /** amplitude modulation (ma) */
        public function setAmplitudeModulation(depth:int) : void {}
        
        
        /** pitch modulation (mp) */
        public function setPitchModulation(depth:int) : void {}
        
        
        
        
    // filter control
    //--------------------------------------------------
        /** Filter activation */
        public function activateFilter(b:Boolean) : void
        {
            _filterOn = b;
        }
        
        
        /** SVFilter envelop (&#64;f).
         *  @param cutoff initial cutoff (0-128).
         *  @param resonance resonance (0-9).
         *  @param ar attack rate (0-63).
         *  @param dr1 decay rate 1 (0-63).
         *  @param dr2 decay rate 2 (0-63).
         *  @param rr release rate (0-63).
         *  @param dc1 decay cutoff level 1 (0-128).
         *  @param dc2 decay cutoff level 2 (0-128).
         *  @param sc sustain cutoff level (0-128).
         *  @param rc release cutoff level (0-128).
         */
        public function setSVFilter(cutoff:int=128, resonance:int=0, ar:int=0, dr1:int=0, dr2:int=0, rr:int=0, dc1:int=128, dc2:int=128, sc:int=128, rc:int=128) : void
        {
            _filter_eg_cutoff[EG_ATTACK]  = (cutoff<0)  ? 0 : (cutoff>128)  ? 128 : cutoff;
            _filter_eg_cutoff[EG_DECAY1]  = (dc1<0) ? 0 : (dc1>128) ? 128 : dc1;
            _filter_eg_cutoff[EG_DECAY2]  = (dc2<0) ? 0 : (dc2>128) ? 128 : dc2;
            _filter_eg_cutoff[EG_SUSTAIN] = (sc<0)  ? 0 : (sc>128)  ? 128 : sc;
            _filter_eg_cutoff[EG_RELEASE] = 0;
            _filter_eg_cutoff[EG_OFF]     = (rc<0) ? 0 : (rc>128) ? 128 : rc;
            _filter_eg_time  [EG_ATTACK]  = _table.filter_eg_rate[ar & 63];
            _filter_eg_time  [EG_DECAY1]  = _table.filter_eg_rate[dr1 & 63];
            _filter_eg_time  [EG_DECAY2]  = _table.filter_eg_rate[dr2 & 63];
            _filter_eg_time  [EG_SUSTAIN] = int.MAX_VALUE;
            _filter_eg_time  [EG_RELEASE] = _table.filter_eg_rate[rr & 63];
            _filter_eg_time  [EG_OFF]     = int.MAX_VALUE;
            
            var res:int = (resonance<0) ? 0 : (resonance>9) ? 9 : resonance;
            _resonance = (1 << (9 - res)) * 0.001953125;   // 0.001953125=1/512
            
            _filterOn = (cutoff<128 || resonance>0 || ar>0 || rr>0);
        }
        
        
        /** LP Filter cutoff offset controled by table envelop (nf) */
        public function offsetFilter(i:int) : void
        {
            _cutoff_offset = i-128;
        }
        
        
        
        
    // connection control
    //--------------------------------------------------
        /** Set input pipe (&#64;i). 
         *  @param level Input level. The value for a standard FM sound module is 5.
         *  @param pipeIndex Input pipe index (0-3).
         */
        public function setInput(level:int, pipeIndex:int) : void
        {
            // pipe index
            pipeIndex &= 3;
            
            // set pipe
            if (level > 0) {
                _inPipe = _chip.getPipe(pipeIndex, _bufferIndex);
                _inputMode = INPUT_PIPE;
                _inputLevel = level + 10;
            } else {
                _inPipe = _chip.zeroBuffer;
                _inputMode = INPUT_ZERO;
                _inputLevel = 0;
            }
        }
        
        
        /** Set ring modulation pipe (&#64;r).
         *  @param level. Input level(0-8).
         *  @param pipeIndex Input pipe index (0-3).
         */
        public function setRingModulation(level:int, pipeIndex:int) : void
        {
            var i:int;

            // pipe index
            pipeIndex &= 3;
            
            // ring modulation level
            _ringmodLevel = level*4/Number(1<<SiOPMTable.LOG_VOLUME_BITS);
            
            // set pipe
            _ringPipe = (level > 0) ? _chip.getPipe(pipeIndex, _bufferIndex) : null;
        }
        
        
        /** Set output pipe (&#64;o).
         *  @param outputMode Output mode. 0=standard stereo out, 1=overwrite pipe. 2=add pipe.
         *  @param pipeIndex Output stream/pipe index (0-3).
         */
        public function setOutput(outputMode:int, pipeIndex:int) : void
        {
            var i:int, flagAdd:Boolean;
            
            // pipe index
            pipeIndex &= 3;

            // set pipe
            if (outputMode == OUTPUT_STANDARD) {
                pipeIndex = 4;      // pipe[4] is used.
                flagAdd = false;    // ovewrite mode
            } else {
                flagAdd = (outputMode == OUTPUT_ADD);  // ovewrite/additional mode
            }

            // output mode
            _outputMode = outputMode;

            // set output pipe
            _outPipe = _chip.getPipe(pipeIndex, _bufferIndex);

            // set base pipe
            _basePipe = (flagAdd) ? (_outPipe) : (_chip.zeroBuffer);
        }
        
        
        /** set velocity and expression tables
         *  @param vtable volume table (length = 513)
         *  @param xtable expression table (length = 513)
         */
        public function setVolumeTables(vtable:Vector.<int>, xtable:Vector.<int>) : void
        {
            _veocityTable = vtable;
            _expressionTable = xtable;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** Initialize. */
        public function initialize(prev:SiOPMChannelBase, bufferIndex:int) : void
        {
            // volume
            var i:int, imax:int = SiOPMModule.STREAM_SEND_SIZE;
            if (prev) {
                for (i=0; i<imax; i++) {
                    _volumes[i] = prev._volumes[i];
                    _streams[i] = prev._streams[i];
                }
                _pan = prev._pan;
                _hasEffectSend = prev._hasEffectSend;
                _mute = prev._mute;
                _veocityTable = prev._veocityTable;
                _expressionTable = prev._expressionTable;
            } else {
                _volumes[0] = 0.5;
                _streams[0] = null;
                for (i=1; i<imax; i++) {
                    _volumes[i] = 0;
                    _streams[i] = null;
                }
                _pan = 64;
                _hasEffectSend = false;
                _mute = false;
                _veocityTable = _table.eg_tlTableLine;
                _expressionTable = _table.eg_tlTableLine;
            }
            
            // buffer index
            _isNoteOn = false;
            _isIdling = true;
            _bufferIndex  = bufferIndex;
            
            // LFO
            initializeLFO(SiOPMTable.LFO_WAVE_TRIANGLE);
            setLFOCycleTime(333);
            setFrequencyRatio(100);
            
            // Connection
            setInput(0, 0);
            setRingModulation(0, 0);
            setOutput(OUTPUT_STANDARD, 0);
            
            // LPFilter
            _filterVriables[0] = _filterVriables[1] = _filterVriables[2] = 0;
            _cutoff_offset = 0;
            _filterType = FILTER_LP;
            setSVFilter();
            shiftSVFilterState(EG_OFF);
        }
        
        
        /** Reset */
        public function reset() : void
        {
            _isNoteOn = false;
            _isIdling = true;
        }
        
        
        /** Note on */
        public function noteOn() : void
        {
            _lfo_phase = 0;     // reset lfo phase
            if (_filterOn) {    // reset envelop
                resetSVFilterState();
                shiftSVFilterState(EG_ATTACK);
            }
            _isNoteOn = true;
        }
        
        
        /** Note off */
        public function noteOff() : void
        {
            if (_filterOn) {    // shift filters status
                shiftSVFilterState(EG_RELEASE);
            }
            _isNoteOn = false;
        }
        
        
        /** set register */
        public function setRegister(addr:int, data:int) : void
        {
            
        }
        
        
        
        
    // processing
    //--------------------------------------------------
        /** reset channel buffering status */
        public function resetChannelBufferStatus() : void
        {
            _bufferIndex = 0;
        }
        
        
        /** Buffering */
        public function buffer(len:int) : void
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
                
                // ring modulation / LPFilter
                if (_ringPipe) _applyRingModulation(monoOut, len);
                if (_filterOn) _applySVFilter(monoOut, len);
                
                // standard output
                if (_outputMode == OUTPUT_STANDARD && !_mute) {
                    if (_hasEffectSend) {
                        for (i=0; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                            if (_volumes[i]>0) {
                                stream = _streams[i] || _chip.streamSlot[i];
                                if (stream) stream.write(monoOut, _bufferIndex, len, _volumes[i], _pan);
                            }
                        }
                    } else {
                        stream = _streams[0] || _chip.outputStream;
                        stream.write(monoOut, _bufferIndex, len, _volumes[0], _pan);
                    }
                }
            }
            
            // update buffer index
            _bufferIndex += len;
        }
        
        
        /** Buffering without processnig */
        public function nop(len:int) : void
        {
            _nop(len);
            _bufferIndex += len;
        }
        
        
        /** ring modulation */
        protected function _applyRingModulation(pointer:SLLint, len:int) : void
        {
            var i:int, rp:SLLint = _ringPipe;
            for (i=0; i<len; i++) {
                pointer.i *= rp.i * _ringmodLevel;
                rp = rp.next;
                pointer = pointer.next;
            }
            _ringPipe = rp;
        }
        
        
        /** state variable filter */
        protected function _applySVFilter(pointer:SLLint, len:int, variables:Vector.<Number>=null) : void
        {
            var i:int, imax:int, step:int, out:int, cut:Number, fb:Number;
            
            // initialize
            if (!variables) variables = _filterVriables;
            out = _cutoff + _cutoff_offset;
            if (out<0) out=0 
            else if (out>128) out=128;
            cut = _table.filter_cutoffTable[out];
            fb  = _resonance;// * _table.filter_feedbackTable[out];

            // previous setting
            step = _prevStepRemain;

            while (len >= step) {
                // processing
                for (i=0; i<step; i++) {
                    variables[2] = Number(pointer.i) - variables[0] - variables[1] * fb;
                    variables[1] += variables[2] * cut;
                    variables[0] += variables[1] * cut;
                    pointer.i = int(variables[_filterType]);
                    pointer   = pointer.next;
                }
                len -= step;
                
                // change cutoff and shift state
                _cutoff += _filter_eg_cutoff_inc;
                out = _cutoff + _cutoff_offset;
                if (out<0) out=0 
                else if (out>128) out=128;
                cut = _table.filter_cutoffTable[out];
                fb  = _resonance;// * _table.filter_feedbackTable[out];
                if (_cutoff == _filter_eg_next) shiftSVFilterState(_filter_eg_state+1);

                // next step
                step = _filter_eg_step;
            }
            
            // process remains
            for (i=0; i<len; i++) {
                variables[2] = Number(pointer.i) - variables[0] - variables[1] * fb;
                variables[1] += variables[2] * cut;
                variables[0] += variables[1] * cut;
                pointer.i = int(variables[_filterType]);
                pointer   = pointer.next;
            }
            
            // next setting
            _prevStepRemain = _filter_eg_step - len;
        }

        
        /** reset SVFilter */
        protected function resetSVFilterState() : void
        {
            _cutoff = _filter_eg_cutoff[EG_ATTACK];
        }
        
        
        /** shift SVFilter state */
        protected function shiftSVFilterState(state:int) : void
        {
            switch (state) {
            case EG_ATTACK:
                if (__shift()) break;
                state++;
                // fail through
            case EG_DECAY1:
                if (__shift()) break; 
                state++;
                // fail through
            case EG_DECAY2:
                if (__shift()) break;
                state++;
                // fail through
            case EG_SUSTAIN:
                // catch all
                _filter_eg_state = EG_SUSTAIN;
                _filter_eg_step  = int.MAX_VALUE;
                _filter_eg_next  = _cutoff + 1;
                _filter_eg_cutoff_inc = 0;
                break;
            case EG_RELEASE:
                if (__shift()) break;
                state++;
                // fail through
            case EG_OFF:
                // catch all
                _filter_eg_state = EG_OFF;
                _filter_eg_step  = int.MAX_VALUE;
                _filter_eg_next  = _cutoff + 1;
                _filter_eg_cutoff_inc = 0;
                break;
            }
            _prevStepRemain = _filter_eg_step;
            
            function __shift() : Boolean
            {
                if (_filter_eg_time[state] == 0) return false;
                _filter_eg_state = state;
                _filter_eg_step  = _filter_eg_time[state];
                _filter_eg_next  = _filter_eg_cutoff[state + 1];
                _filter_eg_cutoff_inc = (_cutoff < _filter_eg_next) ? 1 : -1;
                return (_cutoff != _filter_eg_next);
            }
        }
        
        

        /** No process (default functor of _funcProcess). */
        protected function _nop(len:int) : void
        {
            var i:int, p:SLLint;
            
            // rotate output buffer
            if (_outputMode == OUTPUT_STANDARD) {
                _outPipe = _chip.getPipe(4, (_bufferIndex + len) & (_chip.bufferLength-1));
            } else {
                for (p=_outPipe, i=0; i<len; i++) p = p.next;
                _outPipe  = p;
                _basePipe = (_outputMode == OUTPUT_ADD) ? p : _chip.zeroBuffer;
            }
            
            // rotate input buffer when connected by @i
            if (_inputMode == INPUT_PIPE) {
                for (p=_inPipe, i=0; i<len; i++) p = p.next;
                _inPipe = p;
            }
            
            // rotate ring buffer
            if (_ringPipe) {
                for (p=_ringPipe, i=0; i<len; i++) p = p.next;
                _ringPipe = p;
            }
        }
        
        
        
        
    // for channel manager operation [internal use]
    //--------------------------------------------------
        /** @private [internal] DLL of channels */
        internal var _isFree:Boolean = true;
        /** @private [internal] DLL of channels */
        internal var _channelType:int = -1;
        /** @private [internal] DLL of channels */
        internal var _next:SiOPMChannelBase = null;
        /** @private [internal] DLL of channels */
        internal var _prev:SiOPMChannelBase = null;
        
        /** channel type */
        public function get channelType() : int { return _channelType; }
    }
}


