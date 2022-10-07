import global
import tokenize
import codegen
import sequtils
import strutils
import strformat

token = tokenize(input)
program()

printf(".intel_syntax noprefix\n");
printf(".globl main\n");
printf("main:\n");
printf("  push rbp\n");
printf("  mov rbp, rsp\n");
printf("  sub rsp, 208\n");
for i in 0..100:
  if code[i] == nil:
    break
  gen(code[i])
  printf("  pop rax\n");
printf("  mov rsp, rbp\n");
printf("  pop rbp\n");
printf("  ret\n")