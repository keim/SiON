//----------------------------------------------------------------------------------------------------
// NSF data class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.nsf {
    import flash.utils.ByteArray;
    
    
    /** NSF data class */
    public class NSFData
    {
    // variables
    //--------------------------------------------------------------------------------
        public var version:int;
        public var songCount:int;
        public var startSongID:int;
        public var loadAddress:int;
        public var initAddress:int;
        public var playAddress:int;
        public var title:String;
        public var artist:String;
        public var copyright:String;
        public var speedNRSC:int;
        public var speedPAL:int;
        public var NTSC_PALbits:int;
        public var bankSwitch:Vector.<int> = new Vector.<int>(8);
        public var extraChipFlag:int;
        public var reserved:uint;
        
        
        
        
    // properties
    //--------------------------------------------------------------------------------
        /** Is avaiblable ? */
        public function isAvailable() : Boolean { return false; }
        
        
        /** to string. */
        public function toString():String
        {
            var text:String = "";
            return text;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        function NSFData() {
        }
        
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : NSFData
        {
            
            return this;
        }
        
        
        /** Load NSF data from byteArray. */
        public function loadBytes(bytes:ByteArray) : NSFData
        {
            bytes.position = 0;
            clear();
            
            if (bytes.readMultiByte(4, "us-ascii") != "NESM") return this;
            bytes.position = 5;
            version = bytes.readUnsignedByte();
            songCount = bytes.readUnsignedByte();
            startSongID = bytes.readUnsignedByte();
            loadAddress = bytes.readUnsignedShort();
            initAddress = bytes.readUnsignedShort();
            playAddress = bytes.readUnsignedShort();
            
            title     = bytes.readMultiByte(32, "us-ascii"); //shift_jis
            artist    = bytes.readMultiByte(32, "us-ascii"); //shift_jis
            copyright = bytes.readMultiByte(32, "us-ascii"); //shift_jis
            
            speedNRSC = bytes.readUnsignedShort();
            for (var i:int=0; i<8; i++) bankSwitch[i] = bytes.readUnsignedByte();
            speedPAL = bytes.readUnsignedShort();
            NTSC_PALbits = bytes.readUnsignedByte();
            extraChipFlag = bytes.readUnsignedByte();
            reserved = bytes.readUnsignedInt();
            bytes.position = 128;
            
            
            
            return this;
        }
    }
}


