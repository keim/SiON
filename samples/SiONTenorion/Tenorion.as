// SiON TENORION
package {
    import flash.display.Sprite;
    import flash.events.*;
    import flash.text.TextField;
    import org.si.sion.*;
    import org.si.sion.events.*;
    import org.si.sion.utils.SiONPresetVoice;
    
    
    public class Tenorion extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // preset voice
        public var presetVoice:SiONPresetVoice = new SiONPresetVoice();
        
        // voices, notes and tracks
        public var voices:Vector.<SiONVoice> = new Vector.<SiONVoice>(16);
        public var notes :Vector.<int> = Vector.<int>([36,48,60,72, 43,48,55,60, 65,67,70,72, 77,79,82,84]);
        public var length:Vector.<int> = Vector.<int>([ 1, 1, 1, 1,  1, 1, 1, 1,  4, 4, 4, 4,  4, 4, 4, 4]);
        
        // beat counter
        public var beatCounter:int;
        
        // control pad
        public var matrixPad:MatrixPad;
        
        // constructor
        function Tenorion() {
            var i:int;
            
            // set voices from preset
            var percusVoices:Array = presetVoice["valsound.percus"];
            voices[0] = percusVoices[0];  // bass drum
            voices[1] = percusVoices[27]; // snare drum
            voices[2] = percusVoices[16]; // close hihat
            voices[3] = percusVoices[22]; // open hihat
            for (i=4; i<8; i++) voices[i] = presetVoice["valsound.bass18"]; // others
            
            // listen
            driver.setBeatCallbackInterval(1);
            driver.addEventListener(SiONTrackEvent.BEAT, _onBeat);
            driver.setTimerInterruption(1, _onTimerInterruption);
            
            // control pad
            matrixPad = new MatrixPad(stage);
            addChild(matrixPad);

            // start streaming
            beatCounter = 0;
            driver.play();
        }
        
        
        // _onBeat (SiONTrackEvent.BEAT) is called back in each beat at the sound timing.
        private function _onBeat(e:SiONTrackEvent) : void 
        {
            matrixPad.beat(e.eventTriggerID & 15);
        }
        
        
        // _onTimerInterruption (SiONDriver.setTimerInterruption) is called back in each beat at the buffering timing.
        private function _onTimerInterruption() : void
        {
            var beatIndex:int = beatCounter & 15;
            for (var i:int=0; i<16; i++) {
                if (matrixPad.sequences[i] & (1<<beatIndex)) driver.noteOn(notes[i], voices[i], length[i]);
            }
            beatCounter++;
        }
    }
}



import flash.display.*;
import flash.events.*;
import flash.geom.*;

class MatrixPad extends Bitmap {
    public var sequences:Vector.<int> = new Vector.<int>(16);
    private var canvas:Shape = new Shape();
    private var buffer:BitmapData = new BitmapData(320, 320, true, 0);
    private var padOn:BitmapData  = _pad(0x303050, 0x6060a0);
    private var padOff:BitmapData = _pad(0x303050, 0x202040);
    private var pt:Point = new Point();
    private var colt:ColorTransform = new ColorTransform(1,1,1,0.1)
    
    
    function MatrixPad(stage:Stage) {
        super(new BitmapData(320, 320, false, 0));
        var i:int;
        for (i=0; i<256; i++) {
            pt.x = (i&15)*20;
            pt.y = (i&240)*1.25;
            buffer.copyPixels(padOff, padOff.rect, pt);
            bitmapData.copyPixels(padOff, padOff.rect, pt);
        }
        for (i=0; i<16; i++) sequences[i] = 0;
        addEventListener("enterFrame", _onEnterFrame);
        stage.addEventListener("click",  _onClick);
    }
    
    
    private function _pad(border:int, face:int) : BitmapData {
        var pix:BitmapData = new BitmapData(20, 20, false, 0);
        canvas.graphics.clear();
        canvas.graphics.lineStyle(1, border);
        canvas.graphics.beginFill(face);
        canvas.graphics.drawRect(1, 1, 17, 17);
        canvas.graphics.endFill();
        pix.draw(canvas);
        return pix;
    }
    
    
    private function _onEnterFrame(e:Event) : void {
        bitmapData.draw(buffer, null, colt);
    }
    
    
    private function _onClick(e:Event) : void {
        if (mouseX>=0 && mouseX<320 && mouseY>=0 && mouseY<320) {
            var track:int = 15-int(mouseY*0.05), beat:int = int(mouseX*0.05);
            sequences[track] ^= 1<<beat;
            pt.x = beat*20;
            pt.y = (15-track)*20;
            if (sequences[track] & (1<<beat)) buffer.copyPixels(padOn, padOn.rect, pt);
            else buffer.copyPixels(padOff, padOff.rect, pt);
        }
    }
    
    
    public function beat(beat16th:int) : void {
        for (pt.x=beat16th*20, pt.y=0; pt.y<320; pt.y+=20) bitmapData.copyPixels(padOn, padOn.rect, pt);
    }
}


