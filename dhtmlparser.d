/**
 * D Module for parsing HTML in similar way like BeautifulSoup.
 *
 * Version: 0.6.1
 * Date: 13.09.2011
 *
 * Authors: 
 *     Bystroushaak (bystrousak@kitakitsune.org)
 * Website: 
 *     Github; https://github.com/Bystroushaak/DHTMLParser
 * Copyright: 
 *     This work is licensed under a CC BY (http://creativecommons.org/licenses/by/3.0/)
*/ 

module dhtmlparser;

import std.string;
import std.array;

import quote_escaper;



/**
 * Container for parsed html elements.
*/
class HTMLElement{
	private string element, tagname;
	private bool istag, isendtag, iscomment, isnonpairtag;
	
	/// Nested tags. Encapsulation would complicate whole class much more then public property.
	public HTMLElement[] childs;
	/// Tag parameters.
	public string[string] params;
	public HTMLElement endtag, openertag;
	
	/// Useful as container for document (root of the DOM).
	this(){
		this("");
	}
	
	/**
	 * Standard constructor used when parsing document from string. 
	*/ 
	this(string str){
		// this code is ugly - crime of premature optimization :(
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
	
	/**
	 * Special constructor used when creating DOM. 
	*/ 
	this(string tagname, string[string] params){
		tagname = tagname.strip().replace(" ", "");
		
		string nonpair = "";
		if (tagname.startsWith("<"))
			tagname = tagname[1 .. $];
		if (tagname.endsWith("/>")){
			tagname = tagname[0 .. $ - 2];
			nonpair = " /";
		}else if (tagname.endsWith(">"))
			tagname = tagname[0 .. $ - 1];
		
		// Convert into single string
		string output = "<" ~ tagname;
			
		foreach(key, val; params)
			output ~= " " ~ key ~ "=\"" ~ quote_escaper.escape(val, '"') ~ "\"";
			
		this(output ~ nonpair ~ ">");
	}
	
	/**
	 * This constructor is used for creating DOM from elements.
	 * 
	 * Example:
	 * -----
	 * HTMLElement e = new HTMLElement([
	 *   new HTMLElement("<val>",[
	 *     new HTMLElement("xe")
	 *   ])
	 * ]);
	 * 
	 * writeln(e);
	 * -----
	 * Writes;
	 * -----
	 * <val>
	 *  xe
	 * </val>
	 * ----- 
	*/ 
	this(string tagname, string[string] params, HTMLElement childs[]){
		this(tagname, params);
		this.childs ~= HTMLElement.closeElements(childs);
	}
	/// Same as previous, but with less options.
	this(string tagname, HTMLElement childs[]){
		this(tagname);
		this.childs ~= HTMLElement.closeElements(childs);
	}
	/// Same as previous, but with less options.
	this(HTMLElement childs[]){
		this();
		this.childs ~= HTMLElement.closeElements(childs);
	}

	/* *************************************************************************
	 * Finders *****************************************************************
	 ************************************************************************ */

	/**
	 * Simple search engine.
	 *
	 * Finds elements and subelements which match patterns given by parameters.
	 * Allows searching defined by users lambda function.
	 *
	 * Params:
		 * tag_name = Name of searched element.
		 * params   = Associative array containing searched parameters
		 * fn       = User defined function. Function takes elements and returns true if wanted.
	 *
	 * Examples:
	 *
	 * ---
	 * import std.stdio;
	 * 
	 * HTMLElement dom = parseString("<div id='xe' a='b'>obsah xe divu</div><div id='xu' a='b'>obsah xu divu</div>");
	 *
	 * writeln(dom);
	 *
	 * // writes:
	 * <div a="b" id="xe">
	 *   obsah xe divu
	 * </div>
	 * <div a="b" id="xu">
	 *   obsah xu divu
	 * </div>
	 * ---
	 * Search by parameters;
	 * ---
	 * writeln(dom.find("div", ["id":"xe"]))
	 *
	 * // writes:
	 * [<div a="b" id="xe">
	 *   obsah xe divu
	 * </div>
	 * ]
	 * ---
	 * Search by lambda function;
	 * ---
	 * writeln(dom.find(null, null, function(HTMLElement e){return ("id" in e.params && e.params["id"] == "xu");}));
	 *
	 * // writes:
	 * [<div a="b" id="xu">
	 *   obsah xu divu
	 * </div>
	 * ]
	 * ---
	 *
	 * Returns: Array of matching elements.
	*/ 
	public HTMLElement[] find(string tag_name, string[string] params = null, bool function(HTMLElement) fn = null){
		HTMLElement[] output;

		if (this.isComment() || this.isNonPairTag() || this.isEndTag())
			return null;
		
		if (fn != null)
			if (fn(this))
				output ~= this;

		if (this.tagname == tag_name && tagname != "" && tagname != null){
			if (params == null)
				output ~= this;
			else{
				bool tmp_stat = true;
				foreach(key, val; params){
					if (key !in this.params)
						tmp_stat = false;
					else if (params[key] != this.params[key])
						tmp_stat = false;
				}
				if (this.params.length == 0)
					tmp_stat = false;
					
				if (tmp_stat)
					output ~= this;
			}
		}
			
		HTMLElement tmp[];
		foreach(el; this.childs){
			tmp = el.find(tag_name, params, fn);

			if (tmp.length > 0)
				output ~= tmp;
		}
		
		return output;
	}
	
	/* *************************************************************************
	 * PARSERS *****************************************************************
	 ************************************************************************ */
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
		
		// Parse parameters (it isn't so simple as it could look..)
		uint li; // last index
		string value, key = tmp[0];
		for(uint i = 1; i < tmp.length - 1; i++){
			li = tmp[i].lastIndexOf(" ");
			li = (li < tmp[i].lastIndexOf("'") ? li : tmp[i].lastIndexOf("'"));
			li = (li < tmp[i].lastIndexOf("\"") ? li : tmp[i].lastIndexOf("\""));
			
			this.params[key.strip()] = tmp[i][0 .. li + 1];
			key = tmp[i][li + 1 .. $];
		}
		this.params[key.strip()] = tmp[$ - 1].strip();
		
		// Read and unescape parameters
		string tmparam;
		foreach(pkey, ref pvalue; this.params){
			tmparam = cast(string) pvalue;
			
			if (pvalue.startsWith("'") || pvalue.startsWith("\""))
				tmparam = cast(string) pvalue[1 .. $];
			if (pvalue.endsWith("'") || pvalue.endsWith("\""))
				if (tmparam.length > 1)
					tmparam = tmparam[0 .. $ - 1];
			
			if (pvalue.startsWith("'") || pvalue.startsWith("\""))
				if (tmparam.length > 2)
					tmparam = quote_escaper.unescape(tmparam, pvalue[0]);
			
			pvalue = tmparam;
		}
		
	}
	//* /Parsers ***************************************************************
	
	/* *************************************************************************
	 * Getters *****************************************************************
	 ************************************************************************ */

	/**
	 * True if element is tag (not content).
	*/ 
	public bool isTag(){
		return this.istag;
	}

	/**
	 * True if HTMLElement is end tag (/tag).
	*/ 
	public bool isEndTag(){
		return this.isendtag;
	}

	/**
	 * True if HTMLElement is nonpair tag (br for example).
	*/ 
	public bool isNonPairTag(){
		return this.isnonpairtag;
	}

	/**
	 * True if HTMLElement is html comment.
	*/
	public bool isComment(){
		return this.iscomment;
	}

	/**
	 * True if is opening tag.
	*/ 
	public bool isOpeningTag(){
		if (this.isTag() && !this.isComment() && !this.isEndTag() && !this.isNonPairTag())
			return true;
		else
			return false;
	}

	/**
	 * Returns true, if this element is endtag to opener.
	*/
	public bool isEndTagTo(HTMLElement opener){
		if (this.isendtag && opener.isOpeningTag())
			if (this.tagname.toLower() == opener.getTagName().toLower())
				return true;
			else
				return false;
		else
			return false;
	} 

	/**
	 * Returns prettifyied tag with content.
	 *
	 * See_also: prettify()
	*/ 
	public string toString(){
		return this.prettify();
	}

	/**
	 * Returns tag (with parameters), without content or endtag.
	*/ 
	public string tagToString(){
		if (! this.isOpeningTag())
			return this.element;
		else{
			string output = "<" ~ this.tagname;
			
			foreach(key, val; this.params)
				output ~= " " ~ key ~ "=\"" ~ quote_escaper.escape(val, '"') ~ "\"";
				
			return output ~ ">";
		}
	}

	/**
	 * Returns tag name.
	*/ 
	public string getTagName(){
		return this.tagname;
	}
	
	/**
	 * Returns content of tag (everything between opener and endtag).
	*/
	public string getContent(){
		string output;
		
		foreach(c; this.childs)
			output ~= c.prettify();
		
		return output;
	}

	/**
	 * Returns prettifyied tag with content. Same as toString().
	 *
	 * See_also: toString()
	*/ 
	public string prettify(uint depth = 0, string separator = "  "){
		string output;
		
		if (this.element != ""){
			output ~= this.tagToString() ~ "\n";
			depth++;
		}
		
		if (this.childs !is null)
			output ~= prettify(this.childs, depth);
		
		if (this.endtag !is null)
			output ~= this.endtag.tagToString() ~ "\n";
		
		return output;
	}
	
	private string prettify(HTMLElement[] istack, uint depth = 0, string separator = "  "){
		string output, strout;
		
		foreach(el; istack){
			for (uint i = 0; i < depth; i++)
				output ~= separator;
			
			output ~= el.tagToString() ~ "\n";

			if (el.childs.length > 0)
					output ~= prettify(el.childs, depth + 1, separator);
		}
		
		// yay, kinky!
		foreach(line; output.splitLines())
			if (line.strip() != "")
				strout ~= line ~ "\n";
		
		return strout;
	}
	//* /Getters ***************************************************************
	
	/* *************************************************************************
	 * Setters *****************************************************************
	 ************************************************************************ */

	public void isNonPairTag(bool isnonpairtag){
		this.isnonpairtag = isnonpairtag;
		if (!isnonpairtag){
			this.endtag = null;
			this.childs = null;
		}
	}
	
	//* /Setters ***************************************************************
	
	/* Static methods *********************************************************/
	
	// Close tags - used in some constructors
	private static HTMLElement[] closeElements(HTMLElement childs[]){
		HTMLElement o[];
		
		// Close all unclosed pair tags
		foreach(e; childs){
			if (e.isTag()){
				if (!e.isNonPairTag() && !e.isEndTag() && !e.isComment() && e.endtag is null){
					e.childs = closeElements(e.childs);
					
					o ~= e;
					o ~= new HTMLElement("</" ~ e.getTagName() ~ ">");
					
					// Join opener and endtag
					e.endtag = o[$ - 1];
					o[$ - 1].openertag = e;
				}else
					o ~= e;
			}else
				o ~= e;
		}
		
		return o;
	}
	//* /Static methods ********************************************************
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
			default: // switch without default is deprecated :S
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
				if (raw_input[index - 1].tagToString().startsWith("<") && raw_input[index + 1].tagToString().endsWith(">")){
					ostack[$ - 1] = new HTMLElement(ostack[$ - 1].tagToString() ~ raw_input[index + 1].tagToString());
					ostack ~= el;
					index++;
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
		if (el.isOpeningTag() && (el.getTagName().toLower() == opener.getTagName().toLower()))
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
			el.endtag = istack[end_tag_index + index]; // Reference to endtag
			el.endtag.openertag = el; // Reference to openertag
			ostack ~= el;
			ostack ~= el.endtag;
			index = end_tag_index + index;
		}else
			ostack ~= el;
	}

	return ostack;
}

/**
 * Parse given string and return DOM from HTMLElements.
 *
 * See_also: HTMLElement
*/
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

//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

unittest{
	HTMLElement dom = parseString(
		"<div id='xe' a='b'>obsah xe divu</div>
		 <div id='xu' a='b'>obsah xu divu</div>"
	);
	HTMLElement divXe, divXu;

	divXe = dom.find("div", ["id":"xe"])[0];
	divXu = dom.find("div", ["id":"xu"])[0];
	
	assert(divXe.tagToString() == `<div a="b" id="xe">`);
	assert(divXu.tagToString() == `<div a="b" id="xu">`);
	
	assert(divXe.getTagName() == "div");
	assert(divXe.getTagName() == divXu.getTagName());
	
	assert(divXe.isComment() == false);
	assert(divXe.isComment() == divXu.isComment());
	
	assert(divXe.isNonPairTag() != divXe.isOpeningTag());
	
	assert(divXe.isTag() == true);
	assert(divXe.isTag() == divXu.isTag());
	
	assert(divXe.getContent() == "obsah xe divu\n");
}