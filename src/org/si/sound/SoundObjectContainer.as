//----------------------------------------------------------------------------------------------------
// Sound object container
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.*;
    import org.si.sound.synthesizers.*;
    import org.si.sound.core.EffectChain;
    import org.si.sound.namespaces._sound_object_internal;
    
    
    /** The SoundObjectContainer class is the base class for all objects that can serve as sound object containers on the sound list. 
     */
    public class SoundObjectContainer extends SoundObject
    {
    // namespace
    //----------------------------------------
        use namespace _sound_object_internal;
        
        
        
        
    // valiables
    //----------------------------------------
        /** @private [protected] the list of child sound objects. */
        protected var _soundList:Vector.<SoundObject>;
        
        /** @private [protected] playing flag of this container */
        protected var _isPlaying:Boolean;
        
        
        
        
    // properties
    //----------------------------------------
        /** Returns the number of children of this object. */
        public function get numChildren() : int { return _soundList.length; }
        
        
        
        
        
        
    // properties
    //----------------------------------------
        /** @private */
        override public function get isPlaying() : Boolean { return _isPlaying; }
        
        
        /** @private */
        override public function set note(n:int) : void {
            _note = n;
            for each (var sound:SoundObject in _soundList) sound.note = n;
        }

        /** @private */
        override public function set voice(v:SiONVoice) : void { 
            super.voice = v;
            for each (var sound:SoundObject in _soundList) sound.voice = v;
        }

        /** @private */
        override public function set synthesizer(s:VoiceReference) : void {
            super.synthesizer = s;
            for each (var sound:SoundObject in _soundList) sound.synthesizer = s;
        }
        
        /** @private */
        override public function set length(l:Number) : void {
            _length = l;
            for each (var sound:SoundObject in _soundList) sound.length = l;
        }
        /** @private */
        override public function set quantize(q:Number) : void {
            _quantize = q;
            for each (var sound:SoundObject in _soundList) sound.quantize = q;
        }
        /** @private */
        override public function set delay(d:Number) : void {
            _delay = d;
            for each (var sound:SoundObject in _soundList) sound.delay = d;
        }
        
        
        /** @private */
        override public function set eventMask(m:int) : void {
            _eventMask = m;
            for each (var sound:SoundObject in _soundList) sound.eventMask = m;
        }
        /** @private */
        override public function set eventTriggerID(id:int) : void {
            _eventTriggerID = id;
            for each (var sound:SoundObject in _soundList) sound.eventTriggerID = id;
        }
        /** @private */
        override public function set coarseTune(n:int) : void {
            _noteShift = n;
            for each (var sound:SoundObject in _soundList) sound.coarseTune = n;
        }
        /** @private */
        override public function set fineTune(p:Number) : void {
            _pitchShift = p;
            for each (var sound:SoundObject in _soundList) sound.fineTune = p;
        }
        /** @private */
        override public function set gateTime(g:Number) : void {
            _gateTime = (g<0) ? 0 : (g>1) ? 1 : g;
            for each (var sound:SoundObject in _soundList) sound.gateTime = g;
        }
        
        
        /** @private */
        override public function set effectSend1(v:Number) : void {
            _volumes[1] = (v<0) ? 0 : (v>1) ? 1 : (v * 128);
            for each (var sound:SoundObject in _soundList) sound.effectSend1 = v;
        }
        /** @private */
        override public function set effectSend2(v:Number) : void {
            _volumes[2] = (v<0) ? 0 : (v>1) ? 1 : (v * 128);
            for each (var sound:SoundObject in _soundList) sound.effectSend2 = v;
        }
        /** @private */
        override public function set effectSend3(v:Number) : void {
            _volumes[3] = (v<0) ? 0 : (v>1) ? 1 : (v * 128);
            for each (var sound:SoundObject in _soundList) sound.effectSend3 = v;
        }
        /** @private */
        override public function set effectSend4(v:Number) : void {
            _volumes[4] = (v<0) ? 0 : (v>1) ? 1 : (v * 128);
            for each (var sound:SoundObject in _soundList) sound.effectSend4 = v;
        }
        /** @private */
        override public function set pitchBend(p:Number) : void {
            _pitchBend = p;
            for each (var sound:SoundObject in _soundList) sound.pitchBend = p;
        }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor. */
        function SoundObjectContainer(name:String = "")
        {
            super(name);
            _soundList = new Vector.<SoundObject>();
            _thisVolume = 1;
            _isPlaying = false;
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** @inheritDoc */
        override public function reset() : void
        {
            super.reset();
            _thisVolume = 1;
            for each (var sound:SoundObject in _soundList) sound.reset();
        }
        
        
        /** Set all children's volume by index.
         *  @param slot streaming slot number.
         *  @param volume volume (0:Minimum - 1:Maximum).
         */
        override public function setVolume(slot:int, volume:Number) : void 
        {
            _volumes[slot] = (volume<0) ? 0 : (volume>1) ? 128 : (volume * 128);
            for each (var sound:SoundObject in _soundList) sound.setVolume(slot, _volumes[slot]);
        }
        
        
        /** Play all children sound. */
        override public function play() : void
        {
            _isPlaying = true;
            if (_effectChain && _effectChain.effectList.length > 0) {
                _effectChain._activateLocalEffect(_childDepth);
                _effectChain.setAllStreamSendLevels(_volumes);
            }
            for each (var sound:SoundObject in _soundList) sound.play();
        }
        
        
        /** Stop all children sound. */
        override public function stop() : void
        {
            _isPlaying = false;
            for each (var sound:SoundObject in _soundList) sound.stop();
            if (_effectChain) {
                _effectChain._inactivateLocalEffect();
                if (_effectChain.effectList.length == 0) {
                    _effectChain.free();
                    _effectChain = null;
                }
            }
        }
        
        
        
        
    // operations for children
    //----------------------------------------
        /** Adds a child SoundObject instance to this SoundObjectContainer instance. The added sound object will play sound during this container is playing.
         *  The child is added to the end of all other children in this SoundObjectContainer instance. (To add a child to a specific index position, use the addChildAt() method.)
         *  If you add a child object that already has a different sound object container as a parent, the object is removed from the child list of the other sound object container. 
         *  @param sound The SoundObject instance to add as a child of this SoundObjectContainer instance.
         *  @return The SoundObject instance that you pass in the sound parameter
         */
        public function addChild(sound:SoundObject) : SoundObject
        {
            sound.stop();
            sound._setParent(this);
            _soundList.push(sound);
            if (_isPlaying) sound.play();
            return sound;
        }
        
        
        /** Adds a child SoundObject instance to this SoundObjectContainer instance. The added sound object will play sound during this container is playing.
         *  The child is added at the index position specified. An index of 0 represents the head of the sound list for this SoundObjectContainer object. 
         *  @param sound The SoundObject instance to add as a child of this SoundObjectContainer instance.
         *  @param index The index position to which the child is added. If you specify a currently occupied index position, the child object that exists at that position and all higher positions are moved up one position in the child list.
         *  @return The child sound object at the specified index position.
         */
        public function addChildAt(sound:SoundObject, index:int) : SoundObject
        {
            sound.stop();
            sound._setParent(this);
            if (index < _soundList.length) _soundList.splice(index, 0, sound);
            else _soundList.push(sound);
            if (_isPlaying) sound.play();
            return sound;
        }
        
        
        /** Removes the specified child SoundObject instance from the child list of the SoundObjectContainer instance. The removed sound object always stops.
         *  The parent property of the removed child is set to null, and the object is garbage collected if no other references to the child exist.
         *  The index positions of any sound objects after the child in the SoundObjectContainer are decreased by 1.
         *  @param sound The DisplayObject instance to remove
         *  @return The SoundObject instance that you pass in the sound parameter.
         */
        public function removeChild(sound:SoundObject) : SoundObject
        {
            var index:int = _soundList.indexOf(sound);
            if (index == -1) throw Error("SoundObjectContainer Error; Specifyed children is not in the children list.");
            _soundList.splice(index, 1);
            sound.stop();
            sound._setParent(null);
            return sound;
        }
        
        
        /** Removes a child SoundObject from the specified index position in the child list of the SoundObjectContainer. The removed sound object always stops.
         *  The parent property of the removed child is set to null, and the object is garbage collected if no other references to the child exist. 
         *  The index positions of any display objects above the child in the DisplayObjectContainer are decreased by 1. 
         *  @param The child index of the SoundObject to remove. 
         *  @return The SoundObject instance that was removed. 
         */
        public function removeChildAt(index:int) : SoundObject
        {
            if (index >= _soundList.length) throw Error("SoundObjectContainer Error; Specifyed index is not in the children list.");
            var sound:SoundObject = _soundList.splice(index, 1)[0];
            sound.stop();
            sound._setParent(null);
            return sound;
        }
        
        
        /** Returns the child sound object instance that exists at the specified index.
         *  @param The child index of the SoundObject to find.
         *  @return founded SoundObject instance.
         */
        public function getChildAt(index:int) : SoundObject
        {
            if (index >= _soundList.length) throw Error("SoundObjectContainer Error; Specifyed index is not in the children list.");
            return _soundList[index];
        }
        
        
        /** Returns the child sound object that exists with the specified name. 
         *  If more than one child sound object has the specified name, the method returns the first object in the child list.
         *  @param The child name of the SoundObject to find.
         *  @return founded SoundObject instance. Returns null if its not found.
         */ 
        public function getChildByName(name:String) : SoundObject
        {
            for each (var sound:SoundObject in _soundList) {
                if (sound.name == name) return sound;
            }
            return null;
        }
        
        
        /** Returns the index position of a child SoundObject instance. 
         *  @param sound The SoundObject instance want to know.
         *  @return index of specifyed SoundObject. Returns -1 if its not found.
         */
        public function getChildIndex(sound:SoundObject) : Number
        {
            return _soundList.indexOf(sound);
        }
        
        
        /** Changes the position of an existing child in the sound object container. This affects the processing order of child objects. 
         *  @param child The child SoundObject instance for which you want to change the index number. 
         *  @param index The resulting index number for the child sound object.
         *  @param The SoundObject instance that you pass in the child parameter.
         */
        public function setChildIndex(child:SoundObject, index:int) : SoundObject
        {
            return addChildAt(removeChild(child), index);
        }
        
        
        
        
    // oprate ancestor
    //----------------------------------------
        /** @private [internal use] */
        override internal function _updateChildDepth() : void
        {
            _childDepth = (parent) ? (parent._childDepth + 1) : 0;
            for each (var sound:SoundObject in _soundList) sound._updateChildDepth();
        }
        
        
        /** @private [internal use] */
        override internal function _updateMute() : void
        {
            super._updateMute();
            for each (var sound:SoundObject in _soundList) sound._updateMute();
        }
        
        
        /** @private [internal use] */
        override internal function _updateVolume() : void
        {
            super._updateVolume();
            for each (var sound:SoundObject in _soundList) sound._updateVolume();
        }
        
        
        /** @private [internal use] */
        override internal function _limitVolume() : void
        {
            super._limitVolume();
            for each (var sound:SoundObject in _soundList) sound._limitVolume();
        }
        
        
        /** @private [internal use] */
        override internal function _updatePan() : void
        {
            super._updatePan();
            for each (var sound:SoundObject in _soundList) sound._updatePan();
        }
        
        
        /** @private [internal use] */
        override internal function _limitPan() : void
        {
            super._limitPan();
            for each (var sound:SoundObject in _soundList) sound._limitPan();
        }
    }
}


