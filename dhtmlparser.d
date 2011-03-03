/**
 *
 * TODO:
	 * přidělat parsování argumentů tagu
*/ 

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
	public HTMLElement[] childs;
	public HTMLElement endtag;
	public HTMLElement nexttag;
	
	this(string str){
		this.element = str;
		
		this.parseIsTag();
		this.parseIsEndTag();
		this.parseIsNonPairTag();
		this.parseIsComment();
		if (!this.istag || this.iscomment)
			this.tagname = element;
		else
			this.parseTagName();
	}
	
	private void parseIsTag(){
		if (this.element.startsWith("<") && this.element.endsWith(">"))
			this.istag = true;
		else
			this.istag = false;
	}
	
	private void parseIsEndTag(){
		char last;
		this.isendtag = false;
		
		if (this.element.startsWith("<") && this.element.endsWith(">")){
			foreach(char c; this.element){
				if (c == '/' && last == '<')
					this.isendtag = true;
				if (c > 32)
					last = c;
			}
		}
	}
	
	private void parseIsNonPairTag(){
		char last;
		this.isnonpairtag = false;
		
		// Tags endings with /> are nonpair
		if (this.element.startsWith("<") && this.element.endsWith(">")){
			foreach(char c; this.element){
				if (c == '>' && last == '/')
					this.isnonpairtag = true;
				if (c > 32)
					last = c;
			}
		}
		
		// Nonpair tags
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
		
		// Check listed nonpair tags
		foreach(string tag; npt){
			if (tag == this.getTagName())
				this.isnonpairtag = true;
		}
	}
	
	private void parseIsComment(){
		if (this.element.startsWith("<!--") && this.element.endsWith("-->"))
			this.iscomment = true;
		else
			this.iscomment = false;
	}
	
	private void parseTagName(){
		foreach(string el; this.element.split(" ")){
			el = el.replace("/", "").replace("<", "").replace(">", "");
			if (el.length > 0){
				this.tagname = el;
				break;
			}
		}
	}
	
	public bool isTag(){
		return this.istag;
	}
		
	public bool isOpeningTag(){
		if (this.isTag() && !this.isComment() && !this.isEndTag() && !this.isNonPairTag())
			return true;
		else
			return false;
	}
		
	public bool isEndTag(){
		return this.isendtag;
	}

	/**
	 * Returns true, if this element is endtag to opener.
	*/
	public bool isEndTagTo(HTMLElement opener){
		if (this.isendtag && opener.isOpeningTag())
			if (this.tagname.tolower() == opener.getTagName().tolower())
				return true;
			else
				return false;
		else
			return false;
	} 
	
	public bool isNonPairTag(){
		return this.isnonpairtag;
	}

	public void setIsNonPairTag(bool isnonpairtag){
		this.isnonpairtag = isnonpairtag;
	}
	
	public bool isComment(){
		return this.iscomment;
	}

	public string toString(){
		return this.element;
	}
	
	public string getTagName(){
		return this.tagname;
	}
}


class HTMLParser{
	/**
	 * Parse HTML from text into array filled with tags end text.
	 * 
	 * Source code is little bit unintutive, because it is simple parser machine.
	 * For better understanding, look at; http://kitakitsune.org/images/field_parser.png
    */ 
	private static string[] raw_split(string itxt){
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

	/**
	 * Repair tags with comments (<HT<!-- asad -->ML> is parsed to ["<HT", "<!-- asad -->", "ML>"]
	 * and I need ["<HTML>", "<!-- asad -->"])
	*/ 
	private static HTMLElement[] repairTags(HTMLElement[] raw_input){
		HTMLElement[] ostack;
		
		foreach(uint index, HTMLElement el; raw_input){
			if (el.isComment()){
				if (index > 0 && index < raw_input.length){
					if (raw_input[index - 1].toString().startsWith("<") && raw_input[index + 1].toString().endsWith(">")){
						ostack[$ - 1] = new HTMLElement(ostack[$ - 1].toString() ~ raw_input[index + 1].toString());
						ostack ~= el;
						index += 1;
						continue;
					}
				}
			}

			ostack ~= el;
		}

		return ostack;
	}

	/**
	 * Element at first index is considered as opening tag.
	 *
	 * Returns: index of end tag or 0 if not found.
	*/ 
	private static uint indexOfEndTag(HTMLElement[] istack){
		if (istack.length <= 0)
			return 0;

		if (!istack[0].isOpeningTag())
			return 0;

		HTMLElement opener = istack[0];
		uint cnt = 0;
		
		foreach(uint index, HTMLElement el; istack[1 .. $]){
			if (el.isOpeningTag() && (el.getTagName().tolower() == opener.getTagName().tolower()))
				cnt++;
			else if (el.isEndTagTo(opener))
				if (cnt == 0)
					return index + 1;
				else
					cnt--;
		}

		return 0;
	}

	private static HTMLElement[] parseDOM(HTMLElement[] istack){
		
	}
	
	public static HTMLElement[] parseString(string txt){
		HTMLElement[] istack, ostack, raw_stack;
		
		// Convert array of strings to HTMLElements
		foreach(string el; raw_split(txt)){
			raw_stack ~= new HTMLElement(el);
		}

		// Create DOM
		uint end_tag_index;
		raw_stack = repairTags(raw_stack);
		
		foreach(uint index, HTMLElement el; raw_stack){
			end_tag_index = indexOfEndTag(raw_stack[index .. $]); // Check if this is pair tag

			if (end_tag_index == 0 && !el.isEndTag())
				el.setIsNonPairTag(true);

			if (end_tag_index != 0)
				writeln(el, " Yes - ", end_tag_index + index);
			else
				;
		}
		
		return ostack;
	}
}



void main(){
	HTMLElement[] dom = HTMLParser.parseString("<h<!--a-->r>asd<HTML><head type= 'xe>'>hlava</he<!-- komen>>tar-->ad><body>tělo:<br>řádek1<!-- asd --><br /><div>obsah divu<div>obsah zanoreneho divu</div></div>řádek2</body></HTML>asd<b<!--a-->r>");
// 	HTMLParser q = new HTMLParser("<!--a-->");

// 	writeln(dom);
}