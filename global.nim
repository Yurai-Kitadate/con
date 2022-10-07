type TokenKind* = enum
  TK_NUM
  TK_RESERVED
  TK_EOF
  TK_IDENT
  TK_RETURN
  TK_IF
  TK_ELSE
  TK_FOR
  TK_KAKKO

type Token* = object
  kind* : TokenKind
  next* : ref Token
  val*  : int
  str*  : string
  len*  : int

type NodeKind* = enum
  ND_ADD
  ND_SUB
  ND_MUL
  ND_DIV
  ND_NUM
  ND_EQ
  ND_NE
  ND_LT
  ND_LE
  ND_ASSIGN
  ND_LVAR
  ND_RETURN
  ND_IF
  ND_ELSE
  ND_FOR
  ND_BLOCK

type Node* = object
  kind* : NodeKind
  lhs* : ref Node
  rhs* : ref Node
  val*  : int
  stmts* :array[0..100, ref Node]
  offset* : int

type LVar* = object
  next* : ref LVar
  name* : string
  len* : int
  offset* : int

proc printf*(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}
var token* = Token.new
var local* = LVar.new
let input* = stdin.readLine
var code* :array[0..100, ref Node]
var now_reading* = 0
var now_reading_token* = 0
var if_jmp* = 0