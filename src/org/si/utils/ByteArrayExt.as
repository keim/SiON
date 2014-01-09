//----------------------------------------------------------------------------------------------------
// Extended ByteArray
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.utils {
    import flash.net.FileFilter;
    import flash.net.FileReference;
    import flash.net.URLRequest;
    import flash.net.URLLoader;
    import flash.utils.Endian;
    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;
    import flash.events.Event;
    import flash.display.BitmapData;


    /** Extended ByteArray, png image serialize, IFF chunk structure, FileReference operations. */
    public class ByteArrayExt extends ByteArray {
    // variables
    //--------------------------------------------------
        static private var crc32:Vector.<uint> = null;
        
        /** name of this ByteArray */
        public var name:String = null;
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function ByteArrayExt(copyFrom:ByteArray = null)
        {
            super();
            if (copyFrom) {
                this.writeBytes(copyFrom);
                this.endian = copyFrom.endian;
                this.position = 0;
            }
        }
        
        
        
        
    // bitmap data operations
    //--------------------------------------------------
        /** translate from BitmapData 
         *  @param bmd BitmapData translating from. 
         *  @return this instance
         */
        public function fromBitmapData(bmd:BitmapData) : ByteArrayExt
        {
            var x:int, y:int, i:int, w:int=bmd.width, h:int=bmd.height, len:int, p:int;
            this.clear();
            len = bmd.getPixel(w-1, h-1);
            for (y=0, i=0; y<h && i<len; y++) for (x=0; x<w && i<len; x++, i++) {
                p = bmd.getPixel(x, y);
                this.writeByte(p>>>16);
                if (++i >= len) break;
                this.writeByte(p>>>8)
                if (++i >= len) break;
                this.writeByte(p);
            }
            this.position = 0;
            return this;
        }
        
        
        /** translate to BitmapData
         *  @param width same as BitmapData's constructor, set 0 to calculate automatically.
         *  @param height same as BitmapData's constructor, set 0 to calculate automatically.
         *  @param transparent same as BitmapData's constructor.
         *  @param fillColor same as BitmapData's constructor.
         *  @return translated BitmapData
         */
        public function toBitmapData(width:int=0, height:int=0, transparent:Boolean = true, fillColor:uint = 0xFFFFFFFF) : BitmapData
        {
            var x:int, y:int, reqh:int, bmd:BitmapData, len:int = this.length, p:uint;
            if (width == 0) width = ((int(Math.sqrt(len)+65535/65536))+15)&(~15);
            reqh = ((int(len/width+65535/65536))+15)&(~15);
            if (height == 0 || reqh > height) height = reqh;
            bmd = new BitmapData(width, height, transparent, fillColor);
            this.position = 0;
            for (y=0; y<height; y++) for (x=0; x<width; x++) {
                if (this.bytesAvailable < 3) break;
                bmd.setPixel32(x, y, 0xff000000|((this.readUnsignedShort()<<8)|this.readUnsignedByte()));
            }
            p = 0xff000000;
            if (this.bytesAvailable > 0) p |= this.readUnsignedByte() << 16;
            if (this.bytesAvailable > 0) p |= this.readUnsignedByte() << 8;
            if (this.bytesAvailable > 0) p |= this.readUnsignedByte();
            bmd.setPixel32(x, y, p);
            this.position = 0;
            bmd.setPixel32(x, y, 0xff000000|(uint(this.length)));
            return bmd;
        }
        
        
        /** translate to 24bit png data 
         *  @param width png file width, set 0 to calculate automatically.
         *  @param height png file height, set 0 to calculate automatically.
         *  @return ByteArrayExt of PNG data
         */
        public function toPNGData(width:int=0, height:int=0) : ByteArrayExt
        {
            var i:int, imax:int, reqh:int, pixels:int = (this.length+2)/3, y:int, 
                png:ByteArrayExt = new ByteArrayExt(), 
                header:ByteArray = new ByteArray(), 
                content:ByteArray = new ByteArray();
            //----- settings
            if (width == 0) width = ((int(Math.sqrt(pixels)+65535/65536))+15)&(~15);
            reqh = ((int(pixels/width+65535/65536))+15)&(~15);
            if (height == 0 || reqh > height) height = reqh;
            header.writeInt(width);  // width
            header.writeInt(height); // height
            header.writeUnsignedInt(0x08020000); // 24bit RGB
            header.writeByte(0);
            imax = pixels - width;
            for (y=0, i=0; i<imax; i+=width, y++) {
                content.writeByte(0);
                content.writeBytes(this, i*3, width*3);
            }
            content.writeByte(0);
            content.writeBytes(this, i*3, this.length-i*3);
            imax = (i + width) * 3;
            for (i=this.length; i<imax; i++) content.writeByte(0);
            imax = width * 3 + 1;
            for (y++; y<height; y++) for (i=0; i<imax; i++) content.writeByte(0);
            i = this.length;
            content.position -= 3;
            content.writeByte(i>>>16);
            content.writeByte(i>>>8);
            content.writeByte(i);
            content.compress();
            
            //----- write png data
            png.writeUnsignedInt(0x89504e47);
            png.writeUnsignedInt(0x0D0A1A0A);
            png_writeChunk(0x49484452, header);
            png_writeChunk(0x49444154, content);
            png_writeChunk(0x49454E44, new ByteArray);
            png.position = 0;
            
            return png;
            
            //----- write png chunk
            function png_writeChunk(type:uint, data:ByteArray) : void {
                png.writeUnsignedInt(data.length);
                var crcStartAt:uint = png.position;
                png.writeUnsignedInt(type);
                png.writeBytes(data);
                png.writeUnsignedInt(calculateCRC32(png, crcStartAt, png.position - crcStartAt));
            }
        }
        
        
        
        
    // IFF chunk operations
    //--------------------------------------------------
        /** write IFF chunk */
        public function writeChunk(chunkID:String, data:ByteArray, listType:String=null) : void
        {
            var isList:Boolean = (chunkID == "RIFF" || chunkID == "LIST"),
                len:int = ((data) ? data.length : 0) + ((isList) ? 4 : 0);
            this.writeMultiByte((chunkID+"    ").substr(0,4), "us-ascii");
            this.writeInt(len);
            if (isList) {
                if (listType) this.writeMultiByte((listType+"    ").substr(0,4), "us-ascii");
                else this.writeMultiByte("    ", "us-ascii");
            }
            if (data) {
                this.writeBytes(data);
                if (len & 1) this.writeByte(0);
            }
        }
        
        
        /** read (or search) IFF chunk from current position. */
        public function readChunk(bytes:ByteArray, offset:int=0, searchChunkID:String=null) : *
        {
            var id:String, len:int, type:String=null;
            while (this.bytesAvailable > 0) {
                id = this.readMultiByte(4, "us-ascii");
                len = this.readInt();
                if (searchChunkID == null || searchChunkID == id) {
                    if (id == "RIFF" || id == "LIST") {
                        type = this.readMultiByte(4, "us-ascii");
                        this.readBytes(bytes, offset, len-4);
                    } else {
                        this.readBytes(bytes, offset, len);
                    }
                    if (len & 1) this.readByte();
                    bytes.endian = this.endian;
                    return {"chunkID":id, "length":len, "listType":type};
                }
                this.position += len + (len & 1);
            }
            return null;
        }
        
        
        /** read all IFF chunks from current position. */
        public function readAllChunks() : *
        {
            var header:*, ret:* = {}, pickup:ByteArrayExt;
            while (header = readChunk(pickup = new ByteArrayExt())) {
                if (header.chunkID in ret) {
                    if (ret[header.chunkID] is Array) ret[header.chunkID].push(pickup);
                    else ret[header.chunkID] = [ret[header.chunkID]];
                } else {
                    ret[header.chunkID] = pickup;
                }
            }
            return ret;
        }
        
        
        
        
    // URL operations
    //--------------------------------------------------
        /** load from URL 
         *  @param url URL string to load swf file.
         *  @param onComplete handler for Event.COMPLETE. The format is function(bae:ByteArrayExt) : void.
         *  @param onCancel handler for Event.CANCEL. The format is function(e:Event) : void.
         *  @param onError handler for Event.IO_ERROR. The format is function(e:IOErrorEvent) : void.
         */
        public function load(url:String, onComplete:Function=null, onCancel:Function=null, onError:Function=null) : void
        {
            var loader:URLLoader = new URLLoader(), bae:ByteArrayExt = this;
            loader.dataFormat = "binary";
            loader.addEventListener("complete", _onLoadComplete);
            loader.addEventListener("cancel", _onLoadCancel);
            loader.addEventListener("ioError", _onLoadError);
            loader.load(new URLRequest(url));

            function _removeAllEventListeners(e:Event, callback:Function) : void {
                loader.removeEventListener("complete", _onLoadComplete);
                loader.removeEventListener("cancel", _onLoadCancel);
                loader.removeEventListener("ioError", _onLoadError);
                if (callback != null) callback(e);
            }
            function _onLoadComplete(e:Event) : void { 
                bae.clear();
                bae.writeBytes(e.target.data);
                _removeAllEventListeners(e, null);
                bae.position = 0;
                if (onComplete != null) onComplete(bae);
            }
            function _onLoadCancel(e:Event)   : void { _removeAllEventListeners(e, onCancel); }
            function _onLoadError(e:Event)    : void { _removeAllEventListeners(e, onError); }
        }
        
        
        
        
    // FileReference operations
    //--------------------------------------------------
        /** Call FileReference::browse().
         *  @param onComplete handler for Event.COMPLETE. The format is function(bae:ByteArrayExt) : void.
         *  @param onCancel handler for Event.CANCEL. The format is function(e:Event) : void.
         *  @param onError handler for Event.IO_ERROR. The format is function(e:IOErrorEvent) : void.
         *  @param fileFilterName name of file filter.
         *  @param extensions extensions of file filter (like "*.jpg;*.png;*.gif").
         */
        public function browse(onComplete:Function=null, onCancel:Function=null, onError:Function=null, fileFilterName:String=null, extensions:String=null) : void
        {
            var fr:FileReference = new FileReference(), bae:ByteArrayExt = this;
            fr.addEventListener("select", function(e:Event) : void {
                e.target.removeEventListener(e.type, arguments.callee);
                fr.addEventListener("complete", _onBrowseComplete);
                fr.addEventListener("cancel", _onBrowseCancel);
                fr.addEventListener("ioError", _onBrowseError);
                fr.load();
            });
            fr.browse((fileFilterName) ? [new FileFilter(fileFilterName, extensions)] : null);

            function _removeAllEventListeners(e:Event, callback:Function) : void {
                fr.removeEventListener("complete", _onBrowseComplete);
                fr.removeEventListener("cancel", _onBrowseCancel);
                fr.removeEventListener("ioError", _onBrowseError);
                if (callback != null) callback(e);
            }
            function _onBrowseComplete(e:Event) : void {
                bae.clear();
                bae.writeBytes(e.target.data);
                _removeAllEventListeners(e, null);
                bae.position = 0;
                if (onComplete != null) onComplete(bae);
            }
            function _onBrowseCancel(e:Event) : void { _removeAllEventListeners(e, onCancel); }
            function _onBrowseError(e:Event)  : void { _removeAllEventListeners(e, onError); }
        }
        
        
        /** Call FileReference::save().
         *  @param defaultFileName default file name.
         *  @param onComplete handler for Event.COMPLETE. The format is function(e:Event) : void.
         *  @param onCancel handler for Event.CANCEL. The format is function(e:Event) : void.
         *  @param onError handler for Event.IO_ERROR. The format is function(e:IOErrorEvent) : void.
         */
        public function save(defaultFileName:String=null, onComplete:Function=null, onCancel:Function=null, onError:Function=null) : void
        {
            var fr:FileReference = new FileReference();
            fr.addEventListener("complete", _onSaveComplete);
            fr.addEventListener("cancel", _onSaveCancel);
            fr.addEventListener("ioError", _onSaveError);
            fr.save(this, defaultFileName);

            function _removeAllEventListeners(e:Event, callback:Function) : void {
                fr.removeEventListener("complete", _onSaveComplete);
                fr.removeEventListener("cancel", _onSaveCancel);
                fr.removeEventListener("ioError", _onSaveError);
                if (callback != null) callback(e);
            }
            function _onSaveComplete(e:Event) : void { _removeAllEventListeners(e, onComplete); }
            function _onSaveCancel(e:Event)   : void { _removeAllEventListeners(e, onCancel); }
            function _onSaveError(e:Event)    : void { _removeAllEventListeners(e, onError); }
        }
        
        
        
        
    // zip file operations
    //--------------------------------------------------
        /** Expand zip file including plural files.
         *  @return List of ByteArrayExt
         */
        public function expandZipFile() : Vector.<ByteArrayExt>
        {
            var bytes:ByteArray = new ByteArray(), fileName:String = new String(), 
                bae:ByteArrayExt, result:Vector.<ByteArrayExt> = new Vector.<ByteArrayExt>(), 
                flNameLength:uint, xfldLength:uint, compSize:uint, compMethod:int, signature:uint;
            
            bytes.endian = Endian.LITTLE_ENDIAN;
            this.endian = Endian.LITTLE_ENDIAN;
            this.position = 0;
            while (this.position < this.length) {
                this.readBytes(bytes, 0, 30);
                bytes.position = 0;  signature = bytes.readUnsignedInt();
                if (signature != 0x04034b50) break; // chech signature
                bytes.position = 8;  compMethod   = bytes.readByte();
                bytes.position = 26; flNameLength = bytes.readShort();
                bytes.position = 28; xfldLength   = bytes.readShort(); 
                
                this.readBytes(bytes, 30, flNameLength + xfldLength);
                bytes.position = 30; fileName = bytes.readUTFBytes(flNameLength);
                bytes.position = 18; compSize = bytes.readUnsignedInt();
                
                bae = new ByteArrayExt();
                this.readBytes(bae, 0, compSize);
                if (compMethod == 8) bae.uncompress(CompressionAlgorithm.DEFLATE);
                bae.name = fileName;
                result.push(bae);
            }
            
            return result;
        }
        
        
        
        
    // utilities
    //--------------------------------------------------
        /** calculate crc32 chuck sum */
        static public function calculateCRC32(byteArray:ByteArray, offset:int=0, length:int=0) : uint 
        {
            var i:int, j:int, c:uint, currentPosition:int;
            if (!crc32) {
                crc32 = new Vector.<uint>(256, false);
                for (i=0; i<256; i++) {
                    for (c=i, j=0; j<8; j++) c = uint(((c&1)?0xedb88320:0)^(c>>>1));
                    crc32[i] = c;
                }
            }
            
            if (length==0) length = byteArray.length;
            currentPosition = byteArray.position;
            byteArray.position = offset;
            for (c=0xffffffff, i=0; i<length; i++) {
                j = (c ^ byteArray.readUnsignedByte()) & 255;
                c >>>= 8;
                c ^= crc32[j];
            }
            byteArray.position = currentPosition;
            
            return c ^ 0xffffffff;
        }
    }
}

