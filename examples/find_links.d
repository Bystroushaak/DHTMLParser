/**
 * DHTMLParser example - find all links (content of <a> href parameter)
*/ 

import std.stdio;
import dhtmlparser;

string code = `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

﻿<HTML>
<head>
    <title>Bystroushaakovo doupě</title>
    <link rel="alternate" type="application/rss+xml" 
          href="rss.xml" title="RSS">
    <link rel="stylesheet" type="text/css"
          href="style.css">
    <meta http-equiv="Content-Type"
          content="text/html; charset=utf-8">
</head>
<body>

<table align= "center">
<tr>
<td><pre>
 -:[<a href= "./textydw/">Texty</a>]:-    
 -:[ <a href="./raw/">Raw</a> ]:-

-:[<a href="./D/">czwiki4d</a>]:-
</pre></td>
<td><pre>



                 .d,                                        
   '.           ,KMWx.                      'lkk:           
   .oc        .xWMWKKo                 'cd0WMMMMMX;         
     'dc.    cNMWo.    ,;.     ..,cdk0KK0kxXXo:;,'.         
       lK:.,KMNx.      OMWk,';coo0MMK.     ox               
        ;WMMNo.        kMMk      :MMO      lk               
       'xXNMO.         xMMx      :MMO      cK.              
     .kO;  kM0.        xMMk      :MMO      :W'              
   'll.    .0Mk        xMMk      :MMO      ;Mc              
            :MMk       xMMk      :MMO      .Wx              
           .OMMM:      xMMk      :MMO      .KN.             
          .OMMMMO      xMMd      :MMO       xMc             
         ,XMX0MMN.     kMMo      :MMO       :M0             
        :NWd..WMM;     OMMl      :MMO       .XWc            
      .kWx.   0MM:     0MM;      :MMO        xMN'           
     ;N0,     OMM:    .NMW.      :MMO        ;MMk           
   .k0,       kMM:    'MMK       :MMO         KMM:          
  ,k:         0MM,    cMMd       :MMO         lMMX.         
             ,WMX     kMW'       :MMO  .,     .KMMX.        
             OMMo    ,NWl        :MMO   cXd.   'XMMK.       
            kMMN.    0Mx         :MMO    'NWx.  ;WMMN:      
          .kMMX,    oMk         .oMMX,'',;0MMX'  lMMMMx.    
     ;oodkNMMN,    'Nx   :KKKXNNWMMWXOkdl;,0MM0   lWMMMWc   
      'lXMMM0,    .0c    .0MNl;,'..        ,NM0    :KOc'    
        .xx,     .d,       '.               .;.
</pre></td>
<td>
<pre>
-:[<a href= "kontakt.html">Kontakt</a>]:-
-:[  <a href= "http://keyserver2.pgp.com/vkd/SubmitSearch.event?SearchCriteria=bystrousak%40kitakitsune.org">PGP</a>  ]:-

-:[<a href="https://github.com/Bystroushaak">Git hub</a>]:-
</pre>
</td></tr>
<tr><td></td><td align="center"><pre>bystrousak@kitakitsune:~$ echo "Vitej poutniku"</pre></td><td></td></tr>

</table>

</body>
</HTML>`;

import std.string;

void main(){
	HTMLElement dom = parseString(code);
	
	// find all links:
	foreach(e; dom.find("a"))
		if ("href" in e.params)
			writeln(e.params["href"]);
}