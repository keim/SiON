//----------------------------------------------------------------------------------------------------
// MML parser class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import flash.utils.getTimer;
    
    /** MML parser class. */
    public class MMLParser
    {
    // tables
    //--------------------------------------------------
        static private var _keySignitureTable:Array = [
            Vector.<int>([ 0, 0, 0, 0, 0, 0, 0]),
            Vector.<int>([ 0, 0, 0, 1, 0, 0, 0]),
            Vector.<int>([ 1, 0, 0, 1, 0, 0, 0]),
            Vector.<int>([ 1, 0, 0, 1, 1, 0, 0]),
            Vector.<int>([ 1, 1, 0, 1, 1, 0, 0]),
            Vector.<int>([ 1, 1, 0, 1, 1, 1, 0]),
            Vector.<int>([ 1, 1, 1, 1, 1, 1, 0]),
            Vector.<int>([ 1, 1, 1, 1, 1, 1, 1]),
            Vector.<int>([ 0, 0, 0, 0, 0, 0,-1]),
            Vector.<int>([ 0, 0,-1, 0, 0, 0,-1]),
            Vector.<int>([ 0, 0,-1, 0, 0,-1,-1]),
            Vector.<int>([ 0,-1,-1, 0, 0,-1,-1]),
            Vector.<int>([ 0,-1,-1, 0,-1,-1,-1]),
            Vector.<int>([-1,-1,-1, 0,-1,-1,-1]),
            Vector.<int>([-1,-1,-1,-1,-1,-1,-1])
        ];
        
        
        
        
    // valiables
    //--------------------------------------------------
        // settting
        static private var _setting:MMLParserSetting = null;
        
        // MML string
        static private var _mmlString:String = null;
        
        // user defined event map.
        static private var _userDefinedEventID:Object = null;
        
        // system event strings
        static private var _systemEventStrings:Vector.<String> = new Vector.<String>(32);
        static private var _sequenceMMLStrings:Vector.<String> = new Vector.<String>(32);
        
        // flag list of global event
        static private var _globalEventFlags:Vector.<Boolean> = null;
        
        // temporaries
        static private var _freeEventChain:MMLEvent = null;

        static private var _interruptInterval:int     = 0;
        static private var _startTime:int             = 0;
        static private var _parsingTime:int           = 0;
        
        static private var _staticLength:int          = 0;
        static private var _staticOctave:int          = 0;
        static private var _staticNoteShift:int       = 0;
        static private var _isLastEventLength:Boolean = false;
        static private var _systemEventIndex:int      = 0;
        static private var _sequenceMMLIndex:int      = 0;
        static private var _headMMLIndex:int          = 0;
        static private var _cacheMMLString:Boolean    = false;
        
        static private var _keyScale    :Vector.<int> = Vector.<int>([0,2,4,5,7,9,11]);
        static private var _keySigniture:Vector.<int> = _keySignitureTable[0];
        static private var _keySignitureCustom:Vector.<int> = new Vector.<int>(7, true);
        static private var _terminator      :MMLEvent = new MMLEvent();
        static private var _lastEvent       :MMLEvent = null;
        static private var _lastSequenceHead:MMLEvent = null;
        static private var _repeatStac:Array          = [];
        
        
        
        
    // properties
    //--------------------------------------------------
        /** Key signiture for all notes. The letter for key signiture is expressed as /[A-G][+\-#b]?m?/. */
        static public function set keySign(sign:String) : void
        {
            var note:int, i:int, list:Array, shift:String, noteLetters:String = "cdefgab";
            switch(sign) {
            case '':
            case 'C':   case 'Am':                          _keySigniture = _keySignitureTable[0];  break;
            case 'G':   case 'Em':                          _keySigniture = _keySignitureTable[1];  break;
            case 'D':   case 'Bm':                          _keySigniture = _keySignitureTable[2];  break;
            case 'A':   case 'F+m': case 'F#m':             _keySigniture = _keySignitureTable[3];  break;
            case 'E':   case 'C+m': case 'C#m':             _keySigniture = _keySignitureTable[4];  break;
            case 'B':   case 'G+m': case 'G#m':             _keySigniture = _keySignitureTable[5];  break;
            case 'F+':  case 'F#':  case 'D+m': case 'D#m': _keySigniture = _keySignitureTable[6];  break;
            case 'C+':  case 'C#':  case 'A+m': case 'A#m': _keySigniture = _keySignitureTable[7];  break;
            case 'F':   case 'Dm':                          _keySigniture = _keySignitureTable[8];  break;
            case 'B-':  case 'Bb':  case 'Gm':              _keySigniture = _keySignitureTable[9];  break;
            case 'E-':  case 'Eb':  case 'Cm':              _keySigniture = _keySignitureTable[10]; break;
            case 'A-':  case 'Ab':  case 'Fm':              _keySigniture = _keySignitureTable[11]; break;
            case 'D-':  case 'Db':  case 'B-m': case 'Bbm': _keySigniture = _keySignitureTable[12]; break;
            case 'G-':  case 'Gb':  case 'E-m': case 'Ebm': _keySigniture = _keySignitureTable[13]; break;
            case 'C-':  case 'Cb':  case 'A-m': case 'Abm': _keySigniture = _keySignitureTable[14]; break;
            default:
                for (i=0; i<7; i++) { _keySignitureCustom[i] = 0; }
                list = sign.split(/[\s,]/);
                for (i=0; i<list.length; i++) {
                    note = noteLetters.indexOf(list.charAt(0).toLowerCase());
                    if (note == -1) throw errorKeySign(sign);
                    if (list.length > 1) {
                        shift = list.charAt(1);
                        _keySignitureCustom[note] = (shift=='+' || shift=='#') ? 1 : (shift=='-' || shift=='b') ? -1 : 0;
                    } else {
                        _keySignitureCustom[note] = 0;
                    }
                }
                _keySigniture = _keySignitureCustom;
            }
        }
        
        
        /** Parsing progression (0-1). */
        static public function get parseProgress() : Number
        {
            if (_mmlString != null) {
                return _mmlRegExp.lastIndex / (_mmlString.length+1);
            }
            return 0;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructer do nothing. */
        function MMLParser()
        {
        }
        
        
        
        
    // allocator
    //--------------------------------------------------
        /** @private [internal] Free all events in the sequence. */
        static internal function _freeAllEvents(seq:MMLSequence) : void
        {
            if (seq.headEvent == null) return;
            
            // connect to free list
            seq.tailEvent.next = _freeEventChain;
            
            // update head of free list
            _freeEventChain = seq.headEvent;

            // clear
            seq.headEvent = null;
            seq.tailEvent = null;
        }
        
        
        /** @private [internal] Free event. */
        static internal function _freeEvent(e:MMLEvent) : MMLEvent
        {
            var next:MMLEvent = e.next;
            e.next = _freeEventChain;
            _freeEventChain = e;
            return next;
        }
        
        
        /** @private [internal] allocate event */
        static internal function _allocEvent(id:int, data:int, length:int=0) : MMLEvent
        {
            if (_freeEventChain) {
                var e:MMLEvent = _freeEventChain;
                _freeEventChain = _freeEventChain.next;
                return e.initialize(id, data, length);
            }
            return (new MMLEvent()).initialize(id, data, length);
        }
        
        
        
        
    // settting
    //--------------------------------------------------
        /** @private [internal] Set map of user defined ids. */
        static internal function _setUserDefinedEventID(map:Object) : void
        {
            if (_userDefinedEventID !== map) {
                _userDefinedEventID = map;
                _mmlRegExp = null;
            }
        }
        
        
        /** @private [internal] Set array of global event flags. */
        static internal function _setGlobalEventFlags(flags:Vector.<Boolean>) : void
        {
            _globalEventFlags = flags;
        }
        
        
        
        
    // public operation
    //--------------------------------------------------
        /* Add new event. */
        static public function addMMLEvent(id:int, data:int=0, length:int=0, noteOption:Boolean=false) : MMLEvent
        {
            if (!noteOption) {
                // Make channel data chain
                if (id == MMLEvent.SEQUENCE_HEAD) {
                    _lastSequenceHead.jump = _lastEvent;
                    _lastSequenceHead = _pushMMLEvent(id, data, length);
                    _initialize_track();
                } else
                // Concatinate REST event
                if (id == MMLEvent.REST && _lastEvent.id == MMLEvent.REST) {
                    _lastEvent.length += length;
                } else {
                    _pushMMLEvent(id, data, length);
                    // seqHead.data is the count of global events
                    if (_globalEventFlags[id]) _lastSequenceHead.data++;
                }
            } else {
                // note option event is inserted after NOTE .
                if (_lastEvent.id == MMLEvent.NOTE) {
                    length = _lastEvent.length;
                    _lastEvent.length = 0;
                    _pushMMLEvent(id, data, length);
                } else {
                    // Error when there is no NOTE before SLUR event.
                    throw errorSyntax("* or &");
                }
            }
            
            _isLastEventLength = false;
            return _lastEvent;
        }
        
        
        /** Get MMLEvent id by mml command letter. 
         *  @param mmlCommand letter of MML command.
         *  @return Event id. Returns 0 if not found.
         */
        static public function getEventID(mmlCommand:String) : int
        {
            switch (mmlCommand) {
            case 'c': case 'd': case 'e': case 'f': case 'g': case 'a': case 'b':   return MMLEvent.NOTE;
            case 'r':   return MMLEvent.REST;
            case 'q':   return MMLEvent.QUANT_RATIO;
            case '@q':  return MMLEvent.QUANT_COUNT;
            case 'v':   return MMLEvent.VOLUME;
            case '@v':  return MMLEvent.FINE_VOLUME;
            case '%':   return MMLEvent.MOD_TYPE;
            case '@':   return MMLEvent.MOD_PARAM;
            case '@i':  return MMLEvent.INPUT_PIPE;
            case '@o':  return MMLEvent.OUTPUT_PIPE;
            case '(':   case ')':   return MMLEvent.VOLUME_SHIFT;
            case '&':   return MMLEvent.SLUR;
            case '&&':  return MMLEvent.SLUR_WEAK;
            case '*':   return MMLEvent.PITCHBEND;
            case ',':   return MMLEvent.PARAMETER;
            case '$':   return MMLEvent.REPEAT_ALL;
            case '[':   return MMLEvent.REPEAT_BEGIN;
            case ']':   return MMLEvent.REPEAT_END;
            case '|':   return MMLEvent.REPEAT_BREAK;
            case 't':   return MMLEvent.TEMPO;
            }
            return 0;
        }
        
        
        /** @private [internal] get command letters. */
        static internal function _getCommandLetters(list:Array) : void
        {
            list[MMLEvent.NOTE] = 'c'
            list[MMLEvent.REST] = 'r';
            list[MMLEvent.QUANT_RATIO] = 'q';
            list[MMLEvent.QUANT_COUNT] = '@q';
            list[MMLEvent.VOLUME] = 'v';
            list[MMLEvent.FINE_VOLUME] = '@v';
            list[MMLEvent.MOD_TYPE] = '%';
            list[MMLEvent.MOD_PARAM] = '@';
            list[MMLEvent.INPUT_PIPE] = '@i';
            list[MMLEvent.OUTPUT_PIPE] = '@o';
            list[MMLEvent.VOLUME_SHIFT] = '(';
            list[MMLEvent.SLUR] = '&';
            list[MMLEvent.SLUR_WEAK] = '&&';
            list[MMLEvent.PITCHBEND] = '*';
            list[MMLEvent.PARAMETER] = ',';
            list[MMLEvent.REPEAT_ALL] = '$';
            list[MMLEvent.REPEAT_BEGIN] = '[';
            list[MMLEvent.REPEAT_END] = ']';
            list[MMLEvent.REPEAT_BREAK] = '|';
            list[MMLEvent.TEMPO] = 't';
        }
        
        
        /** @private [internal] get system event string */
        static internal function _getSystemEventString(e:MMLEvent) : String
        {
            return _systemEventStrings[e.data];
        }
        
        
        /** @private [internal] get sequence mml string */
        static internal function _getSequenceMML(e:MMLEvent) : String
        {
            return (e.length == -1) ? "" : _sequenceMMLStrings[e.length];
        }
        

        // push event
        static private function _pushMMLEvent(id:int, data:int, length:int) : MMLEvent
        {
            _lastEvent.next = _allocEvent(id, data, length);
            _lastEvent = _lastEvent.next;
            return _lastEvent;
        }
        

        // register system event string
        static private function _regSystemEventString(str:String) : int
        {
            if (_systemEventStrings.length <= _systemEventIndex) _systemEventStrings.length = _systemEventStrings.length * 2;
            _systemEventStrings[_systemEventIndex++] = str;
            return _systemEventIndex - 1;
        }
        
        
        // register sequence MML string
        static private function _regSequenceMMLStrings(str:String) : int
        {
            if (_sequenceMMLStrings.length <= _sequenceMMLIndex) _sequenceMMLStrings.length = _sequenceMMLStrings.length * 2;
            _sequenceMMLStrings[_sequenceMMLIndex++] = str;
            return _sequenceMMLIndex - 1;
        }
        
        
        
    // regular expression
    //--------------------------------------------------
        static private const REX_WHITESPACE:int = 1;
        static private const REX_SYSTEM    :int = 2;
        static private const REX_COMMAND   :int = 3;
        static private const REX_NOTE      :int = 4;
        static private const REX_SHIFT_NOTE:int = 5;
        static private const REX_USER_EVENT:int = 6;
        static private const REX_EVENT     :int = 7;
        static private const REX_TABLE     :int = 8;
        static private const REX_PARAM     :int = 9;
        static private const REX_PERIOD    :int = 10;
        static private var _mmlRegExp:RegExp = null;
        static private function createRegExp(reset:Boolean) : RegExp
        {
            if (_mmlRegExp == null) {
                // user defined event letters
                var ude:Array = [];
                for (var letter:String in _userDefinedEventID) { ude.push(letter); }
                var uderex:String = (ude.length > 0) ? (ude.sort(Array.DESCENDING).join('|')) : 'a';    // ('A`) I know its an ad-hok solution...
                
                var rex:String;
                rex  = "(\\s+)";                                            // whitespace (res[1])
                rex += "|(#[^;]*)";                                         // system (res[2])
                rex += "|(";                                                // --all-- (res[3])
                    rex += "([a-g])([\\-+#]?)";                                 // note (res[4],[5])
                    rex += "|(" + uderex + ")";                                 // module events (res[6])
                    rex += "|(@[qvio]?|&&|!@ns|[rlqovt^<>()\\[\\]/|$%&*,;])";   // default events (res[7])
                    rex += "|(\\{.*?\\}[0-9]*\\*?[\\-0-9.]*\\+?[\\-0-9.]*)";    // table event (res[8])
                rex += ")\\s*(-?[0-9]*)"                                    // parameter (res[9])
                rex += "\\s*(\\.*)"                                         // periods (res[10])
                _mmlRegExp = new RegExp(rex, 'gms');
            }
            
            // reset last index
            if (reset) _mmlRegExp.lastIndex = 0;
            return _mmlRegExp;
        }
        
        
        
        
    // parser
    //--------------------------------------------------
        /** Prepare to parse. 
         *  @param mml MML String.
         *  @return Returns head MMLEvent. The return value of null means no head event.
         */
        static public function prepareParse(setting:MMLParserSetting, mml:String) : void
        {
            // set internal parameters
            _setting   = setting;
            _mmlString = mml;
            _parsingTime = getTimer();
            // create RegExp
            createRegExp(true);
            // initialize
            _initialize();
        }
        
        
        /** Parse mml string. 
         *  @param  interrupt Interrupting interval [ms]. 0 means no interruption. The interrupt appears between each sequence.
         *  @return Returns head MMLEvent. The return value of null means no head event.
         */
        static public function parse(interrupt:int=0) : MMLEvent
        {
            var shift:int, note:int, halt:Boolean, rex:RegExp, res:*,
                mml2nn:int = _setting.mml2nn,
                codeC:int = "c".charCodeAt();
            
            // set interrupting interval
            _interruptInterval = interrupt;
            _startTime         = getTimer();
            
            // regular expression
            rex = createRegExp(false);
            
            // parse
            halt = false;
            res = rex.exec(_mmlString);
            while (res && String(res[0]).length>0) {
                // skip comments
                if (res[REX_WHITESPACE] == undefined) {
                    if (res[REX_NOTE]) {
                        // note events.
                        note  = String(res[REX_NOTE]).charCodeAt() - codeC;
                        if (note < 0) note += 7;
                        shift = _keySigniture[note];
                        switch(String(res[REX_SHIFT_NOTE])) {
                        case '+':   case '#':   shift++;    break;
                        case '-':               shift--;    break;
                        }
                        _note(_keyScale[note] + shift + mml2nn, __calcLength(), __period());
                    } else 
                    if (res[REX_USER_EVENT]) {
                        // user defined events.
                        if (!String(res[REX_USER_EVENT]) in _userDefinedEventID) throw errorUnknown("REX_USER_EVENT");
                        addMMLEvent(_userDefinedEventID[String(res[REX_USER_EVENT])], __param());
                    } else
                    if (res[REX_EVENT]) {
                        // default events.
                        switch(String(res[REX_EVENT])) {
                        case 'r':   _rest     (__calcLength(), __period());          break;
                        case 'l':   _length   (__calcLength(), __period());          break;
                        case '^':   _tie      (__calcLength(), __period());          break;
                        case 'o':   _octave   (__param(_setting.defaultOctave));     break;
                        case 'q':   _quant    (__param(_setting.defaultQuantRatio)); break;
                        case '@q':  _at_quant (__param(_setting.defaultQuantCount)); break;
                        case 'v':   _volume   (__param(_setting.defaultVolume));     break;
                        case '@v':  _at_volume(__param(_setting.defaultFineVolume)); break;
                        case '%':   _mod_type (__param());                           break;
                        case '@':   _mod_param(__param());                           break;
                        case '@i':  _input (__param(0));        break;
                        case '@o':  _output(__param(0));        break;
                        case '(':   _volumeShift( __param(1));  break;
                        case ')':   _volumeShift(-__param(1));  break;
                        case '<':   _octaveShift( __param(1));  break;
                        case '>':   _octaveShift(-__param(1));  break;
                        case '&':   _slur();                    break;
                        case '&&':  _slurweak();                break;
                        case '*':   _portament();               break;
                        case ',':   _parameter(__param());      break;
                        case ';':   halt = _end_sequence();     break;
                        case '$':   _repeatPoint();             break;
                        case '[':   _repeatBegin(__param(2));   break;
                        case ']':   _repeatEnd(__param());      break;
                        case '|':   _repeatBreak();             break;
                        case '!@ns': _noteShift( __param(0));               break;
                        case 't':   _tempo(__param(_setting.defaultBPM));   break;
                        default:
                            throw errorUnknown("REX_EVENT;"+res[REX_EVENT]);
                            break;
                        }
                    } else 
                    if (res[REX_SYSTEM]) {
                        // system command is only available at the top of the channel sequence.
                        if (_lastEvent.id != MMLEvent.SEQUENCE_HEAD) throw errorSyntax(res[0]);
                        // add system event
                        addMMLEvent(MMLEvent.SYSTEM_EVENT, _regSystemEventString(res[REX_SYSTEM]));
                    } else
                    if (res[REX_TABLE]) {
                        // add table event
                        addMMLEvent(MMLEvent.TABLE_EVENT, _regSystemEventString(res[REX_TABLE]));
                    } else {
                        // syntax error
                        throw errorSyntax(res[0]);
                    }
                }
                
                // halt
                if (halt) return null;
                
                // parse next
                res = rex.exec(_mmlString);
            }
            
            // parsing complete
            // check repeating stac
            if (_repeatStac.length != 0) throw errorStacOverflow("[");
            // set last channel's last event.
            if (_lastEvent.id != MMLEvent.SEQUENCE_HEAD) _lastSequenceHead.jump = _lastEvent;

            // calculate parsing time
            _parsingTime = getTimer() - _parsingTime;

            // clear terminator
            var headEvent:MMLEvent = _terminator.next;
            _terminator.next = null;
            return headEvent;


        // internal functions
        //----------------------------------------
            // parse length. The return value of int.MIN_VALUE means abbreviation.
            function __calcLength() : int {
                if (String(res[REX_PARAM]).length == 0) return int.MIN_VALUE;
                var len:int = int(res[REX_PARAM]);
                if (len == 0) return 0;
                var iLength:int = _setting.resolution/len;
                if (iLength<1 || iLength>_setting.resolution) throw errorRangeOver("length", 1, _setting.resolution);
                return iLength;
            }
            
            // parse param.
            function __param(defaultValue:int = int.MIN_VALUE) : int {
                return (String(res[REX_PARAM]).length > 0) ? int(res[REX_PARAM]) : defaultValue;
            }
            
            // parse periods.
            function __period() : int {
                return String(res[REX_PERIOD]).length;
            }
        }
        
        
        // initialize before parse
        static private function _initialize() : void
        {
            // free all remains
            var e:MMLEvent = _terminator.next;
            while (e) { e = _freeEvent(e); }
            
            // initialize tempraries
            _systemEventIndex = 0;                                            // system event index
            _sequenceMMLIndex = 0;                                            // sequence mml index
            _lastEvent        = _terminator;                                  // clear event chain
            _lastSequenceHead = _pushMMLEvent(MMLEvent.SEQUENCE_HEAD, 0, 0);  // add first event (SEQUENCE_HEAD).
            if (_cacheMMLString) addMMLEvent(MMLEvent.DEBUG_INFO, -1);
            _initialize_track();
        }
        
        
        // initialize before starting new track.
        static private function _initialize_track() : void
        {
            _staticLength      = _setting.defaultLength;    // initialize l command value
            _staticOctave      = _setting.defaultOctave;    // initialize o command value
            _staticNoteShift   = 0;                         // initialize note shift
            _isLastEventLength = false;                     // initialize l command flag
            _repeatStac.length = 0;                         // clear repeating pointer stac
            _headMMLIndex      = _mmlRegExp.lastIndex;      // mml index of sequence head
        }
        
        
        
        
    // note
    //------------------------------
        // note
        static private function _note(note:int, iLength:int, period:int) : void
        {
            note += _staticOctave*12 + _staticNoteShift;
            if (note < 0) {
                //throw errorNoteOutofRange(note);
                note = 0;
            } else 
            if (note > 127) {
                //throw errorNoteOutofRange(note);
                note = 127;
            }
            addMMLEvent(MMLEvent.NOTE, note, __calcLength(iLength, period));
        }
        
        
        // rest
        static private function _rest(iLength:int, period:int) : void
        {
            addMMLEvent(MMLEvent.REST, 0, __calcLength(iLength, period));
        }
        
        
    // length operation
    //------------------------------
        // length
        static private function _length(iLength:int, period:int) : void
        {
            _staticLength = __calcLength(iLength, period);
            _isLastEventLength = true;
        }
        
        
        // tie
        static private function _tie(iLength:int, period:int) : void
        {
            if (_isLastEventLength) {
                _staticLength += __calcLength(iLength, period);
            } else 
            if (_lastEvent.id == MMLEvent.REST || _lastEvent.id == MMLEvent.NOTE) {
                _lastEvent.length += __calcLength(iLength, period);
            } else {
                throw errorSyntax("tie command");
            }
        }
        
        
        // slur
        static private function _slur() : void
        {
            addMMLEvent(MMLEvent.SLUR, 0, 0, true);
        }
        
        
        // weak slur
        static private function _slurweak() : void
        {
            addMMLEvent(MMLEvent.SLUR_WEAK, 0, 0, true);
        }
        
        
        // portament
        static private function _portament() : void
        {
            addMMLEvent(MMLEvent.PITCHBEND, 0, 0, true);
        }
        
        
        // gate time
        static private function _quant(param:int) : void
        {
            if (param<_setting.minQuantRatio || param>_setting.maxQuantRatio) {
                throw errorRangeOver("q", _setting.minQuantRatio, _setting.maxQuantRatio);
            }
            addMMLEvent(MMLEvent.QUANT_RATIO, param);
        }
        
        
        // absolute gate time
        static private function _at_quant(param:int) : void
        {
            if (param<_setting.minQuantCount || param>_setting.maxQuantCount) {
                throw errorRangeOver("@q", _setting.minQuantCount, _setting.maxQuantCount);
            }
            addMMLEvent(MMLEvent.QUANT_COUNT, param);
        }
        
        
        // calculate length
        static private function __calcLength(iLength:int, period:int) : int
        {
            // set default value
            if (iLength == int.MIN_VALUE) iLength = _staticLength;
            // extension by period
            var len:int = iLength;
            while (period>0) { iLength += len>>(period--); }
            return iLength;
        }
        
        
    // pitch operation
    //------------------------------
        // octave
        static private function _octave(param:int) : void
        {
            if (param<_setting.minOctave || param>_setting.maxOctave) {
                throw errorRangeOver("o", _setting.minOctave, _setting.maxOctave);
            }
            _staticOctave = param;
        }
        
        
        // octave shift
        static private function _octaveShift(param:int) : void
        {
            param *= _setting.octavePolarization;
            _staticOctave += param;
        }
        

        // note shift
        static private function _noteShift(param:int) : void
        {
            _staticNoteShift += param;
        }
        
        
        // volume
        static private function _volume(param:int) : void
        {
            if (param<0 || param>_setting.maxVolume) {
                throw errorRangeOver("v", 0, _setting.maxVolume);
            }
            addMMLEvent(MMLEvent.VOLUME, param);
        }
        
        
        // fine volume
        static private function _at_volume(param:int) : void
        {
            if (param<0 || param>_setting.maxFineVolume) {
                throw errorRangeOver("@v", 0, _setting.maxFineVolume);
            }
            addMMLEvent(MMLEvent.FINE_VOLUME, param);
        }
        
        
        // volume shift
        static private function _volumeShift(param:int) : void
        {
            param *= _setting.volumePolarization;
            if (_lastEvent.id == MMLEvent.VOLUME_SHIFT || _lastEvent.id == MMLEvent.VOLUME) {
                _lastEvent.data += param;
            } else {
                addMMLEvent(MMLEvent.VOLUME_SHIFT, param);
            }
        }
        
        
    // repeating
    //------------------------------
        // repeat point
        static private function _repeatPoint() : void
        {
            addMMLEvent(MMLEvent.REPEAT_ALL, 0);
        }
        
        
        // begin repeating
        static private function _repeatBegin(rep:int) : void
        {
            if (rep < 1 || rep > 65535) throw errorRangeOver("[", 1, 65535);
            addMMLEvent(MMLEvent.REPEAT_BEGIN, rep, 0);
            _repeatStac.unshift(_lastEvent);
        }
        
        
        // break repeating
        static private function _repeatBreak() : void
        {
            if (_repeatStac.length == 0) throw errorStacUnderflow("|");
            addMMLEvent(MMLEvent.REPEAT_BREAK);
            _lastEvent.jump = MMLEvent(_repeatStac[0]);
        }
        
        
        // end repeating
        static private function _repeatEnd(rep:int) : void
        {
            if (_repeatStac.length == 0) throw errorStacUnderflow("]");
            addMMLEvent(MMLEvent.REPEAT_END);
            var beginEvent:MMLEvent = MMLEvent(_repeatStac.shift());
            _lastEvent.jump = beginEvent;   // rep_end.jump   = rep_start
            beginEvent.jump = _lastEvent;   // rep_start.jump = rep_end
            
            // update repeat count
            if (rep != int.MIN_VALUE) {
                if (rep < 1 || rep > 65535) throw errorRangeOver("]", 1, 65535);
                beginEvent.data = rep;
            }
        }
        
        
    // others
    //------------------------------
        // module type
        static private function _mod_type(param:int) : void
        {
            addMMLEvent(MMLEvent.MOD_TYPE, param);
        }
        
        
        // module parameters
        static private function _mod_param(param:int) : void
        {
            addMMLEvent(MMLEvent.MOD_PARAM, param);
        }
        
        
        // set input pipe
        static private function _input(param:int) : void
        {
            addMMLEvent(MMLEvent.INPUT_PIPE, param);
        }
        
        
        // set output pipe
        static private function _output(param:int) : void
        {
            addMMLEvent(MMLEvent.OUTPUT_PIPE, param);
        }
        
        
        // pural parameters
        static private function _parameter(param:int) : void
        {
            addMMLEvent(MMLEvent.PARAMETER, param);
        }
        
        
        // sequence change
        static private function _end_sequence() : Boolean
        {
            if (_lastEvent.id != MMLEvent.SEQUENCE_HEAD) {
                if (_lastSequenceHead.next && _lastSequenceHead.next.id == MMLEvent.DEBUG_INFO) {
                    // memory sequence MMLs id in _lastSequenceHead.next.data
                    _lastSequenceHead.next.data = _regSequenceMMLStrings(_mmlString.substring(_headMMLIndex, _mmlRegExp.lastIndex));
                }
                addMMLEvent(MMLEvent.SEQUENCE_HEAD, 0);
                if (_cacheMMLString) addMMLEvent(MMLEvent.DEBUG_INFO, -1);
                // Returns true when it has to interrupt.
                if (_interruptInterval == 0) return false;
                return (_interruptInterval < (getTimer() - _startTime));
            }
            return false;
        }
        
        
        // tempo
        static private function _tempo(t:int) : void
        {
            addMMLEvent(MMLEvent.TEMPO, t);
        }
        
        
        
        
    // errors
    //--------------------------------------------------
        static public function errorUnknown(n:String) : Error
        {
            return new Error("MMLParser Error : Unknown error #" + n + ".");
        }
        

        static public function errorNoteOutofRange(note:int) : Error
        {
            return new Error("MMLParser Error : Note #" + note + " is out of range.");
        }
        
        
        static public function errorSyntax(syn:String) : Error
        {
            return new Error("MMLParser Error : Syntax error '" + syn + "'.");
        }
        
        
        static public function errorRangeOver(cmd:String, min:int, max:int) : Error
        {
            return new Error("MMLParser Error : The parameter of '" + cmd + "' command must ragne from " + min + " to " + max + ".");
        }


        static public function errorStacUnderflow(cmd:String) : Error
        {
            return new Error("MMLParser Error : The stac of '" + cmd + "' command is underflow.");
        }
        
        
        static public function errorStacOverflow(cmd:String) : Error
        {
            return new Error("MMLParser Error : The stac of '" + cmd + "' command is overflow.");
        }
        
        
        static public function errorKeySign(ksign:String) : Error
        {
            return new Error("MMLParser Error : Cannot recognize '" + ksign + "' as a key signiture.");
        }
    }
}

