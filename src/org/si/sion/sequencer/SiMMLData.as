//----------------------------------------------------------------------------------------------------
// SiMML data
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMWaveTable;
    import org.si.sion.module.SiOPMWavePCMTable;
    import org.si.sion.module.SiOPMWaveSamplerTable;
    import org.si.sion.module._siopm_module_internal;
    import org.si.sion.sequencer.base.MMLData;
    import org.si.utils.SLLint;
    import org.si.sion.namespaces._sion_internal;
    
    
    
    /** SiMML data class. */
    public class SiMMLData extends MMLData
    {
    // valiables
    //----------------------------------------
        /** envelope tables */
        public var envelopes:Vector.<SiMMLEnvelopTable>;
        
        /** wave tables */
        public var waveTables:Vector.<SiOPMWaveTable>;
        
        /** FM voice data */
        public var fmVoices:Vector.<SiMMLVoice>;
       
        /** pcm data (log-transformed) */
        public var pcmVoices:Vector.<SiMMLVoice>;
        
        /** wave data */
        public var samplerTables:Vector.<SiOPMWaveSamplerTable>;
        
        
        
        
    // properties
    //----------------------------------------
        /** [NOT RECOMMENDED] This property is for the compatibility of previous versions, please use fmVoices instead of this. @see #fmVoices */
        public function get voices() : Vector.<SiMMLVoice> { return fmVoices; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor. */
        function SiMMLData()
        {
            envelopes    = new Vector.<SiMMLEnvelopTable>(SiMMLTable.ENV_TABLE_MAX);
            waveTables   = new Vector.<SiOPMWaveTable>(SiOPMTable.WAVE_TABLE_MAX);
            fmVoices     = new Vector.<SiMMLVoice>(SiMMLTable.VOICE_MAX);
            pcmVoices    = new Vector.<SiMMLVoice>(SiOPMTable.PCM_DATA_MAX);
            samplerTables = new Vector.<SiOPMWaveSamplerTable>(SiOPMTable.SAMPLER_TABLE_MAX);
            for (var i:int=0; i<SiOPMTable.SAMPLER_TABLE_MAX; i++) {
                samplerTables[i] = new SiOPMWaveSamplerTable();
            }
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Clear all parameters and free all sequence groups. */
        override public function clear() : void
        {
            super.clear();
            
            var i:int, pcm:SiOPMWavePCMTable;
            for (i=0; i<SiMMLTable.ENV_TABLE_MAX; i++) envelopes[i] = null;
            for (i=0; i<SiMMLTable.VOICE_MAX; i++) fmVoices[i] = null;
            for (i=0; i<SiOPMTable.WAVE_TABLE_MAX; i++) {
                if (waveTables[i]) { 
                    waveTables[i].free();
                    waveTables[i] = null;
                }
            }
            for (i=0; i<SiOPMTable.PCM_DATA_MAX; i++) { 
                if (pcmVoices[i]) { 
                    pcm = pcmVoices[i].waveData as SiOPMWavePCMTable;
                    if (pcm) pcm._siopm_module_internal::_free();
                    pcmVoices[i] = null;
                }
            }
            for (i=0; i<SiOPMTable.SAMPLER_TABLE_MAX; i++) {
                samplerTables[i]._siopm_module_internal::_free();
            }
        }
        
        
        /** Set envelope table data refered by &#64;&#64;,na,np,nt,nf,_&#64;&#64;,_na,_np,_nt and _nf.
         *  @param index envelope table number.
         *  @param envelope envelope table.
         */
        public function setEnvelopTable(index:int, envelope:SiMMLEnvelopTable) : void
        {
            if (index >= 0 && index < SiMMLTable.ENV_TABLE_MAX) envelopes[index] = envelope;
        }
        
        
        /** Set wave table data refered by %6.
         *  @param index wave table number.
         *  @param voice voice to register.
         */
        public function setVoice(index:int, voice:SiMMLVoice) : void
        {
            if (index >= 0 && index < SiMMLTable.VOICE_MAX) {
                if (!voice._sion_internal::_isSuitableForFMVoice) throw errorNotGoodFMVoice();
                 fmVoices[index] = voice;
            }
        }
        
        
        /** Set wave table data refered by %4.
         *  @param index wave table number.
         *  @param data Vector.&lt;Number&gt; wave shape data ranged from -1 to 1.
         *  @return created data instance
         */
        public function setWaveTable(index:int, data:Vector.<Number>) : SiOPMWaveTable
        {
            index &= SiOPMTable.WAVE_TABLE_MAX-1;
            var i:int, imax:int=data.length;
            var table:Vector.<int> = new Vector.<int>(imax);
            for (i=0; i<imax; i++) table[i] = SiOPMTable.calcLogTableIndex(data[i]);
            waveTables[index] = SiOPMWaveTable.alloc(table);
            return waveTables[index];
        }
        
        
        
        
    // internal function
    //--------------------------------------------------
        /** @private [internal] Get channel parameter */
        internal function _getSiOPMChannelParam(index:int) : SiOPMChannelParam
        {
            var v:SiMMLVoice = new SiMMLVoice();
            v.channelParam = new SiOPMChannelParam();
            fmVoices[index] = v;
            return v.channelParam;
        }
        
        
        /** @private [internal] Get CPM SiMMLVoice */
        _sion_internal function _getPCMVoice(index:int) : SiMMLVoice
        {
            index &= (SiOPMTable.PCM_DATA_MAX-1);
            if (pcmVoices[index] == null) {
                pcmVoices[index] = new SiMMLVoice();
                return pcmVoices[index]._sion_internal::_newBlankPCMVoice(index);
            }
            return pcmVoices[index];
        }
        
        
        /** @private [internal] register all tables. called from SiMMLTrack._prepareBuffer(). */
        internal function _registerAllTables() : void
        {
            /**/ // currently bank2,3 are not avairable
            SiOPMTable._instance.samplerTables[0].stencil = samplerTables[0];
            SiOPMTable._instance.samplerTables[1].stencil = samplerTables[1];
            SiOPMTable._instance._sion_internal::_stencilCustomWaveTables = waveTables;
            SiOPMTable._instance._sion_internal::_stencilPCMVoices        = pcmVoices;
            SiMMLTable._instance._stencilEnvelops = envelopes;
            SiMMLTable._instance._stencilVoices   = fmVoices;
        }
        
        
        
        
    // error
    //----------------------------------------
        private function errorNotGoodFMVoice() : Error {
            return new Error("SiONDriver error; Cannot register the voice.");
        }
    }
}

