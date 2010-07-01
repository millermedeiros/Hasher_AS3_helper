package org.osflash.hasher {
	import flash.events.Event;

	/**
	 * Hasher Event
	 * @author Miller Medeiros <http://www.millermedeiros.com/>
	 * @version 0.1 (2010/07/01)
	 */
	public class HasherEvent extends Event {
		
		//---------------------------------------
		// CONSTANTS
		//---------------------------------------
		
		/** Defines the value of the type property of a change event object. */
		public static const CHANGE:String = "change";
		
		/** Defines the value of the type property of an init event object. */
		public static const INIT:String = "init";
		
		/** Defines the value of the type property of a stop event object. */
		public static const STOP:String = "stop";
		
		//---------------------------------------
		// VARIABLES
		//---------------------------------------
		
		/** Previous Hash value */
		public var oldHash:String;
		
		/** Curent Hash value */
		public var newHash:String;

		//---------------------------------------
		// METHODS
		//---------------------------------------
		
		/**
		 * HasherEvent
		 * @param type	Hasher Event type
		 * @param oldHash	Previous Hash value.
		 * @param newHash	Current Hash value.
		 */
		public function HasherEvent(type:String, oldHash:String = "", newHash:String = "") {
			super(type, false, false);
			this.oldHash = oldHash;
			this.newHash = newHash;
		}
		
		/**
		 * Returns string representation of the HasherEvent
		 */
		override public function toString():String {
			return '[HasherEvent type="'+ type +'" oldHash="'+ oldHash +'" newHash="'+ newHash +'"]';
		}
	}
}
