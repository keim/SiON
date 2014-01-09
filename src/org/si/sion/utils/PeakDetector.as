//----------------------------------------------------------------------------------------------------
// Peak detector
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils {
    import org.si.sion.effector.*;
    import org.si.utils.*;

    /** PeakDetector provides wave power peak profiler with bandpass filter. This analyzer takes finer time resolution, looser frequency resolution and faster calculation than FFT. */
    public class PeakDetector
    {
    // valiables
    //----------------------------------------
        /** maximum value of peaksPerMinute, the minimum value is a half of maximum value. @default 192 */
        static public var maxPeaksPerMinute:Number = 192;
        
        
        private var _bpf:SiFilterBandPass = new SiFilterBandPass();
        private var _window:SLLNumber = null;
        
        private var _frequency:Number;
        private var _bandWidth:Number;
        private var _windowLength:Number;
        private var _profileDirty:Boolean;
        private var _peakListDirty:Boolean;
        private var _peakFreqDirty:Boolean;
        private var _signalToNoiseRatio:Number;
        private var _samplesChannelCount:int;
        private var _samples:Vector.<Number> = null;
        
        private var _stream:Vector.<Number> = new Vector.<Number>();
        private var _profile:Vector.<Number> = new Vector.<Number>();
        private var _diffLogProfile:Vector.<Number> = new Vector.<Number>();
        private var _peakList:Vector.<Number> = new Vector.<Number>();
        private var _ppmScore:Vector.<Number>;
        private var _peaksPerMinute:Number;
        private var _peaksPerMinuteProbability:Number;
        private var _maximum:Number;
        private var _average:Number;
        
        
        
        
    // properties
    //----------------------------------------
        /** window length of simple moving avarage [ms] @default 20 */
        public function get windowLength() : int { return _windowLength; }
        public function set windowLength(l:int) : void {
            if (_windowLength != l) {
                _peakFreqDirty = _peakListDirty = _profileDirty = true;
                _windowLength = l;
                _resetWindow();
            }
        }
        
        
        /** frequency of band pass filter [Hz], set 0 to skip filtering @default 0 */
        public function get frequency() : Number { return _frequency; }
        public function set frequency(f:Number) : void {
            if (_frequency != f) {
                _peakFreqDirty = _peakListDirty = _profileDirty = true;
                _frequency = f;
                _updateFilter();
            }
        }
        
        
        /** half band width of band pass filter [oct.] @default 0.5 */
        public function get bandWidth() : Number { return (_frequency>0) ? _bandWidth : 0; }
        public function set bandWidth(b:Number) : void {
            if (_bandWidth != b) {
                _peakFreqDirty = _peakListDirty = _profileDirty = true;
                _bandWidth = b;
                _updateFilter();
            }
        }
        
        
        /** S/N ratio for peak detection [dB] @default 20 */
        public function get signalToNoiseRatio() : Number { return _signalToNoiseRatio; }
        public function set signalToNoiseRatio(n:Number) : void { _signalToNoiseRatio = n; }
        
        
        /** samples to analyze, 44.1kHz only */
        public function get samples() : Vector.<Number> { return _samples; }
        
        
        /** channel count of analyzing samples (1 or 2) */
        public function get samplesChannelCount() : int { return _samplesChannelCount; }
        
        
        /** analyzed wave energy profile 2100[fps] (the length is 1/21(2100/44100) of analyzing samples). */
        public function get powerProfile() : Vector.<Number> {
            _updateProfile();
            return _profile;
        }
        
        
        /** exponential of differencial of log scaled powerProfile, same length with powerProfile */
        public function get differencialOfLogPowerProfile() : Vector.<Number> {
            _updatePeakList();
            return _diffLogProfile;
        }
        
        
        /** avarage wave energy */
        public function get average() : Number {
            _updateProfile();
            return _average;
        }
        
        
        /** maximum wave energy */
        public function get maximum() : Number {
            _updateProfile();
            return _maximum;
        }
        
        
        /** analyzed peak list in [ms]. */
        public function get peakList() : Vector.<Number> {
            _updatePeakList();
            return _peakList;
        }
        
        
        /** @internal peak per minutes estimation score table. */
        public function get peaksPerMinuteEstimationScoreTable() : Vector.<Number> {
            _updatePeakFreq();
            return _ppmScore;
        }
        
        
        /** estimated peak per minutes. this value is similar but different form bpm(tempo), because the peaks are not only on 4th beats, but also 8th or 16th beats. */
        public function get peaksPerMinute() : Number {
            _updatePeakFreq();
            return _peaksPerMinute;
        }
        
        
        /** probability of estimated peaksPerMinute value. 1 means estimated perfectly and 0 means not good estimation. */
        public function get peaksPerMinuteProbability() : Number {
            _updatePeakFreq();
            return _peaksPerMinuteProbability;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param frequency frequency of band pass filter [Hz], set 0 to skip filtering
         *  @param bandWidth half band width of band pass filter [oct.]
         *  @param windowLength window length of simple moving avarage [ms]
         *  @param signalToNoiseRatio S/N ratio for peak detection [dB]
         */
        function PeakDetector(frequency:Number=0, bandWidth:Number=0.5, windowLength:Number=20, signalToNoiseRatio:Number=20) {
            _frequency = frequency;
            _bandWidth = bandWidth;
            _windowLength = windowLength;
            _signalToNoiseRatio = signalToNoiseRatio;
            _updateFilter();
            _resetWindow();
            _profileDirty = true;
            _peakListDirty = true;
            _peakFreqDirty = true;
            _average = 0;
        }
        
        
        
        
    // methods
    //----------------------------------------
        /** set analyzing source samples
         *  @param samples analyzing source 
         *  @param channelCount channel count of analyzing source
         *  @param isStreaming true to continuous data with previous analyze
         *  @return this instance
         */
        public function setSamples(samples:Vector.<Number>, channelCount:int=2, isStreaming:Boolean=false) : PeakDetector
        {
            _peakFreqDirty = _peakListDirty = _profileDirty = true;
            _samples = samples;
            _samplesChannelCount = channelCount;
            if (!isStreaming) _resetWindow();
            return this;
        }
        
        
        /** calcuate peak inetncity 
         *  @param peakPosition peak positoin [ms]
         *  @param integrateLength integration length [ms]
         */
        public function calcPeakIntencity(peakPosition:Number, integrateLength:Number=10) : Number
        {
            var i:int, n:Number, 
                imin:int = int(peakPosition * 2.1 + 0.5),
                imax:int = int((peakPosition + integrateLength) * 2.1 + 0.5);
            _updateProfile();
            if (imin > _profile.length) imin = _profile.length;
            if (imax > _profile.length) imax = _profile.length;
            for (n=0, i=imin; i<imax; i++) n += _profile[i];
            return n;
        }
        
        
        /** merage peak list
         *  @param arrayOfPeakList Array of peakList(Vector.<Number> type) to marge
         *  @param singlePeakLength time distance to merge near peaks as 1 peak
         *  @return merged peak list
         */ 
        static public function mergePeakList(arrayOfPeakList:Array, singlePeakLength:Number=40) : Vector.<Number>
        {
            var listIndex:int, peakListCount:int, i:int, 
                currentPosition:Number, nextPeakPosition:Number, nextPeakHolder:int, 
                merged:Vector.<Number>, list:Vector.<Number>, idx:Vector.<int>;
            peakListCount = arrayOfPeakList.length;
            idx = new Vector.<int>(peakListCount);
            merged = new Vector.<Number>();
            
            for (i=0; i<peakListCount; i++) idx[i] = 0;
            currentPosition = -singlePeakLength;
            while (true) {
                nextPeakPosition = 99999999;
                nextPeakHolder = -1;
                for (listIndex=0; listIndex<peakListCount; listIndex++) {
                    list = arrayOfPeakList[listIndex];
                    if (idx[listIndex] < list.length && list[idx[listIndex]] < nextPeakPosition) {
                        nextPeakPosition = list[idx[listIndex]];
                        nextPeakHolder = listIndex;
                    }
                }
                if (nextPeakHolder != -1) {
                    idx[nextPeakHolder]++;
                    if (nextPeakPosition - currentPosition >= singlePeakLength) {
                        merged.push(nextPeakPosition);
                        currentPosition = nextPeakPosition;
                    }
                } else break; // finished
            }
            
            return merged;
        }
        
        
        
        
    // internals
    //----------------------------------------
        // reset window buffer
        private function _resetWindow() : void {
            if (_window) SLLNumber.freeRing(_window);
            _window = SLLNumber.allocRing(int(_windowLength * 2.1 + 0.5), 0);
        }
        
        
        // update filter parameters
        private function _updateFilter() : void {
            if (_frequency > 0) {
                _bpf.initialize();
                _bpf.setParameters(_frequency, _bandWidth);
            }
        }
        
        
        // update power prof.
        private function _updateProfile() : void {
            if (_profileDirty && _samples) {
                var imax:int, i:int, ix2:int, ix42:int, pow:Number, n:Number;

                // copy samples to working area (_stream)
                imax = _samples.length;
                if (_samplesChannelCount == 1) { // monoral input
                    _stream.length = imax * 2;
                    for (ix2=i=0; i<imax; i++) {
                        _stream[ix2] = _samples[i]; ix2++;
                        _stream[ix2] = _samples[i]; ix2++;
                    }
                } else { // stereo input
                    _stream.length = imax;
                    for (i=0; i<imax;) {
                        n  = _samples[i]; i++;
                        n += _samples[i]; i--;
                        n *= 0.5;
                        _stream[i] = n; i++;
                        _stream[i] = n; i++;
                    }
                }
                
                // filtering
                if (_frequency > 0) {
                    _bpf.prepareProcess();
                    _bpf.process(1, _stream, 0, _stream.length>>1);
                }
                
                // calculate power profile
                imax = (_stream.length-41) / 42;
                _profile.length = imax;
                pow = 0;
                _average = 0;
                _maximum = 0;
                for (i=ix42=0; i<imax; i++) {
                    // 44100/21 = 2100fps
                    _window.n  = _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    _window.n += _stream[ix42] * _stream[ix42]; ix42+=2;
                    pow += _window.n;
                    _window = _window.next;
                    pow -= _window.n;
                    _profile[i] = pow;
                    _average += pow;
                    if (_maximum < pow) _maximum = pow;
                }
                _average /= imax;
                
                _profileDirty = false;
            }
        }
        
        
        // update DLP and peakList
        private function _updatePeakList() : void
        {
            _updateProfile();
            if (_peakListDirty && _profile.length>0) {
                var imax:int = _profile.length,
                    thres:Number = _maximum * 0.001, 
                    snr:Number = Math.pow(10, _signalToNoiseRatio*0.1),
                    wnd:int = int(_windowLength * 2.1 + 0.5), 
                    decay:Number = Math.pow(2, -1/wnd),
                    i:int, i1:int, n:Number, envelope:Number, prevPoint:int;
                
                _diffLogProfile.length = imax;
                _diffLogProfile[0] = 0;
                for (i=1; i<imax; i++) {
                    i1 = i-1;
                    _diffLogProfile[i] = (_profile[i1] > thres) ? (_profile[i]/_profile[i1]-1) : 0;
                }
                
                _peakList.length = 0;
                envelope = 0;
                prevPoint = 0;
                for (i=wnd; i<imax; i++) {
                    if (_diffLogProfile[i] > envelope) {
                        n = _diffLogProfile[i-wnd];
                        if (n <= 0) n = 0.001;
                        n = _diffLogProfile[i] / n;
                        if (n > snr) {
                            if (i-prevPoint < wnd) {
                                _peakList[_peakList.length - 1] = i/2.1;
                            } else {
                                _peakList.push(i/2.1);
                            }
                            prevPoint = i;
                            envelope = _diffLogProfile[i];
                        }
                    }
                    envelope *= decay;
                }
                _peakListDirty = false;
            }
        }
        
        
        // update peak frequency
        private function _updatePeakFreq() : void
        {
            _updatePeakList();
            if (_peakFreqDirty && _profile.length>0) {
                var i:int, j:int, highScoreFrames:int, total:int, frm:int, score:int;
                _ppmScore = calcPeaksPerMinuteEstimationScoreTable(_peakList, _ppmScore);
                _estimatePeaksPerMinuteFromScoreTable();
                _peakFreqDirty = false;
            }
        }
        
        
        // estimate peaks per minute from score table
        private function _estimatePeaksPerMinuteFromScoreTable() : void
        {
            var highScoreFrames:int, i:int, imax:int, j:int, frm:int, thres:Number, pmin:Number, pmax:Number;
            // find highest score
            for (highScoreFrames=100, i=101; i<2000; i++) {
                if (_ppmScore[i] > _ppmScore[highScoreFrames]) highScoreFrames = i;
            }
            // move finding peak to less than 200ppm (630frames)
            while (highScoreFrames < 630) highScoreFrames *= 2;
            // move to peak top
            while (_ppmScore[highScoreFrames]<_ppmScore[highScoreFrames+1]) highScoreFrames++;
            while (_ppmScore[highScoreFrames]<_ppmScore[highScoreFrames-1]) highScoreFrames--;
            // calculate cross point of [peak height] * 0.7
            thres = _ppmScore[highScoreFrames] * 0.7;
            pmin = 0;
            imax = highScoreFrames - 100;
            for (i=highScoreFrames; i>imax; i--) {
                if (_ppmScore[i] < thres) {
                    pmin = i + (thres-_ppmScore[i])/(_ppmScore[i+1]-_ppmScore[i]);
                    break;
                }
            }
            pmax = 0;
            imax = highScoreFrames + 100;
            for (i=highScoreFrames; i<imax; i++) {
                if (_ppmScore[i] < thres) {
                    pmax = i + (_ppmScore[i-1]-thres)/(_ppmScore[i-1]-_ppmScore[i]);
                    break;
                }
            }
            // calcualte peak top again and translate to peaks per minute value
            if (pmin != 0 && pmax != 0) _peaksPerMinute = (highScoreFrames>0) ? (2100*60/((pmax+pmin)*0.5)) : 0;
            else _peaksPerMinute = (highScoreFrames>0) ? (2100*60/highScoreFrames) : 0;
            // move range into maxPeaksPerMinute
            var minPeaksPerMinute:Number = maxPeaksPerMinute * 0.5;
            while (_peaksPerMinute >= maxPeaksPerMinute) _peaksPerMinute *= 0.5;
            while (_peaksPerMinute <  minPeaksPerMinute) _peaksPerMinute *= 2;
            // integrate peaks to calculate probability
            _peaksPerMinuteProbability = 0;
            for (i=0; i<10; i++) {
                frm = int(highScoreFrames * _probCheck[i]);
                if (frm>2100) break;
                for (j=-22; j<23; j++) _peaksPerMinuteProbability += _ppmScore[frm+j];
            }
        }
        static private var _probCheck:Vector.<Number> = Vector.<Number>([0.25,0.5,1,2,3,4,5,6,7,8]);

        
        /** @internal caclulate peak frequency estimation scores 
         *  @param peakList peal list [ms]
         *  @param scoreTable score table instance to set, null to create new table.
         *  @return score table
         */
        static public function calcPeaksPerMinuteEstimationScoreTable(peakList:Vector.<Number>, scoreTable:Vector.<Number>=null) : Vector.<Number>
        {
            var i:int, j:int, k:int, s:int, peakCount:int, peakDist:int, dist:Number, dist2:Number, scale:Number, scoreTotal:int;
            if (scoreTable == null) scoreTable = new Vector.<Number>(2124);
            
            // clear score table
            for(i=0; i<2124; i++) scoreTable[i] = 0;
            
            // calculate scores
            peakCount = peakList.length;
            for (i=0; i<peakCount;i++) {
                for (j=i+1; j<peakCount; j++) {
                    dist = peakList[j] - peakList[i];
                    if (dist<48) continue;
                    if (dist>1000) break;
                    scale = 1;
                    for (k=j+1; k<peakCount; k++) {
                        dist2 = (peakList[k] - peakList[j]) / dist + 0.1;
                        dist2 -= int(dist2);
                        if (dist2 < 0.2) {
                            dist2 -= 0.1;
                            if (dist2<0) dist2 = -dist2;
                            scale += _normalDist[int(dist2 * 20)] * 0.01;
                        }
                    }
                    peakDist = int(dist * 2.1 + 0.5);
                    scoreTable[peakDist] += _normalDist[0] * scale;
                    for (k=1; k<20; k++) {
                        s = peakDist + k; scoreTable[s] += _normalDist[k] * scale;
                        s = peakDist - k; scoreTable[s] += _normalDist[k] * scale;
                    }
                }
            }

            // normalize
            for (scoreTotal=0,       i=0; i<2124; i++) scoreTotal += scoreTable[i];
            for (scale=1/scoreTotal, i=0; i<2124; i++) scoreTable[i] *= scale;
            return scoreTable;
        }
        static private var _normalDist:Vector.<int> = Vector.<int>([100,99,95,89,81,73,63,53,44,35,28,21,16,11,8,6,4,2,2,1]);
    }

}

