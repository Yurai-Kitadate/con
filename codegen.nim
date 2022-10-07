import tokenize
import global
import sequtils
import strutils
import strformat

proc memcmp(str : string,op : string) : bool = 
  var res = true
  var i = 0
  for s in op:
    if s != str[i]:
      res = false
    i += 1
  return res

proc consume(op : string) : bool = 
  if token == nil or token[].kind != TK_RESERVED or len(op) != token[].len or (not memcmp(token[].str,op)):
    return false
  token = token[].next
  return true

proc expect(op : string) = 
  if token == nil or token[].kind != TK_RESERVED or len(op) != token[].len or (not memcmp(token[].str,op)):
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

type NodeKind = enum
  ND_ADD
  ND_SUB
  ND_MUL
  ND_DIV
  ND_NUM
  ND_EQ
  ND_NE
  ND_LT
  ND_LE

type Node = object
  kind : NodeKind
  lhs : ref Node
  rhs : ref Node
  val  : int

#prototype
proc mul(): ref Node
proc expr*(): ref Node
proc primary(): ref Node
proc unary() : ref Node
proc equality() : ref Node
proc relational() : ref Node
proc add() : ref Node
#

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

proc add(): ref Node = 
  var node = mul()
  while true:
    if consume("+"):
      node = new_node(ND_ADD,node,mul())
    elif consume("-"):
      node = new_node(ND_SUB,node,mul())
    else:
      return node
proc mul(): ref Node = 
  var node = unary()
  while true:
    if consume("*"):
      node = new_node(ND_MUL,node,unary())
    elif consume("/"):
      node = new_node(ND_DIV,node,unary())
    else:
      return node

proc expr(): ref Node = 
  return equality()
proc primary(): ref Node =
  if consume("("):
    var node = expr()
    expect(")")
    return node
  return new_node_num(expect_number())

proc equality(): ref Node = 
  var node = relational()

  while true:
    if consume("=="):
      node = new_node(ND_EQ, node, relational())
    elif consume("!="):
      node = new_node(ND_NE, node, relational())
    else:
      return node

proc relational(): ref Node = 
  var node = add()

  while true:
    if consume("<"):
      node = new_node(ND_LT, node, add())
    elif consume("<="):
      node = new_node(ND_LE, node, add())
    elif consume(">"):
      node = new_node(ND_LT, add(), node)
    elif consume(">="):
      node = new_node(ND_LE, add(), node)
    else:
      return node


proc unary(): ref Node =
  if consume("+"):
    return primary()
  if consume("-"):
    return new_node(ND_SUB,new_node_num(0),primary())
  return primary()
#condegen

proc gen*(node : ref Node) = 
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
  of ND_EQ:
    printf("  cmp rax, rdi\n")
    printf("  sete al\n")
    printf("  movzb rax, al\n")
  of ND_NE:
    printf("  cmp rax, rdi\n")
    printf("  setne al\n")
    printf("  movzb rax, al\n")
  of ND_LT:
    printf("  cmp rax, rdi\n")
    printf("  setl al\n")
    printf("  movzb rax, al\n")
  of ND_LE:
    printf("  cmp rax, rdi\n")
    printf("  setle al\n")
    printf("  movzb rax, al\n")
  printf("  push rax\n")
