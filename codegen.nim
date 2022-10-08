import global

#condegen
proc gen_lval(node: ref Node) =
  if node[].kind != ND_LVAR:
    raiseAssert("left is not variable")
  printf("  mov rax, rbp\n")
  printf("  sub rax, %d\n", node[].offset)
  printf("  push rax\n")

proc gen*(node: ref Node) =
  if node == nil:
    return
  jmp_count += 1
  var jmp_id = jmp_count
  var arg_count = 0
  if node[].kind == ND_CALL_FUN:
    var i = 0
    while node[].stmts[i] != nil:
      gen(node[].stmts[i])
      arg_count += 1
      i += 1
    i = arg_count - 1
    while i >= 0:
      printf("  pop %s\n", arg_register[i])
      i -= 1
    printf("  mov rax, rsp\n")
    printf("  and rax, 15\n")
    printf("  jnz .L.call.%d\n", jmp_id)
    printf("  mov rax, 0\n")
    printf("  call %s\n", node[].fun_name)
    printf("  jmp .L.end.%d\n", jmp_id)
    printf(".L.call.%d:\n", jmp_id);
    printf("  sub rsp, 8\n");
    printf("  mov rax, 0\n")
    printf("  call %s\n", node[].fun_name)
    printf("  add rsp, 8\n")
    printf(".L.end.%d:\n", jmp_id)
    printf("  push rax\n")
    return
  if node[].kind == ND_DEF_FUN:
    printf("%s:\n", node[].fun_name)
    printf("  push rbp\n")
    printf("  mov rbp, rsp\n")
    var i = 0
    while node[].args[i] != nil:
      printf("  push %s\n", arg_register[i])
      arg_count += 1
      i += 1
    if local_variables[fun_count] != nil:
      var offset = local_variables[fun_count].offset
      offset -= arg_count * 8
      printf("  sub rsp, %d\n", offset)

    gen(node[].lhs)
    printf("  mov rax, 0\n")
    printf("  mov rsp, rbp\n")
    printf("  pop rbp\n")
    printf("  ret\n")
    return
  if node[].kind == ND_BLOCK:
    var i = 0
    while node[].stmts[i] != nil:
      gen(node[].stmts[i])
      i += 1
    return
  if node[].kind == ND_FOR:
    if node[].lhs.lhs != nil:
      gen(node[].lhs.lhs)
    printf(".Lbegin%d:\n", jmp_id)
    if node[].lhs.rhs != nil:
      gen(node[].lhs.rhs)
    printf("  pop rax\n")
    printf("  cmp rax, 0\n")
    printf("  je  .Lend%d\n", jmp_id)
    gen(node[].rhs.rhs)
    if node[].rhs.lhs != nil:
      gen(node[].rhs.lhs)
    printf("  jmp .Lbegin%d\n", jmp_id)
    printf(".Lend%d:\n", jmp_id)
    return
  if node[].kind == ND_IF:
    gen(node[].lhs)
    printf("  pop rax\n")
    printf("  cmp rax, 0\n")
    if node[].rhs.kind == ND_ELSE:
      printf("  je .Lelse%d\n", jmp_id)
      gen(node[].rhs[].lhs)
      printf("  jmp .Lend%d\n", jmp_id)
      printf(".Lelse%d:\n", jmp_id)
      gen(node[].rhs[].rhs)
      printf(".Lend%d:\n", jmp_id)
      return
    else:
      printf("  je .Lend%d\n", jmp_id)
      gen(node[].rhs)
      printf(".Lend%d:\n", jmp_id)
      return
  if node[].kind == ND_RETURN:
    gen(node[].lhs)
    printf("  pop rax\n")
    printf("  mov rsp, rbp\n")
    printf("  pop rbp\n")
    printf("  ret\n")
    return
  if node[].kind == ND_NUM:
    printf("  push %d\n", node[].val)
    return
  if node[].kind == ND_LVAR:
    gen_lval(node)
    printf("  pop rax\n")
    printf("  mov rax, [rax]\n")
    printf("  push rax\n")
    return
  if node[].kind == ND_ASSIGN:
    gen_lval(node[].lhs)
    gen(node[].rhs)
    printf("  pop rdi\n")
    printf("  pop rax\n")
    printf("  mov [rax], rdi\n")
    printf("  push rdi\n")
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
  of ND_LVAR:
    return
  of ND_ASSIGN:
    return
  of ND_RETURN:
    return
  of ND_IF:
    return
  of ND_ELSE:
    return
  of ND_FOR:
    return
  of ND_BLOCK:
    return
  of ND_DEF_FUN:
    return
  of ND_CALL_FUN:
    return
  printf("  push rax\n")
