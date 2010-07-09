package {
	import com.millermedeiros.utils.ArrayUtils;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import org.osflash.hasher.HasherEvent;
	import org.osflash.hasher.Hasher;
	import flash.display.Sprite;
	import flash.events.Event;

	/**
	 * Basic Test #1
	 * WARNING: poor code ahead, used only for testing, shouldn't be used as reference.
	 * @author Miller Medeiros
	 */
	public class Test1 extends Sprite {

		private static const BTN_MARGIN:int = 5;
		private static const STAGE_WID:int = 800;

		private var _logger:Logger;
		private var _btnHolder:Sprite;
		
		public function Test1() {
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			setupButtons();
			setupLogger();
		}

		private function setupButtons():void {
			
			_btnHolder = new Sprite();
			_btnHolder.x = 10;
			_btnHolder.y = 10;
			addChild(_btnHolder);
			
			var btns:Vector.<SimpleButton> = new Vector.<SimpleButton>();
			
			btns[btns.length] = new SimpleButton('Hasher.init()', function(e:Event):void{ 
				_logger.log('Hasher.init()');
				Hasher.init();
			});
			btns[btns.length] = new SimpleButton('Hasher.stop()', function(e:Event):void{ 
				_logger.log('Hasher.stop()');
				Hasher.stop();
			});
			btns[btns.length] = new SimpleButton('Hasher.back()', function(e:Event):void{ 
				_logger.log('Hasher.back()');
				Hasher.back(); 
			});
			btns[btns.length] = new SimpleButton('Hasher.forward()', function(e:Event):void{ 
				_logger.log('Hasher.forward()');
				Hasher.forward();
			});
			btns[btns.length] = new SimpleButton('get: Title + Hash + HashArray + HashQuery', function(e:Event):void{ 
				_logger.log('Hasher.title:', Hasher.title);
				_logger.log('Hasher.hash:', Hasher.hash);
				_logger.log('Hasher.getHashAsArray():', ArrayUtils.toStringArray( Hasher.getHashAsArray() ));
				_logger.log('Hasher.hashQuery:', Hasher.hashQuery );
			});
			
			/*
			btns[btns.length] = new SimpleButton('set: Title + Hash', function(e:Event):void{ 
				var hash:String = 'lorem-ipsum';
				var title:String = 'Lorem Ipsum';
				_logger.log('Hasher.hash = ' + hash +';', 'Hasher.title = '+ title +';');
				Hasher.hash = hash;
				Hasher.title = title;
			});
			
			btns[btns.length] = new SimpleButton('set: Title + Hash', function(e:Event):void{ 
				var hash:String = 'lorem-ipsum/dolor-sit';
				var title:String = 'Dolor Sit | Lorem Ipsum';
				_logger.log('Hasher.hash = ' + hash +';', 'Hasher.title = '+ title +';');
				Hasher.hash = hash;
				Hasher.title = title;
			});
			 */
			
			var curBtn:SimpleButton;
			var prevBtn:SimpleButton;
			var lineNum:int = 0;
			var wrapX:int = int(STAGE_WID - (_btnHolder.x * 2));
			
			for(var i:int = 0; i < btns.length; i++) {
				curBtn = btns[i]; 
				curBtn.x = (prevBtn)? int(prevBtn.x + prevBtn.width + BTN_MARGIN) : 0;
				
				//line break
				if(curBtn.x + curBtn.width > wrapX){
					lineNum++;
					curBtn.x = 0;
				}
				curBtn.y = int((lineNum * curBtn.height) + (lineNum * BTN_MARGIN));
				
				_btnHolder.addChild(curBtn);
				prevBtn = curBtn;
			}
		}

		private function setupLogger():void {
			_logger = new Logger();
			addChild(_logger);
			
			_logger.x = _btnHolder.x;
			_logger.y = _btnHolder.y + _btnHolder.height + BTN_MARGIN;
			
			Hasher.addEventListener(HasherEvent.INIT, updateLogger);
			Hasher.addEventListener(HasherEvent.STOP, updateLogger);
			Hasher.addEventListener(HasherEvent.CHANGE, updateLogger);
			
			var clearBtn:SimpleButton = new SimpleButton('Clear', function(e:Event):void {
				_logger.text = '';
			});
			clearBtn.x = _logger.x + _logger.width - clearBtn.width;
			clearBtn.y = _logger.y + _logger.height + BTN_MARGIN;
			addChild(clearBtn);
		}

		private function updateLogger(event:HasherEvent):void {
			_logger.log(event);
		}
	}
}
