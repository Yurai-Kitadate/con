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
  next : ref Token
  val  : int
  str  : string

var token = Token.new

proc consume(op : char) : bool = 
  if token == nil:
    return false
  if token.kind != TK_RESERVED or token.str[0] != op:
    return false
  token = token[].next
  return true

proc expect(op : char) = 
  if token[].kind != TK_RESERVED or token[].str[0] != op:
    raiseAssert("unexpected character")
  token = token.next

proc at_eof() : bool =
  return token[].kind == TK_EOF

proc expect_number() : int = 
  if token[].kind != TK_NUM:
    raiseAssert("not number!!")
  var val = token[].val
  token = token[].next
  return val
  

proc new_token(kind : TokenKind,cur : var ref Token,str : string) : ref Token = 
  var tok = Token.new
  tok[].kind = kind
  tok[].str = str
  cur[].next = tok
  return tok

proc isspace(c : char) : bool = 
  return c == ' '

proc strtol(p : string) : int = 
  var res = ""
  while now_reading < len(p) and '1' <= p[now_reading] and p[now_reading] <= '9':
    res &= p[now_reading]
    now_reading += 1
  return res.parseInt

proc tokenize(p : string) : ref Token = 
  var head = Token.new
  head[].next = nil
  var cur = head
  while now_reading < len(p):
    if isspace(p[now_reading]):
      now_reading += 1
      continue

    if p[now_reading] == '+' or p[now_reading] == '-' or  p[now_reading] == '*' or p[now_reading] == '/' or  p[now_reading] == '(' or p[now_reading] == ')':
      cur = new_token(TK_RESERVED,cur,$p[now_reading])
      now_reading += 1
      continue
    if isdigit(p[now_reading]):
      cur = new_token(TK_NUM,cur,$p[now_reading])
      cur[].val = strtol(p)
      continue
    raiseAssert("cannot tokenize")
  return head[].next


type NodeKind = enum
  ND_ADD
  ND_SUB
  ND_MUL
  ND_DIV
  ND_NUM

type Node = object
  kind : NodeKind
  lhs : ref Node
  rhs : ref Node
  val  : int

#prototype
proc mul(): ref Node
proc expr(): ref Node
proc primary(): ref Node

proc new_node(kind : NodeKind, lhs : ref Node, rhs : ref Node) : ref Node = 
  var node = Node.new
  node[].kind = kind
  node[].lhs = lhs
  node[].rhs = rhs
  return node
proc new_node_num(val : int) : ref Node = 
  var node = Node.new
  node[].kind = ND_NUM
  node[].val = val
  return node

proc mul(): ref Node = 
  var node = primary()
  while true:
    if consume('*'):
      node = new_node(ND_MUL,node,primary())
    elif consume('/'):
      node = new_node(ND_DIV,node,primary())
    else:
      return node
proc expr(): ref Node = 
  var node = mul()
  while true:
    if consume('+'):
      node = new_node(ND_ADD,node,mul())
    elif consume('-'):
      node = new_node(ND_SUB,node,mul())
    else:
      return node

proc primary(): ref Node =
  if consume('('):
    var node = expr()
    expect(')')
    return node
  return new_node_num(expect_number())


#condegen

proc gen(node : ref Node) = 
  if node[].kind == ND_NUM:
    printf("  push %d\n", node[].val)
    return
  gen(node[].lhs)
  gen(node[].rhs)
  printf("  pop rdi\n")
  printf("  pop rax\n")
  case node[].kind
  of ND_NUM:
    return
  of ND_ADD:
    printf("  add rax, rdi\n")
  of ND_SUB:
    printf("  sub rax, rdi\n")
  of ND_MUL:
    printf("  imul rax, rdi\n")
  of ND_DIV:
    printf("  cqo\n")
    printf("  idiv rdi\n")

  printf("  push rax\n")

# main

token = tokenize(input)
var node = expr()
printf(".intel_syntax noprefix\n")
printf(".globl main\n")
printf("main:\n")

gen(node)

printf("  pop rax\n")
printf("  ret\n")
        