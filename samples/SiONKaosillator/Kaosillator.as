// SiON KAOSCILLATOR
package {
    import flash.display.Sprite;
    import flash.events.*;
    import flash.text.TextField;
    import org.si.sion.*;
    import org.si.sion.events.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.utils.SiONPresetVoice;
    import org.si.sion.utils.Scale;
    
    import org.si.sound.Arpeggiator;
    
    
    public class Kaosillator extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // preset voice
        public var presetVoice:SiONPresetVoice = new SiONPresetVoice();
        
        // MML data
        public var rythmLoop:SiONData;
        
        // control pad
        public var controlPad:ControlPad;
        
        // text
        public var startPortamentHere:TextField = new TextField();
        
        // arpeggiator
        public var arpeggiator:Arpeggiator;
        
        
        // constructor
        function Kaosillator() {
            // compile mml. 
            var mml:String = "t132;";
            mml += "%6@0o3l8$c2cc.c.; %6@1o3$rcrc; %6@2v8l16$[crccrrcc]; %6@3v8o3$[rc8r8];";
            mml += "%6@4v8l16o3$aa<a8>a<ga>ararara<e8>;";
            rythmLoop = driver.compile(mml);
            
            // set voices of "%6@0-4" from preset
            var percusVoices:Array = presetVoice["valsound.percus"];
            rythmLoop.setVoice(0, percusVoices[0]);  // bass drum
            rythmLoop.setVoice(1, percusVoices[27]); // snare drum
            rythmLoop.setVoice(2, percusVoices[16]); // close hihat
            rythmLoop.setVoice(3, percusVoices[21]); // open hihat
            rythmLoop.setVoice(4, presetVoice["valsound.bass3"]); // bass
            
            // listen click
            driver.addEventListener(SiONEvent.STREAM,    _onStream);
            driver.addEventListener(SiONTrackEvent.BEAT, _onBeat);
            stage.addEventListener("mouseDown", _onMouseDown);
            stage.addEventListener("mouseUp",   _onMouseUp);
            
            // arpeggiator setting
            arpeggiator = new Arpeggiator(new Scale("o1Ajap"), 1, [0,1,2,5,4,3]);
            arpeggiator.voice = presetVoice["valsound.lead32"];
            arpeggiator.quantize = 4;
            arpeggiator.volume = 0.3;
            arpeggiator.noteQuantize = 8;
            
            // control pad
            controlPad = new ControlPad(stage, 320, 320, 0.5, 0.5, 0x101030);
            addChild(controlPad);
            
            startPortamentHere.htmlText = "<font color='#808080'>Start Portament Here</font>";
            startPortamentHere.selectable = false;
            startPortamentHere.x = 24;
            startPortamentHere.y = 24;
            startPortamentHere.width = 320;
            addChild(startPortamentHere);

            // play with an argument of resetEffector = false.
            driver.play(rythmLoop, false);
        }
        
        
        private function _onMouseDown(e:MouseEvent) : void
        {
            // set portament if mouseY < 40
            if (mouseY < 40) arpeggiator.portament = 4;
            else arpeggiator.portament = 0;
            
            // set pitch
            arpeggiator.scaleIndex = controlPad.controlX * 32;
            
            // start arpeggio
            arpeggiator.play();
            
            // update setup
            arpeggiator.track.channel.setFilterResonance(3);
            arpeggiator.track.channel.activateFilter(true);
        }
        
        
        private function _onMouseUp(e:MouseEvent) : void
        {
            // stop arpeggio
            arpeggiator.stop();
        }
        
        
        private function _onStream(e:SiONEvent) : void
        {
            // update arpeggiators track parameters
            var track:SiMMLTrack = arpeggiator.track;
            if (track) {
                // update arpeggiator pitch
                arpeggiator.scaleIndex = controlPad.controlX * 32;
                // update filter
                var cutoff:int = (controlPad.controlY - 0.1) * 192;
                if (cutoff > 128) cutoff = 128;
                else if (cutoff < 16) cutoff = 16;
                track.channel.setFilterOffset(cutoff);
            }
        }
        
        
        private function _onBeat(e:SiONTrackEvent) : void 
        {
            controlPad.beat(32);
        }
    }
}



import flash.display.*;
import flash.events.*;
import flash.filters.BlurFilter;

class ControlPad extends Bitmap {
    public var controlX:Number;
    public var controlY:Number;
    public var isDragging:Boolean;
    public var color:int;
    
    private var buffer:BitmapData;
    private var ratX:Number,  ratY:Number;
    private var prevX:Number, prevY:Number;
    private var clsDrawer:Shape = new Shape();
    private var canvas:Shape = new Shape();
    private var blur:BlurFilter = new BlurFilter(5, 5);
    private var pointerSize:Number = 8;
    
    
    function ControlPad(stage:Stage, width:int, height:int, initialX:Number=0, initialY:Number=0, color:int=0x101030) {
        super(new BitmapData(width+32, height+32, false, 0));
        buffer = new BitmapData(width+32, height+32, false, 0);
        
        clsDrawer.graphics.clear();
        clsDrawer.graphics.lineStyle(1, 0xffffff);
        clsDrawer.graphics.drawRect(16, 16, width, height);
        
        bitmapData.draw(clsDrawer);
        buffer.fillRect(buffer.rect, 0);
        
        this.color = color;
        controlX = initialX;
        controlY = initialY;
        ratX = 1 / width;
        ratY = 1 / height;
        prevX = buffer.width * controlX;
        prevY = buffer.height * controlY;
        addEventListener("enterFrame", _onEnterFrame);
        stage.addEventListener("mouseMove",  _onMouseMove);
        stage.addEventListener("mouseDown",  function(e:Event):void { isDragging = true; } );
        stage.addEventListener("mouseUp",    function(e:Event):void { isDragging = false; });
    }
    
    
    private function _onEnterFrame(e:Event) : void {
        var x:Number = (buffer.width-32) * controlX + 16;
        var y:Number = (buffer.height-32) * (1-controlY) + 16;
        canvas.graphics.clear();
        canvas.graphics.lineStyle(pointerSize, color);
        canvas.graphics.moveTo(prevX, prevY);
        canvas.graphics.lineTo(x, y);
        buffer.applyFilter(buffer, buffer.rect, buffer.rect.topLeft, blur);
        buffer.draw(canvas, null, null, "add");
        bitmapData.copyPixels(buffer, buffer.rect, buffer.rect.topLeft);
        bitmapData.draw(clsDrawer);
        prevX = x+Math.random();
        prevY = y;
        pointerSize *= 0.96;
    }
    
    
    private function _onMouseMove(e:MouseEvent) : void {
        if (isDragging) {
            controlX = (mouseX - 16) * ratX;
            controlY = 1 - (mouseY - 16) * ratY;
            if (controlX < 0) controlX = 0;
            else if (controlX > 1) controlX = 1;
            if (controlY < 0) controlY = 0;
            else if (controlY > 1) controlY = 1;
        }
    }
    
    
    public function beat(size:int) : void {
        pointerSize = size;
    }
}


