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
		var ori:String = "my.eye";
		var dest:String = "boy.mouth";
		var replaceMode:String = "-c";	
		
		var args:Array<String> = Sys.args();
		if (args.length >0 && args.length <4) {
			Lib.println("replace packageName:  test1.swf -p my xxxx" + "\n" + "replace className :  test1.swf -c my.eye xxxx.boy.eye");
			Sys.exit(1);
		} else if (args.length == 4) {
			file = args[0];
			replaceMode =args[1];
			ori = args[2];
			dest  = args[3];
			 
		}
		
		var ori_pack = "";
		var ori_class = "";
		var dest_pack = "";
		var dest_class = "";
		
		if (replaceMode == "-p") {
			dest_pack = dest;
			ori_pack = ori;
		} else {
			var r = new EReg("(.*)(\\.)(\\w+|\\*)$", "");
			if (r.match(ori)) {
				ori_pack = r.matched(1);
				ori_class = r.matched(3);
			} else {
				ori_pack = "";
				ori_class = ori;
			}
			if (r.match(dest)) {
				dest_pack = r.matched(1);
				dest_class = r.matched(3);
			} else {
				dest_pack = "";
				dest_class = ori;
			}
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
		if (replaceMode == "-p") {
			Lib.println("replace package:" + ori_pack + " -> " + dest_pack);
		} else {
			Lib.println("replace class:" + ori + " -> " + dest + "\n" + "replace package:" + ori_pack + " -> " + dest_pack);
		}

		

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
						if (replaceMode == "-p") {
							var index:Int = nstr.indexOf(ori_pack);
							if (index != -1) {
								s.className  = dest + nstr.substr(ori_pack.length);
							}
						} else {
							if (nstr == ori ) {
								s.className  = dest ;
							}
						}
						
					}
				case TActionScript3(data, context): 
					
					var inputabc:BytesInput = new BytesInput(data);
					var r:format.abc.Reader = new format.abc.Reader (inputabc);
					var abcData:ABCData = r.read();
				
					
					doReplace(abcData, ori_pack, ori_class, dest_class, dest_pack, replaceMode);
					
					
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
	
	
	
	static function doReplace(abcData:ABCData, ori_pack:String, ori_class:String, dest_class:String, dest_pack:String, replaceMode:String):Void {
		if (replaceMode == "-c") {
			for (m in abcData.names) {
			
				var nsIndex:Int = getNsOfMName(m);
				var nameIndex:Int = getNameOfMName(m);
				var ns:Namespace = abcData.namespaces[iov(nsIndex)];
				if (ns == null) {
					continue;
				}
				var nsValueIndex:Int = getValueOfNs(ns);
				//Lib.println(abcData.strings[iov(nsValueIndex)] + '<->' + ori_pack);
				if (abcData.strings[iov(nsValueIndex)] == ori_pack && abcData.strings[iov(nameIndex)] == ori_class) {
					//Lib.println("find class at " + m);
					abcData.strings[iov(nameIndex)] = dest_class;
				} 
			}
		}
		
		replacePackageName(abcData, ori_pack, dest_pack);

	}
	
	static function replacePackageName(abcData:ABCData, ori_pack:String, dest_pack:String):Void {
		for (i in 0...abcData.strings.length - 1) {
			var nstr:String = abcData.strings[i];
			if (ori_pack == nstr) {
				abcData.strings[i] = dest_pack;
			} else {
				if (nstr.length > ori_pack.length ) {
					var index:Int = nstr.indexOf(ori_pack);
					if (index != -1) {
						abcData.strings[i]  = dest_pack + nstr.substr(ori_pack.length);
					}
				}
			}
		}
	}
	
	/**
	 * 取得枚举Index<T>的Int值，坑爹的haxe枚举值
	 */
	static function getEnumValue<T>(e:Index<T>):Int {
		switch(e) {
			case Idx(v):
				return v;
			default:
		}
		return 0;
	}
	/**
	 * index of value
	 */
	static function iov(i:Int):Int {
		
		return i-1;
	}
	
	/**
	 * index of enum value
	 */
	static function ioev<T>(e:Index<T>):Int {
		return getEnumValue(e)-1;
	}
	/**
	 * 取得枚举实例值MName的内部成员name
	 */
	static function getNameOfMName(name:Name):Int {
		switch(name) {
			case  NName( name, ns  ):
				return getEnumValue(name);
			default:
		}
		return 0;
	}
	/**
	 * 取得枚举实例值MName的内部成员ns
	 */
	static function getNsOfMName(name:Name):Int {
		switch(name) {
			case  NName( name, ns  ):
				return getEnumValue(ns);
			default:
		}
		return 0;
	}
	/**
	 * 取得枚举实例值NPublic的内部成员ns
	 */
	static function getValueOfNs(ns:Namespace):Int {
		switch(ns) {
			case  NPublic( ns  ):
				return getEnumValue(ns);
			default:
		}
		return 0;
	}	
	
}

					