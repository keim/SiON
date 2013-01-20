//----------------------------------------------------------------------------------------------------
// BPM analyzer
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils {
    import flash.media.*;


    /** BPMAnalyzer analyzes beat per minute value of music */
    public class BPMAnalyzer {
    // valiables
    //----------------------------------------
        /** filter banks, 5000Hz, 2400Hz, 100Hz @ default. */
        public var filterbanks:Vector.<PeakDetector>;
        
        private var _bpm:int;
        private var _bpmProbability:Number;
        private var _pickedupCount:int;
        private var _pickedupBPMList:Vector.<int> = new Vector.<int>(10, true);
        private var _pickedupBPMProbabilityList:Vector.<Number> = new Vector.<Number>(10, true);
        private var _snapShotIndex:int;
        
        
        
        
    // properties
    //----------------------------------------
        /** estimated bpm */
        public function get bpm() : int { return _bpm; }
        
        /** estimated bpm's probability */
        public function get bpmProbability() : Number { return _bpmProbability; }
        
        /** number of picked up point */
        public function get pickedupCount() : int { return _pickedupCount; }
        
        /** picked up bpm list */
        public function get pickedupBPMList() : Vector.<int> { return _pickedupBPMList; }
        
        /** picked up bpm's probability list */
        public function get pickedupBPMProbabilityList() : Vector.<Number> { return _pickedupBPMProbabilityList; }
        
        /** starting position that has maximum probability */
        public function get snapShotPosition() : Number { return _snapShotIndex * 0.000022675736961451247; } // 1/44100
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
        *  @param filterbankCount Number of filter bank for analysis (1-4).
         */
        function BPMAnalyzer(filterbankCount:int=3) {
            if (filterbankCount < 1 || filterbankCount > 4) filterbankCount = 4;
            filterbanks = new Vector.<PeakDetector>(filterbankCount);
            filterbanks[0] = new PeakDetector(5000, 0.50, 25);
            if (filterbankCount > 1) filterbanks[1] = new PeakDetector(2400, 0.50, 25);
            if (filterbankCount > 2) filterbanks[2] = new PeakDetector( 100, 0.50, 40);
            if (filterbankCount > 3) filterbanks[3] = new PeakDetector();
        }
        
        
        
        
    // methods
    //----------------------------------------
        /** estimate BPM from Sound 
         *  @param sound sound to analyze
         *  @param rememberFilterbanksSnapShot remember filterbanks status that has the biggest probability
         *  @return estimated bpm value
         */
        public function estimateBPM(sound:Sound, rememberFilterbanksSnapShot:Boolean = false) : int {
            var pickupIndex:int, pickupStep:int, i:int, maxProb:Number, thres:Number, 
                probs:Vector.<Number> = _pickedupBPMProbabilityList, 
                bpms:Vector.<int>=_pickedupBPMList, scores:Vector.<Number>;
            
            _pickedupCount = int(sound.length / 20000);
            if (_pickedupCount == 0) _pickedupCount = 1;
            else if (_pickedupCount > 10) _pickedupCount = 10;
            scores = new Vector.<Number>(100, true);
            
            pickupStep = (sound.length - _pickedupCount * 4000) * 44.1 / (_pickedupCount + 1);
            if (pickupStep < 0) pickupStep = 0;
            maxProb = 0;
            
            for (pickupIndex=pickupStep, i=0; i<_pickedupCount; i++, pickupIndex+=176400+pickupStep) {
                _estimateBPMFromSamples(SiONUtil.extract(sound, null, 1, 176400, pickupIndex), 1);
                probs[i] = _bpmProbability;
                bpms[i] = int(_bpm);
                if (maxProb < _bpmProbability) {
                    maxProb = _bpmProbability;
                    _snapShotIndex = pickupIndex;
                }
            }
            _bpmProbability = maxProb;
            
            thres = maxProb * 0.75;
            for (i=0; i<_pickedupCount; i++) {
                if (probs[i] > thres && 100<=bpms[i] && bpms[i]<200) scores[bpms[i]-100] += probs[i];
            }
            maxProb = 0;
            for (i=0; i<100; i++) {
                if (maxProb < scores[i]) {
                    maxProb = scores[i];
                    _bpm = i + 100;
                }
            }

            if (rememberFilterbanksSnapShot) _estimateBPMFromSamples(SiONUtil.extract(sound, null, 1, 176400, _snapShotIndex), 1);
            
            return _bpm;
        }
        
        
        /** estimate BPM from samples
         *  @param sample samples to analyze
         *  @param channels channel count of samples
         *  @return estimated bpm value
         */
        public function estimateBPMFromSamples(sample:Vector.<Number>, channels:int) : int {
            _pickedupCount = 0;
            _estimateBPMFromSamples(sample, channels);
            return _bpm;
        }
        
        
        
        
    // internal
    //----------------------------------------
        // estimate BPM from samples
        private function _estimateBPMFromSamples(sample:Vector.<Number>, channels:int) : void {
            var pd1:PeakDetector, pd2:PeakDetector, pmp:Number, pmr:Number, bpm:Number;
            var i:int, banksCount:int = filterbanks.length;
            
            // set samples to filter banks
            for (i=0; i<banksCount; i++) filterbanks[i].setSamples(sample, channels);
            
            // pick up 1st and 2nd acculate filterbanks
            if (banksCount > 1) {
                // pick up 2 banks
                if (filterbanks[0].peaksPerMinuteProbability < filterbanks[1].peaksPerMinuteProbability) {
                    pd1 = filterbanks[1];
                    pd2 = filterbanks[0];
                } else {
                    pd1 = filterbanks[0];
                    pd2 = filterbanks[1];
                }
                for (i=2; i<banksCount; i++) {
                    if (pd2.peaksPerMinuteProbability < filterbanks[i].peaksPerMinuteProbability) {
                        if (pd1.peaksPerMinuteProbability < filterbanks[i].peaksPerMinuteProbability) {
                            pd2 = pd1;
                            pd1 = filterbanks[i];
                        } else {
                            pd2 = filterbanks[i];
                        }
                    }
                }
                // estimate bpm
                pmp = pd1.peaksPerMinuteProbability / pd2.peaksPerMinuteProbability;
                pmr = pd1.peaksPerMinute / pd2.peaksPerMinute;
                if (pmp > 1.333 || pmr > 1.1 || pmr < 0.9) bpm = pd1.peaksPerMinute;
                else bpm = (pd1.peaksPerMinute + pd2.peaksPerMinute) * 0.5;
                _bpm = int(bpm+0.5);
                _bpmProbability = pd1.peaksPerMinuteProbability;
            } else {
                // only one bank
                _bpm = filterbanks[0].peaksPerMinute;
                _bpmProbability = filterbanks[0].peaksPerMinuteProbability;
            }
        }
    }
}

