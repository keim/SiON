//----------------------------------------------------------------------------------------------------
// class for SiOPM PCM data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import flash.media.Sound;
    import org.si.sion.utils.SiONUtil;
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.sion.module.SiOPMTable;
    
    
    /** PCM data class */
    public class SiOPMWavePCMData extends SiOPMWaveBase
    {
    // valiables
    //----------------------------------------
        /** maximum sampling length when converted from Sound instance */
        static public var maxSampleLengthFromSound:int = 1048576;
        
        /** wave data */
        public var wavelet:Vector.<int>;
        /** channel count */
        public var channelCount:int;
        
        /** sampling pitch (noteNumber*64) */
        public var samplingPitch:int;
        
        /** wave starting position in sample count. */
        private var _startPoint:int;
        /** wave end position in sample count. */
        private var _endPoint:int;
        /** wave looping position in sample count. -1 means no repeat. */
        private var _loopPoint:int;
        /** flag to slice after loading */
        private var _sliceAfterLoading:Boolean;
        
        // sin table
        static private var _sin:Vector.<Number> = new Vector.<Number>();
        
        
    // properties
    //----------------------------------------
        /** Sampling data's length */
        public function get sampleCount() : int { return (wavelet) ? (wavelet.length >> (channelCount-1)) : 0; }
        
        /** Sampling data's octave */
        public function get samplingOctave() : int { return int(samplingPitch*0.001272264631043257); }
        
        /** wave starting position in sample count. you can set this property by slice(). @see #slice() */
        public function get startPoint() : int { return _startPoint; }
        
        /** wave end position in sample count. you can set this property by slice(). @see #slice() */
        public function get endPoint()   : int { return _endPoint; }
        
        /** wave looping position in sample count. -1 means no repeat. you can set this property by slice(). @see #slice() */
        public function get loopPoint()  : int { return _loopPoint; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** Constructor. 
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound instance is extracted internally.
         *  @param samplingPitch sampling data's original pitch (noteNumber*64)
         *  @param srcChannelCount channel count of source data, this argument is only available when data type is Vector.<Number>.
         *  @param channelCount channel count of this data, 0 sets same with srcChannelCount
         */
        function SiOPMWavePCMData(data:*=null, samplingPitch:int=4416, srcChannelCount:int=2, channelCount:int=0)
        {
            super(SiMMLTable.MT_PCM);
            if (data) initialize(data, samplingPitch, srcChannelCount, channelCount);
        }
        
        
        
        
    // oprations
    //----------------------------------------
        /** Initializer.
         *  @param data wave data, Sound, Vector.&lt;Number&gt; or Vector.&lt;int&gt; is available. The Sound instance is extracted internally.
         *  @param samplingPitch sampling data's original note
         *  @param srcChannelCount channel count of source data, this argument is only available when data type is Vector.<Number>.
         *  @param channelCount channel count of this data, 0 sets same with srcChannelCount
         *  @return this instance.
         */
        public function initialize(data:*, samplingPitch:int=4416, srcChannelCount:int=2, channelCount:int=0) : SiOPMWavePCMData
        {
            _sliceAfterLoading = false;
            srcChannelCount = (srcChannelCount == 1) ? 1 : 2;
            if (channelCount == 0) channelCount = srcChannelCount;
            this.channelCount = (channelCount == 1) ? 1 : 2;
            if (data is Sound) {
                _listenSoundLoadingEvents(data as Sound);
            } else if (data is Vector.<Number>) {
                wavelet = SiONUtil.logTransVector(data as Vector.<Number>, srcChannelCount, null, this.channelCount);
            } else if (data is Vector.<int>) {
                wavelet = data as Vector.<int>;
            } else if (data == null) {
                wavelet = null;
            } else {
                throw new Error("SiOPMWavePCMData; not suitable data type");
            }
            this.samplingPitch = samplingPitch;

            _startPoint = 0;
            _endPoint   = this.sampleCount - 1;
            _loopPoint  = -1;
            return this;
        }
        
        
        /** Slicer setting. You can cut samples and set repeating.
         *  @param startPoint slicing point to start data. The negative value skips head silence.
         *  @param endPoint slicing point to end data, The negative value calculates from the end.
         *  @param loopPoint slicing point to repeat data, -1 sets no repeat, other negative value sets loop tail samples
         *  @return this instance.
         */
        public function slice(startPoint:int=-1, endPoint:int=-1, loopPoint:int=-1) : SiOPMWavePCMData 
        {
            _startPoint = startPoint;
            _endPoint = endPoint;
            _loopPoint = loopPoint;
            if (!_isSoundLoading) _slice();
            else _sliceAfterLoading = true;
            return this;
        }
        
        
        /** Get initial sample index. 
         *  @param phase Starting phase, ratio from start point to end point(0-1).
         */
        public function getInitialSampleIndex(phase:Number=0) : int
        {
            return int(_startPoint*(1-phase) + _endPoint*phase);
        }
        
        
        /** Loop tail samples, this function updates endPoint and loopPoint. This function is called from slice() when loopPoint < -1.
         *  @param sampleCount looping sample count.
         *  @param tailMargin margin for end point. sample count from tail of wave data (consider mp3's end gap).
         *  @param crossFade using short cross fading to reduce sample step noise while looping.
         *  @see #slice()
         */
        public function loopTailSamples(sampleCount:int=2205, tailMargin:int=0, crossFade:Boolean=true) : SiOPMWavePCMData
        {
            _endPoint = _seekEndGap() - tailMargin;
            if (_endPoint < _startPoint+sampleCount) {
                if (_endPoint < _startPoint) _endPoint = _startPoint;
                _loopPoint = _startPoint;
                return this;
            }
            _loopPoint = _endPoint - sampleCount;
            
            if (crossFade && _loopPoint > _startPoint+sampleCount) {
                var i:int, j:int, t:Number, idx0:int, idx1:int, li0:int ,li1:int, 
                    log:Vector.<int> = SiOPMTable.instance.logTable,
                    envtop:int = (-SiOPMTable.ENV_TOP)<<3,
                    i2n:Number = 1/Number(1<<SiOPMTable.LOG_VOLUME_BITS),
                    offset:int = _loopPoint << (channelCount - 1),
                    imax:int = sampleCount << (channelCount - 1),
                    dt:Number = 1.5707963267948965/imax;
                if (_sin.length != imax) {
                    _sin.length = imax;
                    for (i=0, t=0; i<imax; i++, t+=dt) _sin[i] =  Math.sin(t);
                }
                for (i=0; i<imax; i++) {
                    idx0 = offset + i;
                    idx1 = idx0 - imax;
                    li0 = wavelet[idx0] + envtop;
                    li1 = wavelet[idx1] + envtop;
                    j = imax - 1 - i;
                    wavelet[idx0] = SiOPMTable.calcLogTableIndex((log[li0] * _sin[j] + log[li1] * _sin[i]) * i2n);
                }
            }
            
            return this;
        }
        
        
        // seek mp3 head gap
        private function _seekHeadSilence() : int
        {
            var i:int, imax:int = wavelet.length, threshold:int = SiOPMTable.LOG_TABLE_BOTTOM - SiOPMTable.LOG_TABLE_RESOLUTION*14; // 1/128
            for (i=0; i<imax; i++) if (wavelet[i] < threshold) break;
            return i >> (channelCount - 1);
        }
        
        
        // seek mp3 end gap
        private function _seekEndGap() : int
        {
            var i:int, threshold:int = SiOPMTable.LOG_TABLE_BOTTOM - SiOPMTable.LOG_TABLE_RESOLUTION*2; // 1/4096
            for (i=wavelet.length-1; i>0; --i) if (wavelet[i] < threshold) break;
            return (i >> (channelCount - 1)) - 100; // 100 = 1 cycle margin
        }
        
        
        /** @private */
        override protected function _onSoundLoadingComplete(sound:Sound) : void 
        {
            wavelet = SiONUtil.logTrans(sound, null, channelCount, maxSampleLengthFromSound);
            if (_sliceAfterLoading) _slice();
            _sliceAfterLoading = false;
        }
        
        
        private function _slice() : void
        {
            // start point
            if (_startPoint < 0) _startPoint = _seekHeadSilence();
            if (_loopPoint < -1) {
                // set loop infinitly
                if (_endPoint >= 0) {
                    loopTailSamples(-_loopPoint);
                    if (_startPoint >= _endPoint) _endPoint = _startPoint;
                } else {
                    loopTailSamples(-_loopPoint, -_endPoint);
                }
            } else {
                // end point
                var waveletLengh:int = sampleCount;
                if (_endPoint < 0) _endPoint = _seekEndGap() + _endPoint;
                else if (_endPoint < _startPoint) _endPoint = _startPoint;
                else if (waveletLengh < _endPoint) _endPoint = waveletLengh - 1;
                // loop point
                if (_loopPoint != -1 && _loopPoint < _startPoint) _loopPoint = _startPoint;
                else if (_endPoint < _loopPoint) _loopPoint = -1;
            }
        }
    }
}

