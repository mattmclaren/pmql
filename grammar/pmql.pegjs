/**
* This ProcessMaker Query Language Grammar is based off of a subset 
* of SQL. Column names and values are validated by a callback passed in through 
* the options variable or is passed-thru. A laravel eloquent query object is 
* also passed through as the starting point.
* The query language only provides the where clause of a SQL statement.
* The ordering and limiting is meant to be handled by the PMQL caller.
*
* Things not supported:
*  * Explicit joins
*  * Select of specific columns
*  * Order by and limit clauses
*
*/

{
  // Any code that needs to be added to the language parser can go here

}

start  = fullExpression

fullExpression = le:logicExpression ler:logicExpressionRest* { 
  $collection = new \ProcessMaker\Query\ExpressionCollection();
  // Add to our collection
  if($le) {
    $collection[] = $le;
  }
  foreach($ler as $expression) {
    // Add each expression into our collection
    $collection[] = $expression;
  }
  return $collection;
}

//logicExpression = _ lparen _ le:logicExpression ler:logicExpressionRest* _ rparen _ {
logicExpression = _ lparen _ fe:fullExpression _ rparen _ {
  return $fe;
}
/
field:field _ op:binary_operator _ value:value _ {
  // Return a new expression instance
  return new \ProcessMaker\Query\Expression($field, $op['value'], $value);
}

logicExpressionRest = go:group_operator _ le:logicExpression {
  $le->setLogical($go['value']);
  return $le;
}

field =
  v: ( whitespace ( 
    (
      "CAST"i lparen field:field _ "AS"i _ type:name rparen { return new \ProcessMaker\Query\Cast($field, $type); }
    )
    /
    (
      name:name lparen param:(field) rparen { return new \ProcessMaker\Query\FunctionCall($name, $param); }
    )
    /
    nested_field
    /
    column_name
  ) ) { return $v[1]; }

/**
* Currently what values we support. Right now we only support literals
*/
value =
  v: ( whitespace ( 
    ( 
      x: literal_value { return new \ProcessMaker\Query\LiteralValue($x) ; } 
    )
  ) ) { return $v[1]; }

nested_field = dn:(name dot nested_element) { return new \ProcessMaker\Query\JsonField(\ProcessMaker\Query\Processor::flatstr($dn, true)); }

nested_element =  el:((json_array_element / name) (dot nested_element)*) { return \ProcessMaker\Query\Processor::flatstr($el, true); }

json_array_element = ae:(name lbrack digit+ rbrack) { return \ProcessMaker\Query\Processor::flatstr($ae); }

literal_value =
  ( number / string_literal )

/**
* Number related rules
* Blatently taken from the number rule at https://github.com/pegjs/pegjs/blob/master/examples/json.pegjs
*/
number = str:(minus? int frac? exp?) { 
  return floatval(\ProcessMaker\Query\Processor::flatstr(
      \ProcessMaker\Query\Processor::flatten($str, true), true
  )); 
}
int = zero / (digit1_9 digit *)
frac = dot digit+
exp = E (minus / plus)? digit+
zero = '0'

/** Helper definitions **/
dot = '.'
comma = ','
minus = '-'
plus = '+'
lparen = '('
rparen = ')'
lbrack = '['
rbrack = ']'
star = '*'
newline = '\n'
string_literal = str:('"' (escape_char / [^"])* '"') { return \ProcessMaker\Query\Processor::flatstr($str[1]); }
escape_char = '\\' .
nil = ''

whitespace =
  [ \t\n\r]*
whitespace1 =
  [ \t\n\r]+
_ = whitespace


unary_operator =
  x: ( whitespace
       ( '-' / '+' / '~' / 'NOT'i) )
  { return $x[1]; }

group_operator =
  x: ( 'AND'i / 'OR'i) { return ['type' => 'operator', 'value' => strtoupper($x) ]; }

binary_operator =
  x: ( whitespace
        ( '<=' / '>='
        / '<' / '>'
        / '=' / '==' / '!=' / '<>'
        / LIKE
      ) )
  { return ['type' => 'operator', 'value' => strtoupper($x[1]) ]; }

digit = [0-9]
digit1_9 = [1-9]
decimal_point = dot
equal = '='


name =
  str:[A-Za-z0-9_]+
  { return implode('', $str); }

column_name = cn:name { return new \ProcessMaker\Query\ColumnField($cn); }
function_name = name


CURRENT_TIME = 'now'
CURRENT_DATE = 'now'
CURRENT_TIMESTAMP = 'now'

end_of_input = ''

/** Keyword definitions */
AND = whitespace1 "AND"i
AS = whitespace1 "AS"i
BETWEEN = whitespace1 "BETWEEN"i
CAST = whitespace1 "CAST"i
DISTINCT = whitespace1 "DISTINCT"i
E = "E"i
ESCAPE = whitespace1 "ESCAPE"i
GLOB = whitespace1 "GLOB"i
IS = whitespace1 "IS"i
ISNULL = whitespace1 "ISNULL"i
LIKE = whitespace1 "LIKE"i
MATCH = whitespace1 "MATCH"i
NOT = whitespace1 "NOT"i
NOTNULL = whitespace1 "NOTNULL"i
NULL = whitespace1 "NULL"i
OR = whitespace1 "OR"i
REGEXP = whitespace1 "REGEXP"i