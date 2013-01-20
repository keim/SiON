package org.si.utils {
    import flash.display.DisplayObjectContainer;
    import flash.text.TextField;
    import flash.events.Event;
    import flash.utils.getTimer;
    
    
    /** static timer class */
    public class timer {
        static public var title:String = "";
        static private var _text:TextField = null;
        static private var _time:Vector.<int>;
        static private var _sum :Vector.<int>;
        static private var _stat:Vector.<String>;
        static private var _cnt :int;
        static private var _avc:int;
        
        
        /** initialize timer.
         *  @param parent parent object
         *  @param averagingCount averaging frames
         *  @param stat texts to display measured times. "##" is replaced with measured time.
         */
        static public function initialize(parent:DisplayObjectContainer, averagingCount:int, ...stat) : void {
            if (!_text) parent.addChild(_text = new TextField());
            _avc  = averagingCount;
            _stat = Vector.<String>(stat);
            _time = new Vector.<int>(stat.length);
            _sum  = new Vector.<int>(stat.length);
            _cnt  = new Vector.<int>(stat.length);
            _text.background = true;
            _text.backgroundColor = 0x80c0f0;
            _text.autoSize = "left";
            _text.multiline = true;
            parent.addEventListener("enterFrame", _onEnterFrame);
        }
        
        /** start timer */
        static public function start(slot:int=0) : void { _time[slot] = getTimer(); }
        
        /** pause timer */
        static public function pause(slot:int=0) : void { _sum[slot] += getTimer() - _time[slot]; }
        
        // enter frame event handler
        static private function _onEnterFrame(e:Event) : void {
            if (++_cnt == _avc) {
                _cnt = 0;
                var str:String = "", line:String;
                for (var slot:int = 0; slot<_sum.length; slot++) {
                    line = _stat[slot].replace("##", String(_sum[slot] / _avc).substr(0,3));
                    str += line + "\n";
                    _sum[slot] = 0;
                }
                _text.text = title + "\n" + str;
            }
        }
    }
}

