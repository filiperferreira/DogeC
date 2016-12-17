SPACES  [\t ]
LINE    [\n]
NUMBER  [0-9]
LETTER  [A-Za-z_]
INT     [-]?{NUMBER}+
DOUBLE  [-]?{NUMBER}+("."{NUMBER}+)?
ID      {LETTER}({LETTER}|{NUMBER})*
CHAR    "'"{LETTER}"'"
STRING  "\""([^\n'])*"\""

%%

{LINE}      {lineNumber++;}
{SPACES}    {}

"doge"      {yylval = Attributes(yytext); return TK_MAIN;}
"numbuh"    {yylval = Attributes(yytext); return TK_INT;}
"letter"    {yylval = Attributes(yytext); return TK_CHAR;}
"woof"      {yylval = Attributes(yytext); return TK_BOOL;}
"floaty"    {yylval = Attributes(yytext); return TK_DOUBLE;}
"wordies"   {yylval = Attributes(yytext); return TK_STRING;}
"real"      {yylval = Attributes("true"); return TK_BOOLVAL;}
"lies"      {yylval = Attributes("false"); return TK_BOOLVAL;}

"say"       {yylval = Attributes(yytext); return TK_OUT;}
"hear"      {yylval = Attributes(yytext); return TK_IN;}

"wow"       {yylval = Attributes(yytext); return TK_IF;}
"scare"     {yylval = Attributes(yytext); return TK_ELSE;}
"loopy"     {yylval = Attributes(yytext); return TK_FOR;}
"chase"     {yylval = Attributes(yytext); return TK_WHILE;}
"make"      {yylval = Attributes(yytext); return TK_DO;}
"switchy"   {yylval = Attributes(yytext); return TK_SWITCH;}
"choose"	{yylval = Attributes(yytext); return TK_CASE;}
"default"   {yylval = Attributes(yytext); return TK_DEFAULT;}

"very"      {yylval = Attributes(yytext); return TK_ATTRIB;}
"much"      {yylval = Attributes(yytext); return TK_SUM;}
"less"      {yylval = Attributes(yytext); return TK_SUB;}
"many"      {yylval = Attributes(yytext); return TK_MUL;}
"few"       {yylval = Attributes(yytext); return TK_DIV;}
"both"      {yylval = Attributes(yytext); return TK_AND;}
"either"    {yylval = Attributes(yytext); return TK_OR;}
"nope"      {yylval = Attributes(yytext); return TK_NEG;}
"biggery"   {yylval = Attributes(yytext); return TK_GT;}
"smallery"  {yylval = Attributes(yytext); return TK_ST;}
"not same"  {yylval = Attributes(yytext); return TK_DIF;}
"same"      {yylval = Attributes(yytext); return TK_EQUAL;}
"biggerish" {yylval = Attributes(yytext); return TK_GET;}
"smallerish" {yylval = Attributes(yytext); return TK_SET;}

{ID}        {yylval = Attributes(yytext); return TK_ID;}
{INT}       {yylval = Attributes(yytext); return TK_INTVAL;}
{DOUBLE}    {yylval = Attributes(yytext); return TK_DOUBLEVAL;}
{STRING}    {yylval = Attributes(yytext); return TK_STRINGVAL;}
{CHAR}      {yylval = Attributes(yytext); return TK_CHARVAL;}
.           {return *yytext;}

%%
