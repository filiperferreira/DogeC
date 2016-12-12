%{
#include <string>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <map>

using namespace std;

string lastType;
int curTempVar = 0;

int yylex();
void error(string);
void yyerror(const char* st);

vector<string> tempVector;

struct Attributes {
  string code;
  string name;
  string type;

  Attributes() {}

  Attributes(string n) {
    name = n;
  }
};

struct Type {
  string baseType;
  int dimension;
  
  Type() {}  

  Type(string type) {
    baseType = type;
    dimension = 0;
  }
};

void newScope();
void exitScope();
void insertSymbolTable(string, string);
void verifyType(string, string);

string attributeToVar(string, string, string);
string declareVariable(string, string);
string getVarType(string);
string newTempVar(string);
string dogeToC(string);
string checkResultType(string, string, string);
string generateOperatorCode(string, string, string, string, string);

string includes = 
"#include <iostream>\n"
"#include <stdio.h>\n"
"#include <stdlib.h>\n"
"#include <string.h>\n"
"\n"
"using namespace std;\n";

#define YYSTYPE Attributes

%}

%token TK_MAIN TK_ATTRIB TK_OUT TK_IN
%token TK_INT TK_CHAR TK_BOOL TK_DOUBLE TK_STRING TK_ID
%token TK_INTVAL TK_DOUBLEVAL TK_STRINGVAL TK_CHARVAL TK_BOOLVAL
%token TK_IF TK_ELSE

%left TK_AND TK_OR
%nonassoc TK_NEG TK_GT TK_ST TK_DIF TK_EQUAL TK_GET TK_SET
%left TK_SUM TK_SUB
%left TK_MUL TK_DIV

%%

S: MAIN
   {cout << includes << endl;
    cout << $1.code << endl;}
 ;

MAIN: TK_MAIN '{' {newScope();} VARS PROG {exitScope();} '}'
      {$$.code = "int main() {\n";
       while(tempVector.size() != 0) {
         $$.code += tempVector[tempVector.size()-1] + ";\n";
         tempVector.pop_back();
       }
       $$.code += $4.code + $5.code + "return 0;\n}";}
    ;

VARS: VAR_TYPE IDS VARS
      {$$.code = $1.code + $2.code + $3.code;}
    |
      {$$.code = "";}
    ;

VAR_TYPE: TK_INT
          {$$.code = "int ";
           lastType = $1.name;}
        | TK_CHAR
          {$$.code = "char ";
           lastType = $1.name;}
        | TK_BOOL
          {$$.code = "int ";
           lastType = $1.name;}
        | TK_DOUBLE
          {$$.code = "double ";
           lastType = $1.name;}
        | TK_STRING
          {$$.code = "char ";
           lastType = $1.name;}
        ;

IDS: TK_ID ',' IDS
     {$$.code = declareVariable($1.name, lastType) + ", " + $3.code;}
   | TK_ID ';'
     {$$.code = declareVariable($1.name, lastType) + ";\n";}
   ;

PROG: OPERATION ';' PROG
      {$$.code = $1.code + $3.code;}
    |
      {$$.code = "";}
    ;

OPERATION: TK_ID TK_ATTRIB E
           {$$.code = $3.code;
            $$.code += attributeToVar($1.name, $3.name, $3.type) + ";\n";}
         | TK_OUT '(' E ')'
           {$$.code = "cout << " + $3.name + ";\n";
            $$.code += "cout << \"\\n\";\n";}
         | TK_IN '(' E ')'
           {$$.code = "cin >> " + $3.name + ";\n";}
         |
           {$$.code = "";}
         ;

E: VALUE
   {$$.name = $1.name;
    $$.type = $1.type;}
 | TK_ID
   {$$.name = $1.name;
    $$.type = getVarType($1.name);}
 | E TK_SUM E
   {$$.type = checkResultType($1.type, $3.type, "+");
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "+", $$.type);}
 | E TK_SUB E
   {$$.type = checkResultType($1.type, $3.type, "-");
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += $$.name + " = " + $1.name + " - " + $3.name + ";\n";}
 | E TK_MUL E
   {$$.type = checkResultType($1.type, $3.type, "*");
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += $$.name + " = " + $1.name + " * " + $3.name + ";\n";}
 | E TK_DIV E
   {$$.type = checkResultType($1.type, $3.type, "/");
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += $$.name + " = " + $1.name + " / " + $3.name + ";\n";}
 | E TK_AND E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code = $$.name + " = " + $1.name + " && " + $3.name + ";\n";}
 | E TK_OR E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code = $$.name + " = " + $1.name + " || " + $3.name + ";\n";}
 | TK_NEG E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $2.code;
    $$.code = $$.name + " = !" + $2.name + ";\n";}
 | E TK_GT E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code = $$.name + " = " + $1.name + " > " + $3.name + ";\n";}
 | E TK_ST E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code = $$.name + " = " + $1.name + " < " + $3.name + ";\n";}
 | E TK_DIF E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code = $$.name + " = " + $1.name + " != " + $3.name + ";\n";}
 | E TK_EQUAL E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code = $$.name + " = " + $1.name + " == " + $3.name + ";\n";}
 | E TK_GET E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code = $$.name + " = " + $1.name + " >= " + $3.name + ";\n";}
 | E TK_SET E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code = $$.name + " = " + $1.name + " <= " + $3.name + ";\n";}
 | '(' E ')'
   {$$.type = $2.type;
    $$.name = $2.name;
    $$.code = $2.code;}
 ;

VALUE: TK_INTVAL
       {$$.name = $1.name;
        $$.type = "numbuh";}
     | TK_DOUBLEVAL
       {$$.name = $1.name;
        $$.type = "floaty";}
     | TK_STRINGVAL
       {$$.name = $1.name;
        $$.type = "wordies";}
     | TK_CHARVAL
       {$$.name = $1.name;
        $$.type = "letter";}
     | TK_BOOLVAL
       {$$.name = $1.name;
        $$.type = "woof";}
     ;

%%

int lineNumber = 1;

#include "lex.yy.c"

int yyparse();

vector<map<string, string>> symbolTable;

void newScope() {
  map<string, string> newTable;
  symbolTable.push_back(newTable);
}

void exitScope() {
  symbolTable.pop_back();
}

void insertSymbolTable(string name, string type) {
  int currentScope = symbolTable.size()-1;

  if (symbolTable[currentScope].find(name) != symbolTable[currentScope].end()) {
    error("Variable " + name + " (" + type + ") has already been declared.");
  }

  symbolTable[currentScope][name] = type;
}

void verifyType(string variable, string type) {
  int currentScope = symbolTable.size()-1;

  if (symbolTable[currentScope].find(variable) == symbolTable[currentScope].end()) {
    error("Variable " + variable + " (" + type + ") has not been declared in this scope.");
  }

  if (symbolTable[currentScope][variable] != type) {
    error("Variable " + variable + " has type " + symbolTable[currentScope][variable] + ". Unable to attribute a " + type + " to it.");
  }
}

string attributeToVar(string variable, string value, string type) {
  string code = "";
  verifyType(variable, type);

  if (type == "wordies") {
    code += "strncpy(" + variable + ", " + value + ", 256);\n";
    code += variable + "[255] = \'\\0\'";
    return code;
  }
  return (variable + " = " + value);
}

string declareVariable(string name, string type) {
  string size = "";

  if (type == "wordies") {
    size = "[256]";
  }

  insertSymbolTable(name, type);

  return (name + size);
}

string getVarType(string name) {
  int currentScope = symbolTable.size()-1;

  if (symbolTable[currentScope].find(name) == symbolTable[currentScope].end()) {
    error("Variable " + name + " has not been declared in this scope.");
  }

  return symbolTable[currentScope][name];
}

string newTempVar(string type) {
  string temp = "temp_" + to_string(++curTempVar);

  if (type != "string") {
    tempVector.push_back(type + " " + temp);
  }
  else {
    tempVector.push_back("char " + temp + "[256]");
  }

  return (temp);
}

string dogeToC(string dogeType) {
  if (dogeType == "numbuh") return "int";
  else if (dogeType == "letter") return "char";
  else if (dogeType == "wordies") return "string";
  else if (dogeType == "floaty") return "double";
  else if (dogeType == "woof") return "int";
}

string checkResultType(string type1, string type2, string op) {
  if (op == "+" || op == "-" || op == "*" || op == "/") {
    if (type1 == "numbuh" && type2 == "numbuh") return "numbuh";
    if (type1 == "numbuh" && type2 == "floaty") return "floaty";
    if (type1 == "floaty" && type2 == "numbuh") return "floaty";
    if (type1 == "floaty" && type2 == "floaty") return "floaty";
  }
  if (op == "+") {
    if (type1 == "wordies" && type2 == "wordies") return "wordies";
  }
}

string generateOperatorCode(string var1, string var2, string destination, string op, string type) {
  string code = "";

  if (type != "wordies") {
    code += destination + " = " + var1 + " " + op + " " + var2;
  } 
  else {
    code += "strcpy(" + destination + ", " + var1 + ");\n";
    code += "strcat(" + destination + ", " + var2 + ");\n";
  }

  return code;  
}

void yyerror( const char* st )
{
  printf( "%s", st );
  printf( "Line: %d, \"%s\"\n", lineNumber, yytext );
}

void error(string message) {
  cerr << "Error: " << message << endl; 
  exit(1);
}

int main( int argc, char* argv[] )
{
  yyparse();
}
