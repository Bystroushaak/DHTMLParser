/**
 * Remove child from dom example.
*/
import std.stdio;

import dhtmlparser;


int main(string[] args){
	string s = `
<root>
	<object1>Content of first object</object1>
	<object2>Second objects content</object2>
</root>`;

	auto dom = parseString(s); // create dom
	
	writeln(dom);
	writeln("---\nRemove all <object1>:\n---\n");
	
	// remove all <object1>
	foreach(e; dom.find("object1"))
		dom.removeChild(e);
	
	writeln(dom);
	
	return 0;
}

/* Write: **********************************************************************
<root>
  <object1>Content of first object</object1>
  <object2>Second objects content</object2>
</root>

---
Remove <object1>:
---

<root>
  <object2>Second objects content</object2>
</root>
*******************************************************************************/