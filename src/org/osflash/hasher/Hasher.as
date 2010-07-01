package org.osflash.hasher {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;

	/**
	 * Hasher - History Manager for rich-media applications.
	 * - Bridge for Hasher.js methods and also allows the application to work outside the browser and/or without any JavaScript calls.
	 * @requires Hasher.js <http://github.com/millermedeiros/Hasher/>
	 * @author Lucas Motta <http://www.lucasmotta.com>, Miller Medeiros <http://www.millermedeiros.com>
	 * @version 0.2
	 */
	public class Hasher {

		//---------------------------------------
		// VARIABLES
		//---------------------------------------
		
		/** Event Dispatcher, used composition instead of inheritance */
		private static var _dispatcher:EventDispatcher = new EventDispatcher();
		
		/** Stores random ID used to identify flash movie */
		private static var _flashMovieId:String;
		
		/** If ExternalInterface is available */
		private static var _isExternalAvailable:Boolean;
		
		/** If Flash movie is registered and Hasher was initialized */
		private static var _isInitialized:Boolean;
		
		/**  Hash string */
		private static var _hash:String = "";
		
		/** Page title */
		private static var _title:String = "";
		
		/** Javascript methods */
		private static var _scripts:XML = <scripts>
			<getHasher>
				<![CDATA[
					function(){ return Hasher; }
				]]>
			</getHasher>
			<registerFlash>
			    <![CDATA[
			    	//Stores a reference to the flash movie that will be used later to attach/detach event listeners/callbacks
		        	function(){
		        		var objects = document.getElementsByTagName('object');
		        		var embeds = document.getElementsByTagName('embed');
		        		var flashMovies = objects.concat(embeds);
		        		var flashMovieId = '::flashMovieId::';
		        		var n = flashMovies.length;
		        		for(var i=0; i<n; i++){
		        			if(flashMovieId in flashMovies[i]){
		        				if(!Hasher._registeredFlashMovies){
		        					Hasher._registeredFlashMovies = {};
		        				}
		        				Hasher._registeredFlashMovies[::flashMovieId::] = flashMovies[i];
		        				break;
		        			}
		        		}
		        	}
			    ]]>
		    </registerFlash>
		    <attachInit>
			    <![CDATA[
			        function() {
			        	Hasher.addEventListener(HasherEvent.INIT,
			        		function(evt){
			        			Hasher._registeredFlashMovies[::flashMovieId::].Hasher_init(evt);
			        		}
			        	);
			        }
			    ]]>
		    </attachInit>
		    <attachStop>
			    <![CDATA[
			        function() {
			        	Hasher.addEventListener(HasherEvent.STOP,
			        		function(e){
			        			Hasher._registeredFlashMovies[::flashMovieId::].Hasher_stop(evt);
			        		}
			        	);
			        }
			    ]]>
		    </attachStop>
		    <attachChange>
			    <![CDATA[
			        function() {
			        	Hasher.addEventListener(HasherEvent.CHANGE,
			        		function(e){
			        			Hasher._registeredFlashMovies[::flashMovieId::].Hasher_change(evt);
			        		}
			        	);
			        }
			    ]]>
		    </attachChange>
		</scripts>;

		//---------------------------------------
		// CONSTRUCTOR
		//---------------------------------------
		
		/**
		 * Constructor (Static Class)
		 * @private
		 */
		public function Hasher() {
			throw Error('this is a static class and should not be instantiated.');
		}

		//---------------------------------------
		// EVENT DISPATCHER
		//---------------------------------------
		
		// Favored Composition over inheritance so we can have a Static Class instead of a Singleton Class.
		
		/**
		 * Registers an event listener
		 * @param	type	Event type
		 * @param	listener	Event listener
		 * @param	useCapture	Determines whether the listener works in the capture phase or the target and bubbling phases
		 * @param	priority	The priority level of the event listener
		 * @param	useWeakReference	Determines whether the reference to the listener is strong or weak
		 */
		public static function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

		/**
		 * Removes an event listener
		 * @param	type	Event type
		 * @param	listener	Event listener
		 */
		public static function removeEventListener(type:String, listener:Function):void {
			_dispatcher.removeEventListener(type, listener, false);
		}

		/**
		 * Dispatches an event to all the registered listeners.
		 * @param	event	Event object
		 */
		public static function dispatchEvent(event:Event):Boolean {
			return _dispatcher.dispatchEvent(event);
		}

		/**
		 * Checks the existance of any listeners registered for a specific type of event
		 * @param	type	Event type
		 */
		public static function hasEventListener(type:String):Boolean {
			return _dispatcher.hasEventListener(type);
		}

		//---------------------------------------
		// GETTERS AND SETTERS
		//---------------------------------------
		
		/**
		 * Hash value without '#'.
		 */
		public static function get hash():String {
			return call("Hasher.getHash", _hash);
		}
		public static function set hash(value:String):void {
			_hash = value;
			
			call("Hasher.setHash", _hash, _hash);
			if(!_isExternalAvailable) onChange();
		}

		/**
		 * Page title
		 */
		public static function get title():String {
			return call("Hasher.getTitle", _title);
		}
		public static function set title(value:String):void {
			_title = value;
			call("Hasher.setTitle", _title, value);
		}

		/**
		 * Retrieve full URL.
		 * @return {String}	Full URL.
		 */
		public static function get url():String {
			return call("Hasher.getURL", "");
		}

		/**
		 * Retrieve URL without query string and hash.
		 * @return {String}	Base URL.
		 */
		public function get baseUrl():String {
			return call("Hasher.getBaseURL", "");
		}

		//---------------------------------------
		// PUBLIC METHODS
		//---------------------------------------
		
		/**
		 * Return hash value as Array.
		 * @param separator	String used to divide hash (default = '/').	
		 * @return Hash splitted into an Array.  
		 */
		public static  function getHashAsArray(separator:String = '/'):Array {
			var regexp:RegExp = new RegExp('^\\'+ separator +'|\\'+ separator +'$', 'g'); //match separator at the end or begin of string
			var hash:String = Hasher.hash.replace(regexp, '');
			return hash.split(separator);
		}
		
		/**
		 * Navigate to previous page in history
		 */
		public static function back():void {
			call("Hasher.back");
		}

		/**
		 * Navigate to next page in history
		 */
		public static function forward():void {
			call("Hasher.forward");
		}

		/**
		 * Loads a page from the session history, identified by its relative location to the current page.
		 * - for example `-1` loads previous page, `1` loads next page.
		 * @param {int} delta	Relative location to the current page.
		 */
		public static function go(delta:int):void {
			call("Hasher.go", null, delta);
		}

		//---------------------------------------
		// PRIVATE AND PROTECTED METHODS
		//---------------------------------------
		protected static function init():void {
			if(ExternalInterface.available) {
				_objectId = ExternalInterface.objectID; //TODO: generate random flashMovieId
				
				// Check if the Hasher class is included
				if(ExternalInterface.call(getScript("gethasher")) == undefined) {
					onInit();
					return;
				}
				
				_isExternalAvailable = true;
				ExternalInterface.addCallback("Hasher_change", onChange);
				ExternalInterface.addCallback("Hasher_init", onInit);
				ExternalInterface.addCallback("Hasher_stop", onStop);
				ExternalInterface.call(getScript("attachInit"));
				ExternalInterface.call(getScript("attachChange"));
				ExternalInterface.call(getScript("attachStop"));
				ExternalInterface.call("Hasher.init");
			}
		}
		
		/**
		 * Get Javascript function
		 * @param nodeName	Node that contain script
		 */
		private static function getScript(nodeName:String):String {
			var node:XMLList = _scripts[nodeName] as XMLList;
			return node.toString().replace("::flashMovieId::", _flashMovieId);
		}
		
		/**
		 * Call a Javascript method and/or returns default value
		 * @param action	Function Name or String representing the function that should be called. 
		 * @param alternativeReturn	Alternative return value if ExternalInterface isn't available.
		 * @param args	Arguments passed to the JavaScript function.
		 */
		private static function call(action:String, alternativeReturn:* = null, ...args):* {
			if(!_isInitialized) throw new Error("You need to wait for the application be initialized.");
			if(_isExternalAvailable) return ExternalInterface.call(action, args) as String;
			return alternativeReturn;
		}

		//---------------------------------------
		// EVENT HANDLERS
		//---------------------------------------
		private static function onChange(evt:Object = null):void {
			
		}

		private static function onInit(evt:Object = null):void {
			_isInitialized = true;
		}

		private static function onStop(evt:Object = null):void {
		}
	}
}
