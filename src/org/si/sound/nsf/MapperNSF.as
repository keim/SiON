//----------------------------------------------------------------------------------------------------
// Mapper for NSF
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//--------------------------------------------------------------------------------


package org.si.sound.nsf {
    public class MapperNSF extends Mapper {
        static public const $WAIT:int = 0x4700;
        static public const $INIT:int = 0x4704;
        static public const $PLAY:int = 0x470a;
        // nse asm code          $4700    01    02    03   /04    05    06    07    08    09   /0a    0b    0c    0d    0e    0f
        private var code:Array = [0x4c, 0x00, 0x47, 0x00, 0x20, 0xff, 0xff, 0x4c, 0x00, 0x47, 0x8d, 0x1e, 0x40, 0x20, 0xff, 0xff,
                                  0x8d, 0x1f, 0x40, 0x4c, 0x00, 0x47];
        
        override public function ExRead(addr:int) : int { return (addr>=0x4700 && addr<0x4716) ? code[addr-0x4700] : 0; }
        override public function ExWrite(addr:int, data:int) : void { }
        
        function MapperNSF() {
        }
        
        public function overwriteCodeData(data:NSFData) : void {
            code[5] = data.initAddress & 0xff;
            code[6] = data.initAddress >> 8;
            code[14] = data.playAddress & 0xff;
            code[15] = data.playAddress >> 8;
        }
    }
}

