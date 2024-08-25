#include "platform.h"

	# size of each hart's stack is 1024 bytes
	.equ	STACK_SIZE, 1024

	.global	_start

	.text
_start: # <- asm program start from the 1st instructions
	# park harts with id != 0
	# csrr (csr read), csrr rd, csr
	# csrw (csr write), csrw csr, rs
	# m-hard-id
	csrr	t0, mhartid		# read current m-hart-id to t0
	mv	    tp, t0			# keep CPU's hartid in its tp for later usage.
	bnez	t0, park		# branch to park if t0 not equal to zero

	# Setup stacks, the stack grows from bottom to top, so we put the
	# stack pointer to the very end of the stack range.
	# slli (shift left logical immediate): slli rd, rs, imm: rd = rs1 << imm
	slli	t0, t0, 10			# shift left the hart id by 1024
	# la (load address): la rd, label
	la	sp, stacks + STACK_SIZE	# set the initial stack pointer
								# to the end of the first stack space
	# add rd, rs1, rs2: rd = rs1 + rs2
	add	sp, sp, t0				# move the current hart stack pointer
								# to its place in the stack space
	# jump
	j	start_kernel			# hart 0 jump to kernal.c

park:
	wfi      # wait for interrupt
	j	park # jump to park (dead loops)

	# In the standard RISC-V calling convention, the stack pointer sp
	# is always 16-byte aligned.
.balign 16
stacks:
	.skip	STACK_SIZE * MAXNUM_CPU # allocate space for all the harts stacks

	.end				# End of file
