/**
 * D Module for parsing HTML in similar way like BeautifulSoup.
 *
 * Version: 1.4.0
 * Date:    24.11.2011
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
import std.ascii;
import std.algorithm : remove;

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
		this.parseIsComment();
		
		if (!this.istag || this.iscomment)
			this.tagname = element;
		else
			this.parseTagName();
		
		if (this.isComment() || !this.isTag())
			return;
		
		this.parseIsEndTag();
		this.parseIsNonPairTag();
		
		if (this.istag && !this.isendtag && this.element.indexOf("=") > 0)
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
		if (tagname.strip().length != 0){
			// containers with childs are automatically considered as tags
			if (!tagname.startsWith("<"))
				tagname = "<" ~ tagname;
			if (!tagname.endsWith(">"))
				tagname ~= ">";
		}
		
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
	 * Same as findAll, but returns tags without endtags. You can always get them
	 * from .endtag property..
	 * 
	 * See_also:
	 *    findAll
	*/ 
	public HTMLElement[] find(string tag_name, string[string] params = null, bool function(HTMLElement) fn = null){
		HTMLElement[] output;
		HTMLElement[] dom = this.findAll(tag_name, params, fn);
		
		// remove endtags
		foreach(e; dom)
			if (!e.isEndTag())
				output ~= e;
				
		return output;
	}
	
	/**
	 * Same as findAllB, but returns tags without endtags. You can always get them
	 * from .endtag property..
	 * 
	 * See_also:
	 *    findAll
	*/ 
	public HTMLElement[] findB(string tag_name, string[string] params = null, bool function(HTMLElement) fn = null){
		HTMLElement[] output;
		HTMLElement[] dom = this.findAllB(tag_name, params, fn);
		
		// remove endtags
		foreach(e; dom)
			if (!e.isEndTag())
				output ~= e;
				
		return output;
	}
	
	/**
	 * Simple search engine (depth-first algorithm - http://en.wikipedia.org/wiki/Depth-first_search).
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
	public HTMLElement[] findAll(string tag_name, string[string] params = null, bool function(HTMLElement) fn = null){
		HTMLElement[] output;

		if (this.isAlmostEqual(tag_name, params, fn))
			output ~= this;
			
		HTMLElement tmp[];
		foreach(el; this.childs){
			tmp = el.findAll(tag_name, params, fn);

			if (tmp.length > 0)
				output ~= tmp;
		}
		
		return output;
	}

	/**
	 * Simple search engine using Breadth-first algorithm - http://en.wikipedia.org/wiki/Breadth-first_search
	 *
	 * Finds elements and subelements which match patterns given by parameters.
	 * Allows searching defined by users lambda function.
	 *
	 * Params:
	 *     tag_name = Name of searched element.
	 *     params   = Associative array containing searched parameters
	 *     fn       = User defined function. Function takes elements and returns true if wanted.
	 *
	 * Returns: Array of matching elements.
	 * 
	 * See_also:
	 *     findAll
	*/
	public HTMLElement[] findAllB(string tag_name, string[string] params = null, bool function(HTMLElement) fn = null, bool _first = true){
		HTMLElement[] output;
		
		if (this.isAlmostEqual(tag_name, params, fn))
			output ~= this;
		
		HTMLElement[] breadth_search = this.childs;
		foreach(el; breadth_search){
			if (el.isAlmostEqual(tag_name, params, fn))
				output ~= el;
			
			if (el.childs.length > 0)
				breadth_search ~= el.childs;
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
			if (tagname.toLower() == this.tagname.toLower()){
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
		params = params[params.indexOf(this.getTagName()) + this.getTagName().length .. $].strip();
		
		// Parser machine
		ubyte next_state = 0;
		string key, value;
		char end_quote = 0;
		char buff[2] = [' ', ' '];
		foreach(char c; params){
			switch(next_state){
				case 0: // key
					if (!isWhite(c)) // skip whitespaces
						if (c == '=')
							next_state = 1;
						else
							key ~= c;
					break;
				case 1: // value decisioner
					if (!isWhite(c))
						if (c == '\'' || c == '"'){
							next_state = 3;
							end_quote = c;
						}else{
							next_state = 2;
							value ~= c;
						}
					break;
				case 2: // one word parameter without quotes
					if (isWhite(c)){
						next_state = 0;
						this.params[key] = value;
						key = "";
						value = "";
					}else
						value ~= c;
					break;
				case 3: // quoted string
					if (c == end_quote && (buff[0] != '\\' || (buff[0]) == '\\' && buff[1] == '\\')){
						next_state = 0;
						this.params[key] = quote_escaper.unescape(value, end_quote);
						key = "";
						value = "";
						end_quote = 0;
					}else
						value ~= c;
					break;
				default: // every switch have to have default :S
					break;
			}
			
			rotate_buff(buff);
			buff[0] = c;
		}
		
		if (key != ""){
			if (end_quote != 0 && value.strip() != "")
				this.params[key] = quote_escaper.unescape(value, end_quote);
			else
				this.params[key] = value;
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
			if (! c.isEndTag())
				output ~= c.prettify();
		
		// remove \n from end, prettify is nice, but sometimes you need just value
		if (output.endsWith("\n"))
			output = output[0 .. $ - 1];
		
		return output;
	}

	/**
	 * Returns prettified tag with content.
	 *
	 * See_also: toString()
	*/ 
	public string prettify(uint depth = 0, string separator = "  ", bool last = true, bool pre = false, bool inline = false){
		string output;
		
		if (this.getTagName() != "" && this.tagToString().strip() == "")
			return "";
		
		// if not inside <pre> and not inline, shift tag to the right
		if (!pre && !inline)
			for (int i = 0; i < depth; i++)
				output ~= separator;
		
		// for <pre> set 'pre' flag
		if (this.getTagName().toLower() == "pre" && this.isOpeningTag()){
			pre = true;
			separator = "";
		}
		
		output ~= this.tagToString();

		// detect if inline
		bool is_inline = inline; // is_inline shows if inline was set by detection, or as parameter
		foreach(c; this.childs)
			if (!(c.isTag() || c.isComment()))
				if (c.tagToString().strip().length != 0)
					inline = true;
		
		// don't shift if inside container (containers have blank tagname)
		uint original_depth = depth;
		if (this.getTagName() != "")
			if (!pre && !inline){ // inside <pre> doesn't shift tags
				depth++;
				if (this.tagToString().strip() != "")
					output ~= "\n";
			}
		
		// prettify childs
		foreach(e; this.childs){
			if (!e.isEndTag())
				output ~= e.prettify(depth, separator, false, pre, inline);
		}
		
		// endtag
		if (this.endtag !is null){
			if (!pre && !inline)
				for (int i = 0; i < original_depth; i++)
					output ~= separator;
			
			output ~= this.endtag.tagToString().strip();
			
			if (!is_inline)
				output ~= "\n";
		}
		
		return output;
	}
	//* /Getters ***************************************************************
	
	/* *************************************************************************
	 * Operators ***************************************************************
	 **************************************************************************/
	
	/**
	 * Returns original string, which was parsed to DOM.
	 *
	 * If you want prettified string, try .prettify()
	 *
	 * See_also: prettify()
	*/ 
	public string toString(){
		string output;
		
		if (! this.childs.empty){
			output ~= this.element;
			
			foreach(c; this.childs){
				output ~= c.toString();
			}
			
			if (this.endtag !is null)
				output ~= this.endtag.tagToString();
		}else if (!this.isEndTag()){
			output ~= this.tagToString();
		}
		
		return output;
	}
	
	/**
	 * Compare element with given tagname, params and/or by lambda function.
	 * 
	 * Lambda function is same as in .find().
	*/ 
	public bool isAlmostEqual(string tag_name, string[string] params = null, bool function(HTMLElement) fn = null){
		// search by lambda function
		if (fn != null)
			if (fn(this))
				return true;
		
		// compare tagname
		if (this.tagname == tag_name && this.tagname != "" && this.tagname != null){
			// compare pamaterers
			if (params == null || params.length == 0)
				return true;
			else if (this.params.length > 0){
				foreach(key, val; params){
					if (key !in this.params)
						return false;
					else if (params[key] != this.params[key])
						return false;
				}
				
				return true;
			}
		}
		
		return false;
	}
	
	//* /Operators *************************************************************
	
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
	
	/** 
	 * Replace element.
	 * 
	 * Useful when you don't want change manually all references to object.
	*/
	public void replaceWith(HTMLElement el){
		this.childs = el.childs;
		this.params = el.params;
		this.endtag = el.endtag;
		this.openertag = el.openertag;
		
		this.tagname = el.getTagName();
		this.element = el.tagToString();
		
		this.istag = el.isTag();
		this.isendtag = el.isEndTag();
		this.iscomment = el.isComment();
		this.isnonpairtag = el.isNonPairTag();
	}
	
	/**
	 * Remove subelement (child) specified by reference.
	 * 
	 * This can't be used for removing subelements by value! If you want do such
	 * thing, do:
	 * 
	 * ----------------
	 * foreach(e; dom.find("value"))
	 *     dom.removeChild(e);
	 * ----------------
	 * 
	 * Params:
	 *   child = child which will be removed from dom (compared by reference)
	 *   end_tag_too = remove end tag too - default true
	*/
	void removeChild(HTMLElement child, bool end_tag_too = true){
		if (this.childs.length <= 0)
			return;
		
		HTMLElement end_tag;
		if (end_tag_too)
			end_tag = child.endtag;
		
		foreach(int i, HTMLElement e; this.childs){
			if (e is child)
				this.childs = this.childs.remove(i);
			else if (end_tag_too && e is end_tag && end_tag !is null)
				this.childs = this.childs.remove(i);
			else
				e.removeChild(child, end_tag_too);
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

private void rotate_buff(T)(T[] buff){
	for(int i = buff.length - 1; i > 0; i--){
		buff[i] = buff[i - 1];
	}
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
		rotate_buff(buff);
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
			if (!el.isEndTag())
				ostack ~= el;
	}

	return ostack;
}

/**
 * Parse given string and return DOM from HTMLElements.
 *
 * See_also: HTMLElement
*/
public static HTMLElement parseString(string txt){
	HTMLElement[] istack;
	
	// remove UTF BOM (prettify fails if not)
	if (txt.startsWith("\xef\xbb\xbf") && txt.length > 3) // utf8
		txt = txt[3 .. $];
	
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

	// find test
	divXe = dom.find("div", ["id":"xe"])[0];
	divXu = dom.find("div", ["id":"xu"])[0];
	
	assert(divXe.tagToString() == `<div a="b" id="xe">`);
	assert(divXu.tagToString() == `<div a="b" id="xu">`);
	
	// unit test for toString (must returns original string)
	assert(divXe.toString() == `<div id='xe' a='b'>obsah xe divu</div>`);
	assert(divXu.toString() == `<div id='xu' a='b'>obsah xu divu</div>`);
	
	// getTagName() test
	assert(divXe.getTagName() == "div");
	assert(divXe.getTagName() == divXu.getTagName());
	
	// isComment() test
	assert(divXe.isComment() == false);
	assert(divXe.isComment() == divXu.isComment());
	
	assert(divXe.isNonPairTag() != divXe.isOpeningTag());
	
	assert(divXe.isTag() == true);
	assert(divXe.isTag() == divXu.isTag());
	
	assert(divXe.getContent() == "obsah xe divu");
	
	// find()/findB() test
	dom = parseString(`
	<div id=first>
		First div.
		<div id=first.subdiv>
			Subdiv in first div.
		</div>
	</div>
	<div id=second>
		Second.
	</div>
	`);
	// find/findB unittest
	assert(dom.find("div")[1].getContent().strip() == "Subdiv in first div.");
	assert(dom.findB("div")[1].getContent().strip() == "Second.");
}
