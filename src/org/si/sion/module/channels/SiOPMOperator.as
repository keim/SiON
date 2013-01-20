//----------------------------------------------------------------------------------------------------
// SiOPM operator class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module.channels {
    import org.si.utils.SLLint;
    import org.si.sion.module.*;
    
    
    /** SiOPM operator class.
     *  This operator based on the OPM emulation of MAME, but its extended in below points,<br/>
     *  1) You can set the phase offest of pulse generator. <br/>
     *  2) You can select the wave form from some wave tables (see class SiOPMTable).<br/>
     *  3) You can set the key scale level.<br/>
     *  4) You can fix the pitch.<br/>
     *  5) You can set the ssgec in OPNA.<br/>
     */
    public class SiOPMOperator
    {
    // constants
    //--------------------------------------------------
        // State of envelop generator.
        static public const EG_ATTACK :int = 0;
        static public const EG_DECAY  :int = 1;
        static public const EG_SUSTAIN:int = 2;
        static public const EG_RELEASE:int = 3;
        static public const EG_OFF    :int = 4;
        
        
        // waveFixedBits for PCM
        static private const PCM_waveFixedBits:int = 11;
        
        
        
                
    // valiables
    //--------------------------------------------------
    // [ IMPORTANT NOTE ] 
    // The access levels of all valiables are set as "internal". 
    // The SiOPMChannelFM accesses these valiables directly only from the wave processing functions to make it faster.
    // Never access these valiables in other classes reason for the maintenances.
    //----------------------------------------------------------------------------------------------------
        /** @private table */
        internal var _table:SiOPMTable;
        /** @private chip */
        internal var _chip:SiOPMModule;
        
        
    // FM module parameters
        /** @private Attack rate [0,63] */
        internal var _ar:int;
        /** @private Decay rate [0,63] */
        internal var _dr:int;
        /** @private Sustain rate [0,63] */
        internal var _sr:int;
        /** @private Release rate [0,63] */
        internal var _rr:int;
        /** @private Sustain level [0,15] */
        internal var _sl:int;
        /** @private Total level [0,127] */
        internal var _tl:int;
        /** @private Key scaling rate = 5-ks [5,2] */
        internal var _ks:int;
        /** @private Key scaling level [0,3] */
        internal var _ksl:int;
        /** @private _multiple = (mul) ? (mul&lt;&lt;7) : 64; [64,128,256,384,512...] */
        internal var _multiple:int;
        /** @private dt1 [0,7]. */
        internal var _dt1:int;
        /** @private dt2 [0,3]. This value is linked with _pitchIndexShift */
        internal var _dt2:int;
        /** @private Amp modulation shift [16,0] */
        internal var _ams:int;
        /** @private Key code = oct&lt;&lt;4 + note [0,127] */
        internal var _kc:int;
        /** @private SSG type envelop control */
        internal var _ssg_type:int;
        /** @private Mute [0/SiOPMTable.ENV_BOTTOM] */
        internal var _mute:int;
        /** @priavet Envelop reset on attack */
        internal var _erst:Boolean;
        
        
    // pulse generator
        /** @private pulse generator type */
        internal var _pgType:int;
        /** @private pitch table type */
        internal var _ptType:int;
        /** @private wave table */
        internal var _waveTable:Vector.<int>;
        /** @private phase shift */
        internal var _waveFixedBits:int;
        /** @private phase step shift */
        internal var _wavePhaseStepShift:int;
        /** @private pitch table */
        internal var _pitchTable:Vector.<int>;
        /** @private pitch table index filter */
        internal var _pitchTableFilter:int;
        /** @private phase */
        internal var _phase:int;
        /** @private phase step */
        internal var _phase_step:int;
        /** @private keyOn phase. -1 sets no phase reset. */
        internal var _keyon_phase:int;
        /** @private pitch fixed */
        internal var _pitchFixed:Boolean;
        /** @private dt1 table */
        internal var _dt1Table:Vector.<int>;

        
        /** @private pitch index = note * 64 + key fraction */
        internal var _pitchIndex:int;
        /** @private pitch index shift. This value is linked with dt2 and detune. */
        internal var _pitchIndexShift:int;
        /** @private pitch index shift by pitch modulation. This value is linked with dt2. */
        internal var _pitchIndexShift2:int;
        /** @private frequency modulation left-shift. 15 for FM, fb+6 for feedback. */
        internal var _fmShift:int;
        
        
    // envelop generator
        /** @private State [EG_ATTACK, EG_DECAY, EG_SUSTAIN, EG_RELEASE, EG_OFF] */
        internal var _eg_state:int;
        /** @private Envelop generator updating timer, initialized (2047 * 3) &lt;&lt; CLOCK_RATIO_BITS. */
        internal var _eg_timer:int;
        /** @private Timer stepping by samples */
        internal var _eg_timer_step:int;
        /** @private Counter rounded on 8. */
        internal var _eg_counter:int;
        /** @private Internal sustain level [0,SiOPMTable.ENV_BOTTOM] */
        internal var _eg_sustain_level :int;
        /** @private Internal total level [0,1024] = ((tl + f(kc, ksl)) &lt;&lt; 3) + _eg_tl_offset + 192. */
        internal var _eg_total_level:int;
        /** @private Internal total level offset by volume [-192,832]*/
        internal var _eg_tl_offset:int;
        /** @private Internal key scaling rate = _kc >> _ks [0,32] */
        internal var _eg_key_scale_rate:int;
        /** @private Internal key scaling level right shift = _ksl[0,1,2,3]->[8,2,1,0] */
        internal var _eg_key_scale_level_rshift:int;
        /** @private Envelop generator level [0,1024] */
        internal var _eg_level:int;
        /** @private Envelop generator output [0,1024&lt;&lt;3] */
        internal var _eg_out:int;
        /** @private SSG envelop control ar switch */
        internal var _eg_ssgec_ar:int;
        /** @private SSG envelop control state */
        internal var _eg_ssgec_state:int;
        
        /** @private Increment table picked up from _eg_incTables or _eg_incTablesAtt. */
        internal var _eg_incTable:Vector.<int>;
        /** @private The level to shift the state to next. */
        internal var _eg_stateShiftLevel:int;
        /** @private Next status list */
        internal var _eg_nextState:Vector.<int>;
        /** @private _eg_level converter */
        internal var _eg_levelTable:Vector.<int>;
        // Next status table
        static private var _table_nextState:Array = [
            //            EG_ATTACK,  EG_DECAY,   EG_SUSTAIN, EG_RELEASE, EG_OFF
            Vector.<int>([EG_DECAY,   EG_SUSTAIN, EG_OFF,     EG_OFF,     EG_OFF]), // normal
            Vector.<int>([EG_DECAY,   EG_SUSTAIN, EG_ATTACK,  EG_OFF,     EG_OFF])  // ssgev
        ];
        
        
    // pipes
        /** @private flag that is final carrior. */
        internal var _final:Boolean;
        /** @private modulator output */
        internal var _inPipe:SLLint;
        /** @private base */
        internal var _basePipe:SLLint;
        /** @private output */
        internal var _outPipe:SLLint;
        /** @private feed back */
        internal var _feedPipe:SLLint;
        
    // for PCM wave
        /** @private channel count */
        internal var _pcm_channels:int;
        /** @private start point */
        internal var _pcm_startPoint:int;
        /** @private end point */
        internal var _pcm_endPoint:int;
        /** @private loop point */
        internal var _pcm_loopPoint:int;
        
        
        
    // properties (fm parameters)
    //--------------------------------------------------
        /** Attack rate [0,63] */
        public function set ar(i:int) : void { 
            _ar = i & 63;
            _eg_ssgec_ar = (_ssg_type == 8 || _ssg_type == 12) ? ((_ar>=56)?1:0) : ((_ar>=60)?1:0);
        }
        /** Decay rate [0,63] */
        public function set dr(i:int) : void { _dr = i & 63; }
        /** Sustain rate [0,63] */
        public function set sr(i:int) : void { _sr = i & 63; }
        /** Release rate [0,63] */
        public function set rr(i:int) : void { _rr = i & 63; }
        /** Sustain level [0,15] */
        public function set sl(i:int) : void {
            _sl = i & 15;
            _eg_sustain_level = _table.eg_slTable[i];
        }
        /** Total level [0,127] */
        public function set tl(i:int) : void {
            _tl = (i < 0) ? 0 : (i > 127) ? 127 : i;
            _updateTotalLevel();
        }
        /** Key scaling rate [0,3] */
        public function set ks(i:int) : void {
            _ks = 5-(i&3);
            _eg_key_scale_rate = _kc >> _ks;
        }
        /** multiple [0,15] */
        public function set mul(m:int) : void {
            m &= 15;
            _multiple = (m) ? (m<<7) : 64;
            _updatePitch();
        }
        /** dt1 [0-7] */
        public function set dt1(d:int) : void {
            _dt1 = d & 7;
            _dt1Table = _table.dt1Table[_dt1];
            _updatePitch();
        }
        /** dt2 [0-3] */
        public function set dt2(d:int) : void {
            _dt2 = d & 3;
            _pitchIndexShift = _table.dt2Table[_dt2];
            _updatePitch();
        }
        /** amplitude modulation enable [t/f] */
        public function set ame(b:Boolean) : void {
            _ams = (b) ? 2 : 16;
        }
        /** amplitude modulation shift [t/f] */
        public function set ams(s:int) : void {
            _ams = (s) ? (3-s) : 16;
        }
        /** Key scaling level [0,3] */
        public function set ksl(i:int) : void {
            _ksl = i;
            // [0,1,2,3]->[8,4,3,2]
            _eg_key_scale_level_rshift = (i==0) ? 8 : (5-i);
            _updateTotalLevel();
        }
        /** SSG type envelop control */
        public function set ssgec(i:int) : void {
            if (i > 7) {
                _eg_nextState = _table_nextState[1];
                _ssg_type = i;
                if (_ssg_type > 17) _ssg_type = 9;
            } else {
                _eg_nextState  = _table_nextState[0];
                _ssg_type = 0;
            }
            
        }
        /** Mute */
        public function set mute(b:Boolean) : void {
            _mute = (b) ? SiOPMTable.ENV_BOTTOM : 0;
            _updateTotalLevel();
        }
        /** Envelop reset on attack */
        public function set erst(b:Boolean) : void {
            _erst = b;
        }
        
        
        public function get ar() : int { return _ar; }
        public function get dr() : int { return _dr; }
        public function get sr() : int { return _sr; }
        public function get rr() : int { return _rr; }
        public function get sl() : int { return _sl; }
        public function get tl() : int { return _tl; }
        public function get ks() : int { return 5-_ks; }
        public function get mul() : int { return (_multiple>>7); }
        public function get dt1() : int { return _dt1; }
        public function get dt2() : int { return _dt2; }
        public function get ame() : Boolean { return (_ams!=16); }
        public function get ams() : int { return (_ams==16) ? 0 : (3-_ams); }
        public function get ksl() : int { return _ksl; }
        public function get ssgec() : int { return _ssg_type; }
        public function get mute() : Boolean { return (_mute != 0); }
        public function get erst() : Boolean { return _erst; }
        
        
    // properties (other fm parameters)
    //--------------------------------------------------
        /** Key code [0,127] */
        public function set kc(i:int) : void {
            if (_pitchFixed) return;
            _updateKC(i & 127);
            _pitchIndex = ((_kc-(_kc>>2)) << 6) | (_pitchIndex & 63);
            _updatePitch();
        }
        /** key fraction [0-63] */
        public function set kf(f:int) : void {
            _pitchIndex = (_pitchIndex & 0xffc0) | (f & 63);
            _updatePitch();
        }
        /** F-Number for OPNA. This property resets kf,dt2 and detune. */
        public function set fnum(f:int) : void {
            // dishonest implement.
            _updateKC((f >> 7) & 127);
            _dt2 = 0;
            _pitchIndex = 0;
            _pitchIndexShift = 0;
            _updatePhaseStep((f & 2047) << ((f >> 11) & 7));
        }

        // Get status, but all of them cannot be read.
        public function get kc() : int { return _kc; }
        public function get kf() : int { return (_pitchIndex & 63); }
        public function get pitchFixed() : Boolean { return _pitchFixed; }
        
        
    // properties (pTSS)
    //--------------------------------------------------
        /** Fixed pitch index. 0 means fixed off. */
        public function set fixedPitchIndex(i:int) : void {
            if (i>0) {
                _pitchIndex = i;
                _updateKC(_table.nnToKC[(i>>6)&127]);
                _updatePitch();
                _pitchFixed = true;
            } else {
                _pitchFixed = false;
            }
        }
        /** pitchIndex = (note &lt;&lt; 6) | (kf &amp; 63) [0,8191] */
        public function set pitchIndex(i:int) : void
        {
            if (_pitchFixed) return;
            _pitchIndex = i;
            _updateKC(_table.nnToKC[(i>>6)&127]);
            _updatePitch();
        }
        /** Detune for pTSS. 1 halftone divides into 64 steps. This property resets dt2. */
        public function set detune(d:int) : void {
            _dt2 = 0;
            _pitchIndexShift = d;
            _updatePitch();
        }
        /** Detune for pitch modulation. This is independent value. */
        public function set detune2(d:int) : void {
            _pitchIndexShift2 = d;
            _updatePitch();
        }
        /** Fine multiple for pTSS. 128=x1. */
        public function set fmul(m:int) : void {
            _multiple = m;
            _updatePitch();
        }
        /** Phase at keyOn [-1-255]. similar with pTSS. The value of 255 sets no phase reset, -1 sets randamize. */
        public function set keyOnPhase(p:int) : void {
            if (p == 255) _keyon_phase = -2;
            else if (p == -1) _keyon_phase = -1;
            else _keyon_phase = (p & 255) << (SiOPMTable.PHASE_BITS - 8);
        }
        /** Pulse generator type. */
        public function set pgType(n:int) : void
        {
            _pgType = n & SiOPMTable.PG_FILTER;
            var waveTable:SiOPMWaveTable = _table.getWaveTable(_pgType);
            _waveTable     = waveTable.wavelet;
            _waveFixedBits = waveTable.fixedBits;
        }
        /** Pitch table type. */
        public function set ptType(n:int) : void
        {
            _ptType = n;
            _wavePhaseStepShift = (SiOPMTable.PHASE_BITS - _waveFixedBits) & _table.phaseStepShiftFilter[n];
            _pitchTable         = _table.pitchTable[n];
            _pitchTableFilter   = _pitchTable.length - 1;
        }
        /** Frequency modulation level. 15 is standard modulation. */
        public function set modLevel(m:int) : void {
            _fmShift = (m) ? (m + 10) : 0;
        }
        
        
        public function get pitchIndex() : int { return _pitchIndex; }
        public function get detune()     : int { return _pitchIndexShift; }
        public function get detune2()    : int { return _pitchIndexShift2; }
        public function get fmul()       : int { return _multiple; }
        public function get keyOnPhase() : int { return (_keyon_phase>=0) ? (_keyon_phase >> (SiOPMTable.PHASE_BITS - 8)) : (_keyon_phase == -1) ? -1 : 255; }
        public function get pgType()     : int { return _pgType; }
        public function get modLevel()   : int { return (_fmShift>10) ? (_fmShift-10) : 0; }
        
        
        /** @private [internal] tl offset [832,-192]. controlled as expression and velocity. */
        internal function _tlOffset(i:int) : void {
            _eg_tl_offset = i;
            _updateTotalLevel();
        }
        
        
        public function toString() : String
        {
            var str:String = "SiOPMOperator : "
            str += String(pgType) + "/";
            str += String(ar) + "/";
            str += String(dr) + "/";
            str += String(sr) + "/";
            str += String(rr) + "/";
            str += String(sl) + "/";
            str += String(tl) + "/";
            str += String(ks) + "/";
            str += String(ksl) + "/";
            str += String(fmul) + "/";
            str += String(dt1) + "/";
            str += String(detune) + "/";
            str += String(ams) + "/";
            str += String(ssgec) + "/";
            str += String(keyOnPhase) + "/";
            str += String(pitchFixed);
            return str;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function SiOPMOperator(chip:SiOPMModule)
        {
            _table = SiOPMTable.instance;
            _chip = chip;
            _feedPipe = SLLint.allocRing(1);
            _eg_incTable   = _table.eg_incTables[17];
            _eg_levelTable = _table.eg_levelTables[0];
            _eg_nextState  = _table_nextState[0];
        }
        
        
        
        
    // operations 
    //--------------------------------------------------
        /** Initialize. */
        public function initialize() : void
        {
            // reset operator connections
            _final = true;
            _inPipe   = _chip.zeroBuffer;
            _basePipe = _chip.zeroBuffer;
            _feedPipe.i = 0;
            
            // reset all parameters
            setSiOPMOperatorParam(_chip.initOperatorParam);
            
            // reset some other parameters 
            _eg_tl_offset     = 0;  // The _eg_tl_offset is controled by velocity and expression.
            _pitchIndexShift2 = 0;  // The _pitchIndexShift2 is controled by pitch modulation.
            _pcm_channels   = 0;
            _pcm_startPoint = 0;
            _pcm_endPoint   = 0;
            _pcm_loopPoint  = -1;
            
            // reset pg and eg status
            reset();
        }
        
        
        /** Reset. */
        public function reset() : void
        {
            _eg_shiftState(EG_OFF);
            _eg_out = (_eg_levelTable[_eg_level] + _eg_total_level)<<3;
            _eg_timer = SiOPMTable.ENV_TIMER_INITIAL;
            _eg_counter = 0;
            _eg_ssgec_state = 0;
            _phase = 0;
        }
        
        
        /** Set paramaters by SiOPMOperatorParam */
        public function setSiOPMOperatorParam(param:SiOPMOperatorParam) : void
        {
            pgType = param.pgType;
            ptType = param.ptType;
            
            if (param.phase == 255) _keyon_phase = -2;
            else if (param.phase == -1) _keyon_phase = -1;
            else _keyon_phase = (param.phase & 255) << (SiOPMTable.PHASE_BITS - 8);
            
            _ar = param.ar & 63;
            _dr = param.dr & 63;
            _sr = param.sr & 63;
            _rr = param.rr & 63;
            _ks = 5 - (param.ksr & 3);
            _ksl = param.ksl & 3;
            _ams = (param.ams) ? (3-param.ams) : 16;
            _multiple = param.fmul;
            _fmShift = (param.modLevel & 7) + 10;
            _dt1 = param.dt1 & 7;
            _dt1Table = _table.dt1Table[_dt1];
            _pitchIndexShift = param.detune;
            ssgec = param.ssgec;
            _mute = (param.mute) ? SiOPMTable.ENV_BOTTOM : 0;
            _erst = param.erst;
            
            // fixed pitch
            if (param.fixedPitch == 0) {
                //_pitchIndex = 3840;
                //_updateKC(_table.nnToKC[(_pitchIndex>>6)&127]);
                _pitchFixed = false;
            } else {
                _pitchIndex = param.fixedPitch;
                _updateKC(_table.nnToKC[(_pitchIndex>>6)&127]);
                _pitchFixed = true;
            }
            // key scale level
            _eg_key_scale_level_rshift = (_ksl==0) ? 8 : (5-_ksl);
            // ar for ssgec
            _eg_ssgec_ar = (_ssg_type == 8 || _ssg_type == 12) ? ((_ar>=56)?1:0) : ((_ar>=60)?1:0);
            // sl,tl requires some special calculation
            sl = param.sl & 15;
            tl = param.tl;
            
            _updatePitch();
        }
        
        
        /** Get paramaters by SiOPMOperatorParam */
        public function getSiOPMOperatorParam(param:SiOPMOperatorParam) : void
        {
            param.pgType = _pgType;
            param.ptType = _ptType;
            
            param.ar = _ar;
            param.dr = _dr;
            param.sr = _sr;
            param.rr = _rr;
            param.sl = sl;
            param.tl = tl;
            param.ksr = ks;
            param.ksl = ksl;
            param.fmul = fmul;
            param.dt1 = _dt1;
            param.detune = detune;
            param.ams = ams;
            param.ssgec = ssgec;
            param.phase = keyOnPhase;
            param.modLevel = (_fmShift>10) ? (_fmShift - 10) : 0;
            param.erst = _erst;
        }
        
        
        /** Set Wave table data. */
        public function setWaveTable(waveTable:SiOPMWaveTable) : void
        {
            _pgType = SiOPMTable.PG_USER_CUSTOM; // -1
            _waveTable     = waveTable.wavelet;
            _waveFixedBits = waveTable.fixedBits;
            ptType = waveTable.defaultPTType;
        }
        
        
        /** Set PCM data. */
        public function setPCMData(pcmData:SiOPMWavePCMData) : void
        {
            if (pcmData && pcmData.wavelet) {
                _pgType = SiOPMTable.PG_USER_PCM; // -2
                _waveTable      = pcmData.wavelet;
                _waveFixedBits  = PCM_waveFixedBits;
                _pcm_channels   = pcmData.channelCount;
                _pcm_startPoint = pcmData.startPoint;
                _pcm_endPoint   = pcmData.endPoint;
                _pcm_loopPoint  = pcmData.loopPoint;
                _keyon_phase = _pcm_startPoint << PCM_waveFixedBits;
                ptType = SiOPMTable.PT_PCM;
            } else {
                // quick initialization for SiOPMChannelPCM
                _pcm_endPoint = _pcm_loopPoint = 0;
                _pcm_loopPoint = -1;
            }
        }
        
        
        /** Note on. */
        public function noteOn() : void
        {
            if (_keyon_phase >= 0) _phase = _keyon_phase;
            else if (_keyon_phase == -1) _phase = int(Math.random() * SiOPMTable.PHASE_MAX);
            _eg_ssgec_state = -1;
            _eg_shiftState(EG_ATTACK);
            _eg_out = (_eg_levelTable[_eg_level] + _eg_total_level)<<3;
        }
        
        
        /** Note off. */
        public function noteOff() : void
        {
            _eg_shiftState(EG_RELEASE);
            _eg_out = (_eg_levelTable[_eg_level] + _eg_total_level)<<3;
        }
        
                
        /** @private [internal] Set pipes. */
        internal function _setPipes(outPipe:SLLint, modPipe:SLLint=null, finalOsc:Boolean=false) : void
        {
            _final    = finalOsc;
            _basePipe = (outPipe == modPipe) ? _chip.zeroBuffer : outPipe;
            _outPipe  = outPipe;
            _inPipe   = modPipe || _chip.zeroBuffer;
            _fmShift  = 15;
        }
        
        
        
        
    // internal operations
    //--------------------------------------------------
        /** @private Update envelop generator. This code is only for testing. */
        internal function eg_update() : void
        {
            _eg_timer -= _eg_timer_step;
            if (_eg_timer < 0) {
                if (_eg_state == EG_ATTACK) {
                    if (_eg_incTable[_eg_counter] > 0) {
                        _eg_level -= 1 + (_eg_level >> _eg_incTable[_eg_counter]);
                        if (_eg_level <= 0) _eg_shiftState(_eg_nextState[_eg_state]);
                    }
                } else {
                    _eg_level += _eg_incTable[_eg_counter];
                    if (_eg_level >= _eg_stateShiftLevel) _eg_shiftState(_eg_nextState[_eg_state]);
                }
                _eg_out = (_eg_levelTable[_eg_level] + _eg_total_level)<<3;
                _eg_counter = (_eg_counter+1)&7;
                _eg_timer += SiOPMTable.ENV_TIMER_INITIAL;
            }
        }
        
        
        /** @private Update pulse generator. This code is only for testing. */
        internal function pg_update() : void
        {
            _phase += _phase_step;
            var p:int = ((_phase + (_inPipe.i << _fmShift)) & SiOPMTable.PHASE_FILTER) >> _waveFixedBits;
            var l:int = _waveTable[p];
            l += _eg_out; // + (channel._am_out<<2>>_ams);
            _feedPipe.i = _table.logTable[l];
            _outPipe.i  = _feedPipe.i + _basePipe.i;
        }
        
        
        /** @private Shift envelop generator state. */
        internal function _eg_shiftState(state:int) : void
        {
            var r:int;
            
            switch (state) {
            case EG_ATTACK:
                // update ssgec_state
                if (++_eg_ssgec_state == 3) _eg_ssgec_state = 1;
                if (_ar + _eg_key_scale_rate < 62) {
                    if (_erst) _eg_level = SiOPMTable.ENV_BOTTOM;
                    _eg_state = EG_ATTACK;
                    r = (_ar) ? (_ar + _eg_key_scale_rate) : 96;
                    _eg_incTable = _table.eg_incTablesAtt[_table.eg_tableSelector[r]];
                    _eg_timer_step = _table.eg_timerSteps[r];
                    _eg_levelTable = _table.eg_levelTables[0];
                    break;
                }
                // fail through
            case EG_DECAY:
                if (_eg_sustain_level) {
                    _eg_state = EG_DECAY;
                    if (_ssg_type) {
                        _eg_level = 0;
                        _eg_stateShiftLevel = _eg_sustain_level>>2;
                        if (_eg_stateShiftLevel > SiOPMTable.ENV_BOTTOM_SSGEC) _eg_stateShiftLevel = SiOPMTable.ENV_BOTTOM_SSGEC;
                        _eg_levelTable = _table.eg_levelTables[_table.eg_ssgTableIndex[_ssg_type-8][_eg_ssgec_ar][_eg_ssgec_state]];
                    } else {
                        _eg_level = 0;
                        _eg_stateShiftLevel = _eg_sustain_level;
                        _eg_levelTable = _table.eg_levelTables[0];
                    }
                    r = (_dr) ? (_dr + _eg_key_scale_rate) : 96;
                    _eg_incTable = _table.eg_incTables[_table.eg_tableSelector[r]];
                    _eg_timer_step = _table.eg_timerSteps[r];
                    break;
                }
                // fail through
            case EG_SUSTAIN:
                {   // catch all
                    _eg_state = EG_SUSTAIN;
                    if (_ssg_type) {
                        _eg_level = _eg_sustain_level>>2;
                        _eg_stateShiftLevel = SiOPMTable.ENV_BOTTOM_SSGEC;
                        _eg_levelTable = _table.eg_levelTables[_table.eg_ssgTableIndex[_ssg_type-8][_eg_ssgec_ar][_eg_ssgec_state]];
                    } else {
                        _eg_level = _eg_sustain_level;
                        _eg_stateShiftLevel = SiOPMTable.ENV_BOTTOM;
                        _eg_levelTable = _table.eg_levelTables[0];
                    }
                    r = (_sr) ? (_sr + _eg_key_scale_rate) : 96;
                    _eg_incTable = _table.eg_incTables[_table.eg_tableSelector[r]];
                    _eg_timer_step = _table.eg_timerSteps[r];
                    break;
                }
                
            case EG_RELEASE:
                if (_eg_level < SiOPMTable.ENV_BOTTOM) {
                    _eg_state = EG_RELEASE;
                    _eg_stateShiftLevel = SiOPMTable.ENV_BOTTOM;
                    r = _rr + _eg_key_scale_rate;
                    _eg_incTable = _table.eg_incTables[_table.eg_tableSelector[r]];
                    _eg_timer_step = _table.eg_timerSteps[r];
                    _eg_levelTable = _table.eg_levelTables[(_ssg_type)?1:0];
                    break;
                }
                // fail through
            case EG_OFF:
            default:
                // catch all
                _eg_state = EG_OFF;
                _eg_level = SiOPMTable.ENV_BOTTOM;
                _eg_stateShiftLevel = SiOPMTable.ENV_BOTTOM+1;
                _eg_incTable = _table.eg_incTables[17];     // 17 = all zero
                _eg_timer_step = _table.eg_timerSteps[96];  // 96 = all zero
                _eg_levelTable = _table.eg_levelTables[0];
                break;
            }
        }
        
        
        // Internal update key code
        private function _updateKC(i:int) : void
        {
            // kc
            _kc = i;
            // ksr
            _eg_key_scale_rate = _kc >> _ks;
            // ksl
            _updateTotalLevel();
        }
        
        
        // Internal update phase step
        private function _updatePitch() : void
        {
            var n:int = (_pitchIndex + _pitchIndexShift + _pitchIndexShift2) & _pitchTableFilter;
            _updatePhaseStep(_pitchTable[n] >> _wavePhaseStepShift);
        }
        
        
        // Internal update phase step
        private function _updatePhaseStep(ps:int) : void
        {
            _phase_step = ps;
            _phase_step += _dt1Table[_kc];
            _phase_step *= _multiple;
            _phase_step >>= (7 - _table.sampleRatePitchShift);  // 44kHz:1/128, 22kHz:1/256
        }
        
        
        // Internal update total level
        private function _updateTotalLevel() : void
        {
            _eg_total_level = ((_tl+(_kc>>_eg_key_scale_level_rshift))<<SiOPMTable.ENV_LSHIFT) + _eg_tl_offset + _mute;
            if (_eg_total_level > SiOPMTable.ENV_BOTTOM) _eg_total_level = SiOPMTable.ENV_BOTTOM;
            _eg_total_level -= SiOPMTable.ENV_TOP;       // table index +192.
            _eg_out = (_eg_levelTable[_eg_level] + _eg_total_level)<<3;
        }
    }
}

