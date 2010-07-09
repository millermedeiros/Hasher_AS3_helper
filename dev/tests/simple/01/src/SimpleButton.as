package {
	import flash.events.MouseEvent;
	import flash.display.Shape;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextField;
	import flash.display.Sprite;

	/**
	 * @author Miller Medeiros
	 */
	public class SimpleButton extends Sprite {

		private static const PADDING_X:int = 10;
		private static const PADDING_Y:int = 6;
		
		private var _bg:Shape;

		public function SimpleButton(txt:String, clickHandler:Function) {
			
			var tf:TextFormat = new TextFormat();
			tf.color = 0xFFFFFF;
			tf.font = "Arial";
			
			var field:TextField = new TextField();
			field.autoSize = TextFieldAutoSize.LEFT;
			field.embedFonts = false;
			field.mouseEnabled = false;
			field.defaultTextFormat = tf;
			field.text = txt;
			field.x = int(PADDING_X / 2);
			field.y = int(PADDING_Y / 2);
			addChild(field);
			
			_bg = new Shape();
			_bg.graphics.beginFill(0);
			_bg.graphics.drawRect(0, 0, field.width + PADDING_X, field.height + PADDING_Y);
			_bg.graphics.endFill();
			addChildAt(_bg, 0);
			
			this.addEventListener(MouseEvent.ROLL_OVER, onOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onOut);
			this.addEventListener(MouseEvent.CLICK, clickHandler);
			this.buttonMode = true;
		}

		private function onOut(event:MouseEvent):void {
			_bg.alpha = 1;
		}

		private function onOver(event:MouseEvent):void {
			_bg.alpha = .75;
		}
	}
}
