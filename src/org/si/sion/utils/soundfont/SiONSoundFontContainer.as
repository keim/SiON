//----------------------------------------------------------------------------------------------------
// SiON sound font containcer
//  Copyright (c) 2011 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.utils.soundfont {
    import flash.display.Sprite;
    
    
    /** SiONSoundFontContainer provides a basic class of swf file that has SiONVoice setting. */
    public class SiONSoundFontContainer extends Sprite 
    {
        /** set sound instance table */
        public var sounds:* = null;
        
        
        /** set mml of this sound font */
        public var mml:String = null;
        
        
        /** version info */
        public var version:String = "1";
        
        
        /** constructor */
        public function SiONSoundFontContainer()
        {
        }
    }
}

