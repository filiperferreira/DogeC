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
int curLabel = 0;

int yylex();
void error(string);
void yyerror(const char* st);

vector<string> tempVector;
vector<string> temPVector;
string tempVar;
string tempSwitchVar;

struct Attributes {
  string code;
  string name;
  string type;

  int size;
  int dimension;

  Attributes() {}

  Attributes(string n) {
    name = n;
  }
};

struct Type {
  string baseType;
  int dimension;
  int size[2];

  Type() {}

  Type(string type) {
    baseType = type;
    dimension = 0;
  }

  Type(string type, int size1) {
    baseType = type;
    dimension = 1;
    size[0] = size1;
  }

  Type(string type, int size1, int size2) {
    baseType = type;
    dimension = 2;
    size[0] = size1;
    size[1] = size2;
  }
};

struct Func {
  string name;
  string type;
  int parameters;
  vector<string> types;

  Func() {}

  Func(string n, string t, int q, vector<string> list) {
    name = n;
    type = t;
    parameters = q;
    for (int i = 0; i < q; i++) {
      types.push_back(list[i]);
    }
  }
};

void newScope();
void exitScope();
void insertSymbolTable(string, Type);
void insertFunctionTable(string, Func);
void verifyType(string, string, string);
void verifyDimension(string, int);
void declareFunction(string, string, vector<string>);

string attributeToVar(string, string, string, string);
string declareVariable(string, string, int, int, int);
string newTempVar(string);
string dogeToC(string);
string checkResultType(string, string, string);
string generateOperatorCode(string, string, string, string, string);
string newLabel();

Type getVarType(string);

Type temp;

string includeHead = 
"#include <iostream>\n"
"#include <stdio.h>\n"
"#include <stdlib.h>\n"
"#include <string.h>\n"
"\n"
"using namespace std;\n";

#define YYSTYPE Attributes

%}

%token TK_MAIN TK_ATTRIB TK_OUT TK_IN TK_RETURN
%token TK_INT TK_CHAR TK_BOOL TK_DOUBLE TK_STRING TK_ID
%token TK_INTVAL TK_DOUBLEVAL TK_STRINGVAL TK_CHARVAL TK_BOOLVAL
%token TK_IF TK_ELSE TK_FOR TK_WHILE TK_DO TK_CASE TK_SWITCH TK_DEFAULT

%left TK_OR
%left TK_AND
%nonassoc TK_GT TK_ST TK_DIF TK_EQUAL TK_GET TK_SET
%left TK_SUM TK_SUB
%left TK_MUL TK_DIV
%nonassoc TK_NEG

%%

S: PROT_FUNCS {newScope();} VARS MAIN {exitScope();}
   {cout << includeHead << endl;
    cout << $1.code;
    cout << $3.code << endl;
    cout << $4.code << endl;}
 ;

PROT_FUNCS: VAR_TYPE TK_ID '(' PARAMS ')' ';' PROT_FUNCS
            {declareFunction($2.name, $1.name, temPVector);
             $$.code = $1.code + $2.name + "(" + $4.code + ");\n" + $7.code;}
          |
            {$$.code = "";}
          ;

PARAMS: FUNC_VAR_TYPE ',' PARAMS
        {$$.code = $1.code + ", " + $3.code;
         temPVector.push_back($1.name);}
      | FUNC_VAR_TYPE
        {temPVector.clear();
         temPVector.push_back($1.name);
         $$.code = $1.code;}
      ;

FUNC_VAR_TYPE: TK_INT
               {$$.code = "int";
                $$.name = $1.name;}
             | TK_CHAR
               {$$.code = "char";
                $$.name = $1.name;}
             | TK_BOOL
               {$$.code = "int";
                $$.name = $1.name;}
             | TK_DOUBLE
               {$$.code = "double";
                $$.name = $1.name;}
             | TK_STRING
               {$$.code = "char[]";
                $$.name = $1.name;}
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
     {$$.code = declareVariable($1.name, lastType, 0, 0, 0) + ", " + $3.code;}
   | TK_ID '[' TK_INTVAL ']' ',' IDS
     {$$.code = declareVariable($1.name, lastType, 1, stoi($3.name), 0) + ", " + $6.code;}
   | TK_ID '[' TK_INTVAL ']' '[' TK_INTVAL ']' ',' IDS
     {$$.code = declareVariable($1.name, lastType, 2, stoi($3.name), stoi($6.name)) + ", " + $9.code;}
   | TK_ID ';'
     {$$.code = declareVariable($1.name, lastType, 0, 0, 0) + ";\n";}
   | TK_ID '[' TK_INTVAL ']' ';'
     {$$.code = declareVariable($1.name, lastType, 1, stoi($3.name), 0) + ";\n";}
   | TK_ID '[' TK_INTVAL ']' '[' TK_INTVAL ']' ';'
     {$$.code = declareVariable($1.name, lastType, 2, stoi($3.name), stoi($6.name)) + ";\n";}
   ;

ID_TOKEN: TK_ID
          {$$.name = $1.name;
           $$.type = getVarType("_" + $1.name).baseType;
           $$.code = "";}
        | TK_ID '[' E ']'
          {$$.code = $3.code;
           $$.type = getVarType("_" + $1.name).baseType;
           $$.name = $1.name + "[" + $3.name + "]";}
        | TK_ID '[' E ']' '[' E ']'
          {$$.code = $3.code + $6.code;
           $$.type = getVarType("_" + $1.name).baseType;
           tempVar = newTempVar(dogeToC($3.type));
           $$.code += tempVar + " = " + $3.name + " * " + to_string(getVarType("_" + $1.name).size[1]) + ";\n";
           $$.code += tempVar + " = " + tempVar + " + " + $6.name + ";\n";
           $$.name = $1.name + "[" + tempVar + "]";}
        ;

PROG: OPERATION ';' PROG
      {$$.code = $1.code + $3.code;}
    | CONTROL PROG
      {$$.code = $1.code + $2.code;}
    |
      {$$.code = "";}
    ;

OPERATION: ID_TOKEN TK_ATTRIB E
           {$$.code = $1.code + $3.code;
            $$.code += attributeToVar($1.name, $1.type, $3.name, $3.type) + ";\n";}
         | TK_OUT '(' E ')'
           {$$.code += $3.code;
            $$.name = newTempVar(dogeToC($3.type));
            if ($3.type == "wordies") {
              $$.code += "strncpy(" + $$.name + ", " + $3.name + ", 256);\n";
            }
            else {
              $$.code += $$.name + " = " + $3.name + ";\n";
            }
            $$.code += "cout << " + $$.name + ";\n";
            $$.code += "cout << \"\\n\";\n";}
         | TK_IN '(' E ')'
           {if ($3.type == "wordies") {
              $$.code = "fgets(" + $3.name + ", 256, stdin);\n";
            }
            else {
              $$.code = "cin >> " + $3.name + ";\n";
            }
           }
         |
           {$$.code = "";}
         ;

E: VALUE
   {$$.name = $1.name;
    $$.type = $1.type;}
 | ID_TOKEN
   {$$.code = $1.code;
    $$.name = "_" + $1.name;
    $$.type = $1.type;}
 | E TK_SUM E
   {$$.type = checkResultType($1.type, $3.type, "+");
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "+", $$.type);}
 | E TK_SUB E
   {$$.type = checkResultType($1.type, $3.type, "-");
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "-", $$.type);}
 | E TK_MUL E
   {$$.type = checkResultType($1.type, $3.type, "*");
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "*", $$.type);}
 | E TK_DIV E
   {$$.type = checkResultType($1.type, $3.type, "/");
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "/", $$.type);}
 | E TK_AND E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "&&", $$.type);}
 | E TK_OR E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "||", $$.type);}
 | E TK_GT E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, ">", $$.type);}
 | E TK_ST E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "<", $$.type);}
 | E TK_DIF E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "!=", $$.type);}
 | E TK_EQUAL E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "==", $$.type);}
 | E TK_GET E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, ">=", $$.type);}
 | E TK_SET E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $1.code + $3.code;
    $$.code += generateOperatorCode($1.name, $3.name, $$.name, "<=", $$.type);}
 | TK_NEG E
   {$$.type = "woof";
    $$.name = newTempVar(dogeToC($$.type));
    $$.code = $2.code;
    $$.code = $$.name + " = !" + $2.name + ";\n";}
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

CONTROL : TK_IF '(' E ')' '{' PROG '}' ELSE
          {$$.name = newLabel();
           $$.code = $3.code;
           $$.code += "if(" + $3.name + ") goto " + $$.name + ";\n";
           $$.code += $8.code;
           $$.code += "goto " + $$.name + "_END;\n";
           $$.code += $$.name + ":;\n";
           $$.code += $6.code;
           $$.code += $$.name + "_END:;\n";}
        | TK_FOR '(' OPERATION ';' E ';' OPERATION ')' '{' PROG '}'
          {$$.name = newLabel();
           $$.code = $3.code;
           $$.code += $5.code;
           $$.code += "if (" + $5.name + ") goto " + $$.name + "_BEGIN;\n";
           $$.code += "goto " + $$.name + "_END;\n";
           $$.code += $$.name + "_BEGIN:;\n";
           $$.code += $10.code;
           $$.code += $7.code;
           $$.code += $5.code;
           $$.code += "if (" + $5.name + ") goto " + $$.name + "_BEGIN;\n";
           $$.code += $$.name + "_END:;\n";}
        | TK_WHILE '(' E ')' '{' PROG '}'
          {$$.name = newLabel();
           $$.code = $3.code;
           $$.code += "if (" + $3.name + ") goto " + $$.name + "_BEGIN;\n";
           $$.code += "goto " + $$.name + "_END;\n";
           $$.code += $$.name + "_BEGIN:;\n";
           $$.code += $6.code;
           $$.code += $3.code;
           $$.code += "if (" + $3.name + ") goto " + $$.name + "_BEGIN;\n";
           $$.code += $$.name + "_END:;\n";}
        | TK_DO '{' PROG '}' TK_WHILE '(' E ')'
          {$$.name = newLabel();
           $$.code = $$.name + "_BEGIN:;\n";
           $$.code += $3.code;
           $$.code += $7.code;
           $$.code += "if (" + $7.name + ") goto " + $$.name + "_BEGIN;\n";}
        | TK_SWITCH '(' E ')' '{' CASES '}'
          {$$.code = $3.code;
           $$.code += tempSwitchVar + " = " + $3.name + ";\n";
           $$.code += $6.code;}
        ;

CASES: TK_CASE VALUE ':' PROG CASES
       {$$.name = newTempVar(dogeToC("woof"));
        $3.name = newLabel();
        $$.code = $$.name + " = " + tempSwitchVar + " != " + $2.name + ";\n";
        $$.code += "if (" + $$.name + ") goto " + $3.name + ";\n";
        $$.code += $4.code;
        $$.code += "goto " + $5.name + "_END;\n";
        $$.code += $3.name + ":;\n";
        $$.code += $5.code;
        $$.name = $5.name;}
     | TK_DEFAULT ':' PROG
       {tempSwitchVar = newTempVar(dogeToC("woof"));
        $$.name = newLabel();
        $$.code = $3.code;
        $$.code += $$.name + "_END:;\n";}
     |
       {$$.code = "";}
     ;

ELSE: TK_ELSE '{' PROG '}'
      {$$.code = $3.code;}
    | TK_ELSE TK_IF '(' E ')' '{' PROG '}' ELSE
      {$$.name = newLabel();
       $$.code = $4.code;
       $$.code += "if(" + $4.name + ") goto " + $$.name + ";\n";
       $$.code += $9.code;
       $$.code += "goto " + $$.name + "_END;\n";
       $$.code += $$.name + ":;\n";
       $$.code += $7.code;
       $$.code += $$.name + "_END:;\n";}
    |
      {$$.code = "";}
    ;

%%

int lineNumber = 1;

#include "lex.yy.c"

int yyparse();

vector<map<string, Type>> symbolTable;
map<string, Func> functionTable;

void newScope() {
  map<string, Type> newTable;
  symbolTable.push_back(newTable);
}

void exitScope() {
  symbolTable.pop_back();
}

void insertSymbolTable(string name, Type type) {
  int currentScope = symbolTable.size()-1;

  if (symbolTable[0].find(name) != symbolTable[0].end() || symbolTable[currentScope].find(name) != symbolTable[currentScope].end()) {
    error("Variable " + name + " has already been declared.");
  }

  symbolTable[currentScope][name] = type;
}

void verifyType(string variable, string variableType, string type) {
  if (variableType == "numbuh") {
    if (type != "numbuh" && type != "letter" && type != "woof") {
      error("Variable " + variable + " has type " + variableType + ". Unable to attribute a " + type + " to it.");
    }
  }
  else if (variableType == "floaty") {
    if (type != "numbuh" && type != "floaty" && type != "woof") {
      error("Variable " + variable + " has type " + variableType + ". Unable to attribute a " + type + " to it.");
    }
  }
  else if (variableType == "letter") {
    if (type != "numbuh" && type != "woof" && type != "letter") {
      error("Variable " + variable + " has type " + variableType + ". Unable to attribute a " + type + " to it.");
    }
  }
  else if (variableType == "wordies") {
    if (type != "wordies") {
      error("Variable " + variable + " has type " + variableType + ". Unable to attribute a " + type + " to it.");
    }
  }
  else if (variableType == "woof") {
    if (type != "numbuh" && type != "letter" && type != "floaty" && type != "woof") {
      error("Variable " + variable + " has type " + variableType + ". Unable to attribute a " + type + " to it.");
    }
  }
}

void verifyDimension(string variable, int dimension) {
  Type varType = getVarType(variable);

  if (varType.dimension != dimension) {
    error("Variable " + variable + " has dimension " + to_string(varType.dimension) + " not " + to_string(dimension) + ".");
  }
}

string attributeToVar(string variable, string variableType, string value, string type) {
  string code = "";
  variable = "_" + variable;
  verifyType(variable, variableType, type);

  if (type == "wordies") {
    code += "strncpy(" + variable + ", " + value + ", 256)";
    return code;
  }
  return (variable + " = " + value);
}

string declareVariable(string name, string type, int dimension, int size1, int size2) {
  int size;
  name = "_" + name;

  if (dimension == 0) {
    Type newType(type);
    if (type == "wordies") {
      size = 256;
      insertSymbolTable(name, newType);
      return (name + "[" + to_string(size) + "]");
    }
    insertSymbolTable(name, newType);
  }
  else if (dimension == 1) {
    Type newType(type, size1);
    size = size1;
    if (type == "wordies") {
      size *= 256;
    }
    insertSymbolTable(name, newType);
    return (name + "[" + to_string(size) + "]");
  }
  else if (dimension == 2) {
    Type newType(type, size1, size2);
    size = size1 * size2;
    if (type == "wordies") {
      size *= 256;
    }
    insertSymbolTable(name, newType);
    return (name + "[" + to_string(size) + "]");
  }

  return (name);
}

void declareFunction(string name, string type, vector<string> params) {
  Func temp(name, type, params.size(), params);

  insertFunctionTable(name, temp);
}

void insertFunctionTable(string name, Func type) {
  if (functionTable.find(name) != functionTable.end()) {
    error("Function " + name + " has already been declared.");
  }

  functionTable[name] = type;
}

Type getVarType(string name) {
  int currentScope = symbolTable.size()-1;

  if (symbolTable[0].find(name) != symbolTable[0].end()) {
    return symbolTable[0][name];
  }
  else if (symbolTable[currentScope].find(name) != symbolTable[currentScope].end()) {
    return symbolTable[currentScope][name];
  }
  else {
    error("Variable " + name + " has not been declared in this scope.");
  }
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

string newLabel() {
  string temp = "LABEL_" + to_string(++curLabel);

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
    if (type1 == "numbuh" && type2 == "wordies") return "wordies";
    if (type1 == "wordies" && type2 == "numbuh") return "wordies";
  }
}

string generateOperatorCode(string var1, string var2, string destination, string op, string type) {
  string code = "";

  if (type != "wordies") {
    code += destination + " = " + var1 + " " + op + " " + var2 + ";\n";
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
