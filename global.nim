type TokenKind* = enum
  TK_NUM
  TK_RESERVED
  TK_EOF
  TK_IDENT
  TK_RETURN
  TK_IF
  TK_ELSE
  TK_FOR
  TK_TYPE
  TK_DEF
  TK_DEFUN

type Token* = object
  kind*: TokenKind
  next*: ref Token
  val*: int
  str*: string
  len*: int
  pos*: int

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
  ND_DEF_FUN
  ND_CALL_FUN

type Node* = object
  kind*: NodeKind
  lhs*: ref Node
  rhs*: ref Node
  val*: int
  stmts*: array[0..100, ref Node]
  offset*: int
  fun_name*: string
  args*: array[0..10, ref Node]

type LVar* = object
  next*: ref LVar
  name*: string
  len*: int
  offset*: int

proc printf*(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>",
    varargs, discardable.}
var token* = Token.new
var local_variables*: array[0..100, ref LVar]
var local* = LVar.new
let p* = stdin.readLine
var code*: array[0..100, ref Node]
var now_reading* = 0
var now_reading_token* = 0
var fun_count* = 0
var jmp_count* = 0
var arg_register* = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]
