//----------------------------------------------------------------------------------------------------
// class for SiOPM samplers wave
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import flash.media.Sound;
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.sion.utils.SiONUtil;
    import org.si.sion.utils.PeakDetector;
    import org.si.utils.SLLNumber;
    
    /** SiOPM samplers wave data */
    public class SiOPMWaveSamplerData extends SiOPMWaveBase
    {
    // constant
    //----------------------------------------
        /** maximum length limit to extract Sound [ms] */
        static public var extractThreshold:int = 4000;
        
        
        
    // valiables
    //----------------------------------------
        // Sound data
        private var _soundData:Sound;
        // Wave data
        private var _waveData:Vector.<Number>;
        // channel count of this data
        private var _channelCount:int;
        // pan
        private var _pan:int;
        // extraction flag
        private var _isExtracted:Boolean;
        // wave starting position in sample count.
        private var _startPoint:int;
        // wave end position in sample count.
        private var _endPoint:int;
        // wave looping position in sample count. -1 means no repeat.
        private var _loopPoint:int;
        // flag to slice after loading
        private var _sliceAfterLoading:Boolean;
        // flag to ignore note off
        private var _ignoreNoteOff:Boolean;
        // peak list for time stretch
        private var _peakList:Vector.<Number>;
        
        
        
    // properties
    //----------------------------------------
        /** Sound data */
        public function get soundData() : Sound { return _soundData; }
        
        /** Wave data */
        public function get waveData() : Vector.<Number> { return _waveData; }
        
        /** channel count of this data. */
        public function get channelCount() : int { return _channelCount; }

        /** pan [-64 - 64] */
        public function get pan():int { return _pan; }
        
        /** Sammple length */
        public function get length() : int {
            if (_isExtracted) return (_waveData.length >> (_channelCount-1));
            if (_soundData) return (_soundData.length * 44.1);
            return 0;
        }
        
        
        /** Is extracted ? */
        public function get isExtracted() : Boolean { return _isExtracted; }
        
        
        /** flag to ignore note off. set true to ignore note off (one shot voice). this flag is only available for non-loop samples. */
        public function get ignoreNoteOff() : Boolean { return _ignoreNoteOff; }
        public function set ignoreNoteOff(b:Boolean) : void {
            _ignoreNoteOff = (_loopPoint == -1) && b;
        }
        
        
        /** wave starting position in sample count. you can set this property by slice(). @see #slice() */
        public function get startPoint() : int { return _startPoint; }
        
        /** wave end position in sample count. you can set this property by slice(). @see #slice() */
        public function get endPoint()   : int { return _endPoint; }
        
        /** wave looping position in sample count. -1 means no repeat. you can set this property by slice(). @see #slice() */
        public function get loopPoint()  : int { return _loopPoint; }
        
        /** peak list only available for extracted data */
        public function get peakList() : Vector.<Number> { return  _peakList; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound is extracted when the length is shorter than SiOPMWaveSamplerData.extractThreshold[msec].
         *  @param ignoreNoteOff flag to ignore note off
         *  @param pan pan of this sample [-64 - 64].
         *  @param srcChannelCount channel count of source data, this argument is only available when data type is Vector.<Number>.
         *  @param channelCount channel count of this data, 0 sets same with srcChannelCount
         *  @param peakList peak list for time stretching
         */
        function SiOPMWaveSamplerData(data:*=null, ignoreNoteOff:Boolean=false, pan:int=0, srcChannelCount:int=2, channelCount:int=0, peakList:Vector.<Number>=null) 
        {
            super(SiMMLTable.MT_SAMPLE);
            if (data) initialize(data, ignoreNoteOff, pan, srcChannelCount, channelCount, peakList);
        }
        
        
        
        
    // oprations
    //----------------------------------------
        /** initialize 
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound is extracted when the length is shorter than SiOPMWaveSamplerData.extractThreshold[msec].
         *  @param ignoreNoteOff flag to ignore note off
         *  @param pan pan of this sample.
         *  @param srcChannelCount channel count of source data, this argument is only available when data type is Vector.<Number>.
         *  @param channelCount channel count of this data, 0 sets same with srcChannelCount. This argument is ignored when the data is not extracted.
         *  @see #extractThreshold
         *  @return this instance.
         */
        public function initialize(data:*, ignoreNoteOff:Boolean=false, pan:int=0, srcChannelCount:int=2, channelCount:int=0, peakList:Vector.<Number>=null) : SiOPMWaveSamplerData
        {
            _sliceAfterLoading = false;
            srcChannelCount = (srcChannelCount == 1) ? 1 : 2;
            if (channelCount == 0) channelCount = srcChannelCount;
            this._channelCount = (channelCount == 1) ? 1 : 2;
            if (data is Vector.<Number>) {
                this._soundData = null;
                this._waveData = _transChannel(data, srcChannelCount, _channelCount);
                _isExtracted = true;
            } else if (data is Sound) {
                _listenSoundLoadingEvents(data as Sound);
            } else if (data == null) {
                this._soundData = null;
                this._waveData = null;
                _isExtracted = false;
            } else {
                throw new Error("SiOPMWaveSamplerData; not suitable data type");
            }
            
            this._startPoint = 0;
            this._endPoint   = length;
            this._loopPoint  = -1;
            this._peakList = peakList;
            this.ignoreNoteOff = ignoreNoteOff;
            this._pan = pan;
            return this;
        }
        
        
        /** Slicer setting. You can cut samples and set repeating.
         *  @param startPoint slicing point to start data.The negative value skips head silence.
         *  @param endPoint slicing point to end data. The negative value plays whole data.
         *  @param loopPoint slicing point to repeat data. The negative value sets no repeat.
         *  @return this instance.
         */
        public function slice(startPoint:int=-1, endPoint:int=-1, loopPoint:int=-1) : SiOPMWaveSamplerData
        {
            _startPoint = startPoint;
            _endPoint = endPoint;
            _loopPoint = loopPoint;
            if (!_isSoundLoading) _slice();
            else _sliceAfterLoading = true;
            return this;
        }
        
        
        /** extract Sound data. The sound data shooter than extractThreshold is already extracted. [CAUTION] Long sound takes long time to extract and consumes large memory area. @see extractThreshold */
        public function extract() : void
        {
            if (_isExtracted) return;
            this._waveData = SiONUtil.extract(this._soundData, null, _channelCount, length, 0);
            _isExtracted = true;
        }
        
        
        /** Get initial sample index. 
         *  @param phase Starting phase, ratio from start point to end point(0-1).
         */
        public function getInitialSampleIndex(phase:Number=0) : int
        {
            return int(_startPoint*(1-phase) + _endPoint*phase);
        }
        
        
        /** construct peak list,  
         */
        public function constructPeakList() : PeakDetector
        {
            if (!_isExtracted) throw new Error("constructPeakList is only available for extracted data");
            var pd:PeakDetector = new PeakDetector();
            pd.setSamples(_waveData, _channelCount);
            _peakList = pd.peakList;
            return pd;
        }
        
        
        // seek head silence
        private function _seekHeadSilence() : int
        {
            if (_waveData) {
                var i:int=0, imax:int=_waveData.length, ms:Number;
                var msWindow:SLLNumber = SLLNumber.allocRing(22); // 0.5ms
                if (_channelCount == 1) {
                    ms = 0;
                    for (i=0; i<imax; i++) {
                        ms -= msWindow.n;
                        msWindow = msWindow.next;
                        msWindow.n = _waveData[i] * _waveData[i];
                        ms += msWindow.n;
                        if (ms > 0.0011) break;
                    }
                } else {
                    ms = 0;
                    for (i=0; i<imax;) {
                        ms -= msWindow.n;
                        msWindow = msWindow.next;
                        msWindow.n  = _waveData[i] * _waveData[i]; i++;
                        msWindow.n += _waveData[i] * _waveData[i]; i++;
                        ms += msWindow.n;
                        if (ms > 0.0022) break;
                    }
                    i >>= 1;
                }
                SLLNumber.freeRing(msWindow);
                return i - 22;
            }
            return (_soundData) ? SiONUtil.getHeadSilence(_soundData) : 0;
        }
        
        
        // seek mp3 end gap
        private function _seekEndGap() : int
        {
            if (_waveData) {
                var i:int, ms:Number;
                if (_channelCount == 1) {
                    for (i=_waveData.length-1; i>=0; i--) {
                        if (_waveData[i]*_waveData[i] > 0.0001) break;
                    }
                } else {
                    for (i=_waveData.length-1; i>=0;) {
                        ms  = _waveData[i] * _waveData[i]; i--;
                        ms += _waveData[i] * _waveData[i]; i--;
                        if (ms > 0.0002) break;
                    }
                    i >>= 1;
                }
                return (i>length-1152) ? i : (length-1152);
            }
            return (_soundData) ? (length - SiONUtil.getEndGap(_soundData)) : 0;
        }
        
        
        // change channel count as needed
        private function _transChannel(src:Vector.<Number>, srcChannelCount:int, channelCount:int) : Vector.<Number>
        {
            var i:int, j:int, imax:int, dst:Vector.<Number>;
            if (srcChannelCount == channelCount) return src;
            if (srcChannelCount == 1) { // 1->2
                imax = src.length;
                dst = new Vector.<Number>(imax<<1);
                for (i=0, j=0; i<imax; i++, j+=2) dst[j+1] = dst[j] = src[i];
            } else { // 2->1
                imax = src.length>>1;
                dst = new Vector.<Number>(imax);
                for (i=0, j=0; i<imax; i++, j+=2) dst[i] = (src[j] + src[j+1]) * 0.5;
            }
            return dst;
        }
        
        
        /** @private */
        override protected function _onSoundLoadingComplete(sound:Sound) : void 
        {
            this._soundData = sound;
            if (this._soundData.length <= extractThreshold) {
                this._waveData = SiONUtil.extract(this._soundData, null, _channelCount, extractThreshold*45, 0);
                _isExtracted = true;
            } else {
                this._waveData = null;
                _isExtracted = false;
            }
            if (_sliceAfterLoading) _slice();
            _sliceAfterLoading = false;
        }
        
        
        private function _slice() : void
        {
            if (_startPoint < 0) _startPoint = _seekHeadSilence();
            if (_loopPoint < 0) _loopPoint = -1;
            if (_endPoint < 0) _endPoint = _seekEndGap();
            if (_endPoint < _loopPoint) _loopPoint = -1;
            if (_endPoint < _startPoint) _endPoint = length - 1;
        }
    }
}

