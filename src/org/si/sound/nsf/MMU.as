//--------------------------------------------------------------------------------
// Memory management unit
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//--------------------------------------------------------------------------------


package org.si.sound.nsf {
    import flash.utils.ByteArray;
    
    
    public class MMU {
        public var RAM :Vector.<uint> = new Vector.<uint>(2048);    // internal RAM;      2k
        public var WRAM:Vector.<uint> = new Vector.<uint>(128*256); // Working RAM;     128k
        public var DRAM:Vector.<uint> = new Vector.<uint>(40*256);  // RAM of disk sys;  40k
        public var ERAM:Vector.<uint> = new Vector.<uint>(32*256);  // RAM of exp.unit;  32k
        public var CRAM:Vector.<uint> = new Vector.<uint>(32*256);  // Ch.pattern RAM;   32k
        public var VRAM:Vector.<uint> = new Vector.<uint>( 4*256);  // name and attr.;    4k
        public var SPRAM:Vector.<uint> = new Vector.<uint>(256);    // Sprite RAM;      256b
        public var BGPAL:Vector.<uint> = new Vector.<uint>(16);     // BG Pallete;       16b
        public var SPPAL:Vector.<uint> = new Vector.<uint>(16);     // Sprite Pallete;   16b
        public var PROM:ByteArray;  // ROM pointer
        public var VROM:ByteArray;  // VROM pointer
        public var onReadPPUport:Function,  onReadCPUport:Function;
        public var onWritePPUport:Function, onWriteCPUport:Function;
        public var CPU_MEM_BANK:Vector.<MMUBank> = new Vector.<MMUBank>(8);
        static public var $:MMU;      // unique instance
        
        function MMU() {
            $ = this;
            CPU_MEM_BANK[0] = new MMUBankRAM();     // $0000-1ffff: internal RAM 
            CPU_MEM_BANK[1] = new PPUIOPort();      // $2000-3ffff: I/O port for PPU
            CPU_MEM_BANK[2] = new CPUIOPort();      // $4000-5ffff: I/O port for APU,DMA,PAD etc.. 
            CPU_MEM_BANK[3] = new MMUBankROMLow();  // $6000-7ffff: ROM area (low address)
            for (var i:int=4; i<8; i++) CPU_MEM_BANK[i] = new MMUBankROM(); // $8000-fffff: ROM area
        }
        
        public function reset(ram:int=0, clearWRAM:Boolean=false) : void {
            var i:int;
            for (i=0; i<RAM.length;  i++) RAM[i] = ram;
            if (clearWRAM) for (i=0; i<WRAM.length; i++) WRAM[i] = 0xff;
            for (i=0; i<DRAM.length; i++) DRAM[i] = 0;
            for (i=0; i<ERAM.length; i++) ERAM[i] = 0;
            for (i=0; i<CRAM.length; i++) CRAM[i] = 0;
            for (i=0; i<VRAM.length; i++) VRAM[i] = 0;
            for (i=0; i<SPRAM.length; i++) SPRAM[i] = 0;
            for (i=0; i<BGPAL.length; i++) BGPAL[i] = 0;
            for (i=0; i<SPPAL.length; i++) SPPAL[i] = 0;
        }
    }
}


import org.si.sound.nsf.MMU;
import org.si.sound.nsf.NES;

class MMUBank {
    // -------- bank types
    static public const ROM:int    = 0x00;
    static public const RAM:int    = 0xff;
    static public const DRAM:int   = 0x01;
    static public const MAPPER:int = 0x80;
    // -------- variables
    public var type:int;
    // -------- functions
    function MMUBank(type:int = ROM) { this.type = type; }
    public function read(addr:int) : int { return 0; }
    public function readW(addr:int) : int { return read(addr)|(read(addr+1)<<8); }
    public function write(addr:int, data:uint) : void { }
}

class MMUBankRAM extends MMUBank { // $0000-$1fff
    function MMUBankRAM() { super(MMUBank.RAM); }
    override public function read(addr:int) : int { var i:int=addr&2047; return MMU.$.RAM[i]; }
    override public function write(addr:int, data:uint) : void { var i:int=addr&2047; MMU.$.RAM[i]=data; }
}

class PPUIOPort extends MMUBank { // $2000-$3fff
    override public function read(addr:int) : int { return MMU.$.onReadPPUport(addr&7); }
    override public function write(addr:int, data:uint) : void { MMU.$.onWritePPUport(addr, data); }
}

class CPUIOPort extends MMUBank { // $4000-$5fff
    override public function read(addr:int) : int { return (addr<0x4020) ? MMU.$.onWriteCPUport(addr&31) : NES.map.ExRead(addr); }
    override public function write(addr:int, data:uint) : void {
        if (addr<0x4020) MMU.$.onWriteCPUport(addr, data);
        else NES.map.ExWrite(addr, data);
    }
}

class MMUBankROM extends MMUBank { // $8000-$ffff
    // -------- variables
    public var offset:int=0;
    // -------- functions
    function MMUBankROM() { super(MMUBank.MAPPER); }
    override public function read(addr:int) : int {
        MMU.$.PROM.position = (addr&8191)+offset;
        return MMU.$.PROM.readUnsignedByte();
    }
    override public function write(addr:int, data:uint) : void {
        NES.map.write(addr, data);
    }
}

class MMUBankROMLow extends MMUBankROM { // $6000-$7fff
    override public function read(addr:int) : int { return NES.map.readLow(addr); }
    override public function write(addr:int, data:uint) : void { NES.map.writeLow(addr, data); }
}


