
;           Copyright Oliver Kowalke 2009.
;  Distributed under the Boost Software License, Version 1.0.
;     (See accompanying file LICENSE_1_0.txt or copy at
;           http://www.boost.org/LICENSE_1_0.txt)

;  ----------------------------------------------------------------------------------
;  |    0    |    1    |    2    |    3    |    4     |    5    |    6    |    7    |
;  ----------------------------------------------------------------------------------
;  |   0x0   |   0x4   |   0x8   |   0xc   |   0x10   |   0x14  |   0x18  |   0x1c  |
;  ----------------------------------------------------------------------------------
;  |        R12        |         R13       |         R14        |        R15        |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    8    |    9    |   10    |   11    |    12    |    13   |    14   |    15   |
;  ----------------------------------------------------------------------------------
;  |   0x20  |   0x24  |   0x28  |  0x2c   |   0x30   |   0x34  |   0x38  |   0x3c  |
;  ----------------------------------------------------------------------------------
;  |        RDI        |        RSI        |         RBX        |        RBP        |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    16   |    17   |    18   |    19   |                                        |
;  ----------------------------------------------------------------------------------
;  |   0x40  |   0x44  |   0x48  |   0x4c  |                                        |
;  ----------------------------------------------------------------------------------
;  |        RSP        |       RIP         |                                        |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    20   |    21   |    22   |    23   |                                        |
;  ----------------------------------------------------------------------------------
;  |   0x50  |   0x54  |   0x58  |   0x5c  |                                        |
;  ----------------------------------------------------------------------------------
;  |       sbase       |       slimit      |                                        |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    24   |    25   |                                                            |
;  ----------------------------------------------------------------------------------
;  |   0x60  |   0x64  |                                                            |
;  ----------------------------------------------------------------------------------
;  |       fc_link     |                                                            |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    26   |    27   |                                                            |
;  ----------------------------------------------------------------------------------
;  |   0x68  |   0x6c  |                                                            |
;  ----------------------------------------------------------------------------------
;  |      fbr_strg     |                                                            |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    28   |    29   |    30   |    31   |                                        |
;  ----------------------------------------------------------------------------------
;  |   0x70  |   0x74  |   0x78  |   0x7c  |                                        |
;  ----------------------------------------------------------------------------------
;  | fc_mxcsr|fc_x87_cw|       fc_xmm      |                                        |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    32    |   33   |   34    |   35    |   36     |   37    |   38    |   39    |
;  ----------------------------------------------------------------------------------
;  |   0x80   |  0x84  |  0x88   |  0x8c   |   0x90   |   0x94  |   0x98  |   0x9c  |
;  ----------------------------------------------------------------------------------
;  |                  XMM6                 |                   XMM7                 |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    40    |   41   |   42    |   43    |    44    |   45    |   46    |   47    |
;  ----------------------------------------------------------------------------------
;  |  0x100   | 0x104  |  0x108  |  0x10c  |   0x110  |  0x114  |  0x118  |  0x11c  |
;  ----------------------------------------------------------------------------------
;  |                  XMM8                 |                   XMM9                 |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    48    |   49   |   50    |   51    |    52    |   53    |   54    |   55    |
;  ----------------------------------------------------------------------------------
;  |  0x120   | 0x124  |  0x128  |  0x12c  |   0x130  |  0x134  |  0x138  |  0x13c  |
;  ----------------------------------------------------------------------------------
;  |                 XMM10                 |                  XMM11                 |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    56    |   57   |   58    |   59    |    60    |   61    |   62    |   63    |
;  ----------------------------------------------------------------------------------
;  |  0x140   | 0x144  |  0x148  |  0x14c  |   0x150  |  0x154  |  0x158  |  0x15c  |
;  ----------------------------------------------------------------------------------
;  |                 XMM12                 |                  XMM13                 |
;  ----------------------------------------------------------------------------------
;  ----------------------------------------------------------------------------------
;  |    64    |   65   |   66    |   67    |    68    |   69    |   70    |   71    |
;  ----------------------------------------------------------------------------------
;  |  0x160   | 0x164  |  0x168  |  0x16c  |   0x170  |  0x174  |  0x178  |  0x17c  |
;  ----------------------------------------------------------------------------------
;  |                 XMM14                 |                  XMM15                 |
;  ----------------------------------------------------------------------------------

EXTERN  _exit:PROC            ; standard C library function
EXTERN  align_stack:PROC      ; stack alignment
EXTERN  seh_fcontext:PROC     ; exception handler
EXTERN  start_fcontext:PROC   ; start fcontext
.code

jump_fcontext PROC EXPORT FRAME:seh_fcontext
    .endprolog

    mov     [rcx],       r12        ; save R12
    mov     [rcx+08h],   r13        ; save R13
    mov     [rcx+010h],  r14        ; save R14
    mov     [rcx+018h],  r15        ; save R15
    mov     [rcx+020h],  rdi        ; save RDI
    mov     [rcx+028h],  rsi        ; save RSI
    mov     [rcx+030h],  rbx        ; save RBX
    mov     [rcx+038h],  rbp        ; save RBP

    mov     r10,         gs:[030h]  ; load NT_TIB
    mov     rax,         [r10+08h]  ; load current stack base
    mov     [rcx+050h],  rax        ; save current stack base
    mov     rax,         [r10+010h] ; load current stack limit
    mov     [rcx+058h],  rax        ; save current stack limit
    mov     rax,         [r10+018h] ; load fiber local storage
    mov     [rcx+068h],  rax        ; save fiber local storage

    stmxcsr [rcx+070h]              ; save MMX control and status word
    fnstcw  [rcx+074h]              ; save x87 control word
    movaps  [rcx+080h],  xmm6
    movaps  [rcx+090h],  xmm7
    movaps  [rcx+0100h], xmm8
    movaps  [rcx+0110h], xmm9
    movaps  [rcx+0120h], xmm10
    movaps  [rcx+0130h], xmm11
    movaps  [rcx+0140h], xmm12
    movaps  [rcx+0150h], xmm13
    movaps  [rcx+0160h], xmm14
    movaps  [rcx+0170h], xmm15

    lea     rax,         [rsp+08h]  ; exclude the return address
    mov     [rcx+040h],  rax        ; save as stack pointer
    mov     rax,         [rsp]      ; load return address
    mov     [rcx+048h],  rax        ; save return address

    mov     r12,        [rdx]       ; restore R12
    mov     r13,        [rdx+08h]   ; restore R13
    mov     r14,        [rdx+010h]  ; restore R14
    mov     r15,        [rdx+018h]  ; restore R15
    mov     rdi,        [rdx+020h]  ; restore RDI
    mov     rsi,        [rdx+028h]  ; restore RSI
    mov     rbx,        [rdx+030h]  ; restore RBX
    mov     rbp,        [rdx+038h]  ; restore RBP

    mov     r10,        gs:[030h]   ; load NT_TIB
    mov     rax,        [rdx+050h]  ; load stack base
    mov     [r10+08h],  rax         ; restore stack base
    mov     rax,        [rdx+058h]  ; load stack limit
    mov     [r10+010h], rax         ; restore stack limit
    mov     rax,        [rdx+068h]  ; load fiber local storage
    mov     [r10+018h], rax         ; restore fiber local storage

    ldmxcsr [rdx+070h]              ; restore MMX control and status word
    fldcw   [rdx+074h]              ; restore x87 control word
    movaps  xmm6,  [rdx+080h]
    movaps  xmm7,  [rdx+090h]
    movaps  xmm8,  [rdx+0100h]
    movaps  xmm9,  [rdx+0110h]
    movaps  xmm10, [rdx+0120h]
    movaps  xmm11, [rdx+0130h]
    movaps  xmm12, [rdx+0140h]
    movaps  xmm13, [rdx+0150h]
    movaps  xmm14, [rdx+0160h]
    movaps  xmm15, [rdx+0170h]

    mov     rsp,        [rdx+040h]  ; restore RSP
    mov     r10,        [rdx+048h]  ; fetch the address to returned to

    mov     rax,        r8          ; use third arg as return value after jump
    mov     rcx,        r8          ; use third arg as first arg in context function

    jmp     r10                     ; indirect jump to caller
jump_fcontext ENDP

make_fcontext PROC EXPORT FRAME ; generate function table entry in .pdata and unwind information in    E
    .endprolog                        ; .xdata for a function's structured exception handling unwind behavior

    mov  [rcx],      rcx         ; store the address of current context
    mov  [rcx+048h], rdx         ; save the address of the function supposed to run
    mov  [rcx+010h], r8          ; save the the void pointer
    mov  rdx,        [rcx+050h]  ; load the address where the context stack beginns

    push  rcx                    ; save pointer to fcontext_t
    sub   rsp,       028h        ; reserve shadow space for align_stack
    mov   rcx,       rdx         ; stack pointer as arg for align_stack
    mov   [rsp+8],   rcx
    call  align_stack   ; align stack
    mov   rdx,       rax         ; begin of aligned stack
    add   rsp,       028h
    pop   rcx                    ; restore pointer to fcontext_t

    lea  rdx,        [rdx-028h]  ; reserve 32byte shadow space + return address on stack, (RSP + 8) % 16 == 0
    mov  [rcx+040h], rdx         ; save the address where the context stack beginns

    mov  rax,       [rcx+060h]   ; load the address of the next context
    mov  [rcx+08h], rax          ; save the address of next context
    stmxcsr [rcx+070h]           ; save MMX control and status word
    fnstcw  [rcx+074h]           ; save x87 control word

    lea  rax,       finish       ; helper code executed after fn() returns
    mov  [rdx],     rax          ; store address off the helper function as return address

    xor  rax,       rax          ; set RAX to zero
    ret

finish:
    xor   rcx,        rcx
    mov   [rsp+08h],  rcx
    call  _exit                  ; exit application
    hlt
make_fcontext ENDP
END
