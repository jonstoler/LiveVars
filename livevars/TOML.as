package livevars
{
public class TOML
{

	public static function parse(s:String):Object
	{
		var values:Object = {};
		var inArray:Boolean = false;
		var group:String = "";
		var current:String = "";

		var lines:Array = s.split("\n");
		for(var i:uint = 0; i < lines.length; i++)
		{
			var line:String = lines[i];

			// trim line, strip comments
			line = line.replace(/^\s+|\s+$/g, '');
			line = line.replace(/#.*/, '');

			if(line == ''){ continue; }

			var match:Array;
			if(match = line.match(/^\[([^\]]+)\]/)){ // group name
				group = match[1];
				continue;
			} else if(/^[a-zA-Z0-9._\s]+=.+$/.test(line)){ // key-value pair
				current += line;
				if(/^.+=\s*\[/.test(line) && !/\]$/.test(line)){
					inArray = true;
					continue;
				}
			} else {
				current += line;
				if(inArray && (current.split("[").length) != (current.split("]").length)){
					continue;
				} else {
					inArray = false;
				}
			}

			if(current == ""){ continue; }

			var keyvalue:Array = current.split("=");
			var key:String = keyvalue[0].replace(/^\s+|\s+$/g, '');
			var value:String = keyvalue[1].replace(/^\s+|\s+$/g, '');
			setItem(values, (group != "" ? group + "." : "") + key, value);
			current = "";
		}

		return values;
	}

	private static function setItem(object:Object, path:String, value:String):void
	{
		var parts:Array = path.split(".");
		var item:Object = object;
		var name:String = parts.pop();
		var access:String = "";

		for(var i:uint = 0; i < parts.length; i++){
			if(item[parts[i]] == null){
				item = item[parts[i]] = {};
			} else {
				item = item[parts[i]];
			}
			access = "item[" + parts[i] + "]";
		}

		item[name] = convertValue(value);
	}

	private static function convertValue(value:String):*
	{
		value = value.replace(/^\s+|\s+$/g, '');

		switch(true){
			case value.charAt(0) == "[":
				return parseArray(value);
				break;

			case value == "true": // intentional fall-through
			case value == "false":
				return (value == "true");
				break;

			case /^\d+$/.test(value): // intentional fall-through to support hex
			case /^0x[0-9a-f]+$/i.test(value):
				return parseInt(value);
				break;

			case /^\d+\.\d+$/.test(value):
				return parseFloat(value);
				break;

			default:
				return value.slice(1, value.length - 1); // remove quotes
				break;
		}
	}

	private static function parseArray(value:String):Array
	{
		var level:uint = 0;
		var isString:Boolean = false;
		var isEscaped:Boolean = false;
		var stringIdentifier:String = "";
		var item:String = "";
		var result:Array = [];

		for(var i:uint = 0; i < value.length; i++){
			var chara:String = value.charAt(i);
			if(chara.replace(/^\s+|\s+$/g, '').length == 0 && !isString){ continue; }

			if(chara == '"' || chara == "'"){
				if(stringIdentifier == ""){
					isString = true;
					stringIdentifier = chara;
					item += chara;
					continue;
				}

				if(isEscaped){
					item += chara;
					continue;
				} else {
					isString = !isString;
				}
			}

			var shouldContinue:Boolean = false;
			switch(chara){
				case "[":
					level++;
					if(level == 1){ shouldContinue = true; continue; }
					break;

				case "]":
					level--;
					if(level == 0){ shouldContinue = true; continue; }
					break;

				case "\\":
					isEscaped = true;
					break;

				case ",":
					if(!isString && level == 1){
						result.push(item);
						item = "";
						shouldContinue = true;
						continue;
					}
					break;
			}
			if(shouldContinue){ continue; }
			item += chara;
		}

		if(level != 0){
			// big problem.
			throw("Array not properly closed near " + item);
		}

		if(item != ""){
			result.push(item);
		}

		for(var ii:uint = 0; ii < result.length; ii++){
			result[i] = convertValue(result[i]);
		}

		return result;
	}
}
}
