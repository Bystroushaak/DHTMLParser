import std.string;

import std.stdio;

class HTMLParserException:Exception{
	this(string msg){
		super(msg);
	}
}

class HTMLElement{
	private string element, tagname;
	private bool istag, isendtag, iscomment, isnonpairtag;
	
	this(string str){
		this.element = str;
		
		this.parseIsTag();
		this.parseIsEndTag();
		this.parseIsNonPairTag();
		this.parseIsComment();
		this.parseTagName();
	}
	
	public bool isTag(){
		return this.istag;
	}
		
	private void parseIsTag(){
		if (this.element.startsWith("<") && this.element.endsWith(">"))
			this.istag = true;
		else
			this.istag = false;
	}
	
	private bool isEndTag(){
		return this.isendtag;
	}
	
	private void parseIsEndTag(){
		char last;
		
		if (this.element.startsWith("<") && this.element.endsWith(">")){
			foreach(char c; this.element){
				if (c == '/' && last == '<')
					this.isendtag = true;
				if (c > 32)
					last = c;
			}
		}
		
		this.isendtag = false;
	}
	
	//~ public bool isEndTag(ref string element, string ) 
	
	public bool isNonPairTag(){
		return this.isnonpairtag;
	}
	
	private void parseIsNonPairTag(){
		char last;
		
		if (this.element.startsWith("<") && this.element.endsWith(">")){
			foreach(char c; this.element){
				if (c == '>' && last == '/')
					this.isnonpairtag = true;
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
			if (tag == this.tagName())
				this.isnonpairtag = true;
		}
		
		this.isnonpairtag = false;
	}
	
	public bool isComment(){
		return iscomment;
	}
	
	private void parseIsComment(){
		if (this.element.startsWith("<!--") && this.element.endsWith("-->"))
			return this.iscomment = true;
		else
			return this.iscomment = false;
	}
		
	public string tagName(){
		return this.tagname;
	}
	
	private void parseTagName(){
		foreach(string el; this.element.split(" ")){
			el = el.replace("/", "").replace("<", "").replace(">", "");
			if (el.length > 0)
				this.tagname = el;
		}
	}
	
	public string toString(){
		return this.element;
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
	
	this(HTMLElement[] elements){
		parseElements(elements);
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
	
	private void parseElements(HTMLElement[] istack){
		
	}
	
	private void parseString(ref string txt){
		HTMLElement[] raw_stack, istack;
		
		// Convert array of strings to HTMLElements
		foreach(string el; this.raw_split(txt)){
			raw_stack ~= new HTMLElement(el);
		}
		
		// Repair tags with comments (<HT<!-- asad -->ML> is parsed to ["<HT", "<!-- asad -->", "ML>"]
		// and I need ["<HTML>", "<!-- asad -->"])
		foreach(uint index, HTMLElement el; raw_stack){
			if (el.isComment()){
				if (index > 0 && index < raw_stack.length){
					if (raw_stack[index - 1].toString().startsWith("<") && raw_stack[index + 1].toString().endsWith(">")){
						istack[$ - 1] = new HTMLElement(istack[$ - 1].toString ~ raw_stack[index + 1].toString());
						istack ~= el;
						index += 1;
						continue;
					}
				}
			}
			
			istack ~= el;
		}
		raw_stack = null;
		
		this.parseElements(istack);
	}
}



void main(){
	HTMLParser p = new HTMLParser("<h<!--a-->r>asd<HTML><head type= 'xe>'>hlava</he<!-- komen>>tar-->ad><body>tělo:<br>řádek1<!-- asd --><br />řádek2</body></HTML>asd<b<!--a-->r>");
	//~ HTMLParser q = new HTMLParser("<!--a-->");
}