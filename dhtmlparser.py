#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# DHTMLParser in python v1.1.0 (14.09.2011) by Bystroushaak (bystrousak@kitakitsune.org)
# This work is licensed under a Creative Commons 3.0 Unported License
# (http://creativecommons.org/licenses/by/3.0/cz/).
# Created in Geany text editor.
#
# Notes:
    #
    
def unescape(input, quote = '"'):
	if len(input) < 2:
		return input

	output = ""
	old = input[0]
	older = ""
	
	for act in input[1:] + " ":
		if act == quote and old == "\\" and older != "\\":
			older = old
			old = act
			continue
		else:
			output += old
		
		older = old
		old = act
	
	return output


def escape(input, quote = '"'):
	output = ""
	
	for c in input:
		if c == quote:
			output += '\\'
		
		output += c
	
	return output


def rotate_buff(buff):
	"Rotate buffer (for each buff[i] = buff[i-1])"
	i = len(buff) - 1
	while i > 0:
		buff[i] = buff[i - 1]
		i -= 1

	return buff


class HTMLElement():
	"""
	Container for parsed html elements.
	
	You can create:
		HTMLElement() # blank element
		
		HTMLElement("<tag>") # from string containing tag (only one tag)
		
		HTMLElement("<tag>", {"param":"value"}) # tag (with or without <>) with parameters defined by dictionary 
		
		# These constructors are usefull for creating documents:
		HTMLElement("tag", {"param":"value"}, [HTMLElement("<tag1>"), HTMLElement("<tag2>"), ...])
		HTMLElement("tag", [HTMLElement("<tag1>"), HTMLElement("<tag2>"), ...])
		HTMLElement([HTMLElement("<tag1>"), HTMLElement("<tag2>"), ...])
	"""
	
	
	def __init__(self, tag = "", second = None, third = None):
		self.__element = None
		self.__tagname = ""
		
		self.__istag        = False
		self.__isendtag     = False
		self.__iscomment    = False
		self.__isnonpairtag = False
		
		self.childs = []
		self.params = {}
		self.endtag = None
		self.openertag = None
		
		# blah, constructor overloading in python sux :P
		if isinstance(tag, str) and second == None and third == None:
			self.__init_tag(tag)
		elif isinstance(tag, str) and isinstance(second, dict) and third == None:
			self.__init_tag_params(tag, second)
		elif isinstance(tag, str) and isinstance(second, dict) and (isinstance(third, list) or isinstance(third, tuple)) and len(third) > 0 and isinstance(third[0], HTMLElement):
			self.__init_tag_params(tag, second)
			self.childs = __closeElements(third)
		elif isinstance(tag, str) and (isinstance(second, list) or isinstance(second, tuple)) and len(second) > 0 and isinstance(second[0], HTMLElement):
			self.__init_tag(tag)
			self.childs = __closeElements(second)
		elif (isinstance(tag, list) or isinstance(tag, tuple)) and len(tag) > 0 and isinstance(tag[0], HTMLElement):
			self.__init_tag("")
			self.childs = __closeElements(tag)
		else:
			raise Exception("Oh no, not this crap!")
	
	#===========================================================================
	#= Constructor overloading =================================================
	#===========================================================================
	def __init_tag(self, tag):
			self.__element = tag
			
			self.__parseIsTag()
			self.__parseIsEndTag()
			
			self.__parseIsComment()
			
			if not self.isTag() or self.isComment():
				self.__tagname = self.__element
			else:
				self.__parseTagName()
			
			if self.isOpeningTag():
				self.__parseParams()
	
	def __init_tag_params(self, tag, params):
		tag = tag.strip().replace(" ", "")
		nonpair = ""
		
		if tag.startswith("<"):
			tag = tag[1:]
		
		if tag.endswith("/>"):
			tag = tag[:-2]
			nonpair = " /"
		elif tag.endswith(">"):
			tag = tag[:-1]
		
		output = "<" + tag
		
		for key in params.keys():
			output += " " + key + '="' + escape(params[key], '"') + '"'
		
		self.__init_tag(output + nonpair + ">")
	
	
	#===========================================================================
	#= Finders =================================================================
	#===========================================================================
	def find(self, tag_name, params = None, fn = None):
		"""	
		Simple search engine.
		 
		Finds elements and subelements which match patterns given by parameters.
		Allows searching defined by users lambda function.
		
		@param tag_name: Name of tag.
		@type tag_name: string
		
		@param params: Parameters of arg.
		@type params: dictionary
		
		@param fn: User defined function for search.
		@type fn: lambda function
		
		@return: Matches.
		@rtype: Array of HTMLElements
		"""
		output = []
		
		if self.isComment() or self.isNonPairTag() or self.isEndTag():
			return None
		
		if fn != None:
			if fn(self):
				output.append(self)
		
		if self.__tagname == tag_name and self.__tagname != "" and self.__tagname != None:
			if params == None:
				output.append(self)
			else:
				tmp_stat = True
				
				for key in params.keys():
					if key not in self.params:
						tmp_stat = False
					elif params[key] != self.params[key]:
						tmp_stat = False
						
				if len(self.params) == 0:
					tmp_stat = False
				
				if tmp_stat:
					output.append(self)
		
		tmp = []
		for el in self.childs:
			tmp = el.find(tag_name, params, fn)
			
			if tmp != None and len(tmp) > 0:
				output.extend(tmp)
		
		return output

	#==========================================================================
	#= Parsers ================================================================
	#==========================================================================
	def __parseIsTag(self):
		if self.__element.startswith("<") and self.__element.endswith(">"):
			self.__istag = True
		else:
			self.__istag = False

	def __parseIsEndTag(self):
		last = ""
		self.__isendtag = False
		
		if self.__element.startswith("<") and self.__element.endswith(">"):
			for c in self.__element:
				if c == "/" and last == "<":
					self.__isendtag = True
				if ord(c) > 32:
					last = c

	def __parseIsNonPairTag(self):
		last = ""
		self.__isnonpairtag = False
		
		# Tags endings with /> are nonpair
		if self.__element.startswith("<") and self.__element.endswith(">"):
			for c in self.__element:
				if c == ">" and last == "/":
					self.__isnonpairtag = True
				if ord(c) > 32:
					last = c
		
		# Nonpair tags
		npt = [
			"br",
			"hr",
			"img",
			"input",
			"link",
			"meta",
			"spacer",
			"frame",
			"base"
		]
		
		if self.__tagname in npt:
			self.__isnonpairtag = True
		
	def __parseIsComment(self):
		if self.__element.startswith("<!--") and self.__element.endswith("-->"):
			self.__iscomment = True
		else:
			self.__iscomment = False

	def __parseTagName(self):
		for el in self.__element.split(" "):
			el = el.replace("/", "").replace("<", "").replace(">", "")
			if len(el) > 0:
				self.__tagname = el
				return

	def __parseParams(self):	
		# check if there are any parameters
		if " " not in self.__element or "=" not in self.__element:
			return
		
		# Remove '<' & '>'
		params = self.__element.strip()[1:-1].strip()
		# Remove tagname
		params = params[params.find(self.getTagName()) + len(self.getTagName()):].strip()
		
		# Parser machine
		next_state = 0
		key = ""
		value = ""
		end_quote = ""
		buff = ["", ""]
		for c in params:
			if next_state == 0: # key
				if c.strip() != "": # safer than list space, tab and all possible whitespaces in UTF
					if c == "=":
						next_state = 1
					else:
						key += c
			elif next_state == 1: # value decisioner
				if c.strip() != "": # skip whitespaces
					if c == "'" or c == '"':
						next_state = 3
						end_quote = c
					else:
						next_state = 2
						value += c
			elif next_state == 2: # one word parameter without quotes
				if c.strip() == "":
					next_state = 0
					self.params[key] = value
					key = ""
					value = ""
				else:
					value += c
			elif next_state == 3: # quoted string
				if c == end_quote and (buff[0] != "\\" or (buff[0]) == "\\" and buff[1] == "\\"):
					next_state = 0
					self.params[key] = unescape(value, end_quote)
					key = ""
					value = ""
					end_quote = ""
				else:
					value += c
				
			buff = rotate_buff(buff)
			buff[0] = c
			
		if key != "":
			if end_quote != "" and value.strip() != "":
				self.params[key] = unescape(value, end_quote)
			else:
				self.params[key] = value

	#===========================================================================
	#= Parsers =================================================================
	#===========================================================================
	def isTag(self):
		"True if element is tag (not content)."
		return self.__istag

	def isComment(self):
		"True if HTMLElement is html comment."
		return self.__iscomment

	def isEndTag(self):
		"True if HTMLElement is end tag (/tag)."
		return self.__isendtag

	def isNonPairTag(self, isnonpair = None):
		"True if HTMLElement is nonpair tag (br for example). Can also change state from pair to nonpair and so."
		if isnonpair == None:
			return self.__isnonpairtag
		else:
			self.__isnonpairtag = isnonpair
			if not isnonpair:
				self.endtag = None
				self.childs = []

	def isOpeningTag(self):
		"True if is opening tag."
		if (self.isTag() and not self.isComment() and not self.isEndTag() and not self.isNonPairTag()):
			return True
		else:
			return False
	
	def isEndTagTo(self, opener):
		"Returns true, if this element is endtag to opener."
		if self.__isendtag and opener.isOpeningTag():
			if self.__tagname.lower() == opener.getTagName().lower():
				return True
			else:
				return False
		else:
			return False

	def __str__(self):
		"Returns prettifyied tag with content."
		return self.prettify()
	
	def tagToString(self):
		"Returns tag (with parameters), without content or endtag."
		if not self.isOpeningTag():
			return self.__element
		else:
			output = "<" + str(self.__tagname)
			
			for key in self.params.keys():
				output += " " + key + "=\"" + escape(self.params[key], '"') + "\""
			
			return output + ">"
	
	def getTagName(self):
		"Returns tag name."
		return self.__tagname
	
	def getContent(self):
		"Returns content of tag (everything between opener and endtag)."
		output = ""
		
		for c in self.childs:
			output = c.prettify()
		
		return output
	
	def prettify(self, depth = 0, separator = "  "):
		"Returns prettifyied tag with content. Same as toString()."
		output = ""
		
		if self.__element != "":
			output += self.tagToString() + "\n"
			depth += 1
		
		if len(self.childs) != 0:
			output += self.__prettify(self.childs, depth)
		
		if self.endtag != None:
			output += self.endtag.tagToString() + "\n"
		
		return output

	def __prettify(self, istack, depth = 0, separator = "  "):
		output = ""
		strout = ""
		
		for el in istack:
			output += depth * separator
			
			output += el.tagToString() + "\n"
			
			if len(el.childs) > 0:
				output += self.__prettify(el.childs, depth + 1, separator)
			
		for line in output.splitlines():
			if line.strip() != "":
				strout += line + "\n"
		
		return strout
	
	#===========================================================================
	#= Static methods ==========================================================
	#===========================================================================
	
	def __closeElements(childs):
		o = []
		
		for e in childs:
			if e.isTag():
				if not e.isNonPairTag() and not e.isEndTag() and not e.isComment() and e.endtag == None:
					e.childs = __closeElements(e.childs)
					
					o.append(e)
					o.append(HTMLElement("</" + e.getTagName() + ">"))
					
					# Join opener and endtag
					e.endtag = o[-1]
					o[-1].openertag = e
				else:
					o.append(e)
			else:
				o.append(e)
		
		return o

def __raw_split(itxt):
	"""
	Parse HTML from text into array filled with tags end text.
	
	Source code is little bit unintutive, because it is simple parser machine.
	For better understanding, look at; http://kitakitsune.org/images/field_parser.png
	"""
	echr = ""
	buff = ["", "", "", ""]
	content = ""
	array = []
	next_state = 0
	inside_tag = False
	
	for c in itxt:
		if next_state == 0: # content
			if c == "<":
				if len(content) > 0:
					array.append(content)
				content = c
				next_state = 1
				inside_tag = False
			else:
				content += c
		elif next_state == 1: # html tag
			if c == ">":
				array.append(content + c)
				content = ""
				next_state = 0
			elif c == "'" or c == '"':
				echr = c
				content += c
				next_state = 2
			elif c == "-" and buff[0] == "-" and buff[1] == "!" and buff[2] == "<":
				if len(content[:-3]) > 0:
					array.append(content[:-3])
				content = content[-3:] + c
				next_state = 3
			else:
				if c == "<": # jump back into tag instead of content
					inside_tag = True
				content += c
		elif next_state == 2: # "" / ''
			if c == echr and (buff[0] != "\\" or (buff[0] == "\\" and buff[1] == "\\")):
				next_state = 1
			content += c
		elif next_state == 3: # html comments
			if c == ">" and buff[0] == "-" and buff[1] == "-":
				if inside_tag:
					next_state = 1
				else:
					next_state = 0
				inside_tag = False
				
				array.append(content + c)
				content = ""
			else:
				content += c
		
		# rotate buffer
		buff = rotate_buff(buff)
		buff[0] = c
	
	if len(content) > 0:
		array.append(content)
	
	return array

def __repair_tags(raw_input):
	"""
	Repair tags with comments (<HT<!-- asad -->ML> is parsed to ["<HT", "<!-- asad -->", "ML>"]
	and I need ["<HTML>", "<!-- asad -->"])
	"""
	ostack = []
	
	index = 0
	while index < len(raw_input):
		el = raw_input[index]
		
		if el.isComment():
			if index > 0 and index < len(raw_input):
				if raw_input[index - 1].tagToString().startswith("<") and raw_input[index + 1].tagToString().endswith(">"):
					ostack[-1] = HTMLElement(ostack[-1].tagToString() + raw_input[index + 1].tagToString())
					ostack.append(el)
					index += 1
					continue
		
		ostack.append(el)
		
		index += 1
	
	return ostack

def __indexOfEndTag(istack):
	"""
	Go through istack and search endtag. Element at first index is considered as opening tag.
	
	Returns: index of end tag or 0 if not found.
	"""
	if len(istack) <= 0:
		return 0
	
	if not istack[0].isOpeningTag():
		return 0
	
	opener = istack[0]
	cnt = 0
	
	index = 0
	for el in istack[1:]:
		if el.isOpeningTag() and (el.getTagName().lower() == opener.getTagName().lower()):
			cnt += 1
		elif el.isEndTagTo(opener):
			if cnt == 0:
				return index + 1
			else:
				cnt -= 1
				
		index += 1
	
	return 0

def __parseDOM(istack):
	"Recursively go through element array and create DOM."
	ostack = []
	end_tag_index = 0
	
	index = 0
	while index < len(istack):
		el = istack[index]
		
		end_tag_index = __indexOfEndTag(istack[index:]) # Check if this is pair tag
		
		if not el.isNonPairTag() and end_tag_index == 0 and not el.isEndTag():
			el.isNonPairTag(True)
		
		if end_tag_index != 0:
			el.childs = __parseDOM(istack[index + 1 : end_tag_index + index])
			el.endtag = istack[end_tag_index + index] # Reference to endtag
			el.openertag = el
			ostack.append(el)
			ostack.append(el.endtag)
			index = end_tag_index + index
		else:
			ostack.append(el)
		
		index += 1
	
	return ostack

def parseString(txt):
	"Parse given string and return DOM from HTMLElements."
	istack = []
	
	for el in __raw_split(txt):
		istack.append(HTMLElement(el))
	
	container = HTMLElement()
	container.childs = __parseDOM(__repair_tags(istack))
	
	return container 