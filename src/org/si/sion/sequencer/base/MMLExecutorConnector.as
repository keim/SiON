//----------------------------------------------------------------------------------------------------
//  MMLExecutor connector.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.sequencer.base {
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.module.channels.SiOPMChannelBase;
    
    
    /** @private MML executor connector. this class is used for #FM connection. */
    public class MMLExecutorConnector
    {
    // namespace
    //--------------------------------------------------
        use namespace _sion_sequencer_internal;
        
        
        
        
    // valiables
    //--------------------------------------------------
        private var _sequenceCount:int;    // sequence count
        private var _executorCount:int;    // executor count
        private var _firstElem:MECElement; // first information of connection
        
        
        
        
    // properties
    //--------------------------------------------------
        /** The count of require executor. */
        public function get executorCount() : int { return _executorCount; }
        /** The count of require sequence. */
        public function get sequenceCount() : int { return _sequenceCount; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        function MMLExecutorConnector()
        {
            _firstElem = null;
            _executorCount = 0;
            _sequenceCount = 0;
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Free all elements. */
        public function clear() : void
        {
            if (_firstElem) _free(_firstElem);
            function _free(elem:MECElement) : void {
                if (elem.firstChild) _free(elem.firstChild);
                if (elem.next)       _free(elem.next);
                MECElement.free(elem);
            }
            _firstElem = null;
            _executorCount = 0;
            _sequenceCount = 0;
        }
        
        
        /** Parse connection formula. */
        public function parse(form:String) : void
        {
            var i:int, imax:int, prev:MECElement=null, elem:MECElement;
            var alp:String = "abcdefghijklmnopqrstuvwxyz";
            var rex:RegExp = /(\()?([a-zA-Z])([0-7])?(\)+)?/g;
            
            // initialize
            clear();
            
            // parse
            var res:* = rex.exec(form);
            while (res) {
                // get current oscillator number
                i = alp.indexOf(res[2].toLowerCase());
                if (_sequenceCount <= i) _sequenceCount = i+1;
                _executorCount++;
                elem = MECElement.alloc(i);
                if (res[3]) elem.modulation = int(res[3]);
                else        elem.modulation = 5;
                
                // modulation start "("
                if (res[1]) {
                    if (!prev) throw _errorWrongFormula("'(' in " + form);
                    prev.firstChild = elem;
                    elem.parent = prev;
                } else {
                    if (prev) {
                        prev.next = elem;
                        elem.parent = prev.parent;
                    } else {
                        _firstElem = elem;
                    }
                }
                
                // modulation end ")+"
                if (res[4]) {
                    imax = String(res[4]).length;
                    for (i=0; i<imax; i++) { 
                        if (!elem.parent) throw _errorWrongFormula("')' in " + form);
                        elem = elem.parent; 
                    }
                }
                prev = elem;
                
                res = rex.exec(form);
            }
            
            if (prev==null || prev.parent!=null) {
                throw _errorWrongFormula(form);
            }
        }
        
        
        /** Connect executors. */
        public function connect(seqGroup:MMLSequenceGroup, prev:MMLSequence) : MMLSequence
        {
            // create sequence list
            var seqList:Array = new Array(_sequenceCount);
            for (var i:int=0; i<_sequenceCount; i++) {
                if (prev.nextSequence == null) throw _errorSequenceNotEnough();
                seqList[i] = prev.nextSequence;
                prev.nextSequence._removeFromChain();
            }
            
            // set executors connections
            _connect(_firstElem, false, -1);
            
            return prev;
            
            
            // connection sub
            function _connect(elem:MECElement, firstOsc:Boolean, outPipe:int) : void {
                var inPipe:int;
                // modulator before carrior
                if (elem.firstChild != null) {
                    inPipe = outPipe + ((firstOsc)?0:1);
                    _connect(elem.firstChild, true, inPipe);
                }

                // assign sequence to executor
                var preprocess:MMLSequence = seqGroup._newSequence();
                preprocess.initialize();
//trace("#FM "+elem.number+";");
                
                // out pipe
                if (outPipe != -1) {
                    preprocess.appendNewEvent(MMLEvent.OUTPUT_PIPE, (firstOsc) ? SiOPMChannelBase.OUTPUT_OVERWRITE : SiOPMChannelBase.OUTPUT_ADD);
                    preprocess.appendNewEvent(MMLEvent.PARAMETER,   outPipe);
//trace(" @o"+((firstOsc)?'1,':'2,')+outPipe);
                } else {
                    preprocess.appendNewEvent(MMLEvent.OUTPUT_PIPE, SiOPMChannelBase.OUTPUT_STANDARD);
                    preprocess.appendNewEvent(MMLEvent.PARAMETER,   0);
//trace(" @o0,0");
                }
                
                // in pipe
                if (elem.firstChild != null) {
                    preprocess.appendNewEvent(MMLEvent.INPUT_PIPE, elem.modulation);
                    preprocess.appendNewEvent(MMLEvent.PARAMETER,  inPipe);
//trace(" @i"+elem.modulation+","+inPipe);
                } else {
                    preprocess.appendNewEvent(MMLEvent.INPUT_PIPE, 0);
                    preprocess.appendNewEvent(MMLEvent.PARAMETER,  0);
//trace(" @i0,0");
                }
                
                // connect preprocess and main sequence
                preprocess.connectBefore(seqList[elem.number].headEvent.next);
                // connect preprocess on sequence chain
                preprocess._insertAfter(prev);
                prev = preprocess;
//trace(preprocess);

                // next oscillator
                if (elem.next != null) _connect(elem.next, false, outPipe);
            }
        }
        
        
        
        
    // errors
    //--------------------------------------------------
        private function _errorWrongFormula(form:String) : Error
        {
            return new Error("MMLExecutorConnector error : Wrong connection formula. " + form);
        }
        
        
        private function _errorSequenceNotEnough() : Error
        {
            return new Error("MMLExecutorConnector error: Not enough sequences to connect.");
        }
    }
}




// MMLExecutorConnector element class
class MECElement
{
    public var number    :int;
    public var modulation:int;
    public var parent    :MECElement = null;
    public var next      :MECElement = null;
    public var firstChild:MECElement = null;
    
    function MECElement()
    {
    }
    
    public function initialize(num:int) : MECElement
    {
        number = num;
        parent = null;
        next = null;
        firstChild = null;
        modulation = 3;
        return this;
    }
    
    
    // Factory
    static private var _freeList:Array = [];
    static public function free(elem:MECElement) : void {
        _freeList.push(elem);
    }
    static public function alloc(number:int) : MECElement {
        var elem:MECElement = _freeList.pop() || new MECElement();
        return elem.initialize(number);
    }
}





