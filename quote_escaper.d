/* quote_escaper.d v1.2.0 (06.06.2011) by Bystroushaak (bystrousak@kitakitsune.org)
 * 
 * Module for (un)escaping quotes.
 * 
 * This work is licensed under a CC BY (http://creativecommons.org/licenses/by/3.0/)
*/
	import std.stdio;
public string unescape(string input, char quote = '"'){
	if (input.length < 2)
		return input;
	
	string output;
	bool unesc = false;
	foreach(act; input){
		if (act == quote && unesc)
			output = output[0 .. $-1];
		
		output ~= act;
		
		if (act == '\\')
			unesc = !unesc;
		else
			unesc = false;
	}

	return output;
}

public string escape(string input, char quote = '"'){
	string output;

	foreach(c; input){
		if (c == quote)
			output ~= '\\';
		
		output ~= c;
	}

	return output;
}

unittest{
		assert(unescape(`\' \\ \" \n`) == `\' \\ " \n`);
		assert(unescape(`\' \\ \" \n`, '\'') == `' \\ \" \n`);
		assert(unescape(`\' \\" \n`) == `\' \\" \n`);
		assert(unescape(`\' \\" \n`) == `\' \\" \n`);
		assert(unescape(`printf(\"hello \t world\");`) == `printf("hello \t world");`);
		
		assert(escape(`printf("hello world");`) == `printf(\"hello world\");`);
		assert(escape(`'`, '\'') == `\'`);
}
