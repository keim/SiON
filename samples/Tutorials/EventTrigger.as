// Sample for event trigger
package {
    import flash.display.*;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.events.*;
    
    
    public class EventTrigger extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // MML data
        public var mainMelody:SiONData;

        
        // constructor
        function EventTrigger() {
            // compile with event trigger command (%t)
            mainMelody = driver.compile("%t0,1,1 t100 l8 [ccggaag4 ffeeddc4 | [ggffeed4]2 ]2");
            
            // listen triggers
            driver.addEventListener(SiONTrackEvent.NOTE_ON_FRAME,  _onNoteOn);
            driver.addEventListener(SiONTrackEvent.NOTE_OFF_FRAME, _onNoteOff);
            addEventListener("enterFrame", _onEnterFrame);
            
            // play main melody
            driver.play(mainMelody);
        }
        
        
        // This event dispatched when note on
        private function _onNoteOn(e:SiONTrackEvent) : void {
            _createNoteShape(e.note);
        }
        
        
        // This event dispatched when note off
        private function _onNoteOff(e:SiONTrackEvent) : void {
        }
        
        
        // create shape
        private function _createNoteShape(noteNumber:int) : Shape {
            var shape:Shape = new Shape();
            shape.graphics.beginFill([0xff8080, 0x80ff80, 0x8080ff, 0xffff80][int(Math.random()*4)]);
            shape.graphics.drawCircle(0, 0, Math.random()*20+10);
            shape.graphics.endFill();
            shape.x = (noteNumber - 60) * 30 + 100;
            shape.y = 300;
            addChild(shape);
            return shape;
        }
        
        
        // on each frame
        private function _onEnterFrame(e:Event) : void {
            var imax:int = numChildren;
            for (var i:int=0; i<imax; i++) {
                var child:DisplayObject = getChildAt(i);
                child.y -= 2;
                child.alpha *= 0.98;
                if (child.y < -30 || child.alpha < 0.1) {
                    removeChild(child);
                    imax--;
                    i--;
                }
            }
        }
    }
}

