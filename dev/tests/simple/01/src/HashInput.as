package {
	import flash.text.TextFieldType;
	import org.osflash.hasher.Hasher;

	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * @author Miller Medeiros
	 */
	public class HashInput extends Sprite {

		private var _btn:SimpleButton;
		private var _field:TextField;
		private var _logger:Logger;

		public function HashInput() {
			
			_logger = Logger.getInstance();
			_field = new TextField();
			
			var tf:TextFormat = new TextFormat();
			tf.color = 0x000000;
			tf.font = "Arial";
			
			_field.border = true;
			_field.borderColor = 0x555555;
			_field.defaultTextFormat = tf;
			_field.type = TextFieldType.INPUT;
			
			addChild(_field);
			
			_btn = new SimpleButton("Hasher.hash = value", updateHash);
			addChild(_btn);
			_btn.x = 780 - _btn.width;
			
			_field.height = _btn.height;
			_field.width = int(_btn.x - 5);
		}

		private function updateHash(evt:MouseEvent):void {
			_logger.log('Hasher.hash = "' + _field.text +'";');
			Hasher.hash = _field.text;
		}
	}
}
