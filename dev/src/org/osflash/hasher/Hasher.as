package org.osflash.hasher {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;

	/**
	 * Hasher - History Manager for rich-media applications.
	 * - Bridge for Hasher.js methods and also allows the application to work outside the browser and/or without any JavaScript calls.
	 * @requires Hasher.js <http://github.com/millermedeiros/Hasher/>
	 * @author Lucas Motta <http://www.lucasmotta.com>, Miller Medeiros <http://www.millermedeiros.com>
	 * @version 0.2 (2010/07/01)
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
		
		/** If Hasher should stop dispatching change Events */
		private static var _isStopped:Boolean = true;
		
		/**  Hash string */
		private static var _hash:String = "";
		
		/** Page title */
		private static var _title:String = "";
		
		/** Javascript methods */
		private static var _scripts:XML = <scripts>
			<getHasher>
				<![CDATA[
					function(){ return (Hasher)? Hasher : false; }
				]]>
			</getHasher>
			<registerFlashMovie>
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
		    </registerFlashMovie>
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
			        		function(evt){
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
			        		function(evt){
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

		//---------------------------------------
		// GETTERS AND SETTERS
		//---------------------------------------
		
		/**
		 * Hash value without '#'.
		 */
		public static function get hash():String {
			return callHasherJS("Hasher.getHash", _hash);
		}
		public static function set hash(value:String):void {
			if(value != _hash){
				if(_isHasherJSAvailable){
					callHasherJS("Hasher.setHash", null, value);
				}else{
					HasherHistoryStack.add(value); //FIXME: check if change is comming from a HistoryStack change (to make sure we don't add same value multiple times).
					if(! _isStopped){
						_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.CHANGE, _hash, value));
					}
				}
				_hash = value;
			}
		}
		
		/**
		 * Return hash value as Array.
		 * @param separator	String used to divide hash (default = '/').
		 * @return Hash splitted into an Array.
		 */
		public static function get hashAsArray(separator:String = '/'):Array {
			var regexp:RegExp = new RegExp('^\\'+ separator +'|\\'+ separator +'$', 'g'); //match separator at the end or begin of string
			var hashString:String = Hasher.hash.replace(regexp, '');
			return hashString.split(separator);
		}
		
		/**
		 * Query portion of the Hash without '?'
		 * - based on MM.queryUtils.getQueryString <http://github.com/millermedeiros/MM_js_lib/>
		 */
		 public static function get hashQuery():String{
		 	var queryString:String = Hasher.hash.replace(/#[\w\W]*/, '');
		 	var searchRegex:RegExp = /\?[a-zA-Z0-9\=\&\%\$\-\_\.\+\!\*\'\(\)\,]+/;
		 	var result:Object = searchRegex.exec(queryString);
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
		 */
		public static function get url():String {
			return callHasherJS("Hasher.getURL", "");
		}

		/**
		 * URL without query string and hash.
		 */
		public static function get baseUrl():String {
			return callHasherJS("Hasher.getBaseURL", "");
		}

		//---------------------------------------
		// PUBLIC METHODS
		//---------------------------------------
		
		/**
		 * Start listening/dispatching changes in the hash/history.
		 * - Will affect al lthe flash movies and JS code listening to the `HashEvent.CHANGE` 
		 */
		public static function init():void {
			if(! _isRegistered) registerFlashMovie();
			
			if(_isHasherJSAvailable){
				ExternalInterface.call("Hasher.init");
			}else{
				HasherHistoryStack.add(hash);
				_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.INIT, hash, hash));
			}
			_isStopped = false;
		}
		
		/**
		 * Stop listening/dispatching changes in the hash/history.
		 * - Will affect al lthe flash movies and JS code listening to the `HashEvent.CHANGE`
		 */
		public static function stop():void {
			if(_isHasherJSAvailable){
				ExternalInterface.call("Hasher.stop");
			}else {
				_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.STOP, hash, hash));
			}
			_isStopped = true;
		}
		
		/**
		 * Navigate to previous page in history
		 */
		public static function back():void {
			if(_isHasherJSAvailable){
				callHasherJS("Hasher.back");
			}else{
				hash = HasherHistoryStack.back();
			}
		}

		/**
		 * Navigate to next page in history
		 */
		public static function forward():void {
			if(_isHasherJSAvailable){
				callHasherJS("Hasher.forward");
			}else{
				hash = HasherHistoryStack.forward();
			}
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
				hash = HasherHistoryStack.go(delta);
			}
		}

		//---------------------------------------
		// PRIVATE AND PROTECTED METHODS
		//---------------------------------------
		
		/**
		 * Register a reference to the flash movie (inside the JavaScript Hasher object) that will be used later to attach/detach Event listeners.
		 * - also setup all the JS event listeners for external changes in the hash/history and also HasherEvent.INIT and HasherEvent.STOP.
		 */
		private static function registerFlashMovie():void{
			
			if(Hasher._isRegistered) return; //can't register flash movie more than once
			
			if(ExternalInterface.available){
				// Check if the Hasher class is included on the HTML
				if(! ExternalInterface.call(getScript("getHasher"))) {
					_isHasherJSAvailable = false;
				}else{
					var ms:Number = new Date().getTime();
					_flashMovieId = "hasher_enabled_"+ (Math.random() * 0xFFFFFF) +"_"+ ms; //random id for the flash movie (used to attach EventListeners)					
					ExternalInterface.addCallback(_flashMovieId, function():Boolean{return true;});
					ExternalInterface.call(getScript("registerFlashMovie"));
					
					ExternalInterface.addCallback("Hasher_change", onExternalChange);
					ExternalInterface.addCallback("Hasher_init", onExternalInit);
					ExternalInterface.addCallback("Hasher_stop", onExternalStop);
					
					ExternalInterface.call(getScript("attachInit"));
					ExternalInterface.call(getScript("attachChange"));
					ExternalInterface.call(getScript("attachStop"));
					
					_isHasherJSAvailable = true;
				}
			}else{
				_isHasherJSAvailable = false;
			}
			
			_isRegistered = true;
		}
		
		/**
		 * Get Javascript function from the _scripts:XML
		 * @param nodeName	Node that contain script
		 */
		private static function getScript(nodeName:String):String {
			var node:XMLList = _scripts[nodeName] as XMLList;
			return node.toString().replace("::flashMovieId::", _flashMovieId);
		}
		
		/**
		 * Call a Javascript method and/or returns default value if ExternalInterface isn't available or page doesn't containg the Hasher.js Object.
		 * @param action	Function Name or String representing the function that should be called. 
		 * @param alternativeReturn	Alternative return value if ExternalInterface and/or Hasher.js isn't available.
		 * @param args	Arguments passed to the JavaScript function.
		 */
		private static function callHasherJS(action:String, alternativeReturn:* = null, ...args):* {
			return (_isHasherJSAvailable)? ExternalInterface.call(action, args) : alternativeReturn;
		}

		//---------------------------------------
		// EVENT HANDLERS
		//---------------------------------------
		
		private static function onExternalChange(evt:Object):void {
			if(! _isStopped) _dispatcher.dispatchEvent(new HasherEvent(HasherEvent.CHANGE, evt["oldHash"], evt["newHash"]));
		}

		private static function onExternalInit(evt:Object):void {
			_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.INIT, evt["oldHash"], evt["newHash"]));
			_isStopped = false;
		}

		private static function onExternalStop(evt:Object):void {
			_dispatcher.dispatchEvent(new HasherEvent(HasherEvent.STOP, evt["oldHash"], evt["newHash"]));
			_isStopped = true;
		}
	}
}
