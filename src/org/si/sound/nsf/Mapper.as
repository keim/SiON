//----------------------------------------------------------------------------------------------------
// Mapper class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//--------------------------------------------------------------------------------


package org.si.sound.nsf {
    public class Mapper {
        public var bank3WRAM:int = 0;
        function Mapper() { }
        public function write(addr:int, data:int) : void { }
        public function readLow(addr:int) : int {
            var a:int=(addr&8191)+(bank3WRAM<<13), i:int=a>>2, s:int=(a&3)<<3;
            return (MMU.$.WRAM[i]>>s)&0xff;
        }
        public function writeLow(addr:int, data:int) : void {
            var a:int=(addr&8191)+(bank3WRAM<<13), i:int=a>>2, s:int=(a&3)<<3;
            MMU.$.WRAM[i] = (MMU.$.WRAM[i]&~(255<<s)) | (data<<s);
        }
    	public function ExCmdRead(cmd:int) : int { return 0x00; }
    	public function ExCmdWrite(cmd:int, data:int) : void {}
        public function ExRead(addr:int) : int { return 0; }
        public function ExWrite(addr:int, data:int) : void { }
        public function sync(cycles:int) : void { }
        public function HSync(scanline:int) : void { }
        public function VSync() : void { }
        public function PPU_Latch(addr:int) : void { }
        public function PPU_ChrLatch(addr:int) : void { }
        public function PPU_ExtLatchX(x:int) : void { }
        public function PPU_ExtLatch(addr:int) : * { return {"chr_l":0, "chr_h":0, "attr":0}; }
    }
}

