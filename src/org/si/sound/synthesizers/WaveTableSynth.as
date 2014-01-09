// Wave Table Synthesizer 
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.synthesizers {
    import org.si.sion.*;
    import org.si.sion.utils.SiONUtil;
    import org.si.sion.module.SiOPMWaveTable;
    import org.si.sion.module.channels.SiOPMChannelFM;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sound.SoundObject;
    
    
    /** Wave Table Synthesizer 
     */
    public class WaveTableSynth extends BasicSynth
    {
    // namespace
    //----------------------------------------
        use namespace _synthesizer_internal;
        
        
        
        
    // constants
    //----------------------------------------
        /** single layer mode */
        static public const SINGLE:String = "single";
        /** detuned layer mode with double operators */
        static public const DETUNE:String = "detune";
        /** detune layer mode with triple operators */
        static public const TRIPLE_DETUNE:String = "tripleDetune";
        /** layered by closed power code (2operators)*/
        static public const POWER:String = "power";
        /** layered by closed detuned power code (4operators)*/
        static public const DETUNE_POWER:String = "detunePower";
        /** layered by closed sus4 code (3operators)*/
        static public const SUS4:String = "sus4";
        /** layered by closed sus2 code (3operators)*/
        static public const SUS2:String = "sus2";
        
        /** operator settings */
        static protected var _operatorSetting:* = {
            "single":[0], "detune":[0,0], "tripleDetune":[0,0,0], 
            "power":[0,5], "detunePower":[5,0,5,0], "sus4":[0,5,7], "sus2":[0,7,14]
        };
        
        
        
    // variables
    //----------------------------------------
        /** wavelet */
        protected var _wavelet:Vector.<Number>;
        /** wave table */
        protected var _waveTable:SiOPMWaveTable;
        /** wave color */
        protected var _waveColor:uint;
        /** layering type */
        protected var _layerType:String;
        /** layering type */
        protected var _operatorPitch:Array;
        /** layering detune */
        protected var _layerDetune:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** wave data. */
        public function get wavelet() : Vector.<Number> { return _wavelet; }
        
        
        /** wave color.  */
        public function get color() : uint { return _waveColor; }
        public function set color(c:uint) : void {
            _waveColor = c;
            SiONUtil.waveColor(_waveColor, 0, _wavelet);
            updateWavelet();
        }
        
        
        /** layering type */
        public function get layerType() : String { return _layerType; }
        public function set layerType(t:String) : void {
            _operatorPitch = _operatorSetting[t];
            if (_operatorPitch == null) throw _errorNoLayerType(t);
            _layerType = t;
            var i:int, det:int, imax:int = _operatorPitch.length;
            _voice.channelParam.opeCount = imax;
            _voice.channelParam.alg = [0,1,5,7][imax];
            for (i=0, det=-((_layerDetune*(imax-1))>>1); i<imax; i++, det+=_layerDetune) {
                _voice.channelParam.operatorParam[i].detune = (_operatorPitch[i]<<6) + det;
            }
            _voiceUpdateNumber++;
        }
        
        
        /** layer detune, 1 = halftone */
        public function get layerDetune() : int { return _layerDetune; }
        public function set layerDetune(d:int) : void { 
            _layerDetune = d;
            var i:int, det:int, imax:int = _operatorPitch.length;
            for (i=0, det=-((_layerDetune*(imax-1))>>1); i<imax; i++, det+=_layerDetune) {
                _voice.channelParam.operatorParam[i].detune = (_operatorPitch[i]<<6) + det;
            }
            var ch:SiOPMChannelFM, op:int, opMax:int = _operatorPitch.length;
            imax = _tracks.length;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) {
                    for (op=0; op<opMax; op++) ch.operator[op].detune = _voice.channelParam.operatorParam[i].detune;
                }
            }
        }

        
        
        
    // constructor
    //----------------------------------------
        /** constructor */
        function WaveTableSynth(layerType:String="single", waveColor:uint=0x1000000f)
        {
            _wavelet = new Vector.<Number>(1024);
            _waveTable = new SiOPMWaveTable();
            _voice.waveData = _waveTable;
            _layerDetune = 4;
            this.layerType = layerType;
            this.color = waveColor;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** update wavelet */
        public function updateWavelet() : void
        {
            _waveTable.initialize(SiONUtil.logTransVector(_wavelet, 1, _waveTable.wavelet));
            var i:int, imax:int = _tracks.length, ch:SiOPMChannelFM;
            for (i=0; i<imax; i++) {
                ch = _tracks[i].channel as SiOPMChannelFM;
                if (ch != null) ch.setWaveData(_waveTable);
            }
        }
        
        
        
    // errors
    //----------------------------------------
        // no layer type error
        private function _errorNoLayerType(type:String) : Error
        {
            return new Error("WaveTableSynth; no layer type '"+type+"'");
        }
    }
}


