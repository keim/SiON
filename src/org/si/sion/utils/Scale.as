//----------------------------------------------------------------------------------------------------
// Scale class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils {
    /** Scale class. */
    public class Scale
    {
    // constants
    //--------------------------------------------------
        /** Scale table of C */
        static protected const ST_MAJOR:int            = 0x1ab5ab5;
        /** Scale table of Cm */
        static protected const ST_MINOR:int            = 0x15ad5ad;
        /** Scale table of Chm */
        static protected const ST_HARMONIC_MINOR:int   = 0x19ad9ad;
        /** Scale table of Cmm */
        static protected const ST_MELODIC_MINOR:int    = 0x1aadaad;
        /** Scale table of Cp */
        static protected const ST_PENTATONIC:int       = 0x1295295;
        /** Scale table of Cmp */
        static protected const ST_MINOR_PENTATONIC:int = 0x14a94a9;
        /** Scale table of Cb */
        static protected const ST_BLUE_NOTE:int        = 0x14e94e9;
        /** Scale table of Cd */
        static protected const ST_DIMINISH:int         = 0x1249249;
        /** Scale table of Ccd */
        static protected const ST_COMB_DIMINISH:int    = 0x16db6db;
        /** Scale table of Cw */
        static protected const ST_WHOLE_TONE:int       = 0x1555555;
        /** Scale table of Cc */
        static protected const ST_CHROMATIC:int        = 0x1ffffff;
        /** Scale table of Csus4 */
        static protected const ST_PERFECT:int          = 0x10a10a1;
        /** Scale table of Csus47 */
        static protected const ST_DPERFECT:int         = 0x14a14a1;
        /** Scale table of C5 */
        static protected const ST_POWER:int            = 0x1081081;
        /** Scale table of Cu */
        static protected const ST_UNISON:int           = 0x1001001;
        /** Scale table of Cdor */
        static protected const ST_DORIAN:int           = 0x16ad6ad;
        /** Scale table of Cphr */
        static protected const ST_PHRIGIAN:int         = 0x15ab5ab;
        /** Scale table of Clyd */
        static protected const ST_LYDIAN:int           = 0x1ad5ad5;
        /** Scale table of Cmix */
        static protected const ST_MIXOLYDIAN:int       = 0x16b56b5;
        /** Scale table of Cloc */
        static protected const ST_LOCRIAN:int          = 0x156b56b;
        /** Scale table of Cgyp */
        static protected const ST_GYPSY:int            = 0x19b39b3;
        /** Scale table of Cspa */
        static protected const ST_SPANISH:int          = 0x15ab5ab;
        /** Scale table of Chan */
        static protected const ST_HANGARIAN:int        = 0x1acdacd;
        /** Scale table of Cjap */
        static protected const ST_JAPANESE:int         = 0x14a54a5;
        /** Scale table of Cryu */
        static protected const ST_RYUKYU:int           = 0x18b18b1;
        
        /** scale table dictionary */
        static protected var _scaleTableDictionary:* = {
            "m"    : ST_MINOR,
            "nm"   : ST_MINOR,
            "aeo"  : ST_MINOR,
            "hm"   : ST_HARMONIC_MINOR,
            "mm"   : ST_MELODIC_MINOR,
            "p"    : ST_PENTATONIC,
            "mp"   : ST_MINOR_PENTATONIC,
            "b"    : ST_BLUE_NOTE,
            "d"    : ST_DIMINISH,
            "cd"   : ST_COMB_DIMINISH,
            "w"    : ST_WHOLE_TONE,
            "c"    : ST_CHROMATIC,
            "sus4" : ST_PERFECT,
            "sus47": ST_DPERFECT,
            "5"    : ST_POWER,
            "u"    : ST_UNISON,
            "dor"  : ST_DORIAN,
            "phr"  : ST_PHRIGIAN,
            "lyd"  : ST_LYDIAN,
            "mix"  : ST_MIXOLYDIAN,
            "loc"  : ST_LOCRIAN,
            "gyp"  : ST_GYPSY,
            "spa"  : ST_SPANISH,
            "han"  : ST_HANGARIAN,
            "jap"  : ST_JAPANESE,
            "ryu"  : ST_RYUKYU
        };
        
        /** note names */
        static protected var _noteNames:Array = ["C", "C+", "D", "D+", "E", "F", "F+", "G", "G+", "A", "A+", "B"];
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** scale table */
        protected var _scaleTable:int;
        /** notes on the scale */
        protected var _scaleNotes:Vector.<int>;
        /** notes on 1octave upper scale*/
        protected var _tensionNotes:Vector.<int>;
        /** scale name */
        protected var _scaleName:String;
        /** default center octave, this apply when there are no octave specification. */
        protected var _defaultCenterOctave:int;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** Scale name.
         *  The regular expression of name is /(o[0-9])?([A-Ga-g])([+#\-])?([a-z0-9]+)?/.<br/>
         *  The 1st letter means center octave. default octave = 5 (when omit).<br/>
         *  The 2nd letter means root note.<br/>
         *  The 3nd letter (option) means note shift sign. "+" and "#" shift +1, "-" shifts -1.<br/>
         *  The 4th letters (option) means scale as follows.<br/>
         *  <table>
         *  <tr><th>the 3rd letters</th><th>scale</th></tr>
         *  <tr><td>(no matching), ion</td><td>Major scale</td></tr>
         *  <tr><td>m, nm, aeo</td><td>Natural minor scale</td></tr>
         *  <tr><td>hm</td><td>Harmonic minor scale</td></tr>
         *  <tr><td>mm</td><td>Melodic minor scale</td></tr>
         *  <tr><td>p</td><td>Pentatonic scale</td></tr>
         *  <tr><td>mp</td><td>Minor pentatonic scale</td></tr>
         *  <tr><td>b</td><td>Blue note scale</td></tr>
         *  <tr><td>d</td><td>Diminish scale</td></tr>
         *  <tr><td>cd</td><td>Combination of diminish scale</td></tr>
         *  <tr><td>w</td><td>Whole tone scale</td></tr>
         *  <tr><td>c</td><td>Chromatic scale</td></tr>
         *  <tr><td>sus4</td><td>table of sus4 chord</td></tr>
         *  <tr><td>sus47</td><td>table of sus47 chord</td></tr>
         *  <tr><td>5</td><td>Power chord</td></tr>
         *  <tr><td>u</td><td>Unison (octave scale)</td></tr>
         *  <tr><td>dor</td><td>Dorian mode</td></tr>
         *  <tr><td>phr</td><td>Phrigian mode</td></tr>
         *  <tr><td>lyd</td><td>Lydian mode</td></tr>
         *  <tr><td>mix</td><td>Mixolydian mode</td></tr>
         *  <tr><td>loc</td><td>Locrian mode</td></tr>
         *  <tr><td>gyp</td><td>Gypsy scale</td></tr>
         *  <tr><td>spa</td><td>Spanish scale</td></tr>
         *  <tr><td>han</td><td>Hangarian scale</td></tr>
         *  <tr><td>jap</td><td>Japanese scale (Ritsu mode)</td></tr>
         *  <tr><td>ryu</td><td>Japanese scale (Ryukyu mode)</td></tr>
         *  </table>
         *  If you want to set "G sharp harmonic minor scale", name = "G+hm".
         */
        public function get name() : String { return _noteNames[_scaleNotes[0]%12] + _scaleName; }
        public function set name(str:String) : void {
            if (str == null || str == "") {
                _scaleName = "";
                _scaleTable = ST_MAJOR;
                this.rootNote = _defaultCenterOctave*12;
                return;
            }
            
            var rex:RegExp = /(o[0-9])?([A-Ga-g])([+#\-b])?([a-z0-9]+)?/;
            var mat:* = rex.exec(str);
            var i:int;
            if (mat) {
                _scaleName = str;
                var note:int = [9,11,0,2,4,5,7][String(mat[2]).toLowerCase().charCodeAt() - 'a'.charCodeAt()];
                if (mat[3]) {
                    if (mat[3]=='+' || mat[3]=='#') note++;
                    else if (mat[3]=='-') note--;
                }
                if (note < 0) note += 12;
                else if (note > 11) note -= 12;
                if (mat[1]) note += int(mat[1].charAt(1)) * 12;
                else note += _defaultCenterOctave*12;
                
                if (mat[4]) {
                    if (!(mat[4] in _scaleTableDictionary)) throw _errorInvalidScaleName(str);
                    _scaleTable = _scaleTableDictionary[mat[4]];
                    _scaleName = mat[4];
                } else {
                    _scaleTable = ST_MAJOR;
                    _scaleName = "";
                }
                this.rootNote = note;
            } else {
                throw _errorInvalidScaleName(str);
            }
        }
        
        
        /** center octave */
        public function get centerOctave() : int { return int(_scaleNotes[0]/12); }
        public function set centerOctave(oct:int) : void {
            _defaultCenterOctave = oct;
            var prevoct:int = int(_scaleNotes[0]/12);
            if (prevoct == oct) return;
            var i:int, offset:int = (oct - prevoct) * 12;
            for (i=0; i<_scaleNotes.length; i++) _scaleNotes[i] += offset;
            for (i=0; i<_tensionNotes.length; i++) _tensionNotes[i] += offset;
        }
        
        
        /** root note number */
        public function get rootNote() : int { return _scaleNotes[0]; }
        public function set rootNote(note:int) : void {
            _scaleNotes.length = 0;
            _tensionNotes.length = 0;
            for (var i:int=0; i<12; i++) if (_scaleTable & (1<<i)) _scaleNotes.push(i + note);
            for (; i<24; i++) if (_scaleTable & (1<<i)) _tensionNotes.push(i + note);
        }
        
        
        /** bass note number */
        public function get bassNote() : int { return _scaleNotes[0]; }
        public function set bassNote(note:int) : void { rootNote = note; }
        
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor 
         *  @param scaleName scale name.
         *  @param defaultCenterOctave default center octave, this apply when there are no octave specification.
         *  @see #scaleName
         */
        function Scale(scaleName:String = "", defaultCenterOctave:int = 5)
        {
            _scaleNotes = new Vector.<int>();
            _tensionNotes = new Vector.<int>();
            _defaultCenterOctave = defaultCenterOctave;
            this.name = scaleName;
        }
        
        
        /** set scale table manualy.
         *  @param name name of this scale.
         *  @param rootNote root note of this scale.
         *  @table Boolean table of available note on this scale. The length is 12. The index of 0 is root note.
@example If you want to set "F japanese scale (1 2 4 5 b7)".<br/>
<listing version="3.0">
    var table:Array = [1,0,1,0,0,1,0,1,0,0,1,0];  // c,d,f,g,b- is available on "C japanese scale".
    scale.setScaleTable("Fjap", 65, table);       // 65="F"s note number
</listing>
         */
        public function setScaleTable(name:String, rootNote:int, table:Array) : void
        {
            _scaleName = name;
            var i:int, imax:int = (table.length<25) ? table.length : 25;
            _scaleTable = 0;
            for (i=0; i<imax; i++) if (table[i]) _scaleTable |= (1<<i);
            this.rootNote = rootNote;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** check note availability on this scale. 
         *  @param note MIDI note number (0-127).
         *  @return Returns true if the note is on this scale.
         */
        public function check(note:int) : Boolean
        {
            note -= _scaleNotes[0];
                 if (note < 0)  note = (note + 144) % 12;
            else if (note > 24) note = ((note - 12) % 12) + 12;
            return ((_scaleTable & (1<<note)) != 0);
        }
        
        
        /** shift note to the nearest note on this scale. 
         *  @param note MIDI note number (0-127).
         *  @return Returns shifted note. if the note is on this scale, no shift.
         */
        public function shift(note:int) : int
        {
            var n:int = note - _scaleNotes[0];
                 if (n < 0)  n = (n + 144) % 12;
            else if (n > 23) n = ((n - 12) % 12) + 12;
            if ((_scaleTable & (1<<n)) != 0) return note;
            var up:int, dw:int;
            for (up=n+1; up<24 && (_scaleTable & (1<<up)) == 0;) up++; 
            for (dw=n-1; dw>=0 && (_scaleTable & (1<<dw)) == 0;) dw--; 
            return note - n + (((n-dw)<=(up-n)) ? dw : up);
        }
        
        
        /** get scale index from note. */
        public function getScaleIndex(note:int) : int
        {
            return 0;
        }
        
        
        /** get note by index on this scale.
         *  @param index index on this scale. You can specify both posi and nega values.
         *  @return MIDI note number on this scale.
         */
        public function getNote(index:int) : int
        {
            var imax:int = _scaleNotes.length, octaveShift:int = 0;
            if (index < 0) {
                octaveShift = int((index-imax+1)/ imax);
                index -= octaveShift * imax;
                return _scaleNotes[index] + octaveShift*12;
            }
            if (index < imax) {
                return _scaleNotes[index];
            }
            
            index -= imax;
            imax = _tensionNotes.length;
            if (index < imax) {
                return _tensionNotes[index];
            }
            
            octaveShift = int(index / imax);
            index -= octaveShift * imax;
            return _tensionNotes[index] + octaveShift*12;
        }
        
        
        /** copy from another scale
         *  @param src another Scale instance copy from
         */
        public function copyFrom(src:Scale) : Scale
        {
            _scaleName = src._scaleName;
            _scaleTable = src._scaleTable;
            var i:int, imax:int = src._scaleNotes.length;
            _scaleNotes.length = imax;
            for (i=0; i<imax; i++) {
                _scaleNotes[i] = src._scaleNotes[i];
            }
            imax = src._tensionNotes.length;
            _tensionNotes.length = imax;
            for (i=0; i<imax; i++) {
                _tensionNotes[i] = src._tensionNotes[i];
            }
            return this;
        }
        
        
        
        
    // errors
    //--------------------------------------------------
        /** Invalid scale name error */
        protected function _errorInvalidScaleName(name:String) : Error
        {
            return new Error("Scale; Invalid scale name. '" + name +"'");
        }
    }
}


