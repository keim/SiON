//----------------------------------------------------------------------------------------------------
// class for SiOPM samplers wave table
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import org.si.sion.sequencer.SiMMLTable;
    
    
    /** SiOPM samplers wave table */
    public class SiOPMWaveSamplerTable extends SiOPMWaveBase
    {
    // valiables
    //----------------------------------------
        /** Stencil table, search sample in stencil table before seaching this instances table. */
        public var stencil:SiOPMWaveSamplerTable;

        // SiOPMWaveSamplerData table to refer from sampler channel.
        private var _table:Vector.<SiOPMWaveSamplerData>;
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor 
         *  @param waveList SiOPMWaveSamplerData list to set as table
         */
        function SiOPMWaveSamplerTable() 
        {
            super(SiMMLTable.MT_SAMPLE);
            _table = new Vector.<SiOPMWaveSamplerData>(SiOPMTable.SAMPLER_DATA_MAX);
            stencil = null;
            clear();
        }
        
        
        
        
    // oprations
    //----------------------------------------
        /** Clear all of the table. 
         *  @param sampleData SiOPMWaveSamplerData to fill with.
         *  @return this instance
         */
        public function clear(sampleData:SiOPMWaveSamplerData = null) : SiOPMWaveSamplerTable
        {
            for (var i:int=0; i<SiOPMTable.SAMPLER_DATA_MAX; i++) _table[i] = sampleData;
            return this;
        }
        
        
        /** Set sample data.
         *  @param sample assignee SiOPMWaveSamplerData
         *  @param keyRangeFrom Assigning key range starts from
         *  @param keyRangeTo Assigning key range ends at. -1 to set only at the key of argument "keyRangeFrom".
         *  @return assigned SiOPMWaveSamplerData (same as sample passed as the 1st argument).
         */
        public function setSample(sample:SiOPMWaveSamplerData, keyRangeFrom:int=0, keyRangeTo:int=-1) : SiOPMWaveSamplerData
        {
            if (keyRangeFrom < 0) keyRangeFrom = 0;
            if (keyRangeTo > 127) keyRangeTo = 127;
            if (keyRangeTo == -1) keyRangeTo = keyRangeFrom;
            if (keyRangeFrom > 127 || keyRangeTo < 0 || keyRangeTo < keyRangeFrom) throw new Error("SiOPMWaveSamplerTable error; Invalid key range");
            for (var i:int=keyRangeFrom; i<=keyRangeTo; i++) _table[i] = sample;
            return sample;
        }
        
        
        /** Get sample data.
         *  @param sampleNumber Sample number (0-127).
         *  @return assigned SiOPMWaveSamplerData
         */
        public function getSample(sampleNumber:int) : SiOPMWaveSamplerData
        {
            if (stencil) return stencil._table[sampleNumber] || _table[sampleNumber];
            return _table[sampleNumber];
        }
        

        /** @private [internal use] free all */
        _siopm_module_internal function _free() : void
        {
            for (var i:int=0; i<SiOPMTable.SAMPLER_DATA_MAX; i++) {
                //if (_table[i]) _table[i].free();
                _table[i] = null;
            }
        }
    }
}

