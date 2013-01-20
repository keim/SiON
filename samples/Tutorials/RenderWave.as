// Sample for rendering wave data and loading as a sampler's data.
package {
    import flash.display.Sprite;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.utils.SiONPresetVoice;
    
    
    public class RenderWave extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // preset voice
        public var presetVoice:SiONPresetVoice = new SiONPresetVoice();
        
        // voice for sampler "%10"
        public var samplerVoice:SiONVoice = new SiONVoice(10);
        
        // MML data
        public var drumLoop:SiONData;
        public var hiQue:SiONData;
        public var mainMelody:SiONData;
        
        // wave data
        public var drumLoopWave:Vector.<Number>;
        public var hiQueWave:Vector.<Number>;
        
        // constructor
        function RenderWave() {
            // compile mml. 
            // [CAUTION!!] The rendering takes very long time. So the rendering MML must be short and NEVER loop infinitly.
            drumLoop = driver.compile("#EFFECT0{ws95lf4000}; %6@0o3l8c2cc.c.; %6@1o3rcrc; %6@2v8l16[crccrrcc]; %6@3v8o3[rc8r8]")
            hiQue = driver.compile("#EFFECT0{ws90};%5v24@0s63o6g16*o3c192");
            
            // set voices of "%6@0-3" from preset
            var percusVoices:Array = presetVoice["valsound.percus"];
            drumLoop.setVoice(0, percusVoices[0]);  // bass drum
            drumLoop.setVoice(1, percusVoices[27]); // snare drum
            drumLoop.setVoice(2, percusVoices[16]); // close hihat
            drumLoop.setVoice(3, percusVoices[21]); // open hihat

            // Render the data to wave. The rendered data is Vector.<Number> ranged between -1 and 1.
            drumLoopWave = driver.render(drumLoop);
            hiQueWave = driver.render(hiQue);
            
            
            // compile data that plays drum loop by sampler module ("%10o5c").
            mainMelody = driver.compile("%6@0l16o3$aa<c8>a<d8>a<d+8d+edc>ag; %10q8o5$c1");
            
            // set voice of "%6@0" bass line
            mainMelody.setVoice(0, presetVoice["valsound.bass8"]);
            
            // load wave samples for "%10". The note number of "o5c" is 60.
            mainMelody.setSamplerData(60, drumLoopWave);    // #60 = "%10o5c"
            mainMelody.setSamplerData(62, hiQueWave);       // #62 = "%10o5d"
            
            // listen click
            stage.addEventListener("click", _onClick);
            
            // note on exception mode set to "reject".
            // in this mode, reject new note when the track with same ID already exists at the same timing.
            driver.noteOnExceptionMode = SiONDriver.NEM_REJECT;
            
            // ...and play it
            driver.play(mainMelody);
        }
        
        
        private function _onClick(e:Event) : void
        {
            // note on sampler's note. note number #62 = hiQueWave
            driver.noteOn(62, samplerVoice, 0, 0, 1);
        }
    }
}

