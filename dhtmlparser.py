#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# NONAME v0.0.0 (dd.mm.yy) by Bystroushaak (bystrousak@kitakitsune.org)
# This work is licensed under a Creative Commons Attribution-Noncommercial-Share Alike 3.0 
# Unported License (http://creativecommons.org/licenses/by-nc-sa/3.0/cz/).
# Created in §Editor text editor.
#
# Notes:
    # 
#===============================================================================
# Imports ======================================================================
#===============================================================================



#===============================================================================
# Variables ====================================================================
#===============================================================================



#===============================================================================
#= Functions & objects =========================================================
#===============================================================================
def unescape(input, quote = '"'):
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
	
	return output

def escape(input, quote = '"'):
	output = ""
	
	for c in input:
		if c == quote:
			ouput += '\\'
		
		output += c
	
	return output


class HTMLElement():
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
			
			if len(tmp) > 0:
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
		if " " not in self.__element or "=" not in self.__element:
			return
		
		# Remove '<' & '>'
		params = self.__element[1:-1].strip()
		
		# Remove tagname
		params = params[params.find(" "):].strip()
		
		tmp = params.split("=")
		
		# Parse parameters (it isn't so simple as it could look..)
		li    = 0 # last index
		value = []
		key   = tmp[0]
		i = 1
		while i < len(tmp) - 1:
			li = tmp[i].rfind(" ")
			if li < tmp[i].rfind("'"):
				li = tmp[i].rfind("'")
			if li < tmp[i].rfind('"'):
				li = tmp[i].rfind('"')
			
			self.params[key.strip()] = tmp[i][0:li + 1]
			key = tmp[i][li + 1:]

			i += 1 
		self.params[key.strip()] = tmp[-1]
		
		# Read and unescape parameters
		tmparam = ""
		for key in self.params.keys():
			pvalue = self.params[key]
			tmparam = str(pvalue)
			
			if pvalue.startswith("'") or pvalue.startswith('"'):
				tmparam = str(pvalue[1:])
			if pvalue.endswith("'") or pvalue.endswith('"'):
				if len(tmparam) > 1:
					tmparam = tmparam[:-1]
			
			if pvalue.startswith("'") or pvalue.startswith('"'):
				if len(tmparam) > 2:
					tmparam = unescape(tmparam, pvalue[0])
			
			pvalue = tmparam
			self.params[key] = pvalue

	#===========================================================================
	#= Parsers =================================================================
	#===========================================================================

	def isTag(self):
		return self.__istag

	def isComment(self):
		return self.__iscomment

	def isEndTag(self):
		return self.__isendtag

	def isNonPairTag(self, isnonpair = None):
		if isnonpair == None:
			return self.__isnonpairtag
		else:
			self.__isnonpairtag = isnonpair
			self.endtag = None
			self.childs = []

	def isOpeningTag(self):
		if (self.isTag() and not self.isComment() and not self.isEndTag() and not self.isNonPairTag()):
			return True
		else:
			return False
	
	def isEndTagTo(self, opener):
		if self.__isendtag and opener.isOpeningTag():
			if self.__tagname.lower() == opener.getTagName().lower():
				return True
			else:
				return False
		else:
			return False

	def __str__(self):
		return self.pretiffy()
	
	def tagToString(self):
		if not self.isOpeningTag():
			return self.__element
		else:
			output = "<" + str(self.__tagname)
			
			for key in self.params.keys():
				output += " " + key + "=\"" + escape(self.params[key], '"') + "\""
			
			return output + ">"
	
	def getTagName(self):
		return self.__tagname
	
	def getContent(self):
		"Returns content of tag (everything between opener and endtag)."
		
		output = ""
		
		for c in self.childs:
			output = c.pretiffy()
		
		return output
	
	def pretiffy(self, depth = 0, separator = "  "):
		output = ""
		
		if self.__element != "":
			output += self.tagToString() + "\n"
			depth += 1
		
		if len(self.childs) != 0:
			output += self.__pretiffy(self.childs, depth)
		
		if self.endtag != None:
			output += self.endtag.tagToString() + "\n"
		
		return output

	def __pretiffy(self, istack, depth = 0, separator = "  "):
		output = ""
		strout = ""
		
		for el in istack:
			output += depth * separator
			
			output += el.tagToString() + "\n"
			
			if len(el.childs) > 0:
				output += self.__pretiffy(el.childs, depth + 1, separator)
			
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


