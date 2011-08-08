/**
 * DHTMLParser DOM creation example. 
*/ 

import std.stdio;

import dhtmlparser;

void main(){
	HTMLElement e = new HTMLElement([ // anonymous element - container
		new HTMLElement("<root>", [
			new HTMLElement("item", ["param1" : "1", "param2" : "2"], [ // when params are present, you don't need <> 
				new HTMLElement("<crap>", [
					new HTMLElement("hello parser!")                    // just data 
				]),
				new HTMLElement("<another_crap/>", ["with" : "params"]), // nonpair tag
				new HTMLElement("<!-- comment -->")
			]),
			
			new HTMLElement("<item/>", ["blank" : "body"])
		])
	]);
	
	writeln(e);

/* Write: **********************************************************************
<root>
  <item param1="1" param2="2">
    <crap>
      hello parser!
    </crap>
    <another_crap with="params" />
    <!-- comment -->
  </item>
  <item blank="body" />
</root>

*******************************************************************************/
}