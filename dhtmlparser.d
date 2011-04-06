/**
 * dhtmlparser.d v0.1.0 (03.03.2011) by Bystroushaak (bystrousak@kitakitsune.org)
 * 
 * TODO:
	 * ukladat informace o typu parametru, nebo provadet nejaky nahrazovani \\, \", \'
	 * pretiffy by měla replacovat "    " za " ", nebrat v ůvahu řádky plné mezer (nikoli prázdné!)
	 * zapouzdřit HTMLElement
	 * přepsat pretiffy tak, aby vytvářela pole stringů, které pak vrátí jako jeden string namísto writeln..
	 * promyslet a přidat vyhledávací a porovnávací metody, nějaký dotazovač
	 * přidat možnost vyhledávání podle vlastní fce..
	 * přidělat transformační fce - setIsComment
*/ 

import std.string;
import std.array;

import std.stdio;

class HTMLParserException:Exception{
	this(string msg){
		super(msg);
	}
}

class HTMLElement{
	private char params_type;
	private string element, tagname;
	private bool istag, isendtag, iscomment, isnonpairtag;
	
	public HTMLElement[] childs;
	public HTMLElement endtag, openertag;
	public string[string] params;
	
	this(string str){
		this.element = str;
		
		this.parseIsTag();
		this.parseIsEndTag();
		
		this.parseIsComment();
		
		if (!this.istag || this.iscomment)
			this.tagname = element;
		else
			this.parseTagName();
		
		this.parseIsNonPairTag();
		
		if (this.isOpeningTag())
			this.parseParams();
	}

	/***************************************************************************
	 * Finders *****************************************************************
	 **************************************************************************/

	// dopsat vyhledavani podle argumentu, findAll
	public HTMLElement[] find(string tag_name, string[string] tag_arguments = null){
		HTMLElement[] output;

		if (this.isComment() || this.isNonPairTag() || this.isEndTag())
			return null;

		if (this.tagname == tag_name){
			return output ~ this;
		}
			
		HTMLElement tmp[];
		foreach(el; this.childs){
			tmp = el.find(tag_name, tag_arguments);

			if (tmp.length > 0)
				output ~= tmp;
		}
		
		return output;
	}
	
	/***************************************************************************
	 * PARSERS *****************************************************************
	 **************************************************************************/ 
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
		foreach(string tagname; npt){
			if (tagname == this.tagname){
				this.isnonpairtag = true;
				break;
			}
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
				return;
			}
		}
	}
	
	private void parseParams(){
		if (this.element.indexOf(" ") <= 0 || this.element.indexOf("=") <= 0)
			return;
		
		// Remove '<' & '>'
		string params = this.element[1 .. $-1].strip();
		
		// Remove tagname
		params = params[params.indexOf(" ") .. $].strip();
		
		string[] tmp = params.split("=");
		
		// Parse parameters (it isn't so simple how it could look..)
			uint li; // last index
			string value, key = tmp[0];
			for(uint i = 1; i < tmp.length - 1; i++){
				li = tmp[i].lastIndexOf(" ");
				li = (li < tmp[i].lastIndexOf("'") ? li : tmp[i].lastIndexOf("'"));
				li = (li < tmp[i].lastIndexOf("\"") ? li : tmp[i].lastIndexOf("\""));
				
				this.params[key] = tmp[i][0 .. li + 1];
				key = tmp[i][li + 1 .. $];
			}
			this.params[key] = tmp[$ - 1];
		
		// Remove craps from parameters
		foreach(pkey, pvalue; this.params){
			if (this.params[pkey].startsWith("'") || this.params[pkey].startsWith("\""))
				this.params[pkey] = this.params[pkey][1 .. $];
			if (this.params[pkey].endsWith("'") || this.params[pkey].endsWith("\""))
				this.params[pkey] = this.params[pkey][0 .. $ - 1];
		}
	}
	//* /Parsers ***************************************************************
	
	/***************************************************************************
	 * Generators **************************************************************
	 **************************************************************************/ 
	
// 	private void generateToString(){
// 		string element = "<" ~ this.tagname;
// 		
// 		if (this.params > 0)
// 			foreach(key, val; this.params)
// 	}
	
	//* /Generators ************************************************************
	
	/***************************************************************************
	 * Getters *****************************************************************
	 **************************************************************************/ 
	
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
	
	public bool isComment(){
		return this.iscomment;
	}

	public string toString(){
		return this.element;
	}
	
	public string getTagName(){
		return this.tagname;
	}
	//* /Getters ***************************************************************
	
	/***************************************************************************
	 * Setters *****************************************************************
	 **************************************************************************/ 
	
	public void isNonPairTag(bool isnonpairtag){
		this.isnonpairtag = isnonpairtag;
		this.endtag = null;
		this.childs = null;
	}
	
	//* /Setters ***************************************************************
}


/**
 * Parse HTML from text into array filled with tags end text.
 * 
 * Source code is little bit unintutive, because it is simple parser machine.
 * For better understanding, look at; http://kitakitsune.org/images/field_parser.png
*/ 
private string[] raw_split(string itxt){
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
private HTMLElement[] repairTags(HTMLElement[] raw_input){
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
 * Go through istack and search endtag. Element at first index is considered as opening tag.
 *
 * Returns: index of end tag or 0 if not found.
*/ 
private uint indexOfEndTag(HTMLElement[] istack){
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

/**
 * Recursively go through element array and create DOM.
*/ 
private HTMLElement[] parseDOM(HTMLElement[] istack){
	uint end_tag_index;
	HTMLElement[] ostack;
	
	foreach(uint index, HTMLElement el; istack){
		end_tag_index = indexOfEndTag(istack[index .. $]); // Check if this is pair tag

		if (!el.isNonPairTag && end_tag_index == 0 && !el.isEndTag())
			el.isNonPairTag(true);

		if (end_tag_index != 0){
			el.childs = parseDOM(istack[index + 1 .. end_tag_index + index]);
			el.endtag = istack[end_tag_index + index]; // Rreference to endtag
			el.endtag.openertag = el; // Reference to openertag
			ostack ~= el;
			ostack ~= el.endtag;
			index = end_tag_index + index;
		}else
			ostack ~= el;
	}

	return ostack;
}

public void pretiffy(HTMLElement[] istack, string separator = "  ", uint depth = 0){
	foreach(el; istack){
		for (uint i = 0; i < depth; i++)
			write(separator);

		writeln(el, " -> \"", el.getTagName(), "\"");
		
		if (el.childs.length > 0)
			pretiffy(el.childs, separator, depth + 1);
	}
}
	
public static HTMLElement parseString(ref string txt){
	HTMLElement[] istack;
	
	// Convert array of strings to HTMLElements
	foreach(string el; raw_split(txt)){
		istack ~= new HTMLElement(el);
	}

	HTMLElement container = new HTMLElement("");
	container.childs ~= parseDOM(repairTags(istack));
	return container;
}



void main(){
	HTMLElement dom = parseString(
		"<?xml syntax?>" ~
		"<doctype sracky=asd>" ~
		"<HTML>" ~
		"<head <!-- Doplnit meta tagy!--> parametr_hlavy=\"hlava..\">" ~
		"<title>Testovaci polygon..</title>" ~
		"</head>" ~
		"<body bgcolor='black'asd=bsd>" ~
		"<h1>Polygon..</h1>" ~
		"Nejaky pekny odstavecek.." ~
		"<!-- zakomentovany text.. >>><<<< \" -->"
		"</body>" ~
		"<html>" ~
		"</html>" ~
		"</html>"
	);

	pretiffy(dom.childs);

	writeln("\n---\n");

	writeln(dom.find("head"));
}