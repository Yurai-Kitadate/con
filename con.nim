import sequtils
import strutils
import strformat
#printf for c
proc printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}
proc strtol(c : string,now_reading : var int) : string = 
    var res = ""
    while now_reading < len(c) and '0' <= c[now_reading] and c[now_reading] <= '9':
        res &= c[now_reading]
        now_reading += 1
    return res
let input = stdin.readLine
var now_reading = 0
printf(".intel_syntax noprefix\n")
printf(".globl main\n")
printf("main:\n")
printf("  mov rax, %s\n",strtol(input,now_reading))

while now_reading < len(input):
    if input[now_reading] == '+':
        now_reading += 1
        printf("  add rax, %s\n", strtol(input,now_reading))
        continue
    if input[now_reading] == '-':
        now_reading += 1
        printf("  sub rax, %s\n", strtol(input,now_reading))
        continue
printf("  ret\n")
        