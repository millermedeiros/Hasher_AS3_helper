package org.osflash.hasher {
	import flash.utils.setTimeout;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;

	/**
	 * Hasher - History Manager for rich-media applications. <http://github.com/millermedeiros/Hasher_AS3_helper/>
	 * - Bridge for Hasher.js methods and also allows the application to work outside the browser and/or without any JavaScript calls.
	 * @requires Hasher.js <http://github.com/millermedeiros/Hasher/>
	 * @author Miller Medeiros <http://www.millermedeiros.com>, Lucas Motta <http://www.lucasmotta.com>
	 * @version 0.5 (2010/07/27)
	 * Released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 */
	public class Hasher {

		//---------------------------------------
		// VARIABLES
		//---------------------------------------
		
		/** Event Dispatcher, used composition instead of inheritance */
		private static var _dispatcher:EventDispatcher = new EventDispatcher();
		
		/** Stores random ID used to identify flash movie */
		private static var _flashMovieId:String;
		
		/** If ExternalInterface is available and the JavaScript Hasher object exists */
		private static var _isHasherJSAvailable:Boolean;
		
		/** If Flash movie is registered and Hasher was initialized */
		private static var _isRegistered:Boolean;
		
		/** If Hasher is active and should listen/dispatch changes on the hash */
		private static var _isActive:Boolean;
		
		/** If current hash change is being triggered by a HistoryStack navigation (only used for internal changes when Hasher.js isn't available) */ 
		private static var _isHistoryChange:Boolean;
		
		/** If JS event listeners were attached */
		private static var _isJSEventsAttached:Boolean;
		
		/**  Hash string */
		private static var _hash:String;
		
		/** Page title */
		private static var _title:String;
		
		/** Javascript methods */
		private static var _scripts:XML = <scripts>
			<getHasher>
				<![CDATA[
					function(){ return Hasher || false; }
				]]>
			</getHasher>
			<registerFlashMovie>
			    <![CDATA[
		        	function(){	        		
		        		var check = function(flashMovies){
		        			var n = flashMovies.length;
		        			var curMovie;
		        			for(var i=0; i<n; i++){
			        			curMovie = flashMovies[i];
			        			if('::flashMovieId::' in curMovie){
			        				if(! Hasher._registeredFlashMovies){
			        					Hasher._registeredFlashMovies = {};
			        				}
			        				Hasher._registeredFlashMovies['::flashMovieId::'] = curMovie;
			        				return true;
			        			}
		        			}
		        		};
		        		check(document.getElementsByTagName('object'));
		        		check(document.getElementsByTagName('embed'));
		        	}
			    ]]>
		    </registerFlashMovie>
		    <attachInit>
			    <![CDATA[
			        function() {
			        	Hasher.addEventListener(HasherEvent.INIT,
			        		function(evt){
			        			Hasher._registeredFlashMovies['::flashMovieId::'].Hasher_init(evt);
			        		}
			        	);
			        }
			    ]]>
		    </attachInit>
		    <attachStop>
			    <![CDATA[
			        function() {
			        	Hasher.addEventListener(HasherEvent.STOP,
			        		function(evt){
			        			Hasher._registeredFlashMovies['::flashMovieId::'].Hasher_stop(evt);
			        		}
			        	);
			        }
			    ]]>
		    </attachStop>
		    <attachChange>
			    <![CDATA[
			        function() {
			        	Hasher.addEventListener(HasherEvent.CHANGE,
			        		function(evt){
			        			Hasher._registeredFlashMovies['::flashMovieId::'].Hasher_change(evt);
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
		 * Pseudo static constructor (static initializer)
		 */
		{
			registerFlashMovie();
		}
		
		/**
		 * Constructor (Static Class)
		 * @private
		 */
		public function Hasher() {
			throw new Error('this is a static class and should not be instantiated.');
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
		
		/**
		 * Checks whether an event listener is registered with this EventDispatcher object or any of its ancestors for the specified event type.
		 * @param type	Event type
		 */
		public static function willTrigger(type:String):Boolean{
			return _dispatcher.willTrigger(type);
		}

		//---------------------------------------
		// GETTERS AND SETTERS
		//---------------------------------------
		
		/**
		 * Hash value without '#'.
		 */
		public static function get hash():String {
			return _hash;
		}
		public static function set hash(value:String):void {
			value = value? value.replace(/^#/, '') : null; //remove '#' from the beginning of string
			 
			if(value != hash){
				var tmpHash:String = _hash;
				_hash = value; //set before calling external JS to avoid dispatching event twice.
				
				if(_isHasherJSAvailable){
					callHasherJS("Hasher.setHash", null, value);
				}else{
					if(! _isHistoryChange) HasherHistoryStack.add(value); //make sure we don't add same value multiple times to the history stack without needing
					_isHistoryChange = false;
				}
				
				if(_isActive) _dispatcher.dispatchEvent(new HasherEvent(HasherEvent.CHANGE, tmpHash, _hash));
			}
		}
		
		/**
		 * Return hash value as Array.
		 * @param separator	String used to divide hash (default = '/').
		 * @return Hash splitted into an Array.
		 */
		public static function getHashAsArray(separator:String = '/'):Array {
			var regexp:RegExp = new RegExp('^\\'+ separator +'|\\'+ separator +'$', 'g'); //match separator at the end or begin of string
			var hashString:String = hash? hash : '';
			hashString = hashString.replace(regexp, '');
			return hashString.split(separator);
		}
		
		/**
		 * Query portion of the Hash without '?'
		 * - based on MM.queryUtils.getQueryString <http://github.com/millermedeiros/MM_js_lib/>
		 */
		 public static function get hashQuery():String{
		 	var searchRegex:RegExp = /\?[a-zA-Z0-9\=\&\%\$\-\_\.\+\!\*\'\(\)\,]+/; //valid chars according to: http://www.ietf.org/rfc/rfc1738.txt
		 	var result:Object = searchRegex.exec(Hasher.hash);
			return (result)? decodeURIComponent(result[0]).substr(1) : '';
		 }
		 
		 /**
		  * Get Query portion of the Hash as an Object
		  * - based on MM.queryUtils.toQueryObject <http://github.com/millermedeiros/MM_js_lib/>
		  */
		 public static function get hashQueryAsObject():Object{
		 	var queryArr:Array = Hasher.hashQuery.replace('?', '').split('&');
		 	var n:int = queryArr.length;
		 	var queryObj:Object = {};
		 	while(n--){
		 		queryArr[n] = (queryArr[n] as String).split('=');
				queryObj[queryArr[n][0]] = queryArr[n][1];
		 	}
			return queryObj;
		}
		
		/**
		 * Get parameter value from the query portion of the Hash
		 */
		public static function getHashQueryParam(paramName:String):String{
			var paramRegex:RegExp = new RegExp("(?<=(?|&)"+ paramName +"=)[^&]*");
			var result:Object = paramRegex.exec(Hasher.hash);
			return (result)? decodeURIComponent(result[0]) : null;
		}

		/**
		 * Page title
		 */
		public static function get title():String {
			return callHasherJS("Hasher.getTitle", _title);
		}
		public static function set title(value:String):void {
			_title = value;
			callHasherJS("Hasher.setTitle", _title, value);
		}

		/**
		 * Full URL.
		 * - IMPORTANT: requires ExternalInterface and Hasher.js to work.
		 * @return Full URL or `null` if ExternalInterface and/or Hasher.js isn't available.
		 */
		public static function get url():String {
			return callHasherJS("Hasher.getURL", null);
		}

		/**
		 * URL without query string and hash.
		 * - IMPORTANT: requires ExternalInterface and Hasher.js to work.
		 * @return URL without query string and hash or `null` if ExternalInterface and/or Hasher.js isn't available.
		 */
		public static function get baseUrl():String {
			return callHasherJS("Hasher.getBaseURL", null);
		}

		//---------------------------------------
		// PUBLIC METHODS
		//---------------------------------------
		
		/**
		 * Start listening/dispatching changes in the hash/history.
		 * - Will affect all the flash movies and JS code listening to Hash Events. 
		 */
		public static function init():void {
			if(_isActive) return;
			_isActive = true;
			//FIXME: something is wrong with INIT on Chrome and IE. (see issue #1 at github)
			if(! _isJSEventsAttached) attachJSListeners();
			
			if(_isHasherJSAvailable){
				callHasherJS("Hasher.init");
			}else{
				HasherHistoryStack.add(hash);
			}
			_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.INIT, _hash, hash));
		}
		
		/**
		 * Stop listening/dispatching changes in the hash/history.
		 * - Will affect all the flash movies and JS code listening to Hash Events.
		 */
		public static function stop():void {
			if(! _isActive) return; 
			_isActive = false;
			
			if(_isHasherJSAvailable){
				callHasherJS("Hasher.stop");
			}
			_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.STOP, hash, hash));
		}
		
		/**
		 * Navigate to previous page in history
		 */
		public static function back():void {
			go(-1);
		}

		/**
		 * Navigate to next page in history
		 */
		public static function forward():void {
			go(1);
		}

		/**
		 * Loads a page from the session history, identified by its relative location to the current page.
		 * - for example `-1` loads previous page, `1` loads next page.
		 * @param delta	Relative location to the current page.
		 */
		public static function go(delta:int):void {
			if(_isHasherJSAvailable){
				callHasherJS("Hasher.go", null, delta);
			}else{
				_isHistoryChange = true;
				hash = HasherHistoryStack.go(delta);
			}
		}

		//---------------------------------------
		// PRIVATE AND PROTECTED METHODS
		//---------------------------------------
		
		/**
		 * Register a reference to the flash movie (inside the JavaScript Hasher object) that will be used later to attach/detach Event listeners.
		 */
		private static function registerFlashMovie():void{
			if(_isRegistered) return; //can't register flash movie more than once
			
			_isRegistered = true;
			
			if(ExternalInterface.available){
				if(! ExternalInterface.call(getScript("getHasher"))) { // Check if the Hasher class is included on the HTML
					_isHasherJSAvailable = false;
				}else{
					//create random ID used to detect and register current flash movie
					var ms:Number = new Date().getTime();
					var rdm:int = int(Math.random() * 0xFFFFFF);
					_flashMovieId = "Hasher_"+ rdm +"_"+ ms;					
					ExternalInterface.addCallback(_flashMovieId, function():Boolean{return true;});					
					setTimeout(function():void{
						ExternalInterface.call(getScript("registerFlashMovie"));
					}, 25);
					_isHasherJSAvailable = true;
				}
			}
		}
		
		/**
		 * Setup all the JS event listeners for external changes in the hash/history CHANGE and also HasherEvent.INIT and HasherEvent.STOP.
		 */
		private static function attachJSListeners():void{
			if(_isJSEventsAttached) return;
			
			ExternalInterface.addCallback("Hasher_change", onExternalChange);
			ExternalInterface.addCallback("Hasher_init", onExternalInit);
			ExternalInterface.addCallback("Hasher_stop", onExternalStop);
			
			setTimeout(function():void{
				ExternalInterface.call(getScript("attachInit"));
				ExternalInterface.call(getScript("attachChange"));
				ExternalInterface.call(getScript("attachStop"));
			}, 25);
			
		}
		
		/**
		 * Get Javascript function from the _scripts:XML
		 * @param nodeName	Node that contain script
		 */
		private static function getScript(nodeName:String):String {
			var node:XMLList = _scripts[nodeName] as XMLList;
			return node.toString().replace(/::flashMovieId::/g, _flashMovieId);
		}
		
		/**
		 * Call a Javascript method and/or returns default value if ExternalInterface isn't available or page doesn't containg the Hasher.js Object.
		 * @param action	Function Name or String representing the function that should be called. 
		 * @param alternativeReturn	Alternative return value if ExternalInterface and/or Hasher.js isn't available.
		 * @param args	Arguments passed to the JavaScript function.
		 */
		private static function callHasherJS(action:String, alternativeReturn:* = null, ...args):* {
			if(_isHasherJSAvailable){
				var tmpArr:Array = [action];
				var argsArr:Array = tmpArr.concat(args);
				return ExternalInterface.call.apply(undefined, argsArr);
			}else{
				return alternativeReturn;
			}
		}

		//---------------------------------------
		// EVENT HANDLERS
		//---------------------------------------
		
		/**
		 * Called when hash is changed from outside flash
		 */
		private static function onExternalChange(evt:Object):void {
			var newHash:String = evt["newHash"];
			if(_isActive && newHash != _hash) {
				_hash = newHash;
				_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.CHANGE, evt["oldHash"], newHash));
			}
		}
		
		/**
		 * Called when Hasher is initialized from outside flash
		 */
		private static function onExternalInit(evt:Object):void {
			if(! _isActive){
				_isActive = true;
				_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.INIT, evt["oldHash"], evt["newHash"]));
			}
		}
		
		/**
		 * Called when Hasher is stopped from outside flash
		 */
		private static function onExternalStop(evt:Object):void {
			if(_isActive){
				_isActive = false;
				_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.STOP, evt["oldHash"], evt["newHash"]));
			}
		}
	}
}
