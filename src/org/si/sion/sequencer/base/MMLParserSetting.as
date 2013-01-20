//----------------------------------------------------------------------------------------------------
// MML parser setting class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    /** Informations for MMLParser
     *  @see org.si.sion.sequencer.base.MMLParser
     */
    public class MMLParserSetting
    {
    // valiables
    //--------------------------------------------------
        /** Resolution of note length. 'resolution/4' is a length of a beat. */
        public var resolution       :int;
        private var _mml2nn         :int;
        /** Default value of beat per minutes. */
        public var defaultBPM       :Number;
        
        /** Default value of the l command. */
        public var defaultLValue    :int;
        /** Minimum ratio of the q command. */
        public var minQuantRatio     :int;
        /** Maximum ratio of the q command. */
        public var maxQuantRatio     :int;
        /** Default value of the q command. */
        public var defaultQuantRatio :int;
        /** Minimum value of the @q command. */
        public var minQuantCount     :int;
        /** Maximum value of the @q command. */
        public var maxQuantCount     :int;
        /** Default value of the @q command. */
        public var defaultQuantCount :int;
        /** Maximum value of the v command. */
        public var maxVolume:int;
        /** Default value of the v command. */
        public var defaultVolume:int;
        /** Maximum value of the @v command. */
        public var maxFineVolume:int;
        /** Default value of the @v command. */
        public var defaultFineVolume:int;
        /** Minimum value of the o command. */
        public var minOctave        :int;
        /** Maximum value of the o command. */
        public var maxOctave        :int;
        private var _defaultOctave  :int;

        /** Polarization of the ( and ) command. 1=x68k/-1=pc98. */
        public var volumePolarization:int;
        /** Polarization of the &lt; and &gt; command. 1=x68k/-1=pc98. */
        public var octavePolarization:int;
        
        
        
    // properties
    //--------------------------------------------------        
        /** Offset from mml notes to MIDI note numbers. Calculated from defaultOctave. */        
        public function get mml2nn() : int { return _mml2nn; }
        
        /** Default value of length in mml event. */
        public function get defaultLength() : int { return resolution / defaultLValue; }
       
        /** Default value of the o command. */
        public function set defaultOctave(o:int) : void
        {
            _defaultOctave = o;
            _mml2nn = 60 - _defaultOctave * 12;
            var octaveLimit:int = int((128 - _mml2nn) / 12) - 1;
            if (maxOctave > octaveLimit) maxOctave = octaveLimit;
        }
        public function get defaultOctave() : int { return _defaultOctave; }
        
        
        
        
    // functions
    //--------------------------------------------------
        /** Constructor 
         *  @param initializer Initializing parameters by Object.
         */
        function MMLParserSetting(initializer:*=null)
        {
            initialize(initializer);
        }
        
        
        /** Initialize. Settings not specifyed in initializer are set as default.
         *  @param initializer Initializing parameters by Object.
         */
        public function initialize(initializer:*=null) : void
        {
            resolution = 1920;
            defaultBPM = 120;

            defaultLValue     =    4;
            minQuantRatio     =    0;
            maxQuantRatio     =    8;
            defaultQuantRatio =   10;
            minQuantCount     = -192;
            maxQuantCount     =  192;
            defaultQuantCount =    0;
            maxVolume         = 15;
            defaultVolume     = 10;
            maxFineVolume     = 127;
            defaultFineVolume = 127;
            minOctave     = 0;
            maxOctave     = 9;
            defaultOctave = 5;

            volumePolarization = 1;
            octavePolarization = 1;
            
            update(initializer);
        }
        
        
        /** update. Settings not specifyed in initializer are not changing.
         *  @param initializer Initializing parameters by Object.
         */
        public function update(initializer:*) : void
        {
            if (initializer == null) return;
            
            if (initializer.resolution       != undefined) resolution = initializer.resolution;
            if (initializer.defaultBPM       != undefined) defaultBPM = initializer.defaultBPM;

            if (initializer.defaultLValue     != undefined) defaultLValue = initializer.defaultLValue;
            if (initializer.minQuantRatio     != undefined) minQuantRatio = initializer.minQuantRatio;
            if (initializer.maxQuantRatio     != undefined) maxQuantRatio = initializer.maxQuantRatio;
            if (initializer.defaultQuantRatio != undefined) defaultQuantRatio = initializer.defaultQuantRatio;
            if (initializer.minQuantCount     != undefined) minQuantCount = initializer.minQuantCount;
            if (initializer.maxQuantCount     != undefined) maxQuantCount = initializer.maxQuantCount;
            if (initializer.defaultQuantCount != undefined) defaultQuantCount = initializer.defaultQuantCount;

            if (initializer.maxVolume         != undefined) maxVolume = initializer.maxVolume;
            if (initializer.defaultVolume     != undefined) defaultVolume = initializer.defaultVolume;
            if (initializer.maxFineVolume     != undefined) maxFineVolume = initializer.maxFineVolume;
            if (initializer.defaultFineVolume != undefined) defaultFineVolume = initializer.defaultFineVolume;

            if (initializer.minOctave     != undefined) minOctave = initializer.minOctave;
            if (initializer.maxOctave     != undefined) maxOctave = initializer.maxOctave;
            if (initializer.defaultOctave != undefined) defaultOctave = initializer.defaultOctave;

            if (initializer.volumePolarization != undefined) volumePolarization = initializer.volumePolarization;
            if (initializer.octavePolarization != undefined) octavePolarization = initializer.volumePolarization;
        }
    }
}


