//----------------------------------------------------------------------------------------------------
// Translators
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.utils {
    import org.si.sion.namespaces._sion_internal;
    import org.si.sion.SiONVoice;
    import org.si.sion.module.*;
    import org.si.sion.sequencer.*;
    import org.si.sion.effector.SiEffectModule;
    import org.si.sion.effector.SiEffectBase;
    import org.si.utils.SLLint;
    
    
    /** Translator */
    public class Translator
    {
        /** constructor, do nothing. */
        function Translator()
        {
        }
        
        
        
        
    // mckc
    //--------------------------------------------------
        /** Translate ppmckc mml to SiOPM mml.
         *  @param mckcMML ppmckc MML text.
         *  @return translated SiON MML text
         */
        static public function mckc(mckcMML:String) : String
        {
            // If I have motivation ..., or I wish someone who know mck well would do ...
            throw new Error("This is not implemented");
            return mckcMML;
        }
        
        
        
        
    // flmml
    //--------------------------------------------------
        /** Translate flMML's mml to SiOPM mml.
         *  @param flMML flMML's MML text.
         *  @return translated SiON MML text
         */
        static public function flmml(flMML:String) : String
        {
            // If I have motivation ..., or I wish someone who know mck well would do ...
            throw new Error("This is not implemented");
            return flMML;
        }
        
        
        
        
    // tsscp
    //--------------------------------------------------
        /** Translate pTSSCP mml to SiOPM mml. 
         *  @param tsscpMML TSSCP MML text.
         *  @param volumeByX true to translate volume control to SiON MMLs 'x' command, false to translate to SiON MMLs 'v' command.
         *  @return translated SiON MML text
         */
        static public function tsscp(tsscpMML:String, volumeByX:Boolean=true) : String
        {
            var mml:String, com:String, str1:String, str2:String, i:int, imax:int, volUp:String, volDw:String, rex:RegExp, rex_sys:RegExp, rex_com:RegExp, res:*;
            
        // translate mml
        //--------------------------------------------------
            var noteLetters:String = "cdefgab";
            var noteShift:Array  = [0,2,4,5,7,9,11];
            var panTable:Array = ["@v0","p0","p8","p4"];
            var table:SiMMLTable = SiMMLTable.instance;
            var charCodeA:int = "a".charCodeAt(0);
            var charCodeG:int = "g".charCodeAt(0);
            var charCodeR:int = "r".charCodeAt(0);
            var hex:String = "0123456789abcdef";
            var p0:int, p1:int, p2:int, p3:int, p4:int, reql8:Boolean, octave:int, revOct:Boolean, 
                loopOct:int, loopMacro:Boolean, loopMMLBefore:String, loopMMLContent:String;

            rex  = new RegExp("(;|(/:|:/|ml|mp|na|ns|nt|ph|@kr|@ks|@ml|@ns|@apn|@[fkimopqsv]?|[klopqrstvx$%<>(){}[\\]|_~^/&*]|[a-g][#+\\-]?)\\s*([\\-\\d]*)[,\\s]*([\\-\\d]+)?[,\\s]*([\\-\\d]+)?[,\\s]*([\\-\\d]+)?[,\\s]*([\\-\\d]+)?)|#(FM|[A-Z]+)=?\\s*([^;]*)|([A-Z])(\\(([a-g])([\\-+#]?)\\))?|.", "gms");
            rex_sys = /\s*([0-9]*)[,=<\s]*([^>]*)/ms;
            rex_com = /[{}]/gms;

            volUp = "(";
            volDw = ")";
            mml = "";
            reql8 = true;
            octave = 5;
            revOct = false;
            loopOct = -1;
            loopMacro = false;
            loopMMLBefore = undefined;
            loopMMLContent = undefined;
            res = rex.exec(tsscpMML);
            while (res) {
                if (res[1] != undefined) {
                    if (res[1] == ';') {
                        mml += res[0];
                        reql8 = true;
                    } else {
                        // mml commands
                        i = res[2].charCodeAt(0);
                        if ((charCodeA <= i && i <= charCodeG) || i == charCodeR) {
                            if (reql8) mml += "l8" + res[0];
                            else       mml += res[0];
                            reql8 = false;
                        } else {
                            switch (res[2]) {
                                case 'l':   { mml += res[0]; reql8 = false; }break;
                                case '/:':  { mml += "[" + res[3]; }break;
                                case ':/':  { mml += "]"; }break;
                                case '/':   { mml += "|"; }break;
                                case '~':   { mml += volUp + res[3]; }break;
                                case '_':   { mml += volDw + res[3]; }break;
                                case 'q':   { mml += "q" + String((int(res[3])+1)>>1); }break;
                                case '@m':  { mml += "@mask" + String(int(res[3])); }break;
                                case 'ml':  { mml += "@ml" + String(int(res[3])); }break;
                                case 'p':   { mml += panTable[int(res[3])&3]; }break;
                                case '@p':  { mml += "@p" + String(int(res[3])-64); }break;
                                case 'ph':  { mml += "@ph" + String(int(res[3])); }break;
                                case 'ns':  { mml += "kt"  + res[3]; }break;
                                case '@ns': { mml += "!@ns" + res[3]; }break;
                                case 'k':   { p0 = Number(res[3]) * 4;     mml += "k"  + String(p0); }break;
                                case '@k':  { p0 = Number(res[3]) * 0.768; mml += "k"  + String(p0); }break;
                                case '@kr': { p0 = Number(res[3]) * 0.768; mml += "!@kr" + String(p0); }break;
                                case '@ks': { mml += "@,,,,,,," + String(int(res[3]) >> 5); }break;
                                case 'na':  { mml += "!" + res[0]; }break;
                                case 'o':   { mml += res[0]; octave = int(res[3]); }break;
                                case '<':   { mml += res[0]; octave += (revOct) ? -1 :  1; }break;
                                case '>':   { mml += res[0]; octave += (revOct) ?  1 : -1; }break;
                                case '%':   { mml += (res[3] == '6') ? '%4' : res[0]; }break;
                                
                                case '@ml': { 
                                    p0 = int(res[3])>>7;
                                    p1 = int(res[3]) - (p0<<7);
                                    mml += "@ml" + String(p0) + "," + String(p1);
                                }break;
                                case 'mp': {
                                    p0 = int(res[3]); p1 = int(res[4]); p2 = int(res[5]); p3 = int(res[6]); p4 = int(res[7]);
                                    if (p3 == 0) p3 = 1;
                                    switch(p0) {
                                    case 0:  mml += "mp0"; break;
                                    case 1:  mml += "@lfo" + String((int(p1/p3)+1)*4*p2) + "mp" + String(p1);   break;
                                    default: mml += "@lfo" + String((int(p1/p3)+1)*4*p2) + "mp0," + String(p1) + "," + String(p0);   break;
                                    }
                                }break;
                                case 'v': {
                                    if (volumeByX) {
                                        p0 = (res[3].length == 0) ? 40 : ((int(res[3])<<2)+(int(res[3])>>2));
                                        if (res[4]) {
                                            p1 = (int(res[4])<<2) + (int(res[4])>>2);
                                            p2 = (p1 > 0) ? (int(Math.atan(p0/p1)*81.48733086305041)) : 128; // 81.48733086305041 = 128/(PI*0.5)
                                            p3 = (p0 > p1) ? p0 : p1;
                                            mml += "@p" + String(p2) + "x" + String(p3);
                                        } else {
                                            mml += "x" + String(p0);
                                        }
                                    } else {
                                        p0 = (res[3].length == 0) ? 10 : (res[3]);
                                        if (res[4]) {
                                            p1 = res[4];
                                            p2 = (p1 > 0) ? (int(Math.atan(p0/p1)*81.48733086305041)) : 128; // 81.48733086305041 = 128/(PI*0.5)
                                            p3 = (p0 > p1) ? p0 : p1;
                                            mml += "@p" + String(p2) + "v" + String(p3);
                                        } else {
                                            mml += "v" + String(p0);
                                        }
                                    }
                                }break;
                                case '@v': {
                                    if (volumeByX) {
                                        p0 = (res[3].length == 0) ? 40 : (int(res[3])>>2);
                                        if (res[4]) {
                                            p1 = int(res[4])>>2;
                                            p2 = (p1 > 0) ? (int(Math.atan(p0/p1)*81.48733086305041)) : 128; // 81.48733086305041 = 128/(PI*0.5)
                                            p3 = (p0 > p1) ? p0 : p1;
                                            mml += "@p" + String(p2) + "x" + String(p3);
                                        } else {
                                            mml += "x" + String(p0);
                                        }
                                    } else {
                                        p0 = (res[3].length == 0) ? 10 : (int(res[3])>>4);
                                        if (res[4]) {
                                            p1 = int(res[4])>>4;
                                            p2 = (p1 > 0) ? (int(Math.atan(p0/p1)*81.48733086305041)) : 128; // 81.48733086305041 = 128/(PI*0.5)
                                            p3 = (p0 > p1) ? p0 : p1;
                                            mml += "@p" + String(p2) + "v" + String(p3);
                                        } else {
                                            mml += "v" + String(p0);
                                        }
                                    }
                                }break;
                                case 's': {
                                    p0 = int(res[3]); p1 = int(res[4]);
                                    mml += "s" + table.tss_s2rr[p0&255];
                                    if (p1!=0) mml += ","  + String(p1*3);
                                }break;
                                case '@s': {
                                    p0 = int(res[3]); p1 = int(res[4]); p3 = int(res[6]);
                                    p2 = (int(res[5]) >= 100) ? 15 : int(Number(res[5])*0.09);
                                    mml += (p0 == 0) ? "@,63,0,0,,0" : (
                                        "@," + table.tss_s2ar[p0&255] + ","  + table.tss_s2dr[p1&255] + "," + table.tss_s2sr[p3&255] + ",," + String(p2)
                                    );
                                }break;
                                case '{': {
                                    i = 1;
                                    p0 = res.index + 1;
                                    rex_com.lastIndex = p0;
                                    do {
                                        res = rex_com.exec(tsscpMML);
                                            if (res == null) throw errorTranslation("{{...} ?");
                                        if (res[0] == '{') i++;
                                        else if (res[0] == '}') --i;
                                    } while (i);
                                    mml += "/*{" + tsscpMML.substring(p0, res.index) + "}*/";
                                    rex.lastIndex = res.index + 1;
                                }break;
                                    
                                case '[': { 
                                    if (loopMMLBefore) errorTranslation("[[...] ?");
                                    loopMacro = false;
                                    loopMMLBefore = mml;
                                    loopMMLContent = undefined;
                                    mml = res[3];
                                    loopOct = octave;
                                }break;
                                case '|': {
                                    if (!loopMMLBefore) errorTranslation("'|' can be only in '[...]'");
                                    loopMMLContent = mml; 
                                    mml = "";
                                }break;
                                case ']': {
                                    if (!loopMMLBefore) errorTranslation("[...]] ?");
                                    if (!loopMacro && loopOct==octave) {
                                        if (loopMMLContent)  mml = loopMMLBefore + "[" + loopMMLContent + "|" + mml + "]";
                                        else                 mml = loopMMLBefore + "[" + mml + "]";
                                    } else {
                                        if (loopMMLContent)  mml = loopMMLBefore + "![" + loopMMLContent + "!|" + mml + "!]";
                                        else                 mml = loopMMLBefore + "![" + mml + "!]";
                                    }
                                    loopMMLBefore = undefined;
                                    loopMMLContent = undefined;
                                }break;

                                case '}': 
                                    throw errorTranslation("{...}} ?");
                                case '@apn': case 'x':
                                    break;
                                
                                default: {
                                    mml += res[0];
                                }break;
                            }
                        }
                    }
                } else 
                
                if (res[10] != undefined) {
                    // macro expansion
                    if (reql8) mml += "l8" + res[10];
                    else       mml += res[10];
                    reql8 = false;
                    loopMacro = true;
                    if (res[11] != undefined) {
                        // note shift
                        i = noteShift[noteLetters.indexOf(res[12])];
                        if (res[13] == '+' || res[13] == '#') i++;
                        else if (res[13] == '-') i--;
                        mml += "(" + String(i) + ")";
                    }
                } else 
                
                if (res[8] != undefined) {
                    // system command
                    str1 = res[8];
                    switch (str1) {
                        case 'END':    { mml += "#END"; }break;
                        case 'OCTAVE': { 
                            if (res[9] == 'REVERSE') {
                                mml += "#REV{octave}"; 
                                revOct = true;
                            }
                        }break;
                        case 'OCTAVEREVERSE': { 
                            mml += "#REV{octave}"; 
                            revOct = true;
                        }break;
                        case 'VOLUME': {
                            if (res[9] == 'REVERSE') {
                                volUp = ")";
                                volDw = "(";
                                mml += "#REV{volume}";
                            }
                        }break;
                        case 'VOLUMEREVERSE': {
                            volUp = ")";
                            volDw = "(";
                            mml += "#REV{volume}";
                        }break;
                        
                        case 'TABLE': {
                            res = rex_sys.exec(res[9]);
                            mml += "#TABLE" + res[1] + "{" + res[2] + "}*0.25";
                        }break;
                        
                        case 'WAVB': {
                            res = rex_sys.exec(res[9]);
                            str1 = String(res[2]);
                            mml += "#WAVB" + res[1] + "{";
                            for (i=0; i<32; i++) {
                                p0 = int("0x" + str1.substr(i<<1, 2));
                                p0 = (p0<128) ? (p0+127) : (p0-128);
                                mml += hex.charAt(p0>>4) + hex.charAt(p0&15);
                            }
                            mml += "}";
                        }break;
                        
                        case 'FM': {
                            mml += "#FM{" + String(res[9]).replace(/([A-Z])([0-9])?(\()?/g, 
                                function() : String {
                                    var num:int = (arguments[2]) ? (int(arguments[2])) : 3;
                                    var str:String = (arguments[3]) ? (String(num) + "(") : "";
                                    return String(arguments[1]).toLowerCase() + str;
                                }
                            ) + "}" ;//))
                        }break;
                        
                        case 'FINENESS':
                        case 'MML':
                            // skip next ";"
                            res = rex.exec(tsscpMML);
                            break;
                        default: {
                            if (str1.length == 1) {
                                // macro
                                mml += "#" + str1 + "=";
                                rex.lastIndex -= res[9].length;
                                reql8 = false;
                            } else {
                                // other system events
                                res = rex_sys.exec(res[9]);
                                if (res[2].length == 0) return "#" + str1 + res[1];
                                mml += "#" + str1 + res[1] + "{" + res[2] + "}";
                            }
                        }break;
                    }
                } else 
                
                {
                    mml += res[0];
                }
                res = rex.exec(tsscpMML);
            }
            tsscpMML = mml;
            
            return tsscpMML;
        }
        
        
        
        
    // Effector
    //--------------------------------------------------
    // parse effector MML string
    //--------------------------------------------------
        /** Parse effector mml and return an array of SiEffectBase.
         *  @param mml Effector MML text.
         *  @param postfix postfix text.
         *  @return An array of SiEffectBase.
         */
        static public function parseEffectorMML(mml:String, postfix:String="") : Array
        {
            var ret:Array, res:*, rex:RegExp = /([a-zA-Z_]+|,)\s*([.\-\d]+)?/g, i:int,
                cmd:String = "", argc:int = 0, args:Vector.<Number> = new Vector.<Number>(16, true);
            
            // clear
            ret = [];
            _clearArgs();
            
            // parse mml
            res = rex.exec(mml);
            while (res) {
                if (res[1] == ",") {
                    args[argc++] = Number(res[2]);
                } else {
                    _connectEffect();
                    cmd = res[1];
                    _clearArgs();
                    args[0] = Number(res[2]);
                    argc = 1;
                }
                res = rex.exec(mml);
            }
            _connectEffect();
            
            return ret;
            
            // connect new effector
            function _connectEffect() : void {
                if (argc == 0) return;
                var e:SiEffectBase = SiEffectModule.getInstance(cmd);
                if (e) {
                    e.mmlCallback(args);
                    ret.push(e);
                }
            }
            
            // clear arguments
            function _clearArgs() : void {
                for (var i:int=0; i<16; i++) args[i]=Number.NaN;
            }
        }
        
        
        
        
    // FM parameters
    //--------------------------------------------------
    // parse MML string
    //--------------------------------------------------
        /** parse inside of #&#64;{..}; */
        static public function parseParam(param:SiOPMChannelParam, dataString:String) : SiOPMChannelParam {
            return _setParamByArray(param, _splitDataString(param, dataString, 3, 15, "#@"));
        }
        
        
        /** parse inside of #OPL&#64;{..}; */
        static public function parseOPLParam(param:SiOPMChannelParam, dataString:String) : SiOPMChannelParam {
            return _setOPLParamByArray(param, _splitDataString(param, dataString, 2, 11, "#OPL@"));
        }
        
        
        /** parse inside of #OPM&#64;{..}; */
        static public function parseOPMParam(param:SiOPMChannelParam, dataString:String) : SiOPMChannelParam {
            return _setOPMParamByArray(param, _splitDataString(param, dataString, 2, 11, "#OPM@"));
        }
        
        
        /** parse inside of #OPN&#64;{..}; */
        static public function parseOPNParam(param:SiOPMChannelParam, dataString:String) : SiOPMChannelParam {
            return _setOPNParamByArray(param, _splitDataString(param, dataString, 2, 10, "#OPN@"));
        }
        
        
        /** parse inside of #OPX&#64;{..}; */
        static public function parseOPXParam(param:SiOPMChannelParam, dataString:String) : SiOPMChannelParam {
            return _setOPXParamByArray(param, _splitDataString(param, dataString, 2, 12, "#OPX@"));
        }
        
        
        /** parse inside of #MA&#64;{..}; */
        static public function parseMA3Param(param:SiOPMChannelParam, dataString:String) : SiOPMChannelParam {
            return _setMA3ParamByArray(param, _splitDataString(param, dataString, 2, 12, "#MA@"));
        }
        
        /** parse inside of #AL&#64;{..}; */
        static public function parseALParam(param:SiOPMChannelParam, dataString:String) : SiOPMChannelParam {
            return _setALParamByArray(param, _splitDataString(param, dataString, 9, 0, "#AL@"));
        }
        
        
        
        
    // set by Array
    //--------------------------------------------------
        /** set inside of #&#64;{..}; */
        static public function setParam(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam {
            return _setParamByArray(_checkOpeCount(param, data.length, 3, 15, "#@"), data);
        }
        
        
        /** set inside of #OPL&#64;{..}; */
        static public function setOPLParam(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam {
            return _setOPLParamByArray(_checkOpeCount(param, data.length, 2, 11, "#OPL@"), data);
        }
        
        
        /** set inside of #OPM&#64;{..}; */
        static public function setOPMParam(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam {
            return _setOPMParamByArray(_checkOpeCount(param, data.length, 2, 11, "#OPM@"), data);
        }
        
        
        /** set inside of #OPN&#64;{..}; */
        static public function setOPNParam(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam {
            return _setOPNParamByArray(_checkOpeCount(param, data.length, 2, 10, "#OPN@"), data);
        }
        
        
        /** set inside of #OPX&#64;{..}; */
        static public function setOPXParam(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam {
            return _setOPXParamByArray(_checkOpeCount(param, data.length, 2, 12, "#OPX@"), data);
        }
        
        
        /** set inside of #MA&#64;{..}; */
        static public function setMA3Param(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam {
            return _setMA3ParamByArray(_checkOpeCount(param, data.length, 2, 12, "#MA@"), data);
        }
        
        /** set inside of #AL&#64;{..}; */
        static public function setALParam(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam {
            if (data.length != 9) throw errorToneParameterNotValid("#AL@", 9, 0);
            return _setALParamByArray(param, data);
        }
        
        
        
        
        
        
    // internal functions
    //--------------------------------------------------
        // split dataString of #@ macro
        static private function _splitDataString(param:SiOPMChannelParam, dataString:String, chParamCount:int, opParamCount:int, cmd:String) : Array
        {
            var data:Array, i:int;
            
            // parse parameters
            if (dataString == "") {
                param.opeCount = 0;
            } else {
                var comrex:RegExp = new RegExp("/\\*.*?\\*/|//.*?[\\r\\n]+", "gms");
                data = dataString.replace(comrex, "").replace(/^[^\d\-.]+|[^\d\-.]+$/g, "").split(/[^\d\-.]+/gm);
                for (i=1; i<5; i++) {
                    if (data.length == chParamCount + opParamCount*i) {
                        param.opeCount = i;
                        return data;
                    }
                }
                throw errorToneParameterNotValid(cmd, chParamCount, opParamCount);
            }
            return null;
        }
        
        
        // check param.opeCount
        static private function _checkOpeCount(param:SiOPMChannelParam, dataLength:int, chParamCount:int, opParamCount:int, cmd:String) : SiOPMChannelParam
        {
            var opeCount:int = (dataLength - chParamCount) / opParamCount;
            if (opeCount > 4 || opeCount*opParamCount+chParamCount != dataLength) throw errorToneParameterNotValid(cmd, chParamCount, opParamCount);
            param.opeCount = opeCount;
            return param;
        }
        
        
        // #@
        // alg[0-15], fb[0-7], fbc[0-3], 
        // (ws[0-511], ar[0-63], dr[0-63], sr[0-63], rr[0-63], sl[0-15], tl[0-127], ksr[0-3], ksl[0-3], mul[], dt1[0-7], detune[], ams[0-3], phase[-1-255], fixedNote[0-127]) x operator_count
        static private function _setParamByArray(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam
        {
            if (param.opeCount == 0) return param;
            
            param.alg = int(data[0]);
            param.fb  = int(data[1]);
            param.fbc = int(data[2]);
            var dataIndex:int = 3, n:Number, i:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                opp.setPGType(int(data[dataIndex++]) & 511); // 1
                opp.ar     = int(data[dataIndex++]) & 63;   // 2
                opp.dr     = int(data[dataIndex++]) & 63;   // 3
                opp.sr     = int(data[dataIndex++]) & 63;   // 4
                opp.rr     = int(data[dataIndex++]) & 63;   // 5
                opp.sl     = int(data[dataIndex++]) & 15;   // 6
                opp.tl     = int(data[dataIndex++]) & 127;  // 7
                opp.ksr    = int(data[dataIndex++]) & 3;    // 8
                opp.ksl    = int(data[dataIndex++]) & 3;    // 9
                n = Number(data[dataIndex++]);
                opp.fmul   = (n==0) ? 64 : int(n*128);      // 10
                opp.dt1    = int(data[dataIndex++]) & 7;    // 11
                opp.detune = int(data[dataIndex++]);        // 12
                opp.ams    = int(data[dataIndex++]) & 3;    // 13
                i = int(data[dataIndex++]);
                opp.phase  = (i==-1) ? i : (i & 255);           // 14
                opp.fixedPitch = (int(data[dataIndex++]) & 127)<<6;  // 15
            }
            return param;
        }
        
        
        // #OPL@
        // alg[0-5], fb[0-7], 
        // (ws[0-7], ar[0-15], dr[0-15], rr[0-15], egt[0,1], sl[0-15], tl[0-63], ksr[0,1], ksl[0-3], mul[0-15], ams[0-3]) x operator_count
        static private function _setOPLParamByArray(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam
        {
            if (param.opeCount == 0) return param;
            
            var alg:int = SiMMLTable.instance.alg_opl[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#OPL@ algorism", data[0]);
            
            param.fratio = 133;
            param.alg = alg;
            param.fb  = int(data[1]);
            var dataIndex:int = 2, i:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                opp.setPGType(SiOPMTable.PG_MA3_WAVE + (int(data[dataIndex++])&31));    // 1
                opp.ar  = (int(data[dataIndex++]) << 2) & 63;   // 2
                opp.dr  = (int(data[dataIndex++]) << 2) & 63;   // 3
                opp.rr  = (int(data[dataIndex++]) << 2) & 63;   // 4
                // egt=0;decay tone / egt=1;holding tone           5
                opp.sr  = (int(data[dataIndex++]) != 0) ? 0 : opp.rr;
                opp.sl  = int(data[dataIndex++]) & 15;          // 6
                opp.tl  = int(data[dataIndex++]) & 63;          // 7
                opp.ksr = (int(data[dataIndex++])<<1) & 3;      // 8
                opp.ksl = int(data[dataIndex++]) & 3;           // 9
                i = int(data[dataIndex++]) & 15;                // 10
                opp.mul = (i==11 || i==13) ? (i-1) : (i==14) ? (i+1) : i;
                opp.ams = int(data[dataIndex++]) & 3;           // 11
                // multiple
            }
            return param;
        }
        
        
        // #OPM@
        // alg[0-7], fb[0-7], 
        // (ar[0-31], dr[0-31], sr[0-31], rr[0-15], sl[0-15], tl[0-127], ks[0-3], mul[0-15], dt1[0-7], dt2[0-3], ams[0-3]) x operator_count
        static private function _setOPMParamByArray(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam
        {
            if (param.opeCount == 0) return param;
            
            var alg:int = SiMMLTable.instance.alg_opm[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#OPN@ algorism", data[0]);

            param.alg = alg;
            param.fb  = int(data[1]);
            var dataIndex:int = 2;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                opp.ar  = (int(data[dataIndex++]) << 1) & 63;       // 1
                opp.dr  = (int(data[dataIndex++]) << 1) & 63;       // 2
                opp.sr  = (int(data[dataIndex++]) << 1) & 63;       // 3
                opp.rr  = ((int(data[dataIndex++]) << 2) + 2) & 63; // 4
                opp.sl  = int(data[dataIndex++]) & 15;              // 5
                opp.tl  = int(data[dataIndex++]) & 127;             // 6
                opp.ksr = int(data[dataIndex++]) & 3;               // 7
                opp.mul = int(data[dataIndex++]) & 15;              // 8
                opp.dt1 = int(data[dataIndex++]) & 7;               // 9
                opp.detune = SiOPMTable.instance.dt2Table[data[dataIndex++] & 3];    // 10
                opp.ams = int(data[dataIndex++]) & 3;               // 11
            }
            return param;
        }
        
        
        // #OPN@
        // alg[0-7], fb[0-7], 
        // (ar[0-31], dr[0-31], sr[0-31], rr[0-15], sl[0-15], tl[0-127], ks[0-3], mul[0-15], dt1[0-7], ams[0-3]) x operator_count
        static private function _setOPNParamByArray(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam
        {
            if (param.opeCount == 0) return param;
            
            var alg:int = SiMMLTable.instance.alg_opm[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#OPN@ algorism", data[0]);

            param.alg = alg;
            param.fb  = int(data[1]);
            var dataIndex:int = 2;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                opp.ar  = (int(data[dataIndex++]) << 1) & 63;       // 1
                opp.dr  = (int(data[dataIndex++]) << 1) & 63;       // 2
                opp.sr  = (int(data[dataIndex++]) << 1) & 63;       // 3
                opp.rr  = ((int(data[dataIndex++]) << 2) + 2) & 63; // 4
                opp.sl  = int(data[dataIndex++]) & 15;              // 5
                opp.tl  = int(data[dataIndex++]) & 127;             // 6
                opp.ksr = int(data[dataIndex++]) & 3;               // 7
                opp.mul = int(data[dataIndex++]) & 15;              // 8
                opp.dt1 = int(data[dataIndex++]) & 7;               // 9
                opp.ams = int(data[dataIndex++]) & 3;               // 10
            }
            return param;
        }
        
        
        // #OPX@
        // alg[0-15], fb[0-7], 
        // (ws[0-7], ar[0-31], dr[0-31], sr[0-31], rr[0-15], sl[0-15], tl[0-127], ks[0-3], mul[0-15], dt1[0-7], detune[], ams[0-3]) x operator_count
        static private function _setOPXParamByArray(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam
        {
            if (param.opeCount == 0) return param;
            
            var alg:int = SiMMLTable.instance.alg_opx[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#OPX@ algorism", data[0]);
            
            param.alg = (alg & 15);
            param.fb  = int(data[1]);
            param.fbc = (alg & 16) ? 1 : 0;
            var dataIndex:int = 2, i:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                i = int(data[dataIndex++]);
                opp.setPGType((i<7) ? (SiOPMTable.PG_MA3_WAVE+(i&7)) : (SiOPMTable.PG_CUSTOM+(i-7)));    // 1
                opp.ar  = (int(data[dataIndex++]) << 1) & 63;       // 2
                opp.dr  = (int(data[dataIndex++]) << 1) & 63;       // 3
                opp.sr  = (int(data[dataIndex++]) << 1) & 63;       // 4
                opp.rr  = ((int(data[dataIndex++]) << 2) + 2) & 63; // 5
                opp.sl  = int(data[dataIndex++]) & 15;              // 6
                opp.tl  = int(data[dataIndex++]) & 127;             // 7
                opp.ksr = int(data[dataIndex++]) & 3;               // 8
                opp.mul = int(data[dataIndex++]) & 15;              // 9
                opp.dt1 = int(data[dataIndex++]) & 7;               // 10
                opp.detune = int(data[dataIndex++]);                // 11
                opp.ams = int(data[dataIndex++]) & 3;               // 12
            }
            return param;
        }
        
        
        // #MA@
        // alg[0-15], fb[0-7], 
        // (ws[0-31], ar[0-15], dr[0-15], sr[0-15], rr[0-15], sl[0-15], tl[0-63], ksr[0,1], ksl[0-3], mul[0-15], dt1[0-7], ams[0-3]) x operator_count
        static private function _setMA3ParamByArray(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam
        {
            if (param.opeCount == 0) return param;
            
            var alg:int = SiMMLTable.instance.alg_ma3[param.opeCount-1][int(data[0])&15];
            if (alg == -1) throw errorParameterNotValid("#MA@ algorism", data[0]);
            
            param.fratio = 133;
            param.alg = alg;
            param.fb  = int(data[1]);
            var dataIndex:int = 2, i:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                opp.setPGType(SiOPMTable.PG_MA3_WAVE + (int(data[dataIndex++]) & 31)); // 1
                opp.ar  = (int(data[dataIndex++]) << 2) & 63;   // 2
                opp.dr  = (int(data[dataIndex++]) << 2) & 63;   // 3
                opp.sr  = (int(data[dataIndex++]) << 2) & 63;   // 4
                opp.rr  = (int(data[dataIndex++]) << 2) & 63;   // 5
                opp.sl  = int(data[dataIndex++]) & 15;          // 6
                opp.tl  = int(data[dataIndex++]) & 63;          // 7
                opp.ksr = (int(data[dataIndex++])<<1) & 3;      // 8
                opp.ksl = int(data[dataIndex++]) & 3;           // 9
                i = int(data[dataIndex++]) & 15;                // 10
                opp.mul = (i==11 || i==13) ? (i-1) : (i==14) ? (i+1) : i;
                opp.dt1 = int(data[dataIndex++]) & 7;           // 11
                opp.ams = int(data[dataIndex++]) & 3;           // 12
            }
            return param;
        }
        

        // #AL@
        // con[0-2], ws1[0-511], ws2[0-511], balance[-64-+64], vco2pitch[]
        // ar[0-63], dr[0-63], sl[0-15], rr[0-63]
        static private function _setALParamByArray(param:SiOPMChannelParam, data:Array) : SiOPMChannelParam
        {
            var opp0:SiOPMOperatorParam = param.operatorParam[0],
                opp1:SiOPMOperatorParam = param.operatorParam[1],
                tltable:Vector.<int> = SiOPMTable.instance.eg_lv2tlTable,
                connectionType:int = int(data[0]), 
                balance:int = int(data[3]);
            param.opeCount = 5;
            param.alg = (connectionType>=0 && connectionType<=2) ? connectionType : 0;
            opp0.setPGType(int(data[1]));
            opp1.setPGType(int(data[2]));
            if (balance > 64) balance = 64;
            else if (balance < -64) balance = -64;
            opp0.tl = tltable[64-balance];
            opp1.tl = tltable[balance+64];
            opp0.detune = 0;
            opp1.detune = data[4];
            
            opp0.ar = (int(data[5])) & 63;
            opp0.dr = (int(data[6])) & 63;
            opp0.sr = 0;
            opp0.rr = (int(data[8])) & 15;
            opp0.sl = (int(data[7])) & 63;
            
            return param;
        }
        
        
        
        
    // get by Array
    //--------------------------------------------------
        /** get number list inside of #&#64;{..}; */
        static public function getParam(param:SiOPMChannelParam) : Array {
            if (param.opeCount == 0) return null;
            var res:Array = [param.alg, param.fb, param.fbc];
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                res.push(opp.pgType, opp.ar, opp.dr, opp.sr, opp.rr, opp.sl, opp.tl, opp.ksr, opp.ksl, opp.mul, opp.dt1, opp.detune, opp.ams, opp.phase, opp.fixedPitch>>6);
            }
            return res;
        }
        
        
        /** get number list inside of #OPL&#64;{..}; */
        static public function getOPLParam(param:SiOPMChannelParam) : Array {
            if (param.opeCount == 0) return null;
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_opl);
            if (alg == -1) throw errorParameterNotValid("#OPL@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            var res:Array = [alg, param.fb];
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex],
                    ws :int = _pgTypeMA3(opp.pgType),
                    egt:int = (opp.sr == 0) ? 1 : 0,
                    tl :int = (opp.tl < 63) ? opp.tl : 63;
                if (ws == -1) throw errorParameterNotValid("#OPL@", "SiOPM ws" + String(opp.pgType));
                res.push(ws, opp.ar>>2, opp.dr>>2, opp.rr>>2, egt, opp.sl, tl, opp.ksr>>1, opp.ksl, opp.mul, opp.ams);
            }
            return res;
        }
        
        
        /** get number list inside of #OPM&#64;{..}; */
        static public function getOPMParam(param:SiOPMChannelParam) : Array {
            if (param.opeCount == 0) return null;
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_opm);
            if (alg == -1) throw errorParameterNotValid("#OPM@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            var res:Array = [alg, param.fb];
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex],
                    dt2:int = _dt2OPM(opp.detune);
                res.push(opp.ar>>1, opp.dr>>1, opp.sr>>1, opp.rr>>2, opp.sl, opp.tl, opp.ksr, opp.mul, opp.dt1, dt2, opp.ams);
            }
            return res;
        }
        
        
        /** get number list inside of #OPN&#64;{..}; */
        static public function getOPNParam(param:SiOPMChannelParam) : Array {
            if (param.opeCount == 0) return null;
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_opm);
            if (alg == -1) throw errorParameterNotValid("#OPN@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            var res:Array = [alg, param.fb];
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                res.push(opp.ar>>1, opp.dr>>1, opp.sr>>1, opp.rr>>2, opp.sl, opp.tl, opp.ksr, opp.mul, opp.dt1, opp.ams);
            }
            return res;
        }
        
        
        /** get number list inside of #OPX&#64;{..}; */
        static public function getOPXParam(param:SiOPMChannelParam) : Array {
            if (param.opeCount == 0) return null;
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_opx);
            if (alg == -1) throw errorParameterNotValid("#OPX@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            var res:Array = [alg, param.fb];
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex],
                    ws :int = _pgTypeMA3(opp.pgType);
                if (ws == -1) throw errorParameterNotValid("#OPX@", "SiOPM ws" + String(opp.pgType));
                res.push(ws, opp.ar>>1, opp.dr>>1, opp.sr>>1, opp.rr>>2, opp.sl, opp.tl, opp.ksr, opp.mul, opp.dt1, opp.detune, opp.ams);
            }
            return res;
        }
        
        
        /** get number list inside of #MA&#64;{..}; */
        static public function getMA3Param(param:SiOPMChannelParam) : Array {
            if (param.opeCount == 0) return null;
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_ma3);
            if (alg == -1) throw errorParameterNotValid("#MA@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            var res:Array = [alg, param.fb];
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex],
                    ws :int = _pgTypeMA3(opp.pgType),
                    tl :int = (opp.tl < 63) ? opp.tl : 63;
                if (ws == -1) throw errorParameterNotValid("#MA@", "SiOPM ws" + String(opp.pgType));
                res.push(ws, opp.ar>>2, opp.dr>>2, opp.sr>>2, opp.rr>>2, opp.sl, tl, opp.ksr>>1, opp.ksl, opp.mul, opp.dt1, opp.ams);
            }
            return res;
        }
        
        
        /** get number list inside of #AL&#64;{..}; */
        static public function getALParam(param:SiOPMChannelParam) : Array {
            if (param.opeCount != 5) return null;
            var opp0:SiOPMOperatorParam = param.operatorParam[0],
                opp1:SiOPMOperatorParam = param.operatorParam[1];
            return [param.alg, opp0.pgType, opp1.pgType, _balanceAL(opp0.tl, opp1.tl), opp1.detune, opp0.ar, opp0.dr, opp0.sl, opp0.rr];
        }
        
        
        
        
    // reconstruct MML string from channel parameters
    //--------------------------------------------------
        /** reconstruct mml text of #&#64;{..}.
         *  @param param SiOPMChannelParam for MML reconstruction
         *  @param separator String to separate each number
         *  @param lineEnd String to separate line end
         *  @param comment comment text inserting after 'fbc' number
         *  @return text formatted as "{..}".
         */
        static public function mmlParam(param:SiOPMChannelParam, separator:String=' ', lineEnd:String='\n', comment:String=null) : String
        {
            if (param.opeCount == 0) return "";
            
            var mml:String = "", res:* = _checkDigit(param);
            mml += "{";
            mml += String(param.alg) + separator;
            mml += String(param.fb)  + separator;
            mml += String(param.fbc);
            if (comment) {
                if (lineEnd == '\n') mml += " // " + comment;
                else mml += "/* " + comment + " */";
            }
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                mml += lineEnd;
                mml += _str(opp.pgType, res.ws) + separator;
                mml += _str(opp.ar, 2) + separator;
                mml += _str(opp.dr, 2) + separator;
                mml += _str(opp.sr, 2) + separator;
                mml += _str(opp.rr, 2) + separator;
                mml += _str(opp.sl, 2) + separator;
                mml += _str(opp.tl, res.tl) + separator;
                mml += String(opp.ksr) + separator;
                mml += String(opp.ksl) + separator;
                mml += _str(opp.mul, 2) + separator;
                mml += String(opp.dt1) + separator;
                mml += _str(opp.detune, res.dt) + separator;
                mml += String(opp.ams) + separator;
                mml += _str(opp.phase, res.ph) + separator
                mml += _str(opp.fixedPitch>>6, res.fn);
            }
            mml += "}";
            
            return mml;
        }
        
        
        /** reconstruct mml text of #OPL&#64;{..}; 
         *  @param param SiOPMChannelParam for MML reconstruction
         *  @param separator String to separate each number
         *  @param lineEnd String to separate line end
         *  @param comment comment text inserting after 'fbc' number
         *  @return text formatted as "{..}".
         */
        static public function mmlOPLParam(param:SiOPMChannelParam, separator:String=' ', lineEnd:String='\n', comment:String=null) : String
        {
            if (param.opeCount == 0) return "";
            
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_opl);
            if (alg == -1) throw errorParameterNotValid("#OPL@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            
            var mml:String = "", res:* = _checkDigit(param);
            mml += "{" + String(alg) + separator + String(param.fb);
            if (comment) {
                if (lineEnd == '\n') mml += " // " + comment;
                else mml += "/* " + comment + " */";
            }
                
            var pgType:int, tl:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                mml += lineEnd;
                pgType = _pgTypeMA3(opp.pgType);
                if (pgType == -1) throw errorParameterNotValid("#OPL@", "SiOPM ws" + String(opp.pgType));
                mml += String(pgType) + separator;              // ws
                mml += _str(opp.ar >> 2, 2) + separator;        // ar
                mml += _str(opp.dr >> 2, 2) + separator;        // dr
                mml += _str(opp.rr >> 2, 2) + separator;        // rr
                mml += ((opp.sr == 0) ? "1" : "0") + separator; // egt
                mml += _str(opp.sl, 2) + separator;                 // sl
                mml += _str((opp.tl<63)?opp.tl:63, 2) + separator;  // tl
                mml += String(opp.ksr>>1) + separator;              // ksr
                mml += String(opp.ksl) + separator;                 // ksl
                mml += _str(opp.mul, 2) + separator;                // mul
                mml += String(opp.ams);                             // ams
            }
            mml += "}";
            
            return mml;
        }
        
        
        /** reconstruct mml text of #OPM&#64;{..}; 
         *  @param param SiOPMChannelParam for MML reconstruction
         *  @param separator String to separate each number
         *  @param lineEnd String to separate line end
         *  @param comment comment text inserting after 'fbc' number
         *  @return text formatted as "{..}".
         */
        static public function mmlOPMParam(param:SiOPMChannelParam, separator:String=' ', lineEnd:String='\n', comment:String=null) : String
        {
            if (param.opeCount == 0) return "";
            
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_opm);
            if (alg == -1) throw errorParameterNotValid("#OPM@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            
            var mml:String = "", res:* = _checkDigit(param);
            mml += "{" + String(alg) + separator + String(param.fb);
            if (comment) {
                if (lineEnd == '\n') mml += " // " + comment;
                else mml += "/* " + comment + " */";
            }
                
            var pgType:int, tl:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                mml += lineEnd;
                // if (opp.pgType != 0) throw errorParameterNotValid("#OPM@", "SiOPM ws" + String(opp.pgType));
                mml += _str(opp.ar >> 1, 2) + separator;        // ar
                mml += _str(opp.dr >> 1, 2) + separator;        // dr
                mml += _str(opp.sr >> 1, 2) + separator;        // sr
                mml += _str(opp.rr >> 2, 2) + separator;        // rr
                mml += _str(opp.sl, 2) + separator;             // sl
                mml += _str(opp.tl, res.tl) + separator;        // tl
                mml += String(opp.ksl) + separator;             // ksl
                mml += _str(opp.mul, 2) + separator;            // mul
                mml += String(opp.dt1) + separator;             // dt1
                mml += String(_dt2OPM(opp.detune)) + separator; // dt2
                mml += String(opp.ams);                         // ams
            }
            mml += "}";
            
            return mml;
        }
        
        
        /** reconstruct mml text of #OPN&#64;{..}; 
         *  @param param SiOPMChannelParam for MML reconstruction
         *  @param separator String to separate each number
         *  @param lineEnd String to separate line end
         *  @param comment comment text inserting after 'fbc' number
         *  @return text formatted as "{..}".
         */
        static public function mmlOPNParam(param:SiOPMChannelParam, separator:String=' ', lineEnd:String='\n', comment:String=null) : String
        {
            if (param.opeCount == 0) return "";
            
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_opm);
            if (alg == -1) throw errorParameterNotValid("#OPN@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            
            var mml:String = "", res:* = _checkDigit(param);
            mml += "{" + String(alg) + separator + String(param.fb);
            if (comment) {
                if (lineEnd == '\n') mml += " // " + comment;
                else mml += "/* " + comment + " */";
            }

            var pgType:int, tl:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                mml += lineEnd;
                // if (opp.pgType != 0) throw errorParameterNotValid("#OPN@", "SiOPM ws" + String(opp.pgType));
                mml += _str(opp.ar >> 1, 2) + separator;    // ar
                mml += _str(opp.dr >> 1, 2) + separator;    // dr
                mml += _str(opp.sr >> 1, 2) + separator;    // sr
                mml += _str(opp.rr >> 2, 2) + separator;    // rr
                mml += _str(opp.sl, 2) + separator;         // sl
                mml += _str(opp.tl, res.tl) + separator;    // tl
                mml += String(opp.ksl) + separator;         // ksl
                mml += _str(opp.mul, 2) + separator;        // mul
                mml += String(opp.dt1) + separator;         // dt1
                mml += String(opp.ams);                     // ams
            }
            mml += "}";
            
            return mml;
        }
        
        
        /** reconstruct mml text of #OPX&#64;{..}; 
         *  @param param SiOPMChannelParam for MML reconstruction
         *  @param separator String to separate each number
         *  @param lineEnd String to separate line end
         *  @param comment comment text inserting after 'fbc' number
         *  @return text formatted as "{..}".
         */
        static public function mmlOPXParam(param:SiOPMChannelParam, separator:String=' ', lineEnd:String='\n', comment:String=null) : String
        {
            if (param.opeCount == 0) return "";
            
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_opx);
            if (alg == -1) throw errorParameterNotValid("#OPX@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            
            var mml:String = "", res:* = _checkDigit(param);
            mml += "{" + String(alg) + separator + String(param.fb);
            if (comment) {
                if (lineEnd == '\n') mml += " // " + comment;
                else mml += "/* " + comment + " */";
            }
            
            var pgType:int, tl:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                mml += lineEnd;
                pgType = _pgTypeMA3(opp.pgType);
                if (pgType == -1) throw errorParameterNotValid("#OPX@", "SiOPM ws" + String(opp.pgType));
                mml += String(pgType) + separator;              // ws
                mml += _str(opp.ar >> 1, 2) + separator;        // ar
                mml += _str(opp.dr >> 1, 2) + separator;        // dr
                mml += _str(opp.sr >> 1, 2) + separator;        // sr
                mml += _str(opp.rr >> 2, 2) + separator;        // rr
                mml += _str(opp.sl, 2) + separator;             // sl
                mml += _str(opp.tl, res.tl) + separator;        // tl
                mml += String(opp.ksl) + separator;             // ksl
                mml += _str(opp.mul, 2) + separator;            // mul
                mml += String(opp.dt1) + separator;             // dt1
                mml += _str(opp.detune, res.dt) + separator;    // det
                mml += String(opp.ams);                         // ams
            }
            mml += "}";
            
            return mml;
        }
        
        
        /** reconstruct mml text of #MA&#64;{..}; 
         *  @param param SiOPMChannelParam for MML reconstruction
         *  @param separator String to separate each number
         *  @param lineEnd String to separate line end
         *  @param comment comment text inserting after 'fbc' number
         *  @return text formatted as "{..}".
         */
        static public function mmlMA3Param(param:SiOPMChannelParam, separator:String=' ', lineEnd:String='\n', comment:String=null) : String
        {
            if (param.opeCount == 0) return "";
            
            var alg:int = _checkAlgorism(param.opeCount, param.alg, SiMMLTable.instance.alg_ma3);
            if (alg == -1) throw errorParameterNotValid("#MA@ alg", "SiOPM opc" + String(param.opeCount) + "/alg" + String(param.alg));
            
            var mml:String = "", res:* = _checkDigit(param);
            mml += "{" + String(alg) + separator + String(param.fb);
            if (comment) {
                if (lineEnd == '\n') mml += " // " + comment;
                else mml += "/* " + comment + " */";
            }
            
            var pgType:int, tl:int;
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                mml += lineEnd;
                pgType = _pgTypeMA3(opp.pgType);
                if (pgType == -1) throw errorParameterNotValid("#MA@", "SiOPM ws" + String(opp.pgType));
                mml += _str(pgType, 2) + separator;                 // ws
                mml += _str(opp.ar >> 2, 2) + separator;            // ar
                mml += _str(opp.dr >> 2, 2) + separator;            // dr
                mml += _str(opp.sr >> 2, 2) + separator;            // sr
                mml += _str(opp.rr >> 2, 2) + separator;            // rr
                mml += _str(opp.sl, 2) + separator;                 // sl
                mml += _str((opp.tl<63)?opp.tl:63, 2) + separator;  // tl
                mml += String(opp.ksr>>1) + separator;              // ksr
                mml += String(opp.ksl) + separator;                 // ksl
                mml += _str(opp.mul, 2) + separator;                // mul
                mml += String(opp.dt1) + separator;                 // dt1
                mml += String(opp.ams);                             // ams
            }
            mml += "}";
            
            return mml;
        }
        
        
        
        /** reconstruct mml text of #AL&#64;{..}; 
         *  @param param SiOPMChannelParam for MML reconstruction
         *  @param separator String to separate each number
         *  @param lineEnd String to separate line end
         *  @param comment comment text inserting after 'fbc' number
         *  @return text formatted as "{..}".
         */
        static public function mmlALParam(param:SiOPMChannelParam, separator:String=' ', lineEnd:String='\n', comment:String=null) : String
        {
            if (param.opeCount != 5) return null;
            
            var opp0:SiOPMOperatorParam = param.operatorParam[0],
                opp1:SiOPMOperatorParam = param.operatorParam[1],
                mml:String = "";
            mml += "{" + String(param.alg) + separator;
            mml += String(opp0.pgType) + separator;
            mml += String(opp1.pgType) + separator;
            mml += String(_balanceAL(opp0.tl, opp1.tl)) + separator;
            mml += String(opp1.detune) + separator;
            if (comment) {
                if (lineEnd == '\n') mml += " // " + comment;
                else mml += "/* " + comment + " */";
            }
            mml += lineEnd + String(opp0.ar) + separator;
            mml += String(opp0.dr) + separator;
            mml += String(opp0.sl) + separator;
            mml += String(opp0.rr);
            mml += "}";
            
            return mml;
        }
        
        
        
        
    // extract system command from mml
    //------------------------------------------------------------
        /** extract system command from mml 
         *  @param mml mml text
         *  @return extracted command list. the mml of "#CMD1{cont}pfx;" is converted to the Object as {command:"CMD", number:1, content:"cont", postfix:"pfx"}.
         */
        static public function extractSystemCommand(mml:String) : Array 
        {
            var comrex:RegExp = new RegExp("/\\*.*?\\*/|//.*?[\\r\\n]+", "gms");
            var seqrex:RegExp = /(#[A-Z@]+)([^;{]*({.*?})?[^;]*);/gms; //}
            var prmrex:RegExp = /\s*(\d*)\s*(\{(.*?)\})?(.*)/ms;
            var res:*, res2:*, cmd:String, num:int, dat:String, pfx:String, cmds:Array=[];
            
            // remove comments
            mml += "\n";
            mml = mml.replace(comrex, "") + ";";
            
            // parse system command
            while (res = seqrex.exec(mml)) {
                cmd = String(res[1]);
                if (res[2] != "") {
                    prmrex.lastIndex = 0;
                    res2 = prmrex.exec(res[2]);
                    num = int(res2[1]);
                    dat = (res2[2] == undefined) ? "" : String(res2[3]);
                    pfx = String(res2[4]);
                } else {
                    num = 0;
                    dat = "";
                    pfx = "";
                }
                cmds.push({command:cmd, number:num, content:dat, postfix:pfx});
            }
            return cmds;
        }
        
                
        
        
        
    // Voice parameters (filter, lfo, portament, gate time, sweep)
    //------------------------------------------------------------
        /** parse voice setting mml 
         *  @param voice voice to update
         *  @param mml setting mml
         *  @param envelopes envelope list to pickup envelope
         *  @return same as argument of 'voice'.
         */
        static public function parseVoiceSetting(voice:SiMMLVoice, mml:String, envelopes:Vector.<SiMMLEnvelopTable>=null) : SiMMLVoice {
            var i:int, j:int;
            var cmd:String = "(%[fvx]|@[fpqv]|@er|@lfo|kt?|m[ap]|_?@@|_?n[aptf]|po|p|q|s|x|v)";
            var ags:String = "(-?\\d*)";
            for (i=0; i<10; i++) ags += "(\\s*,\\s*(-?\\d*))?";
            var rex:RegExp = new RegExp(cmd+ags, "g");
            var res:* = rex.exec(mml);
            var param:SiOPMChannelParam = voice.channelParam;
            while (res) {
                switch(res[1]) {
                case '@f':
                    param.cutoff    = (res[2] != "")  ? int(res[2])  : 128;
                    param.resonance = (res[4] != "")  ? int(res[4])  : 0;
                    param.far       = (res[6] != "")  ? int(res[6])  : 0;
                    param.fdr1      = (res[8] != "")  ? int(res[8])  : 0;
                    param.fdr2      = (res[10] != "") ? int(res[10]) : 0;
                    param.frr       = (res[12] != "") ? int(res[12]) : 0;
                    param.fdc1      = (res[14] != "") ? int(res[14]) : 128;
                    param.fdc2      = (res[16] != "") ? int(res[16]) : 64;
                    param.fsc       = (res[18] != "") ? int(res[18]) : 32;
                    param.frc       = (res[20] != "") ? int(res[20]) : 128;
                    break;
                case '@lfo':
                    param.lfoFrame = (res[2] != "") ? int(res[2]) : 30;
                    param.lfoWaveShape = (res[4] != "") ? int(res[4]) : SiOPMTable.LFO_WAVE_TRIANGLE;
                    break;
                case 'ma':
                    voice.amDepth    = (res[2] != "") ? int(res[2]) : 0;
                    voice.amDepthEnd = (res[4] != "") ? int(res[4]) : 0;
                    voice.amDelay    = (res[6] != "") ? int(res[6]) : 0;
                    voice.amTerm     = (res[8] != "") ? int(res[8]) : 0;
                    param.amd = voice.amDepth;
                    break;
                case 'mp':
                    voice.pmDepth    = (res[2] != "") ? int(res[2]) : 0;
                    voice.pmDepthEnd = (res[4] != "") ? int(res[4]) : 0;
                    voice.pmDelay    = (res[6] != "") ? int(res[6]) : 0;
                    voice.pmTerm     = (res[8] != "") ? int(res[8]) : 0;
                    param.pmd = voice.pmDepth;
                    break;
                case 'po':
                    voice.portament = (res[2] != "") ? int(res[2]) : 30;
                    break;
                case 'q':
                    voice.defaultGateTime = (res[2] != "") ? (int(res[2])*0.125) : Number.NaN;
                    break;
                case 's':
                    //[releaseRate] = (res[2] != "") ? int(res[2]) : 0;
                    voice.releaseSweep = (res[4] != "") ? int(res[4]) : 0;
                    break;
                    
                case '%f':
                    voice.channelParam.filterType = (res[2] != "") ? int(res[2]) : 0;
                    break;
                case '@er':
                    for (i=0; i<4; i++) voice.channelParam.operatorParam[i].erst = (res[2] != "1");
                    break;
                case 'k':
                    voice.pitchShift = (res[2] != "") ? int(res[2]) : 0;
                    break;
                case 'kt':
                    voice.noteShift = (res[2] != "") ? int(res[2]) : 0;
                    break;
                    
                case '@v':
                    voice.channelParam.volumes[0] = (res[2]  != "") ? (int(res[2])*0.0078125)  : 0.5;
                    voice.channelParam.volumes[1] = (res[4]  != "") ? (int(res[4])*0.0078125)  : 0;
                    voice.channelParam.volumes[2] = (res[6]  != "") ? (int(res[6])*0.0078125)  : 0;
                    voice.channelParam.volumes[3] = (res[8]  != "") ? (int(res[8])*0.0078125)  : 0;
                    voice.channelParam.volumes[4] = (res[10] != "") ? (int(res[10])*0.0078125) : 0;
                    voice.channelParam.volumes[5] = (res[12] != "") ? (int(res[12])*0.0078125) : 0;
                    voice.channelParam.volumes[6] = (res[14] != "") ? (int(res[14])*0.0078125) : 0;
                    voice.channelParam.volumes[7] = (res[16] != "") ? (int(res[16])*0.0078125) : 0;
                    break;
                case 'p':
                    voice.channelParam.pan = (res[2] != "") ? int(res[2])*16 : 64;
                    break;
                case '@p':
                    voice.channelParam.pan = (res[2] != "") ? int(res[2]) : 64;
                    break;
                case 'v':
                    voice.velocity = (res[2] != "") ? (int(res[2])<<voice.vcommandShift) : 256;
                    break;
                case 'x':
                    voice.expression = (res[2] != "") ? int(res[2]) : 128;
                    break;
                    
                case '%v':
                    voice.velocityMode  = (res[2] != "") ? int(res[2]) : 0;
                    voice.vcommandShift = (res[4] != "") ? int(res[4]) : 4;
                    break;
                case '%x':
                    voice.expressionMode = (res[2] != "") ? int(res[2]) : 0;
                    break;
                case '@q':
                    voice.defaultGateTicks       = (res[2] != "") ? int(res[2]) : 0;
                    voice.defaultKeyOnDelayTicks = (res[4] != "") ? int(res[4]) : 0;
                    break;
                    
                case '@@':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOnToneEnvelop = envelopes[i];
                        voice.noteOnToneEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                case 'na':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOnAmplitudeEnvelop = envelopes[i];
                        voice.noteOnAmplitudeEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                case 'np':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOnPitchEnvelop = envelopes[i];
                        voice.noteOnPitchEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                case 'nt':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOnNoteEnvelop = envelopes[i];
                        voice.noteOnNoteEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                case 'nf':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOnFilterEnvelop = envelopes[i];
                        voice.noteOnFilterEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                case '_@@':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOffToneEnvelop = envelopes[i];
                        voice.noteOffToneEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                case '_na':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOffAmplitudeEnvelop = envelopes[i];
                        voice.noteOffAmplitudeEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                case '_np':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOffPitchEnvelop = envelopes[i];
                        voice.noteOffPitchEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                case '_nt':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOffNoteEnvelop = envelopes[i];
                        voice.noteOffNoteEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                case '_nf':
                    i = int(res[2]);
                    if (envelopes && i>=0 && i<255) {
                        voice.noteOffFilterEnvelop = envelopes[i];
                        voice.noteOffFilterEnvelopStep = (int(res[4])>0) ? int(res[4]) : 1;
                    }
                    break;
                }
                res = rex.exec(mml);
            }
            return voice;
        }
        
        
        /** reconstruct voice setting mml (except for channel operator parameters and envelopes) */
        static public function mmlVoiceSetting(voice:SiMMLVoice) : String {
            var mml:String = "", param:SiOPMChannelParam = voice.channelParam, i:int;
            if (voice.channelParam.filterType > 0) mml += "%f" + String(voice.channelParam.filterType);
            if (param.cutoff<128 || param.resonance>0 || param.far>0 || param.frr>0) {
                mml += "@f" + String(param.cutoff) + "," + String(param.resonance);
                if (param.far>0 || param.frr>0) {
                    mml += "," + String(param.far)  + "," + String(param.fdr1) + "," + String(param.fdr2) + "," + String(param.frr);
                    mml += "," + String(param.fdc1) + "," + String(param.fdc2) + "," + String(param.fsc)  + "," + String(param.frc);
                }
            }
            if (voice.amDepth > 0 || voice.amDepthEnd > 0 || param.amd > 0 || voice.pmDepth > 0 || voice.pmDepthEnd > 0 || param.pmd > 0) {
                var lfo:int = param.lfoFrame, ws:int = param.lfoWaveShape;
                if (lfo != 30 || ws != SiOPMTable.LFO_WAVE_TRIANGLE) {
                    mml += "@lfo" + String(lfo);
                    if (ws != SiOPMTable.LFO_WAVE_TRIANGLE) mml += "," + String(ws);
                }
                if (voice.amDepth > 0 || voice.amDepthEnd > 0) {
                    mml += "ma" + String(voice.amDepth);
                    if (voice.amDepthEnd > 0) mml += "," + String(voice.amDepthEnd);
                    if (voice.amDelay > 0 || voice.amTerm > 0) mml += "," + String(voice.amDelay);
                    if (voice.amTerm > 0) mml += "," + String(voice.amTerm);
                } else if (param.amd > 0) {
                    mml += "ma" + String(param.amd);
                }
                if (voice.pmDepth > 0 || voice.pmDepthEnd > 0) {
                    mml += "mp" + String(voice.pmDepth);
                    if (voice.pmDepthEnd > 0) mml += "," + String(voice.pmDepthEnd);
                    if (voice.pmDelay > 0 || voice.pmTerm > 0) mml += "," + String(voice.pmDelay);
                    if (voice.pmTerm > 0) mml += "," + String(voice.pmTerm);
                } else if (param.pmd > 0) {
                    mml += "mp" + String(param.pmd);
                }
            }
            if (voice.velocityMode != 0 || voice.vcommandShift != 4) {
                mml += "%v" + String(voice.velocityMode) + "," + String(voice.vcommandShift);
            }
            if (voice.expressionMode != 0) mml += "%x" + String(voice.expressionMode);
            if (voice.portament > 0) mml += "po" + String(voice.portament);
            if (!isNaN(voice.defaultGateTime)) mml += "q" + String(int(voice.defaultGateTime*8));
            if (voice.defaultGateTicks > 0 || voice.defaultKeyOnDelayTicks > 0) {
                mml += "@q" + String(voice.defaultGateTicks) + "," + String(voice.defaultKeyOnDelayTicks);
            }
            if (voice.releaseSweep > 0) mml += "s," + String(voice.releaseSweep);
            if (voice.channelParam.operatorParam[0].erst) mml += "@er1";
            if (voice.pitchShift) mml += "k"  + String(voice.pitchShift);
            if (voice.noteShift)  mml += "kt" + String(voice.noteShift);
            if (voice.updateVolumes) {
                var ch:int = (voice.channelParam.volumes[0] == 0.5) ? 0 : 1;
                for (i=1; i<8; i++) if (voice.channelParam.volumes[i] != 0) ch = i+1;
                if (i != 0) {
                    mml += "@v";
                    if (voice.channelParam.volumes[0] != 0.5) mml += int(voice.channelParam.volumes[0]*128).toString();
                    for (i=1; i<ch; i++) {
                        if (voice.channelParam.volumes[i] != 0) mml += "," + int(voice.channelParam.volumes[i]*128).toString();
                    }
                }
                if (voice.channelParam.pan != 64) {
                    if (voice.channelParam.pan & 15) mml += "@p" + String(voice.channelParam.pan-64);
                    else mml += "p" + String(voice.channelParam.pan >> 4);
                }
                if (voice.velocity   != 256) mml += "v"  + String(voice.velocity >> voice.vcommandShift);
                if (voice.expression != 128) mml += "@v" + String(voice.expression);
            }
            
            return mml;
        }
        
        
        
        
    // envelop table
    //------------------------------------------------------------
        /** parse mml of envelop and wave table numbers.
         *  @param tableNumbers String of table numbers
         *  @param postfix String of postfix
         *  @param maxIndex maximum size of envelop table
         *  @return this instance
         */
        static public function parseTableNumbers(tableNumbers:String, postfix:String, maxIndex:int=65536) : *
        {
            var index:int = 0, i:int, imax:int, j:int, v:int, ti0:int, ti1:int, tr:Number, 
                t:Number, s:Number, r:Number, o:Number, jmax:int, last:SLLint, rep:SLLint;
            var regexp:RegExp, res:*, array:Array, itpl:Vector.<int> = new Vector.<int>(), loopStac:Array=[];
            var tempNumberList:SLLint = SLLint.alloc(0), loopHead:SLLint, loopTail:SLLint, l:SLLint;

            // initialize
            last = tempNumberList;
            rep = null;

            // magnification
            regexp = /(\d+)?(\*(-?[\d.]+))?(([+-])([\d.]+))?/;
            res    = regexp.exec(postfix);
            jmax = (res[1]) ? int(res[1]) : 1;
            r    = (res[2]) ? Number(res[3]) : 1;
            o    = (res[4]) ? ((res[5] == '+') ? Number(res[6]) : -Number(res[6])) : 0;
            
            // res[1];(n..),m {res[2];n.., res[3];m} / res[4];n / res[5];|[] / res[6]; ]n
            regexp = /(\(\s*([,\-\d\s]+)\)[,\s]*(\d+))|(-?\d+)|(\||\[|\](\d*))/gm;
            res    = regexp.exec(tableNumbers);
            while (res && index<maxIndex) {
                if (res[1]) {
                    // interpolation "(res[2]..),res[3]"
                    array = String(res[2]).split(/[,\s]+/);
                    imax = int(res[3]);
                    if (imax < 2 || array.length < 1) throw errorParameterNotValid("Table MML", tableNumbers);
                    itpl.length = array.length;
                    for (i=0; i<itpl.length; i++) { itpl[i] = int(array[i]); }
                    if (itpl.length > 1) {
                        t = 0;
                        s = Number(itpl.length - 1) / imax;
                        for (i=0; i<imax && index<maxIndex; i++) {
                            ti0 = int(t);
                            ti1 = ti0 + 1;
                            tr  = t - Number(ti0);
                            v = int(itpl[ti0] * (1-tr) + itpl[ti1] * tr + 0.5);
                            v = int(v * r + o + 0.5);
                            for (j=0; j<jmax; j++, index++) {
                                last.next = SLLint.alloc(v);
                                last = last.next;
                            }
                            t += s;
                        }
                    } else {
                        // repeat
                        v = int(itpl[0] * r + o + 0.5);
                        for (i=0; i<imax && index<maxIndex; i++) {
                            for (j=0; j<jmax; j++, index++) {
                                last.next = SLLint.alloc(v);
                                last = last.next;
                            }
                        }
                    }
                } else
                if (res[4]) {
                    // single number
                    v = int(int(res[4]) * r + o + 0.5);
                    for (j=0; j<jmax; j++) {
                        last.next = SLLint.alloc(v);
                        last = last.next;
                    }
                    index++;
                } else 
                if (res[5]) {
                    switch (res[5]) {
                    case '|': // repeat point
                        rep = last;
                        break;
                    case '[': // begin loop
                        loopStac.push(last);
                        break;
                    default: // end loop "]n"
                        if (loopStac.length == 0) errorParameterNotValid("Table MML's Loop", tableNumbers);
                        loopHead = loopStac.pop().next;
                        if (!loopHead) errorParameterNotValid("Table MML's Loop", tableNumbers);
                        loopTail = last;
                        for (j=int(res[6])||2; j>0; --j) {
                            for (l=loopHead; l!==loopTail.next; l=l.next) {
                                last.next = SLLint.alloc(l.i);
                                last = last.next;
                            }
                        }
                        break;
                    }
                } else {
                    // unknown error
                    throw errorUnknown("@parseWav()");
                }
                res = regexp.exec(tableNumbers);
            }
            
            //for(var e:SLLint=tempNumberList.next; e!=null; e=e.next) { trace(e.i); }
            
            if (rep) last.next = rep.next;
            return {'head':tempNumberList.next, 'tail':last, 'length':index, 'repeated':(rep!=null)};
        }
        
        
        
        
    // wave table mml parser
    //--------------------------------------------------
        /** parse #WAV data
         *  @param tableNumbers number string of #WAV command.
         *  @param postfix postfix string of #WAV command.
         *  @return vector of Number in the range of [-1,1]
         */
        static public function parseWAV(tableNumbers:String, postfix:String) : Vector.<Number>
        {
            var i:int, imax:int, v:Number, wav:Vector.<Number>;
            
            var res:* = Translator.parseTableNumbers(tableNumbers, postfix, 1024),
                num:SLLint = res.head;
            for (imax=2; imax<1024; imax<<=1) {
                if (imax >= res.length) break;
            }

            wav = new Vector.<Number>(imax);
            for (i=0; i<imax && num!=null; i++) {
                v = (num.i + 0.5) * 0.0078125;
                wav[i] = (v>1) ? 1 : (v<-1) ? -1 : v;
                num = num.next;
            }
            for (; i<imax; i++) { wav[i] = 0; }
            
            return wav;
        }
        
        
        /** parse #WAVB data
         *  @param hex hex string of #WAVB command.
         *  @return vector of Number in the range of [-1,1]
         */
        static public function parseWAVB(hex:String) : Vector.<Number>
        {
            var ub:int, i:int, imax:int, wav:Vector.<Number>;
            hex = hex.replace(/\s+/gm, '');
            imax = hex.length >> 1;
            wav = new Vector.<Number>(imax);
            for (i=0; i<imax; i++) {
                ub = parseInt(hex.substr(i<<1,2), 16);
                wav[i] = (ub<128) ? (ub * 0.0078125) : ((ub-256) * 0.0078125);
            }
            return wav;
        }
        
        
        
        
    // pcm mml parser
    //--------------------------------------------------
        /** parse mml text of sampler wave setting (#SAMPLER system command).
         *  @param table table to set sampler wave
         *  @param noteNumber note number to set sample
         *  @param mml comma separated text of #SAMPLER system command
         *  @param soundReferTable reference table of Sound instances.
         *  @return true when success to find wave from soundReferTable.
         */
        static public function parseSamplerWave(table:SiOPMWaveSamplerTable, noteNumber:int, mml:String, soundReferTable:*) : Boolean
        {
            var args:Array = mml.split(/\s*,\s*/g),
                waveID:String = String(args[0]), 
                ignoreNoteOff:Boolean = (args[1] != undefined && args[1] != "") ? Boolean(args[1]) : false, 
                pan:int               = (args[2] != undefined && args[2] != "") ? int(args[2]) : 0,
                channelCount:int      = (args[3] != undefined && args[3] != "") ? int(args[3]) : 2,
                startPoint:int        = (args[4] != undefined && args[4] != "") ? int(args[4]) : -1,
                endPoint:int          = (args[5] != undefined && args[5] != "") ? int(args[5]) : -1,
                loopPoint:int         = (args[6] != undefined && args[6] != "") ? int(args[6]) : -1;
            if (waveID in soundReferTable) {
                var sample:SiOPMWaveSamplerData = new SiOPMWaveSamplerData(soundReferTable[waveID], ignoreNoteOff, pan, 2, channelCount);
                sample.slice(startPoint, endPoint, loopPoint);
                table.setSample(sample, noteNumber);
                return true;
            }
            return false;
        }
        
        
        /** parse mml text of pcm wave setting (#PCMWAVE system command).
         *  @param table table to set PCM wave
         *  @param mml comma separated values of #PCMWAVE system command
         *  @param soundReferTable reference table of Sound instances.
         *  @return true when success to find wave from soundReferTable.
         */
        static public function parsePCMWave(table:SiOPMWavePCMTable, mml:String, soundReferTable:*) : Boolean
        {
            var args:Array = mml.split(/\s*,\s*/g),
                waveID:String = String(args[0]), 
                samplingNote:int = (args[1] != undefined && args[1] != "") ? int(args[1]) : 69,
                keyRangeFrom:int = (args[2] != undefined && args[2] != "") ? int(args[2]) : 0,
                keyRangeTo:int   = (args[3] != undefined && args[3] != "") ? int(args[3]) : 127,
                channelCount:int = (args[4] != undefined && args[4] != "") ? int(args[4]) : 2,
                startPoint:int   = (args[5] != undefined && args[5] != "") ? int(args[5]) : -1,
                endPoint:int     = (args[6] != undefined && args[6] != "") ? int(args[6]) : -1,
                loopPoint:int    = (args[7] != undefined && args[7] != "") ? int(args[7]) : -1;
            if (waveID in soundReferTable) {
                var sample:SiOPMWavePCMData = new SiOPMWavePCMData(soundReferTable[waveID], int(samplingNote*64), 2, channelCount);
                sample.slice(startPoint, endPoint, loopPoint);
                table.setSample(sample, keyRangeFrom, keyRangeTo);
                return true;
            }
            return false;
        }
        
        
        /** parse mml text of pcm voice setting (#PCMVOICE system command)
         *  @param voice SiMMLVoice to update parameters
         *  @param mml comma separated values of #PCMVOICE system command
         *  @param postfix postfix of #PCMVOICE system command
         *  @param envelopes envelope list to pickup envelope
         *  @return true when success to update parameters
         */
        static public function parsePCMVoice(voice:SiMMLVoice, mml:String, postfix:String, envelopes:Vector.<SiMMLEnvelopTable>=null) : Boolean
        {
            var table:SiOPMWavePCMTable = voice.waveData as SiOPMWavePCMTable;
            if (!table) return false;
            var args:Array = mml.split(/\s*,\s*/g),
                volumeNoteNumber:int  = (args[0]  != undefined && args[0]  != "") ? args[0] : 64, 
                volumeKeyRange:Number = (args[1]  != undefined && args[1]  != "") ? args[1] : 0, 
                volumeRange:Number    = (args[2]  != undefined && args[2]  != "") ? args[2] : 0, 
                panNoteNumber:int     = (args[3]  != undefined && args[3]  != "") ? args[3] : 64, 
                panKeyRange:Number    = (args[4]  != undefined && args[4]  != "") ? args[4] : 0, 
                panWidth:Number       = (args[5]  != undefined && args[5]  != "") ? args[5] : 0,
                dr:int                = (args[7]  != undefined && args[7]  != "") ? args[7] : 0,
                sr:int                = (args[8]  != undefined && args[8]  != "") ? args[8] : 0,
                rr:int                = (args[9]  != undefined && args[9]  != "") ? args[9] : 63,
                sl:int                = (args[10] != undefined && args[10] != "") ? args[10] : 0;
            var opp:SiOPMOperatorParam = voice.channelParam.operatorParam[0];
            opp.ar = (args[6]  != undefined && args[6]  != "") ? args[6]  : 63;
            opp.dr = (args[7]  != undefined && args[7]  != "") ? args[7]  : 0;
            opp.sr = (args[8]  != undefined && args[8]  != "") ? args[8]  : 0;
            opp.rr = (args[9]  != undefined && args[9]  != "") ? args[9]  : 63;
            opp.sl = (args[10] != undefined && args[10] != "") ? args[10] : 0;
            table.setKeyScaleVolume(volumeNoteNumber, volumeKeyRange, volumeRange);
            table.setKeyScalePan(panNoteNumber, panKeyRange, panWidth);
            parseVoiceSetting(voice, postfix, envelopes);
            return true;
        }
        
        
        
        
    // register data
    //--------------------------------------------------
        /** set SiONVoice list by OPM register data
         *  @param regData int vector of register data.
         *  @param address address of the first data in regData
         *  @param enableLFO flag to enable LFO parameters
         *  @param voiceSet voice list to set parameters. When this argument is null, returning voices are allocated inside.
         *  @return voice list pick up values from register data.
         */
        static public function setOPMVoicesByRegister(regData:Vector.<int>, address:int, enableLFO:Boolean=false, voiceSet:Array=null) : Array
        {
            var i:int, imax:int, value:int, index:int, v:int, ams:int, pms:int, 
                chp:SiOPMChannelParam, opp:SiOPMOperatorParam, opi:int, _pmd:int=0, _amd:int=0, 
                opia:Array = [0,2,1,3], table:SiOPMTable = SiOPMTable.instance;
            
            // initialize result voice list
            voiceSet = voiceSet || [];
            for (opi=0; opi<8; opi++) { 
                if (voiceSet[opi]) voiceSet[opi].initialize();
                else voiceSet[opi] = new SiONVoice();
                voiceSet[opi].channelParam.opeCount = 4;
                voiceSet[opi].chipType = SiONVoice.CHIPTYPE_OPM;
            }
            
            // pick up parameters from register data
            imax = regData.length;
            for (i=0; i<imax; i++, address++) {
                value = regData[i];
                chp = voiceSet[address & 7].channelParam;
                
                // Module parameter
                if (address < 0x20) {
                    switch(address) {
                    case 1:  // TEST:7-2 LFO RESET:1
                        break;
                    case 8:  // (KEYON) MUTE:7 OP0:6 OP1:5 OP2:4 OP3:3 CH:2-0
                        break;
                    case 15: // NOIZE:7 FREQ:4-0
                        if (value & 128) {
                            voiceSet[7].channelParam.operatorParam[3].setPGType(SiOPMTable.PG_NOISE_PULSE);
                            voiceSet[7].channelParam.operatorParam[3].fixedPitch = ((value & 31) << 6) + 2048;
                        }
                        break;
                    case 16: // TIMER AH:7-0
                        break;
                    case 17: // TIMER AL:10
                        break;
                    case 18: // TIMER B :7-0
                        break;
                    case 19: // TIMER FUNC ?
                        break;
                    case 24: // LFO FREQ:7-0
                        if (enableLFO) {
                            v = table.lfo_timerSteps[value];
                            for (opi=0; opi<8; opi++) { voiceSet[opi].channelParam.lfoFreqStep = v; }
                        }
                        break;
                    case 25: // A(0)/P(1):7 DEPTH:6-0
                        if (enableLFO) {
                            if (value & 128) _pmd = value & 127;
                            else             _amd = value & 127;
                        }
                        break;
                    case 27: // LFO WS:10
                        if (enableLFO) {
                            v = value & 3;
                            for (opi=0; opi<8; opi++) { voiceSet[opi].channelParam.lfoWaveShape = v; }
                        }
                        break;
                    }
                } else 

                // Channel parameter
                if (address < 0x40) {
                    switch((address-0x20) >> 3) {
                    case 0: // L:7 R:6 FB:5-3 ALG:2-0
                        v = value >> 6;
                        chp.volumes[0] = (v) ? 0.5 : 0;
                        chp.pan = (v==1) ? 128 : (v==2) ? 0 : 64;
                        chp.fb  = (value >> 3) & 7;
                        chp.alg = (value     ) & 7;
                        break;
                    case 1: // KC:6-0
                        // channel.kc = value & 127
                        break;
                    case 2: // KF:6-0
                        // channel.keyFraction = value & 127
                        break;
                    case 3: // PMS:6-4 AMS:10
                        if (enableLFO) {
                            pms = (value >> 4) & 7;
                            ams = (value     ) & 3;
                            chp.pmd = (pms<6) ? (_pmd >> (6-pms)) : (_pmd << (pms-5));
                            chp.amd = (ams>0) ? (_amd << (ams-1)) : 0;
                        }
                        break;
                    }
                } else 
                
                // Operator parameter
                {
                    index = opia[(address >> 3) & 3];
                    opp = chp.operatorParam[index];
                    switch((address-0x40) >> 5) {
                    case 0: // DT1:6-4 MUL:3-0
                        opp.dt1 = (value >> 4) & 7;
                        opp.mul = (value     ) & 15;
                        break;
                    case 1: // TL:6-0
                        opp.tl = value & 127;
                        break;
                    case 2: // KS:76 AR:4-0
                        opp.ksr = (value >> 6) & 3;
                        opp.ar  = (value & 31) << 1;
                        break;
                    case 3: // AMS:7 DR:4-0
                        opp.ams = ((value >> 7) & 1)<<1;
                        opp.dr  = (value & 31) << 1;
                        break;
                    case 4: // DT2:76 SR:4-0
                        opp.detune = table.dt2Table[(value >> 6) & 3];
                        opp.sr     = (value & 31) << 1;
                        break;
                    case 5: // SL:7-4 RR:3-0
                        opp.sl = (value >> 4) & 15;
                        opp.rr = (value & 15) << 2;
                        break;
                    }
                }
            }
            
            return voiceSet;
        }
        
        
        
        
        
    // internal functions
    //--------------------------------------------------
        // int to string with 0 filling
        static private function _str(v:int, length:int) : String {
            if (v>=0) return ("0000"+String(v)).substr(-length);
            return "-" + ("0000"+String(-v)).substr(-length+1);
        }
        
        
        // check parameters digit
        static private function _checkDigit(param:SiOPMChannelParam) : * {
            var res:* = {'ws':1, 'tl':2, 'dt':1, 'ph':1, 'fn':1};
            for (var opeIndex:int=0; opeIndex<param.opeCount; opeIndex++) {
                var opp:SiOPMOperatorParam = param.operatorParam[opeIndex];
                res.ws = max(res.ws, String(opp.pgType).length);
                res.tl = max(res.tl, String(opp.tl).length);
                res.dt = max(res.dt, String(opp.detune).length);
                res.ph = max(res.ph, String(opp.phase).length);
                res.fn = max(res.fn, String(opp.fixedPitch>>6).length);
            }
            return res;
            
            function max(a:int, b:int) : int { return (a>b) ? a:b; }
        }
        
        
        // translate algorism by algorism list, return index in the list.
        static private function _checkAlgorism(oc:int, al:int, algList:Array) : int {
            var list:Array = algList[oc-1];
            for (var i:int=0; i<list.length; i++) if (al == list[i]) return i;
            return -1;
        }
        
        
        // translate pgType to MA3 valid.
        static private function _pgTypeMA3(pgType:int) : int {
            var ws:int = pgType - SiOPMTable.PG_MA3_WAVE;
            if (ws>=0 && ws<=31) return ws;
            switch (pgType) {
            case 0:                             return 0;   // sin
            case 1: case 2: case 128: case 255: return 24;  // saw
            case 4: case 192: case 191:         return 16;  // triangle
            case 5: case 72:                    return 6;   // square
            }
            return -1;
        }
        
        
        // find nearest dt2 value
        static private function _dt2OPM(detune:int) : int {
                 if (detune <= 100) return 0;   // 0
            else if (detune <= 420) return 1;   // 384
            else if (detune <= 550) return 2;   // 500
            return 3;                           // 608
        }
        
        
        // find nearest balance value from opp0.tl and opp1.tl
        static private function _balanceAL(tl0:int, tl1:int) : int {
            if (tl0 == tl1) return 0;
            if (tl0 == 0) return -64;
            if (tl1 == 0) return 64;
            var tltable:Vector.<int> = SiOPMTable.instance.eg_lv2tlTable, i:int;
            for (i=1; i<128; i++) if (tl0 >= tltable[i]) return i-64;
            return 64;
        }
        
        
        
        
    // errors
    //--------------------------------------------------
        static public function errorToneParameterNotValid(cmd:String, chParam:int, opParam:int) : Error
        {
            return new Error("Translator error : Parameter count is not valid in '" + cmd + "'. " + String(chParam) + " parameters for channel and " + String(opParam) + " parameters for each operator.");
        }
        
        
        static public function errorParameterNotValid(cmd:String, param:String) : Error
        {
            return new Error("Translator error : Parameter not valid. '" + param + "' in " + cmd);
        }
        
        
        static public function errorTranslation(str:String) : Error
        {
            return new Error("Translator Error : mml error. '" + str + "'");
        }

        
        static public function errorUnknown(str:String) : Error
        {
            return new Error("Translator error : Unknown. "+str);
        }
    }
}

