import sequtils
import strutils
import strformat
proc printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}


let input = stdin.readLine
var now_reading = 0
var now_reading_token = 0
#Token
type TokenKind = enum
  TK_NUM
  TK_RESERVED
  TK_EOF

type Token = object
  kind : TokenKind
  val  : int
  str  : string

var token : seq[Token] = @[]

proc consume(op : char) : bool = 
  if token[now_reading_token].kind != TK_RESERVED or token[now_reading_token].str[0] != op:
    return false
  now_reading_token += 1
  return true

proc expect(op : char) = 
  if token[now_reading_token].kind != TK_RESERVED or token[now_reading_token].str[0] != op:
    raiseAssert("unexpected character")
  now_reading_token += 1

proc at_eof() : bool =
  return token[now_reading_token].kind == TK_EOF

proc expect_number() : int = 
  if token[now_reading_token].kind != TK_NUM:
    raiseAssert("not number!!")
  var val = token[now_reading_token].val
  now_reading_token += 1
  return val
  

proc new_token(kind : TokenKind,str : string) = 
  var tok = Token(kind : kind,str : str)
  token.add(tok)

proc isspace(c : char) : bool = 
  return c == ' '

proc strtol(p : string) : int = 
  var res = ""
  while now_reading < len(p) and '1' <= p[now_reading] and p[now_reading] <= '9':
    res &= p[now_reading]
    now_reading += 1
  return res.parseInt
proc tokenize(p : string) = 
  while now_reading < len(p):
    if isspace(p[now_reading]):
      now_reading += 1
      continue
    if p[now_reading] == '+' or p[now_reading] == '-':
      new_token(TK_RESERVED,$p[now_reading])
      now_reading += 1
      continue
    if isdigit(p[now_reading]):
      new_token(TK_NUM,$p[now_reading])
      token[len(token) - 1].val = strtol(p)
      continue
    raiseAssert("cannot tokenize")

#node

# type NodeKind = enum
#   ND_ADD
#   ND_SUB
#   ND_MUL
#   ND_DIV
#   ND_NUM

# type Node = object
#   kind : NodeKind
#   lhs : ref Node
#   rhs : ref Node
#   val  : int

# proc new_node(kind : NodeKind, lhs : ref Node, rhs : ref Node):
#   var node = Node(kind : ND_ADD,lhs : nil,rhs: nil,val: 0)
#   node.kind = kind
#   node.lhs = lhs
#   node.rhs = rhs
#   return node
#proc new_node_num(val : int) = 





# main
tokenize(input)
printf(".intel_syntax noprefix\n")
printf(".globl main\n")
printf("main:\n")
printf("  mov rax, %d\n",token[now_reading_token].val)
now_reading_token += 1
while now_reading_token < len(token):
  if consume('+'):
    printf("  add rax, %d\n", expect_number())
    continue
  expect('-')
  printf("  sub rax, %d\n", expect_number());
printf("  ret\n")
        