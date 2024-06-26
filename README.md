# Deprecated

This repository was created long time ago when I was learning D and it is unmaintained and abandoned for more than a decade now. Use it at your own risk.

# DHTMLParser 

## What is it?
DHTMLParser is a lightweight parser created for one purpose - quick parsing 
of selected information, when you know where to look.

It can be very useful when you're writing your own API for a page, or a 
checker (a script that is continuously checking something on the web and 
alerts you when the information being checked has been changed).

If you want, you can also create HTML/XML documents much more easily than 
from a string.

## How it works?
The module has just one, important function - parseString(), which takes
a string and returns a DOM (Document Object Model) made of HTMLElement 
objects.

The DOM is encapsulated in a container - a blank HTMLElement that holds
the whole DOM in its .childs property.

## HTMLElement

```
|
|++ HTMLElement[] childs
|		If the element has children, they are stored in this property.
|
|++ string[string] params
|		If the element has parametres, you will find them here.
|
|++ HTMLElement endtag
|		In case this tag is an Opener (<p> for example), this variable holds a 
|		link to the closing element (</p>).
|
|++ HTMLElement openertag
|		Analogous to endtag.
|
|-- HTMLElement[] find(string tag_name, string[string] params = null, function fn = null)
|		Same as findAll(), but doesn't returns endtags. You can always get them 
|		from .endtag property.
|
|-- HTMLElement[] findB(string tag_name, string[string] params = null, function fn = null)
|		Same as find(), but using Breadth-first search algorithm.
|
|-- HTMLElement[] findAll(string tag_name, string[string] params = null, function fn = null)
|		One of the most important methods, which handles DOM queries.
|
|		Lets say that you want each link in a page - 'dom.find("a")' will 
|		return an array of links.
|
|		You can also specify parametres or define a lambda function which will 
|		find whatever you want.
|
|		This method is using depth-first algorithm. For bread-first, see findAllB()
|		and findB().
|
|-- HTMLelement findAllB(string tag_name, string[string] params = null, function fn = null)
|		Same as findAll(), but using Breadth-first search algorithm.
|
|		See http://en.wikipedia.org/wiki/Breadth-first_search for details.
|
|-- bool isTag()
|		Returns true if the element is a tag (closed in <>). Comments aren't tags!
|
|-- bool isOpeningTag()
|		Returns true if element have .endtag (is closed).
|
|-- bool isEndTag()
|		Returns true if closing tag. 
|
|-- bool isEndTagTo(HTMLElement opener)
|		Returns true if this element is an end tag </tagname> for given element.
|
|-- bool isNonPairTag()
|		Returns true if nonpair tag (<br /> for example).
|
|-- void isNonPairTag(bool isnonpairtag)
|		Setter which allows setting whether this element is nonpair. 
|
|-- bool isComment()
|		Returns true if this element is an HTML comment (<!-- -->).
|
|-- bool isAlmostEqual(string tag_name, string[string] params = null, bool function(HTMLElement) fn = null)
|		Compare element with given tagname, params and/or by lambda function.
|
|		Lambda function is same as in .find().
|
|-- string toString()
|		String representation of this element, same as prettify().
|
|-- string prettify()
|		Returns prettified HTML output with childs (full document).
|
|-- void replaceWith(HTMLElement el)
|		Replace element.
|
|		Useful when you don't want change manually all references to object.
|
|-- void removeChild(HTMLElement child, bool end_tag_too = true)
|		Removes given subelement. Element is specified by reference, not by
|		value, so it always removes only one element!
|
|		end_tag_too specifies if endtag shoud be removed too. Default true.
|
|-- string tagToString()
|		Returns a string representation if tag, without childs.
|
|-- string getTagName()
|		Tagname - <a href="bla"> returns "a".
|
`-- string getContent()
		Childs to string.
```

## Creating DOM
If you want to create DOM from HTMLElements, you can use one of theese 
constructors:

```D
HTMLElement()
```

Blank element.

```D
HTMLElement("<tag>")
```

From string containing tag (only one tag).

```D
HTMLElement("<tag>", ["param":"value"])
```

Tag (with or without <>) with parameters defined by dictionary.

These constructors are useful for creating documents:

```D
HTMLElement("tag", ["param":"value"], [new HTMLElement("<tag1>"), new HTMLElement("<tag2>"), ...])
```

With specified tag, params and childs.
		
```D
HTMLElement("tag", [new HTMLElement("<tag1>"), new HTMLElement("<tag2>"), ...])
```

With specified tag and childs.

```
HTMLElement([new HTMLElement("<tag1>"), new HTMLElement("<tag2>"), ...])
```

With speicifed childs. Usefull for containers.

## Confused?
If you don't understand how to use it, look at examples in ./examples/.
	

