package ;

import format.abc.OpReader;
import format.abc.OpWriter;
import format.swf.Reader;
import format.swf.Tools;
import format.swf.Writer;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Input;
import neko.FileSystem;
import neko.io.FileInput;
import neko.io.FileOutput;
import neko.Lib;
import format.abc.Data;
import format.swf.Data;
import neko.Sys;
/**
 * ...
 * @author ldx, www.swfdiy.com
 * 
 *  this script aims to remove unneeded scripts/classes without exported in symbolClassesTag in a swf
 * 
 */

class Main 
{
	static function main() 
	{
		
		var ar = FileSystem.readDirectory('./');
		var dest:String = "";
		for (file in ar) {
			var rf = new EReg("(\\w+)\\.swf$", "");
			var dest:String = "";
			if (rf.match(file)) {
				dest = rf.matched(1);
			} else {
				//Lib.println(file + " is not correct file");
				continue;
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
		
			
			//1. collect export symbol classes
			var hs = getExportSymbolsHash(tags);
			
			for ( t in 0...tags.length ) {
				var tag:SWFTag = tags[t];
				switch (tag) {
					case TActionScript3(data, context): 
						
						var inputabc:BytesInput = new BytesInput(data);
						var r:format.abc.Reader = new format.abc.Reader (inputabc);
						var abcData:ABCData = r.read();
					
						//2.set unneed script/class/instance/ to null
						for (i in 0...abcData.inits.length ) {
							var fit = false;
							var fitcl:Int=0;
							var c = abcData.inits[i];
							setNullInUnneedABC(abcData, c, hs, i);
						}
						
						debugNull(abcData);
						
					
						//3. re-arrange the script/class/instance/methodinfo to delete null slots.
						
						var hash_script :IntHash<Int> = new IntHash<Int>();
						var hash_class :IntHash<Int> = new IntHash<Int>();
						var hash_method :IntHash<Int> = new IntHash<Int>();
						var hash_methodbody :IntHash<Int> = new IntHash<Int>();

						var new_scripts = new Array<format.abc.Init>();
						var new_classes = new Array<format.abc.ClassDef>();
						var new_methods = new Array<format.abc.MethodType>();
						var new_methodbodys= new Array<format.abc.Function>();

						for (i in 0...abcData.inits.length) {
							if (abcData.inits[i] != null) {
								hash_script.set(i , new_scripts.length);
								new_scripts.push(abcData.inits[i]);
							}
						}
						for (i in 0...abcData.classes.length) {
							if (abcData.classes[i] != null) {
								hash_class.set(i , new_classes.length);
								new_classes.push(abcData.classes[i]);
							}
						}
						for (i in 0...abcData.methodTypes.length) {
							if (abcData.methodTypes[i] != null) {
								hash_method.set(i , new_methods.length);
								new_methods.push(abcData.methodTypes[i]);
							}
						}
						
						for (i in 0...abcData.functions.length) {
							if (abcData.functions[i] != null) {
								hash_methodbody.set(i , new_methodbodys.length);
								new_methodbodys.push(abcData.functions[i]);
							}
						}
					
						abcData.classes = new_classes;
						abcData.methodTypes = new_methods;
						abcData.functions = new_methodbodys;
						abcData.inits = new_scripts;
						
						Lib.println("--------------------------------------");
						debugNull(abcData);

						
						//4. update new index
						updateScripts(abcData, new_scripts, hash_class, hash_method);
						updateClasses(abcData, new_classes,  hash_class, hash_method);
						updateMethodbody(abcData,new_methodbodys,  hash_class, hash_method);
						
						
						
						var outputabc:BytesOutput = new BytesOutput();
						var w:format.abc.Writer = new format.abc.Writer(outputabc);
						w.write(abcData);
						
						tags[t] = TActionScript3(outputabc.getBytes(), context);
						
					
					default:
					
				}
			
			}
			
			if (!FileSystem.exists("o") ){
				FileSystem.createDirectory("o");
			}
		
			var output:FileOutput = neko.io.File.write("o/"  + dest + ".swf" , true);
			var writer:Writer = new Writer(output);
			writer.write(swf);
			Lib.println("saved");
			
		}
		
	}
	
	
	static function updateScripts( abcData:ABCData, scripts:Array<format.abc.Init>, hash_class:IntHash<Int>,hash_method:IntHash<Int>):Void {
		for (script in scripts) {
			var v = getEnumValue(script.method);
			if (hash_method.exists(v)) {
				script.method = Idx(hash_method.get(v));
				Lib.println("[script]initMethod " + v + '->' + hash_method.get(v));
			}
			
			
			for ( fi in 0...script.fields.length) {
				var f = script.fields[fi];
				switch (f.kind) {
					case FClass( cl  ): 
						var v =  getEnumValue(cl);
						if (hash_class.exists(v)) {
							var nv = hash_class.get(v);
							f.kind = FClass(Idx(nv));
							Lib.println("[script]class " + v + '->' + nv);
						}
					default:
				}
			}
		}
		
		
	}
	
	static function updateClasses( abcData:ABCData, classes:Array<format.abc.ClassDef>, hash_class:IntHash<Int>,hash_method:IntHash<Int>):Void {
		var v;
		var nv;
		for (cl in classes) {
			v = getEnumValue(cl.constructor);
			if (hash_method.exists(v)) {
				nv = hash_method.get(v);
				cl.constructor= Idx(nv);
				Lib.println("[classes]constructor " + v + '->' + nv);
			}
			
			v = getEnumValue(cl.statics);
			if (hash_method.exists(v)) {
				nv = hash_method.get(v);
				cl.statics =  Idx(nv);
				Lib.println("[classes]staticConstructor " + v + '->' + nv);
			}
			
			for ( f in cl.fields) {
				switch (f.kind) {
					case FMethod( type , k , isFinal, isOverride ):
						v = getEnumValue(type);
						if (hash_method.exists(v)) {
							nv = hash_method.get(v);
							f.kind = FMethod(Idx(nv),k,isFinal,isOverride);
							Lib.println("[classes]method " + v + '->' + nv);
						}
					default:
				}
			}
			for ( f in cl.staticFields) {
				switch (f.kind) {
					case FMethod( type , k , isFinal, isOverride ):
						v = getEnumValue(type);
						if (hash_method.exists(v)) {
							nv = hash_method.get(v);
							f.kind = FMethod(Idx(nv),k,isFinal,isOverride);
							Lib.println("[classes]staticMethod " + v + '->' + nv);
						}
					default:
				}
			}
		}
	}
	
	static function updateMethodbody( abcData:ABCData, methodbodys:Array<format.abc.Function>,hash_class:IntHash<Int>,hash_method:IntHash<Int>):Void {
		var v;
		var nv;
		//update method info index
		for (m in methodbodys) {
			v = getEnumValue(m.type);
			if (hash_method.exists(v)) {
				nv = hash_method.get(v);
				m.type = Idx(nv);
				Lib.println("[methodbodys]method " + v + '->' + nv);
			}
		}
		
		//update class index and method index in avm2 code
		//OP_newclass
		//OP_callstatic
		//OP_newfunction
		for (m in methodbodys) {
			var code:BytesInput = new BytesInput(m.code);
			var changed = false;
			var ops = OpReader.decode(code);
			for (i in 0...ops.length) {
				var op = ops[i];
				switch(op) {
					case OFunction(m) :
						v = getEnumValue(m);
						if (hash_method.exists(v)) {
							nv = hash_method.get(v);
							Lib.println("[opcode]OFunction " + v + '->' + nv);
							ops[i] = OFunction(Idx(nv));
							 changed = true;
						}
					case OCallStatic( m, n) :
						v = getEnumValue(m);
						if (hash_method.exists(v)) {
							nv = hash_method.get(v);
							Lib.println("[opcode]OCallStatic " + v + '->' + nv);
							ops[i] = OCallStatic(Idx(nv), n);
							changed = true;
						}
					case OClassDef(c) :
						v = getEnumValue(c);
						if (hash_class.exists(v)) {
							nv = hash_class.get(v);
							Lib.println("[opcode]OClassDef " + v + '->' + nv);
							ops[i] = OClassDef(Idx(nv));
							changed = true;

						}
					default:
						
				}
			}
			if ( changed) {
				var outputcode:BytesOutput = new BytesOutput();
				var w:OpWriter = new OpWriter(outputcode);
				for (op in ops) {
					w.write(op);
				}
				
				m.code = outputcode.getBytes();
			}
		}
		
	}
	
	
	static function setNullInUnneedABC( abcData:ABCData, c:format.abc.Init, hs:Hash<Bool>, i:Int) :Void {
		var fit = false;
		var fitcl = -1;
		for ( f in c.fields) {
			switch (f.kind) {
				case FClass( cl  ): 
					var nameIndex:Int = ioev(f.name);
					var n = abcData.names[nameIndex];
					var nsIndex:Int = getNsOfMName(n);
					var nameIndex:Int = getNameOfMName(n);
					var ns:Namespace = abcData.namespaces[iov(nsIndex)];
					if (ns == null) {
						continue;
					}
					var nsValueIndex:Int = getValueOfNs(ns);
					//Lib.println(abcData.strings[iov(nsValueIndex)] + '<->' + ori_pack);
					var s1 = abcData.strings[iov(nsValueIndex)];
					var s2 =  abcData.strings[iov(nameIndex)];
					
					var s;
					if (s1 != "") {
						s = s1 + "." + s2;
					} else {
						s = s2;
					}
					
					if (hs.exists(s)) {
						fit = true;
					} else {
						fitcl = getEnumValue(cl);
						Lib.println("remove clss:" + cl);
					}
					
				default:
			}
		}
		if (!fit) {
			//remove script init method
			removeFunction(abcData, c.method);
			//remove instances and classes
			var cl = abcData.classes[fitcl];
			for ( f in cl.fields) {
				switch (f.kind) {
					case FMethod( type , k , isFinal, isOverride ):
						removeFunction(abcData, type);
					default:
				}
			}
			removeFunction(abcData, cl.constructor);

			//Lib.println("remove funcion1:" + getEnumValue(  cl.statics));
			//remove  classes
			for ( f in cl.staticFields) {
				switch (f.kind) {
					case FMethod( type , k , isFinal, isOverride ):
						removeFunction(abcData, type);

					//Lib.println("remove funcion2:" + getEnumValue(  type));
					default:
				}
			}
			removeFunction(abcData,  cl.statics);
			
			//remove script
			abcData.inits[i] = null;
			
			abcData.classes[fitcl] = null;
			
		}
	}
	
	
	static function getExportSymbolsHash( tags : Array<SWFTag>):Hash<Bool> {
		var hs = new Hash();
		for ( i in 0...tags.length ) {
			var tag:SWFTag = tags[i];
			switch (tag) {
				case TSymbolClass(symbols): 
					for (s in symbols) {
						var nstr:String = s.className;
						//Lib.println(nstr);
						hs.set(nstr, true);
					}
				
				default:
				
			}
		
		}
		
		for (k in hs.keys()) {
			//Lib.println(k);
		}
			
		return hs;
	}
	
	static function debugNull(abcData:ABCData):Void {
		var i:Int = 0;	
		i = 0;
		for (c in abcData.methodTypes) {
			if (c == null) {
				Lib.println(i + "[methodtype],,null");
			} else {
				Lib.println(i + "[methodtype],g");
			}
			i++;
		}
		i = 0;
		for (c in abcData.functions) {
			if (c == null) {
				Lib.println(i + "[method],,null");
			} else {
				Lib.println(i + "[method],g");
			}
			i++;
		}
		i = 0;
		for (c in abcData.classes) {
			if (c == null) {
				Lib.println(i + "[class],null");
			} else {
				Lib.println(i + "[class],g");
			}
			i++;
		}
		i = 0;
		for (c in abcData.inits) {
			if (c == null) {
				Lib.println(i + "[script],null");
			} else {
				Lib.println(i + "[script],g");
			}
			i++;
		}
	}
	static function removeFunction(abcData:ABCData, type:Index<format.abc.MethodType>):Void {
		//Lib.println("remove function:" + getEnumValue(type));
		for (i in 0...abcData.functions.length) {
			var m = abcData.functions[i];
			if (m != null && getEnumValue(m.type) == getEnumValue(type)) {
				//Lib.println("..find: " + i);
				//var ba = new BytesOutput();
				
				abcData.functions[i] = null;
				break;
			}
		}
		//Lib.println("end");

		abcData.methodTypes[getEnumValue(type)] = null;

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

						
						

					