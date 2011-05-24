/* quote_escaper.d v1.0.0 (24.05.2011) by Bystroushaak (bystrousak@kitakitsune.org)
 * 
 * Module for (un)escaping quotes.
 * 
 * This work is licensed under a Creative Commons Attribution-Noncommercial-Share Alike 3.0 
 * Unported License (http://creativecommons.org/licenses/by-nc-sa/3.0/cz/).
*/

public string unescape(string input, char quote = '"'){
	string output;
	char old = input[0];
	char older;

	foreach(act; input[1 .. $] ~ ' '){
		if (act == quote && old == '\\' && older != '\\'){
			older = old;
			old = act;
			continue;
		}else
			output ~= old;

		older = old;
		old = act;
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
    
    assert(escape(`printf("hello world");`) == `printf(\"hello world\");`);
    assert(escape(`'`, '\'') == `\'`);
}
