package bscript

import (
	"github.com/alecthomas/participle"
	"github.com/alecthomas/participle/lexer"
	"github.com/alecthomas/participle/lexer/ebnf"

	"strings"
)

type Program struct {
	Pos lexer.Position

	TopLevel []*TopLevel `( @@ )*`
}

type TopLevel struct {
	Pos lexer.Position

	Remark *Remark `(  @@ `
	Let    *Let    `| @@ ";"`
	Const  *Const  `| @@ ";"`
	Fun    *Fun    `| @@ )`
}

type Const struct {
	Pos lexer.Position

	Name  string      `"const" @Ident`
	Value *Expression `"=" @@`
}

type Fun struct {
	Pos lexer.Position

	Name     string     `"def" @Ident "("`
	Params   []string   `( @Ident ( "," @Ident )* )*`
	Commands []*Command `")" "{" ( @@ )* "}"`
}

type AnonFun struct {
	Pos lexer.Position

	Params        []string    `( "(" ( @Ident ( "," @Ident )* )* ")" "=" ">"`
	SingleParam   *string     `| @Ident "=" ">" )`
	Commands      []*Command  `( "{" ( @@ )* "}"`
	SingleCommand *Expression `| @@ )`
}

type Command struct {
	Pos lexer.Position

	Remark *Remark `(   @@ `
	Let    *Let    `  | @@ ";" `
	Del    *Del    `  | @@ ";" `
	Return *Return `  | @@ ";" `
	If     *If     `  | @@ `
	While  *While  `  | @@ `
	Fun    *Fun    `  | @@ `
	Call   *Call   `  | @@ ";" )`
}

type Del struct {
	Pos lexer.Position

	ArrayElement *ArrayElement `"del" @@`
}

type While struct {
	Pos lexer.Position

	Condition *Expression `"while" "(" @@ ")" "{"`
	Commands  []*Command  `( @@ )* "}"`
}

type If struct {
	Pos lexer.Position

	Condition    *Expression `"if" "(" @@ ")" "{"`
	Commands     []*Command  `( @@ )* "}"`
	ElseCommands []*Command  `( "else" "{" ( @@ )* "}" )?`
}

type Remark struct {
	Pos lexer.Position

	Comment string `@Comment`
}

type Call struct {
	Pos lexer.Position

	Name       string        `@Ident`
	CallParams []*CallParams `( @@ )+`
}

type CallParams struct {
	Pos lexer.Position

	Args []*Expression `"(" [ @@ { "," @@ } ] ")"`
}

type Let struct {
	Pos lexer.Position

	ArrayElement *ArrayElement `( @@ `
	Variable     *string       `| @Ident )`
	Value        *Expression   `":" "=" @@`
}

type Return struct {
	Pos lexer.Position

	Value *Expression `"return" @@`
}

type Operator string

func (o *Operator) Capture(s []string) error {
	*o = Operator(strings.Join(s, ""))
	return nil
}

type Value struct {
	Pos lexer.Position

	Array         *Array        ` @@`
	Map           *Map          `| @@`
	AnonFun       *AnonFun      `| @@`
	Null          *string       `| @"null"`
	Number        *SignedNumber `| @@`
	Boolean       *string       `| @("true" | "false")`
	Call          *Call         `| @@`
	ArrayElement  *ArrayElement `| @@`
	Variable      *Variable     `| @@`
	String        *string       `| @String`
	Subexpression *Expression   `| "(" @@ ")"`
}

type SignedNumber struct {
	Pos lexer.Position

	Sign   *string `@("+" | "-")?`
	Number float64 `@Number`
}

type Variable struct {
	Pos lexer.Position

	Variable string `@Ident`
}

type ArrayElement struct {
	Pos lexer.Position

	Variable *Variable     `@@`
	Indexes  []*ArrayIndex `( @@ )+`
}

type ArrayIndex struct {
	Pos   lexer.Position
	Index *Expression `"[" @@ "]"`
}

type Array struct {
	Pos lexer.Position

	LeftValue   *Expression   `"[" @@*`
	RightValues []*Expression `( "," @@ )* "]"`
}

type Map struct {
	Pos lexer.Position

	LeftNameValuePair   *NameValuePair   `"{" @@*`
	RightNameValuePairs []*NameValuePair `( "," @@ )* "}"`
}

type NameValuePair struct {
	Pos lexer.Position

	Name  string      `@String ":"`
	Value *Expression `@@`
}

type Factor struct {
	Pos lexer.Position

	Base     *Value `@@`
	Exponent *Value `[ "^" @@ ]`
}

type OpFactor struct {
	Pos lexer.Position

	Operator Operator `@("*" | "/" | "%")`
	Factor   *Factor  `@@`
}

type Term struct {
	Pos lexer.Position

	Left  *Factor     `@@`
	Right []*OpFactor `{ @@ }`
}

type OpTerm struct {
	Pos lexer.Position

	Operator Operator `@("+" | "-")`
	Term     *Term    `@@`
}

type Cmp struct {
	Pos lexer.Position

	Left  *Term     `@@`
	Right []*OpTerm `{ @@ }`
}

type OpCmp struct {
	Pos lexer.Position

	Operator Operator `@("=" | "<" "=" | ">" "=" | "<" | ">" | "!" "=")`
	Cmp      *Cmp     `@@`
}

type BoolTerm struct {
	Left  *Cmp     `@@`
	Right []*OpCmp `{ @@ }`
}

type OpBoolTerm struct {
	Pos lexer.Position

	Operator Operator  `@("&" "&" | "|" "|")`
	Right    *BoolTerm `@@`
}

type Expression struct {
	Pos lexer.Position

	BoolTerm   *BoolTerm     `@@`
	OpBoolTerm []*OpBoolTerm `{ @@ }`
}

var (
	benjiLexer = lexer.Must(ebnf.New(`
		Comment = "#" { "\u0000"…"\uffff"-"\n"-"\r" } .
		Ident = (alpha | "_") { "_" | alpha | digit } .
		String = "\"" { "\u0000"…"\uffff"-"\""-"\\" | "\\" any } "\"" .
		Number = ("." | digit) { "." | digit } .
		Punct = "!"…"/" | ":"…"@" | "["…` + "\"`\"" + ` | "{"…"~" .
		Whitespace = ( " " | "\t" | "\n" | "\r" ) { " " | "\t" | "\n" | "\r" } .

		alpha = "a"…"z" | "A"…"Z" .
		digit = "0"…"9" .
		any = "\u0000"…"\uffff" .
	`))

	Parser = participle.MustBuild(&Program{},
		participle.Lexer(benjiLexer),
		participle.CaseInsensitive("Ident"),
		participle.Unquote("String"),
		participle.UseLookahead(8),
		participle.Elide("Whitespace"),
	)

	CommandParser = participle.MustBuild(&Command{},
		participle.Lexer(benjiLexer),
		participle.CaseInsensitive("Ident"),
		participle.Unquote("String"),
		participle.UseLookahead(8),
		participle.Elide("Whitespace"),
	)
)
