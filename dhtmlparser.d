

import std.stdio;

class HTMLParser{
	this(ref string txt){
		parse(txt);
	}
	
	/**
	 * http://kitakitsune.org/images/field_parser.png
    */ 
	private string[] raw_split(ref string itxt){
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
	
	public void parse(ref string txt){
		string[] parts = this.raw_split(txt);
		
		foreach(string line; parts)
			writeln(line);
	}
}

void main(){
	HTMLParser p = new HTMLParser("asd<HTML><head type= 'xe>'>hlava</he<!-- komen>>tar-->ad><body>tělo:<br>řádek1<!-- asd --><br />řádek2</body></HTML>asd");
}