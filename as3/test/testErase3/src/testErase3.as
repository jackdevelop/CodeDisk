package
{
	import com.buraks.utils.fastmem;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	
	[SWF(frameRate="24",width="1000",height="1000", backgroundColor="#333333")]

	public class testErase3 extends Sprite
	{
		public var txt:TextField;
		public function testErase3()
		{
			stage.addEventListener(MouseEvent.CLICK, onClick);
			txt = new TextField;
			txt.multiline = true;
			txt.height = 550;
			this.addChild(txt);
			this.graphics.beginFill(0x330000);
			this.graphics.drawRect(0,0,1000,1000);
			this.graphics.endFill();
			
		}
		private function test():void {
			var sp:Sprite = new Sprite;
			var c:int = 0xffff00;
			sp.graphics.beginFill(c);
			sp.graphics.drawCircle(20,20, 20);
			sp.graphics.endFill(); 
			
			
			var bmp:BitmapData = new BitmapData(40,40,true, 0);			
			bmp.draw(sp);
			
			var erase:Bitmap = new Bitmap(bmp);
			
			
			var bmpBg:BitmapData = new BitmapData(2000, 1000, true, 0);
		
		
			
			var sp3:Sprite = new Sprite;
			sp3.graphics.beginFill(0x00ffff);
			sp3.graphics.drawRect(0,0, 40, 40);
			sp3.graphics.endFill(); 
			
			var bitmapSp3:BitmapData = new BitmapData(40,40,true,0);
			bitmapSp3.draw(sp3);
			bitmapSp3.draw(erase,null,null, BlendMode.ERASE);
		//	this.addChild(new Bitmap(bitmapSp3));
			//return;
			var sp2:Sprite = new Sprite;
			sp.graphics.beginFill(0x0000ff);
			sp.graphics.drawRect(0,0, 2000, 1000);
			sp.graphics.endFill(); 
			bmpBg.draw(sp);
			//bmpBg.copyChannel(bitmapSp3, bitmapSp3.rect, new Point(0,0), BitmapDataChannel.ALPHA,BitmapDataChannel.ALPHA);
			//bmpBg.copyChannel(bitmapSp3, bitmapSp3.rect, new Point(30,0), BitmapDataChannel.ALPHA,BitmapDataChannel.ALPHA);

			
			bmpBg.copyPixels(bitmapSp3,bitmapSp3.rect,  new Point(0,0),null, new Point(0,0), true);
			bmpBg.copyPixels(bitmapSp3,bitmapSp3.rect,  new Point(30,0),null, new Point(0,0), true);

			this.addChild(new Bitmap(bmpBg));
			return;
		
		
			var t1:int = flash.utils.getTimer();
			for (var i:int=0;i<1000;i++) {
				bmpBg.draw(erase,null,null, BlendMode.ERASE);
			}
			
			txt.text += "erase:" +  String( flash.utils.getTimer() - t1) + "\n";
			
			
			t1 = flash.utils.getTimer();
			
			for ( i=0;i<1000;i++) {
				bmpBg.copyPixels(bmp, bmp.rect, new Point(0,0));

				
			}
			txt.text +="copyPixels:" + String( flash.utils.getTimer() - t1) + "\n";
			
			
			t1 = flash.utils.getTimer();
			for ( i=0;i<1000;i++) {
				bmpBg.copyChannel(bmp, bmp.rect, new Point(0,0), BitmapDataChannel.ALPHA,BitmapDataChannel.ALPHA);
				
				
			}
			txt.text +="copyChannel:" + String( flash.utils.getTimer() - t1) + "\n";
			
			var ar:Vector.<Vector.<int>> = new Vector.<Vector.<int>>();
			var ari:Vector.<int> = new Vector.<int>();
			ari.push(1);
			ar.push(ari);
			var j:int;
			
			t1 = flash.utils.getTimer();
			
			for ( i=0;i<1000;i++) {
				for (j=0;j<1200;j++){
					ar[0][0] = 0;
				}
				
			}
			txt.text +="vector:" + String( flash.utils.getTimer() - t1) + "\n";

			
			var ba:ByteArray = new ByteArray();
			
			
			t1 = flash.utils.getTimer();
			
			for ( i=0;i<1000;i++) {
				for (j=0;j<1200;j++){
					ba.position = 0;
					ba.writeByte(1);
				}
				
			}
			txt.text +="ByteArray:" + String( flash.utils.getTimer() - t1) + "\n";

			
			
			var mem = new ByteArray();
			
			mem.length=1024;
			mem.endian = Endian.LITTLE_ENDIAN;
			fastmem.fastSelectMem(mem);
			//write 1234 at postion 555
			
			
			//Deselect the ByteArray
			
			
			t1 = flash.utils.getTimer();
			
			for ( i=0;i<1000;i++) {
				for (j=0;j<1200;j++){
					//ba.writeByte(0);
					fastmem.fastSetI32(1234,555);
				}
				
			}
			fastmem.fastDeselectMem();
			
			txt.text +="fastmem 32:" + String( flash.utils.getTimer() - t1) + "\n";
			
			fastmem.fastSelectMem(mem);

			t1 = flash.utils.getTimer();
			
			for ( i=0;i<1000;i++) {
				for (j=0;j<1200;j++){
					//ba.writeByte(0);
					fastmem.fastSetByte(123,33);
				}
				
			}
			fastmem.fastDeselectMem();
			
			txt.text +="fastmem 8:" + String( flash.utils.getTimer() - t1) + "\n";
			
		}
		protected function onClick(event:MouseEvent):void
		{
			// TODO Auto-generated method stub
			test();
		}
	}
}