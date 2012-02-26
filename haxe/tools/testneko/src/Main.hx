package ;

import format.swf.Reader;
import format.swf.Tools;
import format.swf.Writer;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Input;
import neko.io.FileInput;
import neko.io.FileOutput;
import neko.Lib;
import format.abc.Data;
import format.swf.Data;
import neko.Sys;
/**
 * ...
 * @author ldx, www.swfdiy.com
 */

class Main 
{

	static function main() 
	{
		
		//read args
		var file:String = "test1.swf";
		var ori:String = "my";
		var dest:String = "bbb";
		var args:Array<String> = Sys.args();
		if (args.length >0 && args.length <3) {
			Lib.println("need args:  swf original_package dest_package");
			Sys.exit(1);
		} else if (args.length == 3) {
			file = args[0];
			ori = args[1];
			dest  = args[2];
		}
		
		
		
		
		//read swf
		var fin:FileInput = neko.io.File.read(file, true);
		if (fin == null) {
			Lib.println("open file error:" + file);
			Sys.exit(1);
		}
		var reader:Reader = new Reader(fin);
		var swf:SWF = reader.read();
		var header:SWFHeader = swf.header;
		var tags : Array<SWFTag> = swf.tags;
		
		Lib.println(file);
		Lib.println("replace " + ori + " -> " + dest);

		Lib.println("SWF version:" + header.version);
		Lib.println("FPS:" + header.fps);
		Lib.println("Size:" + header.width + "x" + header.height);
		
	
		//fixed names in abc tags and symbol tags
		for ( i in 0...tags.length ) {
			var tag:SWFTag = tags[i];
			switch (tag) {
				case TSymbolClass(symbols): 
					for (s in symbols) {
						var nstr:String = s.className;
						if (nstr.length >= ori.length ) {
							var index:Int = nstr.indexOf(ori);
							if (index != -1) {
								s.className  = dest + nstr.substr(ori.length);
							}
						}
					}
				case TActionScript3(data, context): 
					
					var inputabc:BytesInput = new BytesInput(data);
					var r:format.abc.Reader = new format.abc.Reader (inputabc);
					var abcData:ABCData = r.read();
					var mFindIndex:Int = -1;
				
					for (i in 0...abcData.strings.length - 1) {
						var nstr:String = abcData.strings[i];
						if (ori == nstr) {
							abcData.strings[i] = dest;
						} else {
							if (nstr.length > ori.length ) {
								var index:Int = nstr.indexOf(ori);
								if (index != -1) {
									abcData.strings[i]  = dest + nstr.substr(ori.length);
								}
							}
						}
					}
					
					Lib.println("abc tag:" + context.label);
					var outputabc:BytesOutput = new BytesOutput();
					var w:format.abc.Writer = new format.abc.Writer(outputabc);
					w.write(abcData);
					
					tags[i] = TActionScript3(outputabc.getBytes(), context);
					
				
				default:
				
			}
		
		}
		
		//write
		var output:FileOutput = neko.io.File.write(file + ".o.swf", true);
		var writer:Writer = new Writer(output);
		writer.write(swf);
		Lib.println(file + ".o.swf saved");
	}
	
	
}

					