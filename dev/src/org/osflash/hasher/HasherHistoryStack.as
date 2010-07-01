package org.osflash.hasher {

	/**
	 * Keep record of the history stack internally if ExternalInterface or Hasher.js isn't available (e.g. running outside a browser) so the Hasher.back(), Hasher.forward() and Hasher.go() still work.
	 * @author Miller Medeiros <http://www.millermedeiros.com/>
	 * @version 0.1 (2010/07/01)
	 */
	public class HasherHistoryStack {

		private static var _instance:HasherHistoryStack;
		private var _stack:Array;
		private var _curIndex:uint;

		//---------------------------------------
		// METHODS
		//---------------------------------------
		
		/**
		 * Singleton Class
		 * @private
		 */
		public function HasherHistoryStack(enforcer:SingletonEnforcer = null) {
			if (enforcer == null) throw( new Error("Singleton Class! Must be acessed by the getInstance() method only."));
			_stack = [];
		}

		/**
		 * Get HasherHistoryStack instance
		 */
		public static function getInstance():HasherHistoryStack {
			if(!_instance) {
				_instance = new HasherHistoryStack(new SingletonEnforcer());
			}
			return _instance;
		}
		
		public function push(value:String):uint {
			_stack.length = _curIndex + 1; //removes any item after current index from history
			_curIndex =	_stack.push(value) - 1;
			return _curIndex;
		}

		public function back():String {
			_curIndex = Math.max(_curIndex - 1, 0);
			return _stack[_curIndex];
		}

		public function forward():String {
			_curIndex = Math.min(_curIndex + 1, _stack.length - 1); 
			return _stack[_curIndex];
		}
		
		public function go(delta:int):String {
			_curIndex = Math.max( Math.min(_curIndex + delta, _stack.length - 1), 0);
			return _stack[_curIndex];
		}
	}
}

/**
 * Ensure Singleton Pattern
 */
class SingletonEnforcer {
}