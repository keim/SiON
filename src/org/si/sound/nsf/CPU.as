//----------------------------------------------------------------------------------------------------
// NES Central processing unit
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//--------------------------------------------------------------------------------


package org.si.sound.nsf {
    public class CPU {
        // register flags
        static public const CF:int = 0x01;       // Carry flag
        static public const ZF:int = 0x02;       // Zero flag
        static public const IF:int = 0x04;       // Irq disabled
        static public const DF:int = 0x08;       // Decimal mode flag (NES unused)
        static public const BF:int = 0x10;       // Break
        static public const RF:int = 0x20;       // Reserved (Always 1)
        static public const VF:int = 0x40;       // Overflow
        static public const NF:int = 0x80;       // Negative
        static public const IZN:int = 0x7d;      // ~(ZF|NF)
        
        // interruption flags
        static public const NMI_FLAG:int     = 0x01;
        static public const IRQ_FLAG:int     = 0xfc;
        static public const IRQ_FRAMEIRQ:int = 0x04;
        static public const IRQ_DPCM:int     = 0x08;
        static public const IRQ_MAPPER:int   = 0x10;
        static public const IRQ_MAPPER2:int  = 0x20;
        static public const IRQ_TRIGGER:int  = 0x40; // one shot(‹ŒIRQ())
        static public const IRQ_TRIGGER2:int = 0x80; // one shot(‹ŒIRQ_NotPending())
        
        // address
        static public const $NMI:int = 0xfffa;
        static public const $RES:int = 0xfffc;
        static public const $IRQ:int = 0xfffe;

        // valiables
        public var A:int, X:int, Y:int, PC:int, SP:int, P:int;
        public var interruptFlag:int, enableClockedProcess:Boolean;
        public var wait:int, totalCycle:int;
        public var ZN_TABLE:Vector.<int> = new Vector.<int>(256);
        public var mmu:MMU;
        
        // constructor
        function CPU() {
            mmu = new MMU();
            mmu.onReadPPUport  = _onReadPPUPort;
            mmu.onReadCPUport  = _onReadCPUPort;
            mmu.onWritePPUport = _onWritePPUPort;
            mmu.onWriteCPUport = _onWriteCPUPort;
            for (var i:int=0; i<256; i++) ZN_TABLE[i] = (i==0)?(ZF):(i&NF);
            _zp = mmu.RAM;
        }
        
        // reset
        public function reset() : void {
            var i:int;
            wait = A = X = Y = 0;
            P = ZF|RF;
            SP = 255;
            PC = readW($RES);
            interruptFlag = 0;
            enableClockedProcess = false;
            mmu.reset();
        }
        
        // execute
        public function exec(cycles:int) : int {
            var opcode:int, residue:int, nmi_request:Boolean, irq_request:Boolean, executed:int, oldCycle:int=totalCycle;

            for (residue=cycles; residue>0;) {
                if (wait) {
                    if (residue < wait) {
                        wait -= residue;
                        NES.map.sync(residue);
                        NES.apu.sync(residue);
                        totalCycle += residue;
                        break;
                    } else {
                        residue -= wait;
                        totalCycle += wait;
                        wait = 0;
                    }
                }

                opcode = read(PC++);
                nmi_request = ((interruptFlag & NMI_FLAG)!=0);
                irq_request = ((interruptFlag & IRQ_FLAG)!=0) && (!nmi_request) && ((P & IF)==0) && (opcode!=0x40);
                interruptFlag &= ~(NMI_FLAG | IRQ_TRIGGER2 | ((irq_request) ? IRQ_TRIGGER : 0));
                
                executed = operations[opcode]();
                if (nmi_request) executed += _gosub($NMI);
                if (irq_request) executed += _gosub($IRQ);
                
                NES.map.sync(residue);
                residue -= executed;
                totalCycle += executed;
            }
            
            executed = totalCycle - oldCycle;
            NES.apu.sync(executed);
            return executed;
        }
        
        // interruptions
        public function setNMI() : void { interruptFlag |= NMI_FLAG; }
        public function setIRQ(irqFlag:int) : void { interruptFlag |= irqFlag; }
        public function clearIRQ(irqFlag:int) : void { interruptFlag &= ~irqFlag; }
        
        // memory access
        public function read(addr:int) : int { return mmu.CPU_MEM_BANK[addr>>13].read(addr); }
        public function readW(addr:int) : int { return mmu.CPU_MEM_BANK[addr>>13].readW(addr); }
        public function write(addr:int, data:int) : void { mmu.CPU_MEM_BANK[addr>>13].write(addr, data); }
        
        // I/O port
        private function _onReadPPUPort(addr:int) : int {
            return 0;
        }
        
        private function _onWritePPUPort(addr:int, data:int) : void {
        }
        
        private function _onReadCPUPort(addr:int) : int {
            return 0;
        }
        
        private function _onWriteCPUPort(addr:int, data:int) : void {
        }
        
        
        // operations
        //--------------------------------------------------------------------------------
        // -------- temporary valiables
        private var _ea:int, _et:int, _execCycle:int, _zp:Vector.<uint>; // zero page memory area
        // -------- address
        private function get $IM() : int { return PC++; }
        private function get $ZP() : int { return _ea = (read(PC++)) & 0xff; }
        private function get $ZX() : int { return _ea = (read(PC++) + X) & 0xff; }
        private function get $ZY() : int { return _ea = (read(PC++) + Y) & 0xff; }
        private function get $AB() : int { _ea = readW(PC); PC+=2; return _ea; }
        private function get $AX() : int { _et = readW(PC); PC+=2; return _ea = _et + X; }
        private function get $AY() : int { _et = readW(PC); PC+=2; return _ea = _et + Y; }
        private function get $IX() : int { var i:int=$ZX; return _ea=_zp[i]|(_zp[i+1]<<8); }
        private function get $IY() : int { var i:int=$ZP; _et=_zp[i]|(_zp[i+1]<<8); return _ea = _et + Y; }
        // -------- sub routines
        private function _check(b:int, f:int) : void { P&=~f; P|=(b)?f:0; }
        private function _checkZN(data:int) : int { data&=0xff; P&=IZN; P|=ZN_TABLE[data]; return data; }
        private function _push(data:int) : void { write(0x100|((SP--)&0xff), data); }
        private function _pop() : int { return read(0x100|((++SP)&0xff)); }
        private function _wm(data:int) : void { write(_ea, data); } // write memory
        private function _wz(data:int) : void { _zp[_ea] = data;  } // write zero page memory
        private function _cs(cycle:int) : int { return cycle + (((_et&0xff00)!=(_ea&0xff00)) ? 1 : 0); } // check segment
        private function _rj(data:int) : int { _et=PC; _ea=PC+data; PC=_ea; _execCycle+=1; return _cs(0); } // relative jump
        private function _gosub(v:int) : int { _push(PC>>8); _push(PC&0xff); P&=~BF; _push(P); P|=IF; PC=readW(v); return 7; }
        // -------- operating subs
        private function adc(data:int) : void {
            var i:int = A + data + (P & CF);
            _check(int(i>0xff), CF);
            _check(((~(A^data))&(A^i)&0x80), VF);
            A = _checkZN(i);
        }
        private function sbc(data:int) : void {
            var i:int = A - data - (~P & CF);
            _check(((A^data)&(A^i)&0x80), VF);
            _check(int(i>=0), CF);
            A = _checkZN(i);
        }
        private function and(data:int) : void { A = _checkZN(A&data); }
        private function ora(data:int) : void { A = _checkZN(A|data); }
        private function eor(data:int) : void { A = _checkZN(A^data); }
        private function inc(data:int) : int  { return _checkZN(++data); }
        private function dec(data:int) : int  { return _checkZN(--data); }
        private function asl(data:int) : int  { _check(data&0x80, CF); return _checkZN(data<<1); }
        private function lsr(data:int) : int  { _check(data&0x01, CF); return _checkZN(data>>1); }
        private function rol(data:int) : int  { var c:int=P&CF;      _check(data&0x80, CF); return _checkZN((data<<1)|c); }
        private function ror(data:int) : int  { var c:int=(P&CF)<<7; _check(data&0x01, CF); return _checkZN((data>>1)|c); }
        private function bit(data:int) : void { _check(int((data&A)==0), ZF); _check(data&0x80, NF); _check(data&0x40, VF); }
        private function cmp(reg:int, data:int) : void { var i:int=reg-data; _check(int(i>=0), CF); _checkZN(i); }
        // -------- operating subs (unofficial)
        private function dcp(data:int) : int { cmp(A, --data); return data; }
        private function isb(data:int) : int { sbc(++data); return data; }
        private function lax(data:int) : void { A = X = _checkZN(data); }
        private function rla(data:int) : int { data = rol(data); A = _checkZN(A&data); return data; }
        private function rra(data:int) : int { data = ror(data); adc(data); return data; }
        private function slo(data:int) : int { _check(data&0x80, CF); data<<=1; A = _checkZN(A|data); return data; }
        private function sre(data:int) : int { _check(data&0x01, CF); data>>=1; A = _checkZN(A^data); return data; }
        private function sh_(reg:int, addr:int) : int { SP = A & X; return SP & ((addr>>8)+1) & 0xff; }
        // SHS;sh_(SP=A&X), SHA;sh_(A&X), SHX;sh_(X), SHY;sh_(Y)
        // -------- no operation subs
        private function nop()  : int { return 2; }
        private function dop2() : int { PC++; return 2; }
        private function dop3() : int { PC++; return 3; }
        private function dop4() : int { PC++; return 4; }
        private function top()  : int { PC+=2; return 4; }
        private function err()  : int { return 4; }
        
        // -------- operation functors
        public var operations:* = {
            0x69: function():int{ adc(read($IM)); return 2; },      // ADC #$??
            0x65: function():int{ adc(_zp[$ZP]);  return 3; },      // ADC $??
            0x75: function():int{ adc(_zp[$ZX]);  return 4; },      // ADC $??,X
            0x6d: function():int{ adc(read($AB)); return 4; },      // ADC $????
            0x7d: function():int{ adc(read($AX)); return _cs(4); }, // ADC $????,X
            0x79: function():int{ adc(read($AY)); return _cs(4); }, // ADC $????,Y
            0x61: function():int{ adc(read($IX)); return 6; },      // ADC ($??,X)
            0x71: function():int{ adc(read($IY)); return _cs(5); }, // ADC ($??),Y (ct=4 in vertualNES)
            
            0xe9: function():int{ sbc(read($IM)); return 2; },      // SBC #$??
            0xe5: function():int{ sbc(_zp[$ZP]);  return 3; },      // SBC $??
            0xf5: function():int{ sbc(_zp[$ZX]);  return 4; },      // SBC $??,X
            0xed: function():int{ sbc(read($AB)); return 4; },      // SBC $????
            0xfd: function():int{ sbc(read($AX)); return _cs(4); }, // SBC $????,X
            0xf9: function():int{ sbc(read($AY)); return _cs(4); }, // SBC $????,Y
            0xe1: function():int{ sbc(read($IX)); return 6; },      // SBC ($??,X)
            0xf1: function():int{ sbc(read($IY)); return _cs(5); }, // SBC ($??),Y
            
            0x09: function():int{ ora(read($IM)); return 2; },      // ORA #$??
            0x05: function():int{ ora(_zp[$ZP]);  return 3; },      // ORA $??
            0x15: function():int{ ora(_zp[$ZX]);  return 4; },      // ORA $??,X
            0x0d: function():int{ ora(read($AB)); return 4; },      // ORA $????
            0x1d: function():int{ ora(read($AX)); return _cs(4); }, // ORA $????,X
            0x19: function():int{ ora(read($AY)); return _cs(4); }, // ORA $????,Y
            0x01: function():int{ ora(read($IX)); return 6; },      // ORA ($??,X)
            0x11: function():int{ ora(read($IY)); return _cs(5); }, // ORA ($??),Y
            
            0x29: function():int{ and(read($IM)); return 2; },      // AND #$??
            0x25: function():int{ and(_zp[$ZP]);  return 3; },      // AND $??
            0x35: function():int{ and(_zp[$ZX]);  return 4; },      // AND $??,X
            0x2d: function():int{ and(read($AB)); return 4; },      // AND $????
            0x3d: function():int{ and(read($AX)); return _cs(4); }, // AND $????,X
            0x39: function():int{ and(read($AY)); return _cs(4); }, // AND $????,Y
            0x21: function():int{ and(read($IX)); return 6; },      // AND ($??,X)
            0x31: function():int{ and(read($IY)); return _cs(5); }, // AND ($??),Y
            
            0x49: function():int{ eor(read($IM)); return 2; },      // EOR #$??
            0x45: function():int{ eor(_zp[$ZP]);  return 3; },      // EOR $??
            0x55: function():int{ eor(_zp[$ZX]);  return 4; },      // EOR $??,X
            0x4d: function():int{ eor(read($AB)); return 4; },      // EOR $????
            0x5d: function():int{ eor(read($AX)); return _cs(4); }, // EOR $????,X
            0x59: function():int{ eor(read($AY)); return _cs(4); }, // EOR $????,Y
            0x41: function():int{ eor(read($IX)); return 6; },      // EOR ($??,X)
            0x51: function():int{ eor(read($IY)); return _cs(5); }, // EOR ($??),Y
            
            0x0a: function():int{ A=asl(A);            return 2; },      // ASL A
            0x06: function():int{ _wz(asl(_zp[$ZP]));  return 5; },      // ASL $??
            0x16: function():int{ _wz(asl(_zp[$ZX]));  return 6; },      // ASL $??,X
            0x0e: function():int{ _wm(asl(read($AB))); return 6; },      // ASL $????
            0x1e: function():int{ _wm(asl(read($AX))); return _cs(6); }, // ASL $????,X (no check in vertualNES)
            
            0x2a: function():int{ A=rol(A);            return 2; },      // ROL A
            0x26: function():int{ _wz(rol(_zp[$ZP]));  return 5; },      // ROL $??
            0x36: function():int{ _wz(rol(_zp[$ZX]));  return 6; },      // ROL $??,X
            0x2e: function():int{ _wm(rol(read($AB))); return 6; },      // ROL $????
            0x3e: function():int{ _wm(rol(read($AX))); return _cs(6); }, // ROL $????,X (no check in vertualNES)

            0x4a: function():int{ A=lsr(A);            return 2; },      // LSR A
            0x46: function():int{ _wz(lsr(_zp[$ZP]));  return 5; },      // LSR $??
            0x56: function():int{ _wz(lsr(_zp[$ZX]));  return 6; },      // LSR $??,X
            0x4e: function():int{ _wm(lsr(read($AB))); return 6; },      // LSR $????
            0x5e: function():int{ _wm(lsr(read($AX))); return _cs(6); }, // LSR $????,X (no check in vertualNES)

            0x6a: function():int{ A=ror(A);            return 2; },      // ROR A
            0x66: function():int{ _wz(ror(_zp[$ZP]));  return 5; },      // ROR $??
            0x76: function():int{ _wz(ror(_zp[$ZX]));  return 6; },      // ROR $??,X
            0x6e: function():int{ _wm(ror(read($AB))); return 6; },      // ROR $????
            0x7e: function():int{ _wm(ror(read($AX))); return _cs(6); }, // ROR $????,X (no check in vertualNES)
            
            0x24: function():int{ bit(_zp[$ZP]);  return 3; }, // BIT $??
            0x2C: function():int{ bit(read($AB)); return 4; }, // BIT $????
            
            0xc6: function():int{ _wz(dec(_zp[$ZP]));  return 5; },      // DEC $??
            0xd6: function():int{ _wz(dec(_zp[$ZX]));  return 6; },      // DEC $??,X
            0xce: function():int{ _wm(dec(read($AB))); return 6; },      // DEC $????
            0xde: function():int{ _wm(dec(read($AX))); return _cs(6); }, // DEC $????,X (no check in vertualNES)
            0xca: function():int{ X=dec(X); return 2; },                 // DEX
            0x88: function():int{ Y=dec(Y); return 2; },                 // DEY

            0xe6: function():int{ _wz(inc(_zp[$ZP]));  return 5; },      // INC $??
            0xf6: function():int{ _wz(inc(_zp[$ZX]));  return 6; },      // INC $??,X
            0xee: function():int{ _wm(inc(read($AB))); return 6; },      // INC $????
            0xfe: function():int{ _wm(inc(read($AX))); return _cs(6); }, // INC $????,X (no check in vertualNES)
            0xe8: function():int{ X=inc(X); return 2; },                 // INX
            0xc8: function():int{ X=inc(Y); return 2; },                 // INY

            0xa9: function():int{ A=_checkZN(read($IM)); return 2; },      // LDA #$??
            0xa5: function():int{ A=_checkZN(_zp[$ZP]);  return 3; },      // LDA $??
            0xb5: function():int{ A=_checkZN(_zp[$ZX]);  return 4; },      // LDA $??,X
            0xad: function():int{ A=_checkZN(read($AB)); return 4; },      // LDA $????
            0xbd: function():int{ A=_checkZN(read($AX)); return _cs(4); }, // LDA $????,X
            0xb9: function():int{ A=_checkZN(read($AY)); return _cs(4); }, // LDA $????,Y
            0xa1: function():int{ A=_checkZN(read($IX)); return 6; },      // LDA ($??,X)
            0xb1: function():int{ A=_checkZN(read($IY)); return _cs(5); }, // LDA ($??),Y

            0xa2: function():int{ X=_checkZN(read($IM)); return 2; },      // LDX #$??
            0xa6: function():int{ X=_checkZN(_zp[$ZP]);  return 3; },      // LDX $??
            0xb6: function():int{ X=_checkZN(_zp[$ZY]);  return 4; },      // LDX $??,Y
            0xae: function():int{ X=_checkZN(read($AB)); return 4; },      // LDX $????
            0xbe: function():int{ X=_checkZN(read($AY)); return _cs(4); }, // LDX $????,Y

            0xa0: function():int{ Y=_checkZN(read($IM)); return 2; },      // LDY #$??
            0xa4: function():int{ Y=_checkZN(_zp[$ZP]);  return 3; },      // LDY $??
            0xb4: function():int{ Y=_checkZN(_zp[$ZX]);  return 4; },      // LDY $??,X
            0xac: function():int{ Y=_checkZN(read($AB)); return 4; },      // LDY $????
            0xbc: function():int{ Y=_checkZN(read($AX)); return _cs(4); }, // LDY $????,X
            
            0x85: function():int{ _zp[$ZP] = A; return 3; },      // STA $??
            0x95: function():int{ _zp[$ZX] = A; return 4; },      // STA $??,X
            0x8d: function():int{ write($AB,A); return 4; },      // STA $????
            0x9d: function():int{ write($AX,A); return _cs(4); }, // STA $????,X (no check in vertualNES)
            0x99: function():int{ write($AY,A); return _cs(4); }, // STA $????,Y (no check in vertualNES)
            0x81: function():int{ write($IX,A); return 6; },      // STA ($??,X)
            0x91: function():int{ write($IY,A); return _cs(5); }, // STA ($??),Y (no check in vertualNES)

            0x86: function():int{ _zp[$ZP] = X; return 3; }, // STX $??
            0x96: function():int{ _zp[$ZX] = X; return 4; }, // STX $??,Y
            0x8e: function():int{ write($AB,X); return 4; }, // STX $????

            0x84: function():int{ _zp[$ZP] = Y; return 3; }, // STY $??
            0x94: function():int{ _zp[$ZX] = Y; return 4; }, // STY $??,X
            0x8c: function():int{ write($AB,Y); return 4; }, // STY $????

            0xaa: function():int{ X=_checkZN(A);  return 2; }, // TAX
            0x8a: function():int{ A=_checkZN(X);  return 2; }, // TXA
            0xa8: function():int{ Y=_checkZN(A);  return 2; }, // TAY
            0x98: function():int{ A=_checkZN(Y);  return 2; }, // TYA
            0xba: function():int{ X=_checkZN(SP); return 2; }, // TSX
            0x9a: function():int{ SP=X;           return 2; }, // TXS
            
            0xc9: function():int{ cmp(A, read($IM)); return 2; },      // CMP #$??
            0xc5: function():int{ cmp(A, _zp[$ZP]);  return 3; },      // CMP $??
            0xd5: function():int{ cmp(A, _zp[$ZX]);  return 4; },      // CMP $??,X
            0xcd: function():int{ cmp(A, read($AB)); return 4; },      // CMP $????
            0xdd: function():int{ cmp(A, read($AX)); return _cs(4); }, // CMP $????,X
            0xd9: function():int{ cmp(A, read($AY)); return _cs(4); }, // CMP $????,Y
            0xc1: function():int{ cmp(A, read($IX)); return 6; },      // CMP ($??,X)
            0xd1: function():int{ cmp(A, read($IY)); return _cs(5); }, // CMP ($??),Y
            
            0xe0: function():int{ cmp(X, read($IM)); return 2; },      // CPX #$??
            0xe4: function():int{ cmp(X, _zp[$ZP]);  return 3; },      // CPX $??
            0xec: function():int{ cmp(X, read($AB)); return 4; },      // CPX $????
            
            0xc0: function():int{ cmp(Y, read($IM)); return 2; },      // CPX #$??
            0xc4: function():int{ cmp(Y, _zp[$ZP]);  return 3; },      // CPX $??
            0xcc: function():int{ cmp(Y, read($AB)); return 4; },      // CPX $????
            
            0x90: function():int{ var r:int=read($IM); return (!(P&CF)) ? (_rj(r)+3) : 2; }, // BCC
            0xb0: function():int{ var r:int=read($IM); return ( (P&CF)) ? (_rj(r)+3) : 2; }, // BCS
            0xd0: function():int{ var r:int=read($IM); return (!(P&ZF)) ? (_rj(r)+3) : 2; }, // BNE
            0xf0: function():int{ var r:int=read($IM); return ( (P&ZF)) ? (_rj(r)+3) : 2; }, // BEQ
            0x10: function():int{ var r:int=read($IM); return (!(P&NF)) ? (_rj(r)+3) : 2; }, // BPL
            0x30: function():int{ var r:int=read($IM); return ( (P&NF)) ? (_rj(r)+3) : 2; }, // BMI
            0x50: function():int{ var r:int=read($IM); return (!(P&VF)) ? (_rj(r)+3) : 2; }, // BVC
            0x70: function():int{ var r:int=read($IM); return ( (P&VF)) ? (_rj(r)+3) : 2; }, // BVS
            
            0x4c: function():int{ PC = readW(PC); return 3; }, // JMP $????
            0x6c: function():int{ var i:int=readW(PC); _ea=read(i); i=(i&0xff00)|((i+1)&0xff); PC=_ea|(read(i)<<8); return 5; }, // JMP ($????)
            0x20: function():int{ _ea=readW(PC++); _push(PC>>8); _push(PC&0xff); PC=_ea; return 6; }, // JSR
            0x40: function():int{ P=_pop()|RF; PC=_pop(); PC|=_pop()<<8; return 6; }, // RTI
            0x60: function():int{ PC=_pop(); PC|=_pop()<<8; PC++; return 6; },  // RTS
            
            0x18: function():int{ P&=~CF; return 2; }, // CLC
            0xd8: function():int{ P&=~DF; return 2; }, // CLD
            0x58: function():int{ P&=~IF; return 2; }, // CLI
            0xb8: function():int{ P&=~VF; return 2; }, // CLV
            0x38: function():int{ P|=CF;  return 2; }, // SEC
            0xf8: function():int{ P|=DF;  return 2; }, // SED
            0x78: function():int{ P|=IF;  return 2; }, // SEI

            0x48: function():int{ _push(A); return 3; },           // PHA
            0x08: function():int{ _push(P|BF); return 3; },        // PHP
            0x68: function():int{ A=_checkZN(_pop()); return 4; }, // PLA
            0x28: function():int{ P=_pop()|RF; return 4; },        // PLP
            
            0x00: function():int{ PC++; _push(PC>>8); _push(PC&0xff); P|=BF; _push(P); P|=IF; PC=readW($IRQ); return 7; }, // BRK
            0xea: nop, // NOP
            
            // ---------- unofiicial operations ----------
            0x0b: function():int{ A=_checkZN(A&read($IM)); _check(P&NF, CF); return 2; }, // ANC #$??
            0x2b: function():int{ A=_checkZN(A&read($IM)); _check(P&NF, CF); return 2; }, // ANC #$??
            0x4b: function():int{ var i:int=read($IM); i&=A; _check(i&1, CF); A=_checkZN(i>>1); return 2; }, // ASR #$??
            0x6b: function():int{ A=_checkZN(((read($IM)&A)>>1)|((P&CF)<<7)); _check(A&0x40,CF); _check((A>>6)^(A>>5),VF); return 2; }, // ARR #$??
            0x8b: function():int{ A=_checkZN((A|0xee)&X&read($IM));          return 2; }, // ANE #$??
            0xc7: function():int{ _wz(dcp(_zp[$ZP]));  return 5; }, // DCP $??
            0xd7: function():int{ _wz(dcp(_zp[$ZX]));  return 6; }, // DCP $??,X
            0xcf: function():int{ _wm(dcp(read($AB))); return 6; }, // DCP $????
            0xdf: function():int{ _wm(dcp(read($AX))); return 7; }, // DCP $????,X
            0xdb: function():int{ _wm(dcp(read($AY))); return 7; }, // DCP $????,Y
            0xc3: function():int{ _wm(dcp(read($IX))); return 8; }, // DCP ($??,X)
            0xd3: function():int{ _wm(dcp(read($IY))); return 8; }, // DCP ($??),Y
            0xe7: function():int{ _wz(isb(_zp[$ZP]));  return 5; }, // ISB $??
            0xf7: function():int{ _wz(isb(_zp[$ZX]));  return 5; }, // ISB $??,X
            0xef: function():int{ _wm(isb(read($AB))); return 5; }, // ISB $????
            0xff: function():int{ _wm(isb(read($AX))); return 5; }, // ISB $????,X
            0xfb: function():int{ _wm(isb(read($AY))); return 5; }, // ISB $????,Y
            0xe3: function():int{ _wm(isb(read($IX))); return 5; }, // ISB ($??,X)
            0xf3: function():int{ _wm(isb(read($IY))); return 5; }, // ISB ($??),Y
            0xbb: function():int{ A=X=SP=_checkZN(SP&read($AY)); return _cs(4); }, // LAS $????,Y
            0xa7: function():int{ lax(_zp[$ZP]);  return 3; },      // LAX $??
            0xb7: function():int{ lax(_zp[$ZY]);  return 4; },      // LAX $??,Y
            0xaF: function():int{ lax(read($AB)); return 4; },      // LAX $????
            0xbF: function():int{ lax(read($AY)); return _cs(4); }, // LAX $????,Y
            0xa3: function():int{ lax(read($IX)); return 6; },      // LAX ($??,X)
            0xb3: function():int{ lax(read($IY)); return _cs(5); }, // LAX ($??),Y
            0xab: function():int{ A=X=_checkZN((A|0xee)&read($IM)); return 2; }, // LXA #$??
            0x27: function():int{ _wz(rla(_zp[$ZP]));  return 5; }, // RLA $??
            0x37: function():int{ _wz(rla(_zp[$ZX]));  return 6; }, // RLA $??,X
            0x2f: function():int{ _wm(rla(read($AB))); return 6; }, // RLA $????
            0x3f: function():int{ _wm(rla(read($AX))); return 7; }, // RLA $????,X
            0x3b: function():int{ _wm(rla(read($AY))); return 7; }, // RLA $????,Y
            0x23: function():int{ _wm(rla(read($IX))); return 8; }, // RLA ($??,X)
            0x33: function():int{ _wm(rla(read($IY))); return 8; }, // RLA ($??),Y
            0x67: function():int{ _wz(rra(_zp[$ZP]));  return 5; }, // RRA $??
            0x77: function():int{ _wz(rra(_zp[$ZX]));  return 6; }, // RRA $??,X
            0x6f: function():int{ _wm(rra(read($AB))); return 6; }, // RRA $????
            0x7f: function():int{ _wm(rra(read($AX))); return 7; }, // RRA $????,X
            0x7b: function():int{ _wm(rra(read($AY))); return 7; }, // RRA $????,Y
            0x63: function():int{ _wm(rra(read($IX))); return 8; }, // RRA ($??,X)
            0x73: function():int{ _wm(rra(read($IY))); return 8; }, // RRA ($??),Y
            0x87: function():int{ _zp[$ZP] = A&X; return 3; }, // SAX $??
            0x97: function():int{ _zp[$ZY] = A&X; return 4; }, // SAX $??,Y
            0x8f: function():int{ write($AB,A&X); return 4; }, // SAX $????
            0x83: function():int{ write($IX,A&X); return 6; }, // SAX ($??,X)
            0xcb: function():int{ var i:int=(A&X)-read($IM); _check(int(i>=0),CF); X=_checkZN(i); return 2; }, // SBX #$??
            0x9f: function():int{ _wm(sh_(A&X,read($AY))); return 5; }, // SHA $????,Y
            0x93: function():int{ _wm(sh_(A&X,read($IY))); return 6; }, // SHA ($??),Y
            0x9b: function():int{ SP=A&X; _wm(sh_(SP,read($AY))); return 5; }, // SHS $????,Y
            0x9e: function():int{ _wm(sh_(X,read($AY))); return 5; }, // SHX $????,Y
            0x9c: function():int{ _wm(sh_(Y,read($AX))); return 5; }, // SHY $????,X
            0x07: function():int{ _wz(slo(_zp[$ZP]));  return 5; }, // SLO $??
            0x17: function():int{ _wz(slo(_zp[$ZX]));  return 6; }, // SLO $??,X
            0x0f: function():int{ _wm(slo(read($AB))); return 6; }, // SLO $????
            0x1f: function():int{ _wm(slo(read($AX))); return 7; }, // SLO $????,X
            0x1b: function():int{ _wm(slo(read($AY))); return 7; }, // SLO $????,Y
            0x03: function():int{ _wm(slo(read($IX))); return 8; }, // SLO ($??,X)
            0x13: function():int{ _wm(slo(read($IY))); return 8; }, // SLO ($??),Y
            0x47: function():int{ _wz(sre(_zp[$ZP]));  return 5; }, // SRE $??
            0x57: function():int{ _wz(sre(_zp[$ZX]));  return 6; }, // SRE $??,X
            0x4f: function():int{ _wm(sre(read($AB))); return 6; }, // SRE $????
            0x5f: function():int{ _wm(sre(read($AX))); return 7; }, // SRE $????,X
            0x5b: function():int{ _wm(sre(read($AY))); return 7; }, // SRE $????,Y
            0x43: function():int{ _wm(sre(read($IX))); return 8; }, // SRE ($??,X)
            0x53: function():int{ _wm(sre(read($IY))); return 8; }, // SRE ($??),Y
            0xeb: function():int{ sbc(read($IM)); return 2; },      // SBC #$?? (Unofficial)
            0x1a:nop,  0x3A:nop,  0x5A:nop,  0x7A:nop,  0xDA:nop,   0xFA:nop, // NOP (Unofficial)
            0x80:dop2, 0x82:dop2, 0x89:dop2, 0xC2:dop2, 0xE2:dop2,            // DOP (CYCLES 2)
            0x04:dop3, 0x44:dop3, 0x64:dop3,                                  // DOP (CYCLES 3)
            0x14:dop4, 0x34:dop4, 0x54:dop4, 0x74:dop4, 0xD4:dop4, 0xF4:dop4, // DOP (CYCLES 4)
            0x0c:top,  0x1c:top,  0x3c:top,  0x5c:top,  0x7c:top,  0xdc:top,  0xfc:top, // TOP
            0x02:err,  0x12:err,  0x22:err,  0x32:err,  0x42:err,  0x52:err, 
            0x62:err,  0x72:err,  0x92:err,  0xb2:err,  0xd2:err,  0xf2:err  // JAM
        };
    }
}


