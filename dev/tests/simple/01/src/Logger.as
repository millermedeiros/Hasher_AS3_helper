package {
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * @author Miller Medeiros
	 */
	public class Logger extends TextField {

		public function Logger() {
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
		
		public function log(...rest):void{
			this.appendText( rest.join(' ') + '\n');
		}
		
	}
}
