package livevars
{
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.getClassByAlias;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;
import flash.utils.setInterval;

import net.flashpunk.FP;
public class LiveVars
{
	private static var _file:String = "livevars.txt";
	private static var _contents:String = "";
	private static var _contentsCache:String = null;

	private static var _fileNotFound:Boolean = false;

	public static var silenced:Boolean = false;

	// refresh rate is in seconds, not milliseconds!
	private static var _refreshRate:Number = 1.0;

	public static function get contents():String { return _contents; }


	public static function init(fileName:String = "livevars.txt", refreshRate:Number = 1.0):void
	{
		_file = fileName;
		_refreshRate = refreshRate;
		load();
		setInterval(reload, (_refreshRate * 1000));
	}

	private static function load():void
	{
		var loader:URLLoader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, function(e:Event):void {
			_contents = e.target.data;
			if(_contents != _contentsCache){
				process();
				_contentsCache = _contents;
			}
		});
		loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void {
			if(!_fileNotFound){
				err("The file " + _file + " could not be loaded.");
				_fileNotFound = true;
			}
		});
		loader.load(new URLRequest(_file));
	}

	public static function reload():void{ load(); }

	private static function log(msg:String, prefix:String = "")
	{
		if(!silenced){ trace(prefix + msg); }
	}

	private static function err(msg:String){ log(msg, "[LIVEVARS ERROR] "); }

	private static function process():void
	{
		var vars:Object = TOML.parse(_contents);
		var worldType:String = getQualifiedClassName(FP.world);

		for(var prop:String in vars){
			if(worldType == prop){ // change current public world variables
				enumerateProperties(vars[prop], FP.world);
			} else { // try public static variables
				try {
					var obj:* = getDefinitionByName(prop);
				} catch(e:*) {
					err("No class named " + prop + " could be found.");
				}
				if(obj != undefined){ enumerateProperties(vars[prop], obj); }
			}
		}
	}

	private static function enumerateProperties(obj:Object, mod:*):void
	{
		for(var prop:String in obj){
			if(mod.hasOwnProperty(prop)){
				if(typeof mod[prop] == "object"){
					enumerateProperties(obj[prop], mod[prop]);
				} else {
					try {
						mod[prop] = obj[prop];
					} catch(e:*) {
						err(getQualifiedClassName(obj) + "." + prop + " is read-only.");
					}
				}
			}
		}
	}
}
}