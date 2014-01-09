//----------------------------------------------------------------------------------------------------
// SiOPM Sampler pad channel.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module.channels {
    import flash.utils.ByteArray;
    import org.si.utils.SLLNumber;
    import org.si.utils.SLLint;
    import org.si.sion.module.*;
    
    
    /** Sampler pad channel. */
    public class SiOPMChannelSampler extends SiOPMChannelBase
    {
    // valiables
    //--------------------------------------------------
        /** bank number */   protected var _bankNumber:int;
        /** wave number */   protected var _waveNumber:int;
        
        /** expression */    protected var _expression:Number;
        
        /** sample table */  protected var _samplerTable:SiOPMWaveSamplerTable;
        /** sample table */  protected var _sampleData :SiOPMWaveSamplerData;
        /** sample index */  protected var _sampleIndex:int;
        /** phase reset */   protected var _sampleStartPhase:int;

        /** ByteArray to extract */ protected var _extractedByteArray:ByteArray;
        /** sample data */          protected var _extractedSample:Vector.<Number>;
        
        // pan of current note
        private var _samplePan:int;
        
        
        
        
    // toString
    //--------------------------------------------------
        /** Output parameters. */
        public function toString() : String
        {
            var str:String = "SiOPMChannelSampler : ";
            $2("vol", _volumes[0]*_expression,  "pan", _pan-64);
            return str;
            function $2(p:String, i:*, q:String, j:*) : void { str += "  " + p + "=" + String(i) + " / " + q + "=" + String(j) + "\n"; }
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function SiOPMChannelSampler(chip:SiOPMModule)
        {
            _extractedByteArray = new ByteArray();
            _extractedSample = new Vector.<Number>(chip.bufferLength*2);
            super(chip);
        }




    // parameter setting
    //--------------------------------------------------
        /** Set by SiOPMChannelParam. 
         *  @param param SiOPMChannelParam.
         *  @param withVolume Set volume when its true.
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
        }
        
        
        /** Get SiOPMChannelParam.
         *  @param param SiOPMChannelParam.
         */
        override public function getSiOPMChannelParam(param:SiOPMChannelParam) : void
        {
            var i:int, imax:int = SiOPMModule.STREAM_SEND_SIZE;
            for (i=0; i<imax; i++) param.volumes[i] = _volumes[i];
            param.pan = _pan;
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
        
        
        /** pgType and ptType (&#64; call from SiMMLChannelSetting.selectTone()/initializeTone()) */
        override public function setType(pgType:int, ptType:int) : void 
        {
            _bankNumber = pgType & 3;
        }
        
        
        
        
    // interfaces
    //--------------------------------------------------
        /** pitch = (note &lt;&lt; 6) | (kf &amp; 63) [0,8191] */
        override public function get pitch() : int { return _waveNumber<<6; }
        override public function set pitch(p:int) : void {
            _waveNumber = p >> 6;
        }
        
        /** Set wave data. */
        override public function setWaveData(waveData:SiOPMWaveBase) : void {
            _samplerTable = waveData as SiOPMWaveSamplerTable;
            _sampleData  = waveData as SiOPMWaveSamplerData;
        }
        
        
        
        
    // volume controls
    //--------------------------------------------------
        /** update all tl offsets of final carriors */
        override public function offsetVolume(expression:int, velocity:int) : void {
            _expression = expression * velocity * 0.00006103515625; // 1/16384
        }
        
        /** phase (&#64;ph) */
        override public function set phase(i:int) : void {
            _sampleStartPhase = i;
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Initialize. */
        override public function initialize(prev:SiOPMChannelBase, bufferIndex:int) : void
        {
            super.initialize(prev, bufferIndex);
            reset();
        }
        
        
        /** Reset. */
        override public function reset() : void
        {
            _isNoteOn = false;
            _isIdling = true;
            _bankNumber = 0;
            _waveNumber = -1;
            _samplePan = 0;
            
            _samplerTable = _table.samplerTables[0];
            _sampleData = null;
            
            _sampleIndex = 0;
            _sampleStartPhase = 0;
            _expression = 1;
        }
        
        
        /** Note on. */
        override public function noteOn() : void
        {
            if (_waveNumber >= 0) {
                if (_samplerTable) _sampleData = _samplerTable.getSample(_waveNumber & 127);
                if (_sampleData && _sampleStartPhase!=255) {
                    _sampleIndex = _sampleData.getInitialSampleIndex(_sampleStartPhase * 0.00390625); // 1/256
                    _samplePan = _pan + _sampleData.pan;
                    if (_samplePan < 0) _samplePan = 0;
                    else if (_samplePan > 128) _samplePan = 128;
                }
                _isIdling = (_sampleData == null);
                _isNoteOn = !_isIdling;
            }
        }
        
        
        /** Note off. */
        override public function noteOff() : void
        {
            if (_sampleData) {
                if (!_sampleData.ignoreNoteOff) {
                    _isNoteOn = false;
                    _isIdling = true;
                    if (_samplerTable) _sampleData = null;
                }
            }
        }
        
        
        /** Buffering */
        override public function buffer(len:int) : void
        {
            var i:int, imax:int, vol:Number, residue:int, processed:int, stream:SiOPMStream;
            if (_isIdling || _sampleData == null || _mute) {
                //_nop(len);
            } else {
                if (_sampleData.isExtracted) {
                    // stream extracted data
                    for (residue=len, i=0; residue>0;) {
                        // copy to buffer
                        processed = (_sampleIndex + residue < _sampleData.endPoint) ? residue : (_sampleData.endPoint - _sampleIndex);
                        if (_hasEffectSend) {
                            for (i=0; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                                if (_volumes[i]>0) {
                                    stream = _streams[i] || _chip.streamSlot[i];
                                    if (stream) {
                                        vol = _volumes[i] * _expression * _chip.samplerVolume;
                                        stream.writeVectorNumber(_sampleData.waveData, _sampleIndex, _bufferIndex, processed, vol, _samplePan, _sampleData.channelCount);
                                    }
                                }
                            }
                        } else {
                            stream = _streams[0] || _chip.outputStream;
                            vol = _volumes[0] * _expression * _chip.samplerVolume;
                            stream.writeVectorNumber(_sampleData.waveData, _sampleIndex, _bufferIndex, processed, vol, _samplePan, _sampleData.channelCount);
                        }
                        _sampleIndex += processed;
                        
                        // processed samples are not enough == achieves to the end
                        residue -= processed;
                        if (residue > 0) {
                            if (_sampleData.loopPoint >= 0) {
                                 // loop
                                if (_sampleData.loopPoint>_sampleData.startPoint) _sampleIndex = _sampleData.loopPoint;
                                else _sampleIndex = _sampleData.startPoint;
                            } else {
                                // end (note off)
                                _isIdling = true;
                                if (_samplerTable) _sampleData = null;
                                //_nop(len - processed);
                                break;
                            }
                        }
                    }
                } else {
                    // stream Sound data with extracting
                    for (residue=len, i=0, imax=0; residue>0;) {
                        // extract a part
                        _extractedByteArray.length = 0;
                        processed = _sampleData.soundData.extract(_extractedByteArray, residue, _sampleIndex<<1);
                        _sampleIndex += processed >> 1;
                        if (_sampleIndex > _sampleData.endPoint) processed -= _sampleIndex - _sampleData.endPoint;
                        
                        // copy to vector
                        imax += processed << 1;
                        _extractedByteArray.position = 0;
                        for (; i<imax; i++) { _extractedSample[i] = _extractedByteArray.readFloat(); }
                        
                        // processed samples are not enough == achieves to the end
                        residue -= processed;
                        if (residue > 0) {
                            if (_sampleData.loopPoint >= 0) {
                                 // loop
                                if (_sampleData.loopPoint>_sampleData.startPoint) _sampleIndex = _sampleData.loopPoint;
                                else _sampleIndex = _sampleData.startPoint;
                            } else {
                                // end (note off)
                                _isIdling = true;
                                if (_samplerTable) _sampleData = null;
                                //_nop(len - processed);
                                break;
                            }
                        }
                    }
                    processed = len - residue;
                    
                    // copy to buffer
                    if (_hasEffectSend) {
                        for (i=0; i<SiOPMModule.STREAM_SEND_SIZE; i++) {
                            if (_volumes[i]>0) {
                                stream = _streams[i] || _chip.streamSlot[i];
                                if (stream) {
                                    vol = _volumes[i] * _expression * _chip.samplerVolume;
                                    stream.writeVectorNumber(_extractedSample, 0, _bufferIndex, processed, vol, _samplePan, 2);
                                }
                            }
                        }
                    } else {
                        stream = _streams[0] || _chip.outputStream;
                        vol = _volumes[0] * _expression * _chip.samplerVolume;
                        stream.writeVectorNumber(_extractedSample, 0, _bufferIndex, processed, vol, _samplePan, 2);
                    }
                }
            }
            
            // update buffer index
            _bufferIndex += len;
        }
        
        
        /** Buffering without processnig */
        override public function nop(len:int) : void
        {
            //_nop(len);
            _bufferIndex += len;
        }
    }
}

