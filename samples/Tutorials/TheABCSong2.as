// simple example
package {
    import flash.display.Sprite;
    import org.si.sion.*;
    
    public class TheABCSong2 extends Sprite {
        public var driver:SiONDriver = new SiONDriver();
        public var data:SiONData;
        
        function TheABCSong2() {
            data = driver.compile("t100 l8 [ccggaag4 ffeeddc4 | [ggffeed4]2 ]2");
            driver.play(data);
        }
    }
}

