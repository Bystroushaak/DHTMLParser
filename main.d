import std.stdio;

import dhtmlparser;

void main(){
	HTMLElement dom = parseString(
		"<?xml syntax?>
		<doctype sracky=asd>
		<HTML>
		<head <!-- Doplnit meta tagy!--> parametr_hlavy=\"hlava..\">
		<title>Testovaci polygon..</title>
		</head>
		<body bgcolor='black'asd=bsd>
		<h1>Polygon..</h1>
		Nejaky pekny odstavecek..
		<!-- zakomentovany text.. >>><<<< \" -->
		<div id='xe' a='b'>obsah xe divu</div>
		<div id='xu' a='b'>obsah xu divu</div>
		</body>"
		`<html onclick="alert('hello \' world');">`
		"</html>
		</html>"
	);

	writeln(dom);

	writeln("---\n");

	writeln(dom.find("head")[0].pretiffy());
	
	writeln("---\n");
	
	writeln(dom.find(null, null, function(HTMLElement e) {return e.getTagName() == "div";}));
    
//     writeln(unescape("<head <!-- Doplnit meta tagy!--> parametr_hlavy=\"hlava..\">", '"'));
}