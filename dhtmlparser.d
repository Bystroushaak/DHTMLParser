import std.string;

import std.stdio;

class HTMLParserException:Exception{
	this(string msg){
		super(msg);
	}
}

class HTMLParser{
	private string tagname;
	private string header, footer;
	private string[string] params;
	private HTMLParser[] content;
	
	this(ref string txt){
		parseString(txt);
	}
	
	this(string[] elements){
		
	}
	
	/**
	 * Parse HTML from text into array filled with tags end text.
	 * 
	 * Source code is little bit unintutive, because it is simple parser machine.
	 * For better understanding, look at; http://kitakitsune.org/images/field_parser.png
    */ 
	private string[] raw_split(ref string itxt){
		char echr;
		char[4] buff;
		string content;
		string[] array;
		ubyte next_state = 0;
		bool inside_tag = false;
		
		foreach(char c; itxt){
			switch(next_state){
				case 0: // content
					if (c == '<'){
						if (content.length > 0)
							array ~= content;
						content = "" ~ c;
						next_state = 1;
						inside_tag = false;
					}else{
						content ~= c;
					}

					break;
				case 1: // html tag
					if (c == '>'){
						array ~= content ~ c;
						content = "";
						next_state = 0;
					}else if (c == '\'' || c == '"'){
						echr = c;
						content ~= c;
						next_state = 2;
					}else if (c == '-' && buff[0] == '-' && buff[1] == '!' && buff[2] == '<'){
						if (content[0 .. ($ - 3)].length > 0)
							array ~= content[0 .. ($ - 3)];
						content = content[($ - 3) .. $] ~ c;
						next_state = 3;
					}else{
						if (c == '<') // jump back into tag instead of content
							inside_tag = true;
						content ~= c;
					}
					
					break;
				case 2: // "" / ''
					if (c == echr && (buff[0] != '\\' || (buff[0] == '\\' && buff[1] == '\\'))){
						next_state = 1;
					}
					content ~= c;
					
					break;
				case 3: // html comments
					if (c == '>' && buff[0] == '-' && buff[1] == '-'){
						if (inside_tag)
							next_state = 1;
						else
							next_state = 0;
						inside_tag = false;
						
						array ~= content ~ c;
						content = "";
					}else{
						content ~= c;
					}
					
					break;
			}
			
			// rotate buffer
			for(int i = buff.length - 1; i > 0; i--){
				buff[i] = buff[i - 1];
			}
			buff[0] = c;
			
		}
		
		if (content.length > 0)
			array ~= content;
		
		return array;
	}
	
	private bool isTag(ref string element){
		if (element.startsWith("<") && element.endsWith(">"))
			return true;
		else
			return false;
	}
	
	private bool isEndTag(ref string element){
		char last;
		
		if (element.startsWith("<") && element.endsWith(">")){
			foreach(char c; element){
				if (c == '/' && last == '<')
					return true;
				if (c > 32)
					last = c;
			}
		}
		
		return false;
	}
	
	private bool isNonPairTag(ref string element){
		char last;
		
		if (element.startsWith("<") && element.endsWith(">")){
			foreach(char c; element){
				if (c == '>' && last == '/')
					return true;
				if (c > 32)
					last = c;
			}
		}
		
		string[] npt = [
			"br",
			"hr",
			"img",
			"input",
			"link",
			"meta",
			"spacer",
			"frame",
			"base"
		];
		
		foreach(string tag; npt){
			if (tag == parseTagName(element))
				return true;
		}
		
		return false;
	}
	
	private bool isComment(ref string element){
		if (element.startsWith("<!--") && element.endsWith("-->"))
			return true;
		else
			return false;
	}
		
	private string parseTagName(string element){
		foreach(string el; element.split(" ")){
			el = el.replace("/", "").replace("<", "").replace(">", "");
			if (el.length > 0)
				return el;
		}
		
		throw new HTMLParserException("Tag not found!");
	}
	
	public void parseString(ref string txt){
		uint counter;
		string tagname;
		
		foreach(string element; this.raw_split(txt)){
			if (isTag(element)){
				
			}else{
				
			}
		}
	}
}



void main(){
	HTMLParser p = new HTMLParser("asd<HTML><head type= 'xe>'>hlava</he<!-- komen>>tar-->ad><body>tělo:<br>řádek1<!-- asd --><br />řádek2</body></HTML>asd");
}