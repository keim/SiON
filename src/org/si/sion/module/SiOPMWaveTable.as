//----------------------------------------------------------------------------------------------------
// class for SiOPM wave table
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import org.si.sion.sequencer.SiMMLTable;

    /** SiOPM wave table */
    public class SiOPMWaveTable extends SiOPMWaveBase
    {
        public var wavelet:Vector.<int>;
        public var fixedBits:int;
        public var defaultPTType:int;
        
        
        /** create new SiOPMWaveTable instance. */
        function SiOPMWaveTable()
        {
            super(SiMMLTable.MT_CUSTOM);
            this.wavelet = null;
            this.fixedBits = 0;
            this.defaultPTType = 0;
        }
        
        
        /** initialize 
         *  @param wavelet wave table in log scale.
         *  @param defaultPTType default pitch table type.
         */
        public function initialize(wavelet:Vector.<int>, defaultPTType:int=0) : SiOPMWaveTable
        {
            var len:int, bits:int=0;
            for (len=wavelet.length>>1; len!=0; len>>=1) bits++;
            
            this.wavelet = wavelet;
            this.fixedBits = SiOPMTable.PHASE_BITS - bits;
            this.defaultPTType = defaultPTType;
            
            return this;
        }
        
        
        /** copy 
         *  @return this instance
         */
        public function copyFrom(src:SiOPMWaveTable) : SiOPMWaveTable
        {
            var i:int, imax:int = src.wavelet.length;
            this.wavelet = new Vector.<int>(imax);
            for (i=0; i<imax; i++) this.wavelet[i] = src.wavelet[i];
            this.fixedBits = src.fixedBits;
            this.defaultPTType = src.defaultPTType;
            
            return this;
        }
        
        
        /** free. */
        public function free() : void
        {
            _freeList.push(this);
        }
        
        
        static private var _freeList:Vector.<SiOPMWaveTable> = new Vector.<SiOPMWaveTable>();
        
        
        /** allocate. */
        static public function alloc(wavelet:Vector.<int>, defaultPTType:int=0) : SiOPMWaveTable
        {
            var newInstance:SiOPMWaveTable = _freeList.pop() || new SiOPMWaveTable();
            return newInstance.initialize(wavelet, defaultPTType);
        }
    }
}

