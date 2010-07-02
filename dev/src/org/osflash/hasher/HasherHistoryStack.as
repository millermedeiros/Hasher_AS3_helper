package org.osflash.hasher {

	/**
	 * Keep record of the history stack internally if ExternalInterface or Hasher.js isn't available (e.g. running outside a browser) so the Hasher.back(), Hasher.forward() and Hasher.go() still work.
	 * - only used if External JS isn't working.
	 * @author Miller Medeiros <http://www.millermedeiros.com/>
	 * @version 0.3 (2010/07/02)
	 * Released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 */
	public class HasherHistoryStack {

		private static var _stack:Array = [];
		private static var _curIndex:uint = -1;

		//---------------------------------------
		// METHODS
		//---------------------------------------
		
		/**
		 * Static Class
		 * @private
		 */
		public function HasherHistoryStack() {
			throw new Error('this is a static class and should not be instantiated.');
		}
		
		/**
		 * Add a new item on the stack
		 * @param hashValue	
		 */
		public static function add(hashValue:String):uint {
			_stack.length = _curIndex + 1; //removes any item after current index from history
			_curIndex =	_stack.push(hashValue) - 1;
			return _curIndex;
		}
		
		/**
		 * Get previous item on the stack (or first item of the stack if the current index == 0) and update current index.
		 */
		public static function back():String {
			_curIndex = Math.max(_curIndex - 1, 0);
			return _stack[_curIndex];
		}
		
		/**
		 * Get next item on the stack (or last item on the stack if the current index == stack.lenght - 1) and update current index.
		 */
		public static function forward():String {
			_curIndex = Math.min(_curIndex + 1, _stack.length - 1); 
			return _stack[_curIndex];
		}
		
		/**
		 * Get item from the stack and update current index based on delta.
		 * @param delta	Relative location to the current page
		 */
		public static function go(delta:int):String {
			_curIndex = Math.max( Math.min(_curIndex + delta, _stack.length - 1), 0);
			return _stack[_curIndex];
		}
		
		/**
		 * Returns string representation of the HasherHistoryStack
		 */
		public static function toString() : String {
			return '[HasherHistoryStack stack="' + _stack + '" currentIndex="' + _curIndex + '" currentValue="'+ _stack[_curIndex] + '"]';
		}
	}
}