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
    import org.si.sion.sequencer.simulator.*;
    
    
    /** table for sequencer */
    public class SiMMLTable
    {
    // constants
    //--------------------------------------------------
        // module types (0-11)
        static public const MT_PSG   :int = SiMMLSimulatorBase.MT_PSG;      // PSG(DCSG)
        static public const MT_APU   :int = SiMMLSimulatorBase.MT_APU;      // FC pAPU
        static public const MT_NOISE :int = SiMMLSimulatorBase.MT_NOISE;    // noise wave
        static public const MT_MA3   :int = SiMMLSimulatorBase.MT_MA3;      // MA3 wave form
        static public const MT_CUSTOM:int = SiMMLSimulatorBase.MT_CUSTOM;   // SCC / custom wave table
        static public const MT_ALL   :int = SiMMLSimulatorBase.MT_ALL;      // all pgTypes
        static public const MT_FM    :int = SiMMLSimulatorBase.MT_FM;       // FM sound module
        static public const MT_PCM   :int = SiMMLSimulatorBase.MT_PCM;      // PCM
        static public const MT_PULSE :int = SiMMLSimulatorBase.MT_PULSE;    // pulse wave
        static public const MT_RAMP  :int = SiMMLSimulatorBase.MT_RAMP;     // ramp wave
        static public const MT_SAMPLE:int = SiMMLSimulatorBase.MT_SAMPLE;   // sampler
        static public const MT_KS    :int = SiMMLSimulatorBase.MT_KS;       // karplus strong
        static public const MT_GB    :int = SiMMLSimulatorBase.MT_GB;       // gameboy
        static public const MT_VRC6  :int = SiMMLSimulatorBase.MT_VRC6;     // vrc6
        static public const MT_SID   :int = SiMMLSimulatorBase.MT_SID;      // sid
        static public const MT_MAX   :int = SiMMLSimulatorBase.MT_MAX;
        
        
        // module restriction type
        /** no restrictions (standard SiON module) */
        static public const NO_RESTRICTION:int = 0;
        /** module restriction as PSG (AY-3-8910) : PSG3 */
        static public const RESTRICT_PSG  :int = 1;
        /** module restriction as SSG (YM2203) : PSG3 */
        static public const RESTRICT_SSG  :int = 2;
        /** module restriction as DCSG (SN76489) : PSG3,NZG1 */
        static public const RESTRICT_DCSG :int = 3;
        
        /** module restriction as RP2A03 pAPU (NES) : APU2,TRI1,NZG1 */
        static public const RESTRICT_APU  :int = 4;
        /** module restriction as RP2C33 (Disc System) : WM(64,4)x1 */
        static public const RESTRICT_FDS  :int = 5;
        /** module restriction as N106 (NAMCO 106) : WM(32,4)x8 */
        static public const RESTRICT_N106 :int = 6;
        /** module restriction as MMC5 : APU2 */
        static public const RESTRICT_MMC5 :int = 7;
        /** module restriction as FME7 (Sunsoft 5B) : PSG3 */
        static public const RESTRICT_FME7 :int = 8;
        /** module restriction as VRC6 (KONAMI) : VRC2,SAW1 */
        static public const RESTRICT_VRC6 :int = 9;
        /** module restriction as VRC7 (KONAMI) : FM2x6 */
        static public const RESTRICT_VRC7 :int = 10;
        
        /** module restriction as Game boy : APU2,WM(32,4)x1,NZG1 */
        static public const RESTRICT_GB :int = 11;
        /** module restriction as KONAMI SCC : WM(32,8)x5 */
        static public const RESTRICT_SCC:int = 12;
        /** module restriction as NAMCO C30 : WM(32,4)x8 */
        static public const RESTRICT_WSG:int = 13;
        /** module restriction as Wonder Swan : WM(32,4)x4 */
        static public const RESTRICT_WS :int = 14;
        /** module restriction as PC Engine : WM(32,5)x6 */
        static public const RESTRICT_PCE:int = 15;
        /** module restriction as Commodole64 : SID*3 */
        static public const RESTRICT_SID:int = 16;
        
        /** module restriction as OPL (YM3526/similar with YM2413;OPLL) : FM2x9 */
        static public const RESTRICT_OPL :int = 17;
        /** module restriction as OPN (YM2203) : FM4x3,PSGx3 */
        static public const RESTRICT_OPN  :int = 18;
        /** module restriction as OPNA (YM2608) : FM4x6,PSGx3 */
        static public const RESTRICT_OPNA :int = 19;
        /** module restriction as OPM (YM2151) : FM4x8 */
        static public const RESTRICT_OPM  :int = 20;
        
        static private const RESTRICTION_MAX:int = 21;
        
        static public const ENV_TABLE_MAX:int = 512;
        static public const VOICE_MAX:int = 256;
        
        
        
    // valiables
    //--------------------------------------------------
        /** module setting table */
        public var channelModuleSetting:Array = null;
        /** module restriction table */
        public var channelModuleRestriction:Array = null;
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
        
        /** table of OPLL preset voices (from virturenes) */
        public var presetRegisterYM2413:Vector.<uint> = Vector.<uint>([
            0x00000000, 0x00000000, 0x61611e17, 0xf07f0717, 0x13410f0d, 0xced24313, 0x03019904, 0xffc30373,
            0x21611b07, 0xaf634028, 0x22211e06, 0xf0760828, 0x31221605, 0x90710018, 0x21611d07, 0x82811017,
            0x23212d16, 0xc0700707, 0x61211b06, 0x64651818, 0x61610c18, 0x85a07907, 0x23218711, 0xf0a400f7,
            0x97e12807, 0xfff302f8, 0x61100c05, 0xf2c440c8, 0x01015603, 0xb4b22358, 0x61418903, 0xf1f4f013
        ]);
        
        /** table of VRC7 preset voices (from virturenes) */
        public var presetRegisterVRC7:Vector.<uint> = Vector.<uint>([
            0x00000000, 0x00000000, 0x3301090e, 0x94904001, 0x13410f0d, 0xced34313, 0x01121b06, 0xffd20032,
            0x61611b07, 0xaf632028, 0x22211e06, 0xf0760828, 0x66211500, 0x939420f8, 0x21611c07, 0x82811017,
            0x2321201f, 0xc0710747, 0x25312605, 0x644118f8, 0x17212807, 0xff8302f8, 0x97812507, 0xcfc80214,
            0x2121540f, 0x807f0707, 0x01015603, 0xd3b24358, 0x31210c03, 0x82c04007, 0x21010c03, 0xd4d34084
        ]);

        /** table of VRC7/OPLL preset drums (from virturenes) */
        public var presetRegisterVRC7Drums:Vector.<uint> = Vector.<uint>([
            0x04212800, 0xdff8fff8, 0x23220000, 0xd8f8f8f8, 0x25180000, 0xf8daf855
        ]);
        
        /** Preset voice set of OPLL */
        public var presetVoiceYM2413:Vector.<SiMMLVoice> = null;
        /** Preset voice set of VRC7 */
        public var presetVoiceVRC7:Vector.<SiMMLVoice> = null;
        /** Preset voice set of VRC7/OPLL drum */
        public var presetVoiceVRC7Drums:Vector.<SiMMLVoice> = null;

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
            var i:int, j:int;
            
            // Channel module setting
            var ms:SiMMLChannelSetting;
            channelModuleSetting = new Array(MT_MAX);
            channelModuleSetting[MT_PSG]    = new SiMMLChannelSetting(MT_PSG,    SiOPMTable.PG_SQUARE,      3,   1, 4);   // PSG
            channelModuleSetting[MT_APU]    = new SiMMLChannelSetting(MT_APU,    SiOPMTable.PG_PULSE,       11,  2, 4);   // FC pAPU
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
            channelModuleSetting[MT_GB]     = new SiMMLChannelSetting(MT_GB,     SiOPMTable.PG_PULSE,       11,  2, 4);   // Gameboy
            channelModuleSetting[MT_VRC6]   = new SiMMLChannelSetting(MT_VRC6,   SiOPMTable.PG_PULSE,       8,   1, 9);   // VRC6
            channelModuleSetting[MT_SID]    = new SiMMLChannelSetting(MT_SID,    SiOPMTable.PG_PULSE,       8,   1, 9);   // SID
            
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
            for (i=0; i<9;  i++) { ms._ptTypeList[i] = SiOPMTable.PT_PSG; }
            for (i=9; i<11; i++) { ms._ptTypeList[i] = SiOPMTable.PT_APU_NOISE; }
            ms._initVoiceIndex = 1;
            ms._voiceIndexTable[0] = 4;
            ms._voiceIndexTable[1] = 4;
            ms._voiceIndexTable[2] = 8;
            ms._voiceIndexTable[3] = 9;
            // GB setting
            ms = channelModuleSetting[MT_GB];
            ms._pgTypeList[8]  = SiOPMTable.PG_CUSTOM;
            ms._pgTypeList[9]  = SiOPMTable.PG_NOISE_PULSE;
            ms._pgTypeList[10] = SiOPMTable.PG_NOISE_GB_SHORT;
            for (i=0; i<9;  i++) { ms._ptTypeList[i] = SiOPMTable.PT_PSG; }
            for (i=9; i<11; i++) { ms._ptTypeList[i] = SiOPMTable.PT_GB_NOISE; }
            ms._initVoiceIndex = 1;
            ms._voiceIndexTable[0] = 4;
            ms._voiceIndexTable[1] = 4;
            ms._voiceIndexTable[2] = 8;
            ms._voiceIndexTable[3] = 9;
            // VRC6 setting
            ms = channelModuleSetting[MT_VRC6];
            ms._pgTypeList[9] = SiOPMTable.PG_SAW_VC6;
            ms._ptTypeList[9] = SiOPMTable.PT_PSG;
            ms._initVoiceIndex = 1;
            ms._voiceIndexTable[0] = 7;
            ms._voiceIndexTable[1] = 7;
            ms._voiceIndexTable[2] = 8;
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

            
            // restriction setting
            channelModuleRestriction = new Array(RESTRICTION_MAX);
            channelModuleRestriction[NO_RESTRICTION] = new SiMMLChannelRestriction(NO_RESTRICTION, MT_ALL);
            channelModuleRestriction[RESTRICT_PSG]   = new SiMMLChannelRestriction(RESTRICT_PSG,   MT_PSG);
            channelModuleRestriction[RESTRICT_SSG]   = new SiMMLChannelRestriction(RESTRICT_SSG,   MT_PSG);
            channelModuleRestriction[RESTRICT_DCSG]  = new SiMMLChannelRestriction(RESTRICT_DCSG,  MT_PSG);
            channelModuleRestriction[RESTRICT_APU]   = new SiMMLChannelRestriction(RESTRICT_APU,   MT_APU);
            channelModuleRestriction[RESTRICT_FDS]   = new SiMMLChannelRestriction(RESTRICT_FDS,   MT_CUSTOM, 64, 4);
            channelModuleRestriction[RESTRICT_N106]  = new SiMMLChannelRestriction(RESTRICT_N106,  MT_CUSTOM, 32, 4);
            channelModuleRestriction[RESTRICT_MMC5]  = new SiMMLChannelRestriction(RESTRICT_MMC5,  MT_APU);
            channelModuleRestriction[RESTRICT_FME7]  = new SiMMLChannelRestriction(RESTRICT_FME7,  MT_PSG);
            channelModuleRestriction[RESTRICT_VRC6]  = new SiMMLChannelRestriction(RESTRICT_VRC6,  MT_VRC6);
            channelModuleRestriction[RESTRICT_VRC7]  = new SiMMLChannelRestriction(RESTRICT_VRC7,  MT_FM);
            channelModuleRestriction[RESTRICT_GB]    = new SiMMLChannelRestriction(RESTRICT_GB,    MT_GB, 32, 4);
            channelModuleRestriction[RESTRICT_SCC]   = new SiMMLChannelRestriction(RESTRICT_SCC,   MT_CUSTOM, 32, 8);
            channelModuleRestriction[RESTRICT_WSG]   = new SiMMLChannelRestriction(RESTRICT_WSG,   MT_CUSTOM, 32, 4);
            channelModuleRestriction[RESTRICT_WS ]   = new SiMMLChannelRestriction(RESTRICT_WS,    MT_CUSTOM, 32, 4);
            channelModuleRestriction[RESTRICT_PCE]   = new SiMMLChannelRestriction(RESTRICT_PCE,   MT_CUSTOM, 32, 5);
            channelModuleRestriction[RESTRICT_OPL]   = new SiMMLChannelRestriction(RESTRICT_OPL,   MT_FM);
            channelModuleRestriction[RESTRICT_OPN]   = new SiMMLChannelRestriction(RESTRICT_OPN,   MT_FM);
            channelModuleRestriction[RESTRICT_OPNA]  = new SiMMLChannelRestriction(RESTRICT_OPNA,  MT_FM);
            channelModuleRestriction[RESTRICT_OPM]   = new SiMMLChannelRestriction(RESTRICT_OPM,   MT_FM);

            // setup OPLL default voices            
            presetVoiceYM2413    = _setupYM2413DefaultVoices(presetRegisterYM2413);
            presetVoiceVRC7      = _setupYM2413DefaultVoices(presetRegisterVRC7);
            presetVoiceVRC7Drums = _setupYM2413DefaultVoices(presetRegisterVRC7Drums);
            
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
        
        private function _setupYM2413DefaultVoices(registerMap:Vector.<uint>) : Vector.<SiMMLVoice>
        {
            var voices:Vector.<SiMMLVoice> = new Vector.<SiMMLVoice>(registerMap.length >> 1), i:int, i2:int;
            for (i=i2=0; i<voices.length; i++,i2+=2) { voices[i] = _dumpYM2413Register(new SiMMLVoice(), registerMap[i2], registerMap[i2+1]); }
            return voices;
        }
        
        private function _dumpYM2413Register(voice:SiMMLVoice, u0:uint, u1:uint) : SiMMLVoice
        {
            var i:int;
            var param:SiOPMChannelParam = voice.channelParam;
            var opp0:SiOPMOperatorParam = param.operatorParam[0];
            var opp1:SiOPMOperatorParam = param.operatorParam[1];
            voice.setModuleType(6);
            voice.chipType = "OPL";
            param.fratio = 133;
            param.opeCount = 2;
            param.alg = 0;
            
            opp0.ams = ((u0>>31)&1)<<1;  //(dump[0]>>7)&1 ;
            opp1.ams = ((u0>>23)&1)<<1;  //(dump[1]>>7)&1 ;
            //opp0.PM = (u0>>30)&1;  //(dump[0]>>6)&1 ;
            //opp1.PM = (u0>>22)&1;  //(dump[1]>>6)&1 ;
            opp0.ksr = ((u0>>28)&1)<<1;  //(dump[0]>>4)&1 ;
            opp1.ksr = ((u0>>20)&1)<<1;  //(dump[1]>>4)&1 ;
            i = (u0>>24)&15; //(dump[0])&15 ;
            opp0.mul = (i==11 || i==13) ? (i-1) : (i==14) ? (i+1) : i;
            i = (u0>>16)&15; //(dump[1])&15 ;
            opp1.mul = (i==11 || i==13) ? (i-1) : (i==14) ? (i+1) : i;
            opp0.ksl = (u0>>14)&3;  //(dump[2]>>6)&3 ;
            opp1.ksl = (u0>> 6)&3;  //(dump[3]>>6)&3 ;
            param.fb = (u0>> 0)&7;   //(dump[3])&7 ;
            opp0.setPGType(SiOPMTable.PG_MA3_WAVE + ((u0>> 3)&1));  //(dump[3]>>3)&1 ;
            opp1.setPGType(SiOPMTable.PG_MA3_WAVE + ((u0>> 4)&1));  //(dump[3]>>4)&1 ;
            opp0.ar = ((u1>>28)&15)<<2; //(dump[4]>>4)&15 ;
            opp1.ar = ((u1>>20)&15)<<2; //(dump[5]>>4)&15 ;
            opp0.dr = ((u1>>24)&15)<<2; //(dump[4])&15 ;
            opp1.dr = ((u1>>16)&15)<<2; //(dump[5])&15 ;
            opp0.sl = (u1>>12)&15; //(dump[6]>>4)&15 ;
            opp1.sl = (u1>> 4)&15; //(dump[7]>>4)&15 ;
            opp0.rr = ((u1>> 8)&15)<<2; //(dump[6])&15 ;
            opp1.rr = ((u1>> 0)&15)<<2; //(dump[7])&15 ;
            opp0.sr  = (((u0>>29)&1) != 0) ? 0 : opp.rr;  //EG=(dump[0]>>5)&1 ;
            opp1.sr  = (((u0>>21)&1) != 0) ? 0 : opp.rr;  //EG=(dump[1]>>5)&1 ;
            opp0.tl = (u0>> 8)&63; //(dump[2])&63 ;
            opp1.tl = 0;
            
            return voice;
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
                if (toneNum == -1 && channelNum>=0 && channelNum<ms._voiceIndexTable.length) toneNum = ms._voiceIndexTable[channelNum];
                if (toneNum <0 || toneNum >=ms._pgTypeList.length) toneNum = ms._initVoiceIndex;
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

