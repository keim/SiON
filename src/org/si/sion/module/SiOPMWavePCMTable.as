//----------------------------------------------------------------------------------------------------
// class for SiOPM PCM data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import org.si.sion.sequencer.SiMMLTable;
    import org.si.sion.module.SiOPMTable;
    
    
    /** PCM data class */
    public class SiOPMWavePCMTable extends SiOPMWaveBase
    {
    // valiables
    //----------------------------------------
        /** @private PCM wave data assign table for each note. */
        _siopm_module_internal var _table:Vector.<SiOPMWavePCMData>;
        /** @private volume table */
        _siopm_module_internal var _volumeTable:Vector.<Number>;
        /** @private pan table */
        _siopm_module_internal var _panTable:Vector.<int>;
        
        
        
        
    // constructor
    //----------------------------------------
        /** Constructor */
        function SiOPMWavePCMTable()
        {
            super(SiMMLTable.MT_PCM);
            _siopm_module_internal::_table = new Vector.<SiOPMWavePCMData>(SiOPMTable.NOTE_TABLE_SIZE, true);
            _siopm_module_internal::_volumeTable = new Vector.<Number>(SiOPMTable.NOTE_TABLE_SIZE, true);
            _siopm_module_internal::_panTable = new Vector.<int>(SiOPMTable.NOTE_TABLE_SIZE, true);
            clear();
        }
        
        
        
        
    // oprations
    //----------------------------------------
        /** Clear all of the table.
         *  @param pcmData SiOPMWavePCMData to fill layer0's pcm.
         *  @return this instance
         */
        public function clear(pcmData:SiOPMWavePCMData = null) : SiOPMWavePCMTable
        {
            var i:int;
            for (i=0; i<SiOPMTable.NOTE_TABLE_SIZE; i++) {
                _siopm_module_internal::_table[i] = pcmData;
                _siopm_module_internal::_volumeTable[i] = 1;
                _siopm_module_internal::_panTable[i] = 0;
            }
            return this;
        }
        
        
        /** Set sample data.
         *  @param pcmData assignee SiOPMWavePCMData
         *  @param keyRangeFrom Assigning key range starts from
         *  @param keyRangeTo Assigning key range ends at. -1 to set only at the key of argument "keyRangeFrom".
         *  @return assigned PCM data (same as pcmData passed as the 1st argument.)
         */
        public function setSample(pcmData:SiOPMWavePCMData, keyRangeFrom:int=0, keyRangeTo:int=127) : SiOPMWavePCMData
        {
            if (keyRangeFrom < 0) keyRangeFrom = 0;
            if (keyRangeTo > 127) keyRangeTo = 127;
            if (keyRangeTo == -1) keyRangeTo = keyRangeFrom;
            if (keyRangeFrom > 127 || keyRangeTo < 0 || keyRangeTo < keyRangeFrom) throw new Error("SiOPMWavePCMTable error; Invalid key range");
            for (var i:int=keyRangeFrom; i<=keyRangeTo; i++) _siopm_module_internal::_table[i] = pcmData;
            return pcmData;
        }
        
        
        /** update key scale volume
         *  @param centerNoteNumber note number of volume changing center
         *  @param keyRange key range of volume changing notes
         *  @param volumeRange range of volume changing (128 for full volouming)
         *  @return this instance
         */
        public function setKeyScaleVolume(centerNoteNumber:int=64, keyRange:Number=0, volumeRange:Number=0) : SiOPMWavePCMTable
        {
            volumeRange *= 0.0078125;
            var imin:int = centerNoteNumber - keyRange * 0.5, imax:int = centerNoteNumber + keyRange * 0.5,
                v:Number, dv:Number = (keyRange == 0) ? volumeRange : (volumeRange / keyRange), i:int;
            if (volumeRange > 0) {
                v = 1 - volumeRange;
                for (i=0; i<imin; i++) _siopm_module_internal::_volumeTable[i] = v;
                for (; i<imax; i++, v+=dv) _siopm_module_internal::_volumeTable[i] = v;
                for (; i<SiOPMTable.NOTE_TABLE_SIZE; i++) _siopm_module_internal::_volumeTable[i] = 1;
            } else {
                v = 1;
                for (i=0; i<imin; i++) _siopm_module_internal::_volumeTable[i] = 1;
                for (;i<imax; i++, v+=dv) _siopm_module_internal::_volumeTable[i] = v;
                v = 1 + volumeRange;
                for (; i<SiOPMTable.NOTE_TABLE_SIZE; i++) _siopm_module_internal::_volumeTable[i] = v;
            }
            return this;
        }
        
        
        /** update key scale panning
         *  @param centerNoteNumber note number of panning center
         *  @param keyRange key range of panning notes
         *  @param panWidth panning width for all of key range (128 for full panning)
         *  @return this instance
         */
        public function setKeyScalePan(centerNoteNumber:int=64, keyRange:Number=0, panWidth:Number=0) : SiOPMWavePCMTable
        {
            var imin:int = centerNoteNumber - keyRange * 0.5, imax:int = centerNoteNumber + keyRange * 0.5, 
                p:Number = -panWidth * 0.5, dp:Number = (keyRange == 0) ? panWidth : (panWidth / keyRange), i:int;
            for (i=0; i<imin; i++)    _siopm_module_internal::_panTable[i] = p;
            for (; i<imax; i++, p+=dp) _siopm_module_internal::_panTable[i] = p;
            for (p=panWidth*0.5; i<SiOPMTable.NOTE_TABLE_SIZE; i++) _siopm_module_internal::_panTable[i] = p;
            return this;
        }
        
        
        /** @private [internal use] free all */
        _siopm_module_internal function _free() : void
        {
            for (var i:int=0; i<SiOPMTable.NOTE_TABLE_SIZE; i++) {
                //if (_table[i]) _table[i].free();
                _siopm_module_internal::_table[i] = null;
            }
        }
    }
}

