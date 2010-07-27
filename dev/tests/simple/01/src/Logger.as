package {
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * @author Miller Medeiros
	 */
	public class Logger extends TextField {

		private static var _instance:Logger;

		public function Logger(enforcer:SingletonEnforcer) {
			
			if(! enforcer){
				throw new Error('Singleton Class!');
			}
			
			var tf:TextFormat = new TextFormat();
			tf.color = 0x000000;
			tf.font = "Arial";
			
			multiline = true;
			width = 780;
			height = 300;
			border = true;
			borderColor = 0x555555;
			defaultTextFormat = tf;
		}
		
		public static function getInstance():Logger{
			if(! _instance) {
				_instance = new Logger(new SingletonEnforcer());
			}
			return _instance;
		}

		public function log(...rest):void{
			this.appendText( rest.join(' ') + '\n');
		}
		
	}
}
class SingletonEnforcer{}