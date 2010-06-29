package org.osflash.hasher
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	import flash.utils.setTimeout;

	/**
	 * Hasher - History Manager for rich-media applications.
	 * - Bridge for Hasher.js methods and also allows the application to work outside the browser and/or without any JavaScript calls.
	 * @requires Hasher.js <http://github.com/millermedeiros/Hasher/>
	 * @author Lucas Motta <http://www.lucasmotta.com>
	 * @version 0.1
	 */
	public class Hasher extends EventDispatcher 
	{

		
		//---------------------------------------
		// PUBLIC VARIABLES
		//---------------------------------------

		//---------------------------------------
		// PRIVATE VARIABLES
		//---------------------------------------
		private static var _instance : Hasher;

		private var _objectId : String;

		private var _available : Boolean;
		
		private var _initialized : Boolean;

		private var _hash : String = "";

		private var _title : String = "";

		private var _scripts : XML = <script>
			<init>
			    <![CDATA[
			        function() {
			        	Hasher.addEventListener(HasherEvent.INIT,
			        		function(e){
			        			document.getElementById('$objectId').init(e.target);
			        		}
			        	);
			        }
			    ]]>
		    </init>
		    <stop>
			    <![CDATA[
			        function() {
			        	Hasher.addEventListener(HasherEvent.STOP,
			        		function(e){
			        			document.getElementById('$objectId').stop(e.target);
			        		}
			        	);
			        }
			    ]]>
		    </stop>
		    <change>
			    <![CDATA[
			        function() {
			        	Hasher.addEventListener(HasherEvent.CHANGE,
			        		function(e){
			        			document.getElementById('$objectId').change(e.target);
			        		}
			        	);
			        }
			    ]]>
		    </change>
		</script>;

		
		//---------------------------------------
		// CONSTRUCTOR
		//---------------------------------------
		
		/**
		 * Constructor
		 */
		public function Hasher()
		{
		}

		public static function getInstance() : Hasher
		{
			if(_instance == null)
			{
				_instance = new Hasher();
				setTimeout(_instance.init, 100);
			}
			
			return _instance;
		}

		public static function get instance() : Hasher
		{
			return getInstance();
		}

		//---------------------------------------
		// GETTERS AND SETTERS
		//---------------------------------------
		
		/**
		 * Return hash value as String.
		 * @return {String}	Hash value without '#'.
		 */
		public function get hash() : String
		{
			return call("Hasher.getHash", _hash);
		}

		/**
		 * Set Hash value.
		 * @param {String} value	Hash value without '#'.
		 */
		public function set hash(value : String) : void
		{
			_hash = value;
			
			call("Hasher.setHash", _hash, _hash);
			if(!_available) onChange();
		}

		/**
		 * Return hash value as Array.
		 * @return {Array}	Hash splitted into an Array.  
		 */
		public function get hashAsArray() : Array
		{
			var value : String = hash;
			if(value.indexOf("?") >= 0) value = value.slice(0, value.indexOf("?"));
			
			return value.replace(/^[\/]+|[\/]+$/gi, "").split("/");
		}

		/**
		 * Get page title
		 * @return {String} Page Title
		 */
		public function get title() : String
		{
			return call("Hasher.getTitle", _title);
		}

		/**
		 * Set page title
		 * @param {String} value	Page Title
		 */
		public function set title(value : String) : void
		{
			_title = value;
			call("Hasher.setTitle", _title, value);
		}

		/**
		 * Retrieve full URL.
		 * @return {String}	Full URL.
		 */
		public function get url() : String
		{
			return call("Hasher.getURL", "");
		}

		/**
		 * Retrieve URL without query string and hash.
		 * @return {String}	Base URL.
		 */
		public function get baseUrl() : String
		{
			return call("Hasher.getBaseURL", "");
		}

		/**
		 * Host name of the URL.
		 * @return {String}	The Host Name.
		 */
		public function get hostName() : String
		{
			return call("Hasher.getHostName", "");
		}

		/**
		 * Retrieves Path relative to HostName
		 * @return {String} Folder path relative to domain
		 */
		public function get pathName() : String
		{
			return call("Hasher.getPathName", "");
		}

		//---------------------------------------
		// PUBLIC METHODS
		//---------------------------------------
		
		/**
		 * Navigate to previous page in history
		 */
		public function back() : void
		{
			call("Hasher.back");
		}

		/**
		 * Navigate to next page in history
		 */
		public function forward() : void
		{
			call("Hasher.forward");
		}

		/**
		 * Loads a page from the session history, identified by its relative location to the current page.
		 * - for example `-1` loads previous page, `1` loads next page.
		 * @param {int} delta	Relative location to the current page.
		 */
		public function go(delta : int) : void
		{
			call("Hasher.go", null, delta);
		}

		/**
		 * Set a new location or hash value without generating a history record for the current page. (user won't be able to return to current page)
		 * @param {String} value	New location (eg: '#newhash', 'newfile.html', 'http://example.com/')
		 */
		public function replaceLocation(value : String) : void
		{
			call("Hasher.replace", null, value);
		}

		//---------------------------------------
		// PRIVATE AND PROTECTED METHODS
		//---------------------------------------
		protected function init() : void
		{
			if(ExternalInterface.available)
			{
				_objectId = ExternalInterface.objectID;
				
				// Check if the Hasher class is included
				if(ExternalInterface.call("Hasher.getBaseURL") == undefined)
				{
					onInit();
					return;
				}
				
				_available = true;
				ExternalInterface.addCallback("change", onChange);
				ExternalInterface.addCallback("init", onInit);
				ExternalInterface.addCallback("stop", onStop);
				ExternalInterface.call(getScript(_scripts["init"]));
				ExternalInterface.call(getScript(_scripts["change"]));
				ExternalInterface.call("Hasher.init");
			}
		}

		private function getScript(value : XMLList) : String
		{
			return value.toString().replace("$objectId", _objectId);
		}

		private function call(action : String, alternative : String = null, ...args) : String
		{
			if(!_initialized) throw new Error("You need to wait for the application be initialized.");
			if(_available) return ExternalInterface.call(action, args) as String;
			if(alternative) return alternative;
			
			return "";
		}

		//---------------------------------------
		// EVENT HANDLERS
		//---------------------------------------
		private function onChange(hasher : Object = null) : void
		{
			dispatchEvent(new Event(Event.CHANGE));
		}

		private function onInit(hasher : Object = null) : void
		{
			_initialized = true;
			
			dispatchEvent(new Event(Event.INIT));
		}

		private function onStop(hasher : Object = null) : void
		{
		}
	}
}
