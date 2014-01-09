//----------------------------------------------------------------------------------------------------
// SiOPM Vowel filter
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.utils.SLLint;

    
    /** Vowel filter, conbination of 6 peaking filters */
    public class SiFilterVowel extends SiEffectBase
    {
    // variables
    //------------------------------------------------------------
        static public const FORMANT_COUNT:int = 6;
        public var formant:Vector.<SiFilterVowelFormant>;
        public var outputLevel:Number = 1;
        
        // tap matrix
        private var _t0i0:Number, _t0i1:Number, _t0o0:Number, _t0o1:Number;
        private var _t1i0:Number, _t1i1:Number, _t1o0:Number, _t1o1:Number;
        private var _t2i0:Number, _t2i1:Number, _t2o0:Number, _t2o1:Number;
        private var _t3i0:Number, _t3i1:Number, _t3o0:Number, _t3o1:Number;
        private var _t4i0:Number, _t4i1:Number, _t4o0:Number, _t4o1:Number;
        private var _t5i0:Number, _t5i1:Number, _t5o0:Number, _t5o1:Number;
        
        private var _eventQueue:FormantEvent;
        
        
        
    // constructor
    //------------------------------------------------------------
        /** constructor
         */
        function SiFilterVowel() 
        {
            SiFilterVowelFormant.initialize();
            formant = new Vector.<SiFilterVowelFormant>(FORMANT_COUNT, true);
            for (var i:int=0; i<FORMANT_COUNT; i++) formant[i] = new SiFilterVowelFormant();
            _eventQueue = null;
            setFilterBand();
        }
        
        
        
        
    // operations
    //------------------------------------------------------------
        /** set 1st and 2nd formant with delay */
        public function setVowellFormant(outputLevel:Number, formFreq1:Number, gain1:int, formFreq2:Number, gain2:int, delay:int = 0) : void 
        {
            var ifreq1:int = SiFilterVowelFormant.calcFreqIndex(formFreq1),
                ifreq2:int = SiFilterVowelFormant.calcFreqIndex(formFreq2),
                e:FormantEvent = new FormantEvent(delay, outputLevel, ifreq1, gain1, ifreq2, gain2);
            _eventQueue = e.insertTo(_eventQueue);
        }
        
        
        /** set all peaking filter */
        public function setFilterBand(formFreq1:Number=800,  gain1:int=36, bandwidth1:int=3, 
                                      formFreq2:Number=1300, gain2:int=24, bandwidth2:int=3, 
                                      formFreq3:Number=2200, gain3:int=12, bandwidth3:int=3, 
                                      formFreq4:Number=3500, gain4:int=9,  bandwidth4:int=3, 
                                      formFreq5:Number=4500, gain5:int=6,  bandwidth5:int=3, 
                                      formFreq6:Number=5500, gain6:int=3,  bandwidth6:int=3) : void 
        {
            formant[0].update(SiFilterVowelFormant.calcFreqIndex(formFreq1), bandwidth1, gain1);
            formant[1].update(SiFilterVowelFormant.calcFreqIndex(formFreq2), bandwidth2, gain2);
            formant[2].update(SiFilterVowelFormant.calcFreqIndex(formFreq3), bandwidth3, gain3);
            formant[3].update(SiFilterVowelFormant.calcFreqIndex(formFreq4), bandwidth4, gain4);
            formant[4].update(SiFilterVowelFormant.calcFreqIndex(formFreq5), bandwidth5, gain5);
            formant[5].update(SiFilterVowelFormant.calcFreqIndex(formFreq6), bandwidth6, gain6);
        }
        
        
        private function _updateEvent(time:int) : int
        {
            while (_eventQueue && _eventQueue.time == 0) {
                formant[0].update(_eventQueue.ifreq1, 3, _eventQueue.igain1);
                formant[1].update(_eventQueue.ifreq2, 2, _eventQueue.igain2);
                outputLevel = _eventQueue.outputLevel;
                _eventQueue = _eventQueue.next;
            }
            return (_eventQueue) ? _eventQueue.updateTime(time) : time;
        }
        
        
        
        
    // overrided funcitons
    //------------------------------------------------------------
        /** @private */
        override public function initialize() : void
        {
        }
        

        /** @private */
        override public function mmlCallback(args:Vector.<Number>) : void
        {
            outputLevel = (!isNaN(args[0]))  ? (args[0]*0.01) : 1;
            setFilterBand((!isNaN(args[1]))  ? args[1] : 800,  
                          (!isNaN(args[2]))  ? args[2] : 30, 3,
                          (!isNaN(args[3]))  ? args[3] : 1300, 
                          (!isNaN(args[4]))  ? args[4] : 24, 3, 
                          (!isNaN(args[5]))  ? args[5] : 2200, 
                          (!isNaN(args[6]))  ? args[6] : 12, 3, 
                          (!isNaN(args[7]))  ? args[7] : 3500, 
                          (!isNaN(args[8]))  ? args[8] : 9, 3, 
                          (!isNaN(args[9]))  ? args[9] : 4500, 
                          (!isNaN(args[10])) ? args[10] : 6, 3, 
                          (!isNaN(args[11])) ? args[11] : 5500, 
                          (!isNaN(args[12])) ? args[12] : 6, 3);
        }
        
        
        /** @private */
        override public function prepareProcess() : int
        {
            _t0i0 = _t0i1 = _t0o0 = _t0o1 = 0;
            _t1i0 = _t1i1 = _t1o0 = _t1o1 = 0;
            _t2i0 = _t2i1 = _t2o0 = _t2o1 = 0;
            _t3i0 = _t3i1 = _t3o0 = _t3o1 = 0;
            _t4i0 = _t4i1 = _t4o0 = _t4o1 = 0;
            _t5i0 = _t5i1 = _t5o0 = _t5o1 = 0;
            return 1;
        }
        
        
        /** @private */
        override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int
        {
            var i:int, imax:int, istep:int;
            imax = startIndex + length;
            for (i=startIndex; i<imax;) {
                istep = _updateEvent(length);
                processLFO(buffer, i, istep);
                i += istep;
                length -= istep;
            }
            return 1;
        }
        
        
        /** @private */
        protected function processLFO(buffer:Vector.<Number>, startIndex:int, length:int) : void {
            startIndex <<= 1;
            length <<= 1;
            var i:int, output:Number, input:Number, imax:int=startIndex+length, 
                f1ab1:Number = formant[0].ab1, f1a2:Number = formant[0].a2, f1b0:Number = formant[0].b0, f1b2:Number = formant[0].b2, 
                f2ab1:Number = formant[1].ab1, f2a2:Number = formant[1].a2, f2b0:Number = formant[1].b0, f2b2:Number = formant[1].b2, 
                f3ab1:Number = formant[2].ab1, f3a2:Number = formant[2].a2, f3b0:Number = formant[2].b0, f3b2:Number = formant[2].b2, 
                f4ab1:Number = formant[3].ab1, f4a2:Number = formant[3].a2, f4b0:Number = formant[3].b0, f4b2:Number = formant[3].b2, 
                f5ab1:Number = formant[4].ab1, f5a2:Number = formant[4].a2, f5b0:Number = formant[4].b0, f5b2:Number = formant[4].b2, 
                f6ab1:Number = formant[5].ab1, f6a2:Number = formant[5].a2, f6b0:Number = formant[5].b0, f6b2:Number = formant[5].b2;
            for (i=startIndex; i<imax;) {
                input = buffer[i];
                output = f1b0 * input + f1ab1 * _t0i0 + f1b2 * _t0i1 - f1ab1 * _t0o0 - f1a2 * _t0o1;
                _t0i1 = _t0i0; _t0i0 = input; _t0o1 = _t0o0; _t0o0 = input = output;
                output = f2b0 * input + f2ab1 * _t1i0 + f2b2 * _t1i1 - f2ab1 * _t1o0 - f2a2 * _t1o1;
                _t1i1 = _t1i0; _t1i0 = input; _t1o1 = _t1o0; _t1o0 = input = output;
                output = f3b0 * input + f3ab1 * _t2i0 + f3b2 * _t2i1 - f3ab1 * _t2o0 - f3a2 * _t2o1;
                _t2i1 = _t2i0; _t2i0 = input; _t2o1 = _t2o0; _t2o0 = input = output;
                output = f4b0 * input + f4ab1 * _t3i0 + f4b2 * _t3i1 - f4ab1 * _t3o0 - f4a2 * _t3o1;
                _t3i1 = _t3i0; _t3i0 = input; _t3o1 = _t3o0; _t3o0 = input = output;
                output = f5b0 * input + f5ab1 * _t4i0 + f5b2 * _t4i1 - f5ab1 * _t4o0 - f5a2 * _t4o1;
                _t4i1 = _t4i0; _t4i0 = input; _t4o1 = _t4o0; _t4o0 = input = output;
                output = f6b0 * input + f6ab1 * _t5i0 + f6b2 * _t5i1 - f6ab1 * _t5o0 - f6a2 * _t5o1;
                _t5i1 = _t5i0; _t5i0 = input; _t5o1 = _t5o0; _t5o0 = input = output;
                output *= outputLevel;
                if (output < -1) output = -1;
                else if (output > 1) output = 1;
                buffer[i] = output; i++;
                buffer[i] = output; i++;
            }
        }
    }
}



class FormantEvent {
    public var next:FormantEvent;
    public var ifreq1:int, igain1:int, ifreq2:int, igain2:int;
    public var outputLevel:Number;
    public var time:int;
    
    function FormantEvent(time:int, outputLevel:Number, ifreq1:int, igain1:int, ifreq2:int, igain2:int) : void {
        this.time = time;
        this.outputLevel = outputLevel;
        this.ifreq1 = ifreq1;
        this.igain1 = igain1;
        this.ifreq2 = ifreq2;
        this.igain2 = igain2;
    }
    
    public function insertTo(list:FormantEvent) : FormantEvent {
        if (list == null) return this;
        if (this.time < list.time) {
            this.next = list;
            return this;
        }
        var e:FormantEvent = list;
        while (e.next) {
            if (e.time <= this.time && this.time < e.next.time) {
                this.next = e.next;
                e.next = this;
                break;
            }
            e = e.next;
        }
        e.next = this;
        return list;
    }
    
    public function updateTime(prog:int) : int {
        if (prog > time) prog = time;
        for (var e:FormantEvent=this; e; e=e.next) e.time -= prog;
        return prog;
    }
}


class SiFilterVowelFormant {
    static private var _alphaTable:Vector.<Vector.<Number>> = null;
    static private var _cosTable:Vector.<Number> = null;
    static private var _gainTable:Vector.<Number> = null;
    static private var _ibandList:Array = [0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4];
    static public function initialize() : void {
        if (!_alphaTable) {
            var iband:int, ifreq:int, igain:int, band:Number, freq:Number, table:Vector.<Number>, 
                omg:Number, cos:Number, sin:Number, angh:Number;            
            _alphaTable = new Vector.<Vector.<Number>>(8, true);
            for (iband=0; iband<8; iband++) {
                _alphaTable[iband] = table = new Vector.<Number>(1024, true);
                band = _ibandList[iband];
                for (ifreq=0, freq=50; ifreq<1024; ifreq++, freq*=1.0218971486541166) { // 2^(1/32)
                    omg  = freq * 0.00014247585730565955; // 2*pi/44100
                    sin  = Math.sin(omg);
                    angh = 0.34657359027997264 * band * omg / sin; // log(2)*0.5
                    table[ifreq] = sin * (Math.exp(angh) - Math.exp(-angh)) * 0.5; // sin * sinh(angh)
                }
            }
            _cosTable = new Vector.<Number>(1024, true);
            for (ifreq=0, freq=50; ifreq<1024; ifreq++, freq*=1.0218971486541166) { // 2^(1/32)
                _cosTable[ifreq]  = Math.cos(freq * 0.00014247585730565955);
            }
            _gainTable = new Vector.<Number>(128, true);
            for (igain=0; igain<128; igain++) {
                _gainTable[igain] = Math.pow(10, (igain-32)*0.025);
            }
        }
    }
    
    static public function calcFreqIndex(frequency:Number) : int {
        var ifreq:int = (Math.log(frequency) * 1.4426950408889633 - 5.643856189774724) * 32; // * 1/loge(2) - log2(50)
        if (ifreq < 0) return 0;
        if (ifreq > 1023) return 1023;
        return ifreq
    }
    
    public var ab1:Number, a2:Number, b0:Number, b2:Number;
    
    function SiFilterVowelFormant() {
        clear();
    }
    
    public function clear() : void {
        b0 = 1;
        ab1 = a2 = b2 = 0;
    }
    
    /** update filtering parameters
     *  @param ifreq frequency index. (0=50[Hz], 32=100[Hz], 64=200[Hz] ...1024=12800[Hz])
     *  @param iband band width index. (0=0.125oct, 1=0.25oct, ...7=16oct)
     *  @param gain gain. ( -32dB - 96dB)
     */
    public function update(ifreq:int, iband:int, gain:int) : void {
        gain += 32;
        if (gain < 0) gain = 0;
        else if (gain > 127) gain = 127;
        var alp:Number   = _alphaTable[iband][ifreq],
            A:Number     = _gainTable[gain],
            alpA:Number  = alp * A, 
            alpiA:Number = alp / A,
            ia0:Number   = 1 / (1+alpiA);
        ab1 = -2 * _cosTable[ifreq] * ia0;
        a2 = (1-alpiA) * ia0;
        b0 = (1+alpA) * ia0;
        b2 = (1-alpA) * ia0;
    }
}


