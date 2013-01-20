//----------------------------------------------------------------------------------------------------
// PDX data storage
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.mdx {
    import flash.events.*;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;
    import org.si.sion.utils.SiONUtil;
    import org.si.utils.AbstructLoader;
    
    
    
    /** PDX data storage */
    dynamic public class PDXDataStorage
    {
    // constructor
    //--------------------------------------------------------------------------------
        /** constructor */
        function PDXDataStorage()
        {
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Clear. */
        public function clear() : void
        {
            var key:String
            for (key in this) delete this[key];
        }
        
        
        /** load pdx data from url */
        public function load(url:URLRequest) : PDXData
        {
            var fileName:String = extractFileName(url.url);
            if (this[fileName] == null) {
                var pdxData:PDXData = new PDXData();
                this[fileName] = pdxData;
                pdxData.load(url);
            }
            return this[fileName];
        }
        

        /** extract file name from url string */
        public function extractFileName(url:String) : String {
            var index:int = url.lastIndexOf('/');
            return ((index == -1) ? (url) : (url.substr(index+1))).toUpperCase();
        }
    }
}

