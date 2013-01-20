//----------------------------------------------------------------------------------------------------
// tables for SiMML driver
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer {
    import org.si.utils.SLLint;
    import org.si.sion.module.SiOPMTable;
    import org.si.sion.module.SiOPMChannelParam;
    import org.si.sion.module.channels.SiOPMChannelManager;
    import org.si.sion.namespaces._sion_internal;
    
    
    /** table for sequencer */
    public class SiMMLTable
    {
    // constants
    //--------------------------------------------------
        // module types (0-9)
        static public const MT_PSG   :int = 0;  // PSG
        static public const MT_APU   :int = 1;  // FC pAPU
        static public const MT_NOISE :int = 2;  // noise wave
        static public const MT_MA3   :int = 3;  // MA3 wave form
        static public const MT_CUSTOM:int = 4;  // SCC / custom wave table
        static public const MT_ALL   :int = 5;  // all pgTypes
        static public const MT_FM    :int = 6;  // FM sound module
        static public const MT_PCM   :int = 7;  // PCM
        static public const MT_PULSE :int = 8;  // pulse wave
        static public const MT_RAMP  :int = 9;  // ramp wave
        static public const MT_SAMPLE:int = 10; // sampler
        static public const MT_KS    :int = 11; // karplus strong
        static public const MT_MAX   :int = 13;
        
        static private const MT_ARRAY_SIZE:int = 11;
        
        static public const ENV_TABLE_MAX:int = 512;
        static public const VOICE_MAX:int = 256;
        
        
        
    // valiables
    //--------------------------------------------------
        /** module setting table */
        public var channelModuleSetting:Array = null;
        /** module setting table */
        public var effectModuleSetting:Array = null;
       
        
        /** table from tsscp @s commnd to OPM ar */
        public var tss_s2ar:Vector.<String> = null;
        /** table from tsscp @s commnd to OPM dr */
        public var tss_s2dr:Vector.<String> = null;
        /** table from tsscp @s commnd to OPM sr */
        public var tss_s2sr:Vector.<String> = null;
        /** table from tsscp s commnd to OPM rr */
        public var tss_s2rr:Vector.<String> = null;
        
        
        /** algorism table for OPM/OPN. */
        public var alg_opm:Array = [[ 0, 0, 0, 0, 0, 0, 0, 0,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1, 1, 1, 1, 0, 1, 1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1, 2, 3, 3, 4, 3, 5,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1, 2, 3, 4, 5, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1]];
        /** algorism table for OPL3 */
        public var alg_opl:Array = [[ 0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 3, 2, 2,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 4, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]];
        /** algorism table for MA3 */
        public var alg_ma3:Array = [[ 0, 0, 0, 0, 0, 0, 0, 0,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0, 1, 1, 1, 0, 1, 1, 1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [-1,-1, 5, 2, 0, 3, 2, 2,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [-1,-1, 7, 2, 0, 4, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1]];
        /** algorism table for OPX. LSB4 is the flag of feedback connection. */
        public var alg_opx:Array = [[ 0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0,16, 1, 2,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0,16, 1, 2, 3,19, 5, 6,-1,-1,-1,-1,-1,-1,-1,-1],
                                    [ 0,16, 1, 2, 3,19, 4,20, 8,11, 6,22, 5, 9,12, 7]];
        /** initial connection */
        public var alg_init:Array = [0,1,5,7];

        // Master envelop tables list
        private var _masterEnvelops:Vector.<SiMMLEnvelopTable> = null;
        // Master voices list
        private var _masterVoices:Vector.<SiMMLVoice> = null;
        /** @private [internal] Stencil envelop tables list */
        internal var _stencilEnvelops:Vector.<SiMMLEnvelopTable> = null;
        /** @private [internal] Stencil voices list */
        internal var _stencilVoices:Vector.<SiMMLVoice> = null;
        
        
        
        
    // static public instance
    //--------------------------------------------------
        /** internal instance, you can access this after creating SiONDriver. */
        static public var _instance:SiMMLTable = null;
        
        
        /** singleton instance */
        static public function get instance() : SiMMLTable
        {
            return _instance || (_instance = new SiMMLTable());
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function SiMMLTable()
        {
            var i:int;
            
            // Channel module setting
            var ms:SiMMLChannelSetting;
            channelModuleSetting = new Array(MT_ARRAY_SIZE);
            channelModuleSetting[MT_PSG]    = new SiMMLChannelSetting(MT_PSG,    SiOPMTable.PG_SQUARE,      3,   1, 4);   // PSG
            channelModuleSetting[MT_APU]    = new SiMMLChannelSetting(MT_APU,    SiOPMTable.PG_PULSE,       12,  2, 5);   // FC pAPU
            channelModuleSetting[MT_NOISE]  = new SiMMLChannelSetting(MT_NOISE,  SiOPMTable.PG_NOISE_WHITE, 16,  1, 16);  // noise
            channelModuleSetting[MT_MA3]    = new SiMMLChannelSetting(MT_MA3,    SiOPMTable.PG_MA3_WAVE,    32,  1, 32);  // MA3
            channelModuleSetting[MT_CUSTOM] = new SiMMLChannelSetting(MT_CUSTOM, SiOPMTable.PG_CUSTOM,      256, 1, 256); // SCC / custom wave table
            channelModuleSetting[MT_ALL]    = new SiMMLChannelSetting(MT_ALL,    SiOPMTable.PG_SINE,        512, 1, 512); // all pgTypes
            channelModuleSetting[MT_FM]     = new SiMMLChannelSetting(MT_FM,     SiOPMTable.PG_SINE,        1,   1, 1);   // FM sound module
            channelModuleSetting[MT_PCM]    = new SiMMLChannelSetting(MT_PCM,    SiOPMTable.PG_PCM,         128, 1, 128); // PCM
            channelModuleSetting[MT_PULSE]  = new SiMMLChannelSetting(MT_PULSE,  SiOPMTable.PG_PULSE,       32,  1, 32);  // pulse
            channelModuleSetting[MT_RAMP]   = new SiMMLChannelSetting(MT_RAMP,   SiOPMTable.PG_RAMP,        128, 1, 128); // ramp
            channelModuleSetting[MT_SAMPLE] = new SiMMLChannelSetting(MT_SAMPLE, 0,                         4,   1, 4);   // sampler. this is based on SiOPMChannelSampler
            channelModuleSetting[MT_KS]     = new SiMMLChannelSetting(MT_KS,     0,                         3,   1, 3);   // karplus strong (0-2 to choose seed generator algrism)
            
            // PSG setting
            ms = channelModuleSetting[MT_PSG];
            ms._pgTypeList[0] = SiOPMTable.PG_SQUARE;
            ms._pgTypeList[1] = SiOPMTable.PG_NOISE_PULSE;
            ms._pgTypeList[2] = SiOPMTable.PG_PC_NZ_16BIT;
            ms._ptTypeList[0] = SiOPMTable.PT_PSG;
            ms._ptTypeList[1] = SiOPMTable.PT_PSG_NOISE;
            ms._ptTypeList[2] = SiOPMTable.PT_PSG;
            ms._voiceIndexTable[0] = 0;
            ms._voiceIndexTable[1] = 0;
            ms._voiceIndexTable[2] = 0;
            ms._voiceIndexTable[3] = 1;
            // APU setting
            ms = channelModuleSetting[MT_APU];
            ms._pgTypeList[8]  = SiOPMTable.PG_TRIANGLE_FC;
            ms._pgTypeList[9]  = SiOPMTable.PG_NOISE_PULSE;
            ms._pgTypeList[10] = SiOPMTable.PG_NOISE_SHORT;
            ms._pgTypeList[11] = SiOPMTable.PG_CUSTOM;
            for (i=0; i<9;  i++) { ms._ptTypeList[i] = SiOPMTable.PT_PSG; }
            for (i=9; i<12; i++) { ms._ptTypeList[i] = SiOPMTable.PT_APU_NOISE; }
            ms._initIndex      = 1;
            ms._voiceIndexTable[0] = 4;
            ms._voiceIndexTable[1] = 4;
            ms._voiceIndexTable[2] = 8;
            ms._voiceIndexTable[3] = 9;
            ms._voiceIndexTable[4] = 11;
            // FM setting
            channelModuleSetting[MT_FM]._selectToneType = SiMMLChannelSetting.SELECT_TONE_FM;
            channelModuleSetting[MT_FM]._isSuitableForFMVoice = false;
            // PCM setting
            channelModuleSetting[MT_PCM]._channelType = SiOPMChannelManager.CT_CHANNEL_PCM;
            channelModuleSetting[MT_PCM]._isSuitableForFMVoice = false;
            // Sampler
            //channelModuleSetting[MT_SAMPLE]._selectToneType = SiMMLChannelSetting.SELECT_TONE_NOP;
            channelModuleSetting[MT_SAMPLE]._channelType = SiOPMChannelManager.CT_CHANNEL_SAMPLER;
            channelModuleSetting[MT_SAMPLE]._isSuitableForFMVoice = false;
            // Karplus strong
            channelModuleSetting[MT_KS]._channelType = SiOPMChannelManager.CT_CHANNEL_KS;
            channelModuleSetting[MT_KS]._isSuitableForFMVoice = false;

            // tables
            _masterEnvelops = new Vector.<SiMMLEnvelopTable>(ENV_TABLE_MAX);
            for (i=0; i<ENV_TABLE_MAX; i++) _masterEnvelops[i] = null;
            _masterVoices = new Vector.<SiMMLVoice>(VOICE_MAX);
            for (i=0; i<VOICE_MAX; i++) _masterVoices[i] = null;
            
            // These tables are just depended on my ear ... ('A`)
            tss_s2ar = _logTable(41, -4, 63, 9);
            tss_s2dr = _logTable(52, -4,  0, 20);
            tss_s2sr = _logTable( 9,  5,  0, 63);
            tss_s2rr = _logTable(12,  4, 63, 63);
            //trace(tss_s2ar); trace(tss_s2dr); trace(tss_s2sr); trace(tss_s2rr);
            
            function _logTable(start:int, step:int, v0:int, v255:int) : Vector.<String> {
                var vector:Vector.<String> = new Vector.<String>(256, true);
                var imax:int, j:int, t:int, dt:int;

                t  = start<<16;
                dt = step<<16;
                for (i=1, j=1; j<=8; j++) {
                    for (imax=1<<j; i<imax; i++) {
                        vector[i] = String(t>>16);
                        t += dt;
                    }
                    dt >>= 1;
                }
                vector[0]   = String(v0);
                vector[255] = String(v255);
                
                return vector;
            }
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** @private [internal use] reset all user tables */
        _sion_internal function resetAllUserTables() : void
        {
            var i:int;
            for (i=0; i<ENV_TABLE_MAX; i++) {
                if (_masterEnvelops[i]) {
                    _masterEnvelops[i].free();
                    _masterEnvelops[i] = null;
                }
            }
            for (i=0; i<VOICE_MAX; i++) {
                _masterVoices[i] = null;
            }
        }
        
        
        /** Register envelop table.
         *  @param index table number refered by &#64;&#64;,na,np,nt,nf,_&#64;&#64;,_na,_np,_nt and _nf.
         *  @param table envelop table.
         */
        static public function registerMasterEnvelopTable(index:int, table:SiMMLEnvelopTable) : void
        {
            if (index>=0 && index<ENV_TABLE_MAX) instance._masterEnvelops[index] = table;
        }
        
        
        /** Register voice data.
         *  @param index voice parameter number refered by %6.
         *  @param voice voice.
         */
        static public function registerMasterVoice(index:int, voice:SiMMLVoice) : void
        {
            if (index>=0 && index<VOICE_MAX) instance._masterVoices[index] = voice;
        }
        
        
        /** Get Envelop table.
         *  @param index table number.
         */
        public function getEnvelopTable(index:int) : SiMMLEnvelopTable
        {
            if (index<0 || index>=ENV_TABLE_MAX) return null;
            if (_stencilEnvelops && _stencilEnvelops[index]) return _stencilEnvelops[index];
            return _masterEnvelops[index];
        }
        
        
        /** Get voice data.
         *  @param index voice parameter number.
         */
        public function getSiMMLVoice(index:int) : SiMMLVoice
        {
            if (index<0 || index>=VOICE_MAX) return null;
            if (_stencilVoices && _stencilVoices[index]) return _stencilVoices[index];
            return _masterVoices[index];
        }
        
        
        /** get 0th operators pgType number from moduleType, channelNum and toneNum. 
         *  @param moduleType Channel module type
         *  @param channelNum Channel number. For %2-11, this value is same as 1st argument of '_&#64;'.
         *  @param toneNum Tone number. Ussualy, this argument is used only in %0;PSG and %1;APU.
         *  @return pgType value, or -1 when moduleType == 6(FM) or 7(PCM).
         */
        static public function getPGType(moduleType:int, channelNum:int, toneNum:int=-1) : int
        {
            var ms:SiMMLChannelSetting = instance.channelModuleSetting[moduleType];
            
            if (ms._selectToneType == SiMMLChannelSetting.SELECT_TONE_NORMAL) {
                if (toneNum == -1) {
                    if (channelNum>=0 && channelNum<ms._voiceIndexTable.length) toneNum = ms._voiceIndexTable[channelNum];
                    else channelNum = ms._initIndex;
                }
                if (toneNum <0 || toneNum >=ms._pgTypeList.length) toneNum = ms._initIndex;
                return ms._pgTypeList[toneNum];
            }
            
            return -1;
        }
        
        
        /** get 0th operators pgType number from moduleType, channelNum and toneNum. 
         *  @param moduleType Channel module type
         *  @param channelNum Channel number. For %2-11, this value is same as 1st argument of '_&#64;'.
         *  @param toneNum Tone number. Ussualy, this argument is used only in %0;PSG and %1;APU.
         *  @return pgType value, or -1 when moduleType == 6(FM) or 7(PCM).
         */
        static public function isSuitableForFMVoice(moduleType:int) : Boolean
        {
            return instance.channelModuleSetting[moduleType]._isSuitableForFMVoice;
        }
    }
}

