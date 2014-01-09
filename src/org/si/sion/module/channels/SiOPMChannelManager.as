//----------------------------------------------------------------------------------------------------
// SiOPM sound channel manager
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module.channels {
    import org.si.sion.module.SiOPMModule;
    
    
    /** @private SiOPM sound channel manager */
    public class SiOPMChannelManager
    {
    // constants
    //--------------------------------------------------
        static public const CT_CHANNEL_FM:int = 0;
        static public const CT_CHANNEL_PCM:int = 1;
        static public const CT_CHANNEL_SAMPLER:int = 2;
        static public const CT_CHANNEL_KS:int = 3;
        static public const CT_MAX:int = 4;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** class instance of SiOPMChannelBase */
        private var _channelClass:Class;
        /** channel type */
        private var _channelType:int;
        /** terminator */
        private var _term:SiOPMChannelBase;
        /** channel count */
        private var _length:int;
        
        
        
    // properties
    //--------------------------------------------------
        /** allocated channel count */
        public function get length() : int { return _length; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function SiOPMChannelManager(channelClass:Class, channelType:int)
        {
            _channelType  = channelType;
            _channelClass = channelClass;
            _term = new SiOPMChannelBase(_chip);
            _term._isFree = false;
            _term._next = _term;
            _term._prev = _term;
            _length = 0;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        // allocate channels.
        private function _alloc(count:int) : void
        {
            var i:int, newInstance:SiOPMChannelBase, imax:int = count - _length;
            // allocate new channels
            for (i=0; i<imax; i++) {
                newInstance = new _channelClass(_chip);
                newInstance._channelType = _channelType;
                newInstance._isFree = true;
                newInstance._prev = _term._prev;
                newInstance._next = _term;
                newInstance._prev._next = newInstance;
                newInstance._next._prev = newInstance;
                _length++;
            }
        }
        
        
        // get new channel. returns null when the channel count is overflow.
        private function _newChannel(prev:SiOPMChannelBase, bufferIndex:int) : SiOPMChannelBase
        {
            var newChannel:SiOPMChannelBase;
            if (_term._next._isFree) {
                // The head channel is free -> The head will be a new channel.
                newChannel = _term._next;
                newChannel._prev._next = newChannel._next;
                newChannel._next._prev = newChannel._prev;
            } else {
                // The head channel is active -> channel overflow.
                // create new channel.
                newChannel = new _channelClass(_chip);
                newChannel._channelType = _channelType;
                _length++;
            }
            
            // set newChannel to tail and activate.
            newChannel._isFree = false;
            newChannel._prev = _term._prev;
            newChannel._next = _term;
            newChannel._prev._next = newChannel;
            newChannel._next._prev = newChannel;
            
            // initialize
            newChannel.initialize(prev, bufferIndex);
            
            return newChannel;
        }
        
        
        // delete channel.
        private function _deleteChannel(ch:SiOPMChannelBase) : void
        {
            ch._isFree = true;
            ch._prev._next = ch._next;
            ch._next._prev = ch._prev;
            ch._prev = _term;
            ch._next = _term._next;
            ch._prev._next = ch;
            ch._next._prev = ch;
        }
        
        
        // initialize all channels
        private function _initializeAll() : void
        {
            var ch:SiOPMChannelBase;
            for (ch=_term._next; ch!=_term; ch=ch._next) {
                ch._isFree = true;
                ch.initialize(null, 0);
            }
        }
        
        
        // reset all channels
        private function _resetAll() : void
        {
            var ch:SiOPMChannelBase;
            for (ch=_term._next; ch!=_term; ch=ch._next) {
                ch._isFree = true;
                ch.reset();
            }
        }
        
        
        
        
    // factory
    //----------------------------------------
        static private var _chip:SiOPMModule;                               // module instance
        static private var _channelManagers:Vector.<SiOPMChannelManager>;   // manager list
        
        
        /** initialize */
        static public function initialize(chip:SiOPMModule) : void 
        {
            _chip = chip;
            _channelManagers = new Vector.<SiOPMChannelManager>(CT_MAX, true);
            _channelManagers[CT_CHANNEL_FM]      = new SiOPMChannelManager(SiOPMChannelFM,      CT_CHANNEL_FM);
            _channelManagers[CT_CHANNEL_PCM]     = new SiOPMChannelManager(SiOPMChannelPCM,     CT_CHANNEL_PCM);
            _channelManagers[CT_CHANNEL_SAMPLER] = new SiOPMChannelManager(SiOPMChannelSampler, CT_CHANNEL_SAMPLER);
            _channelManagers[CT_CHANNEL_KS]      = new SiOPMChannelManager(SiOPMChannelKS,      CT_CHANNEL_KS);
        }
        
        
        /** initialize all channels */
        static public function initializeAllChannels() : void
        {
            // initialize all channels
            for each (var mng:SiOPMChannelManager in _channelManagers) {
                mng._initializeAll();
            }
        }
        
        
        /** reset all channels */
        static public function resetAllChannels() : void
        {
            // reset all channels
            for each (var mng:SiOPMChannelManager in _channelManagers) {
                mng._resetAll();
            }
        }
        
        
        /** New channel with initializing. */
        static public function newChannel(type:int, prev:SiOPMChannelBase, bufferIndex:int) : SiOPMChannelBase
        {
            return _channelManagers[type]._newChannel(prev, bufferIndex);
        }
        
        
        /** Free channel. */
        static public function deleteChannel(channel:SiOPMChannelBase) : void
        {
            _channelManagers[channel._channelType]._deleteChannel(channel);
        }
    }
}

