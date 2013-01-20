// Sample for note on ecxeption mode
package {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.utils.SiONPresetVoice;
    
    
    public class NoteOnException extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // voice for sampler "%5,5"
        public var squareWave:SiONVoice = new SiONVoice(5,5);
        
        // note on exception mode 
        public var exceptionMode:Array = [{name:"ignore",    mode:SiONDriver.NEM_IGNORE},
                                          {name:"reject",    mode:SiONDriver.NEM_REJECT},
                                          {name:"overwrite", mode:SiONDriver.NEM_OVERWRITE},
                                          {name:"shift",     mode:SiONDriver.NEM_SHIFT}];
        
        // index
        public var exceptionModeIndex:int;
        
        // text field
        public var tf:TextField = new TextField();
        
        
        // constructor
        function NoteOnException() {
            // display text
            addChild(tf);
            
            // initialize index
            exceptionModeIndex = 3;
            
            // listen click
            stage.addEventListener("click", _onClick);
            
            // play without data. This only starts streaming.
            driver.play();
        }
        
        
        private function _onClick(e:Event) : void
        {
            _changeExceptionMode();
            // note on at same time, same trackID = 0
            driver.noteOn(60, squareWave, 4, 0, 1, 0);   // o5c
            driver.noteOn(64, squareWave, 4, 0, 1, 0);   // o5e   
            driver.noteOn(67, squareWave, 4, 0, 1, 0);   // o5g
        }
        
        private function _changeExceptionMode() : void
        {
            if (++exceptionModeIndex >= exceptionMode.length) exceptionModeIndex = 0;
            tf.htmlText = "<font color='#808080'>" + exceptionMode[exceptionModeIndex].name + "</font>";
            
            // set note on exception mode
            driver.noteOnExceptionMode = exceptionMode[exceptionModeIndex].mode;
        }
    }
}

