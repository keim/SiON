// Sample for event trigger
package {
    import flash.display.*;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.events.*;
    
    
    public class EventTrigger2 extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // MML data
        public var mainMelody:SiONData;

        // shape displays key of tracks
        public var keyShapes:Array;
        
        // constructor
        function main() {
            // compile with event trigger command (%t)
            var mml:String = "t100;";
            mml += "%3@8 l8 [ccggaag4 ffeeddc4 | [ggffeed4]2 ]2;";
            mml += "%3@8 l4 [o4ccfc >g<c>g<c | cccc ccc>g< ];"
            mml += "%3@8 l4 r8 [o4 ggag dgdg | gggg gggd ];"
            mainMelody = driver.compile(mml);
            
            // listen triggers
            driver.addEventListener(SiONEvent.STREAM_START, _onStreamStart);
            driver.addEventListener(SiONTrackEvent.NOTE_ON_FRAME,  _onNoteOn);
            driver.addEventListener(SiONTrackEvent.NOTE_OFF_FRAME, _onNoteOff);
            
            keyShapes = [_keyShape(0), _keyShape(1), _keyShape(2)];
            
            // play main melody
            driver.play(mainMelody);
        }
        
        
        // This event dispatched when ther streming starts.
        private function _onStreamStart(e:SiONEvent) : void {
            var i:int;
            var imax:int = driver.sequencer.tracks.length;  // <= same as driver.trackCount
            
            // set event trigger on all tracks. you can access them by driver.sequencer.tracks[].
            // but the driver.sequencer.tracks[] is available only after driver.play().
            for (i=0; i<imax; i++) {
                // The eventTriggerID (The 1st argument) is track number.
                driver.sequencer.tracks[i].setEventTrigger(i, 1, 1);
            }
        }
        
        
        // This event dispatched when note on
        private function _onNoteOn(e:SiONTrackEvent) : void {
            var keyShape:Shape = keyShapes[e.eventTriggerID];
            keyShape.x = (e.note - 40) * 16;
            keyShape.visible = true;
        }
        
        
        // This event dispatched when note off
        private function _onNoteOff(e:SiONTrackEvent) : void {
            keyShapes[e.eventTriggerID].visible = false;
        }
        
        
        // create shape
        private function _keyShape(id:int) : Shape {
            var shape:Shape = new Shape();
            shape.graphics.beginFill([0xff8080, 0x80ff80, 0x8080ff][id]);
            shape.graphics.drawCircle(0, 0, 20);
            shape.graphics.endFill();
            shape.visible = false;
            shape.y = id * 60 + 30;
            addChild(shape);
            return shape;
        }
    }
}

