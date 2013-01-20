//----------------------------------------------------------------------------------------------------
// PDX data class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.mdx {
    import flash.events.*;
    import flash.utils.ByteArray;
    import org.si.sion.utils.SiONUtil;
    import org.si.utils.AbstructLoader;
    
    
    /** PDX data class */
    public class PDXData extends AbstructLoader
    {
    // variables
    //--------------------------------------------------------------------------------
        /** PDX file name */
        public var fileName:String = "";
        /** ADPCM data */
        public var adpcmData:Vector.<ByteArray>;
        /** extracted PCM data */
        public var pcmData:Vector.<Vector.<Number>>;
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** constructor */
        function PDXData()
        {
            adpcmData = new Vector.<ByteArray>(96, true);
            pcmData = new Vector.<Vector.<Number>>(96, true);
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : PDXData
        {
            fileName = "";
            for (var i:int=0; i<96; i++) {
                adpcmData[i] = null;
                pcmData[i] = null;
            }
            return this;
        }
        
        
        /** Load PDX data from byteArray. 
         *  @param bytes ByteArray of PDX data
         *  @param extractAll extract all ADPCM data to PCM data
         */
        public function loadBytes(bytes:ByteArray, extractAll:Boolean = true) : PDXData
        {
            var offset:int, length:int;
            
            clear();
            bytes.endian = "bigEndian";
            
            for (var i:int = 0; i<96; i++) {
                bytes.position = i*8;
                offset = bytes.readUnsignedInt();
                length = bytes.readUnsignedInt();
                if (offset != 0 && length != 0) {
                    adpcmData[i] = new ByteArray();
                    bytes.position = offset;
                    bytes.readBytes(adpcmData[i], 0, length);
                    if (extractAll) pcmData[i] = SiONUtil.extractYM2151ADPCM(adpcmData[i]);
                }
            }
            
            return this;
        }
        
        
        /** extract adpcm data 
         *  @param noteNumber note number to extract.
         *  @return extracted PCM data (monoral). returns null when the ADPCM data is not assigned on specifyed note number.
         */
        public function extract(noteNumber:int) : Vector.<Number> 
        {
            if (pcmData[noteNumber] != null) return pcmData[noteNumber];
            if (adpcmData[noteNumber] == null) return null;
            pcmData[noteNumber] = SiONUtil.extractYM2151ADPCM(adpcmData[noteNumber]);
            return pcmData[noteNumber];
        }
    }
}

