# Common part for the Makefile.
# This file will be included by the Makefile of each project.

# Custom Macro Definition (Common part)

include ../defines.mk
DEFS +=

CROSS_COMPILE = riscv64-unknown-elf-
CFLAGS += -nostdlib -fno-builtin -g -Wall
CFLAGS += -march=rv32g -mabi=ilp32

QEMU = qemu-system-riscv32
QFLAGS = -nographic -smp 1 -machine virt -bios none

GDB = gdb-multiarch
CC = ${CROSS_COMPILE}gcc
OBJCOPY = ${CROSS_COMPILE}objcopy
OBJDUMP = ${CROSS_COMPILE}objdump
MKDIR = mkdir -p
RM = rm -rf

OUTPUT_PATH = out

# SRCS_ASM & SRCS_C are defined in the Makefile of each project.
# $(addprefix src/,foo bar) -> src/foo src/bar
OBJS_ASM := $(addprefix ${OUTPUT_PATH}/, $(patsubst %.S, %.o, ${SRCS_ASM}))
OBJS_C   := $(addprefix $(OUTPUT_PATH)/, $(patsubst %.c, %.o, ${SRCS_C}))
OBJS = ${OBJS_ASM} ${OBJS_C}

ELF = ${OUTPUT_PATH}/os.elf
BIN = ${OUTPUT_PATH}/os.bin

USE_LINKER_SCRIPT ?= true
ifeq (${USE_LINKER_SCRIPT}, true)
LDFLAGS = -T ${OUTPUT_PATH}/os.ld.generated
else
LDFLAGS = -Ttext=0x80000000
endif

.DEFAULT_GOAL := all
all: ${OUTPUT_PATH} ${ELF}

# mkdir -p ${OUTPUT_PATH}
${OUTPUT_PATH}:
	@${MKDIR} $@

# start.o must be the first in dependency!
#
# For USE_LINKER_SCRIPT == true, before do link, run preprocessor manually for
# linker script.
# -E specifies GCC to only run preprocessor
# -P prevents preprocessor from generating linemarkers (#line directives)
# -x c tells GCC to treat your linker script as C source file
${ELF}: ${OBJS}
ifeq (${USE_LINKER_SCRIPT}, true)
	${CC} -E -P -x c ${DEFS} ${CFLAGS} os.ld > ${OUTPUT_PATH}/os.ld.generated
endif
	${CC} ${CFLAGS} ${LDFLAGS} -o ${ELF} $^
	${OBJCOPY} -O binary ${ELF} ${BIN}

${OUTPUT_PATH}/%.o : %.c
	${CC} ${DEFS} ${CFLAGS} -c -o $@ $<

${OUTPUT_PATH}/%.o : %.S
	${CC} ${DEFS} ${CFLAGS} -c -o $@ $<

# $ qemu-system-riscv32 -M ?
# Supported machines are:
# none                 empty machine
# sifive_e             RISC-V Board compatible with SiFive E SDK
# sifive_u             RISC-V Board compatible with SiFive U SDK
# spike                RISC-V Spike Board (default)
# spike_v1.10          RISC-V Spike Board (Privileged ISA v1.10)
# spike_v1.9.1         RISC-V Spike Board (Privileged ISA v1.9.1)
# virt                 RISC-V VirtIO board
# $ qemu-system-riscv32 -M ? | grep virt
# virt                 RISC-V VirtIO board
# $ qemu-system-riscv32 -M ? | grep virt >/dev/null
# $ qemu-system-riscv32 -M ? | grep virt >/dev/null || exit
# if "qemu-system-riscv32 -M ? | grep virt >/dev/null" successfully execute,
# which means grep find "virt" in the output of "qemu-system-riscv32 -M ?",
# then nothing will be output; else execute "exit" 

.PHONY : run
run: all
	@# qemu-system-riscv32 -M ? | grep virt >/dev/null || exit
	${QEMU} -M ? | grep virt >/dev/null || exit
	@echo "Press Ctrl-A and then X to exit QEMU"
	@echo "------------------------------------"
	@# qemu-system-riscv32 -nographic -smp 1 -machine virt -bios none -kernel out/os.elf
	${QEMU} ${QFLAGS} -kernel ${ELF}

.PHONY : run-qemu
run-qemu: all
	@echo "Press Ctrl-A and then X to exit QEMU"
	@echo "------------------------------------"
	${QEMU} ${QFLAGS} -kernel ${ELF} -gdb tcp::1234 -S

.PHONY : debug
debug: all
	@echo "Press Ctrl-C and then input 'quit' to exit GDB and QEMU"
	@echo "-------------------------------------------------------"
	${QEMU} ${QFLAGS} -kernel ${ELF} -s -S &
	${GDB} ${ELF} -q -x ../gdbinit

.PHONY : code
code: all
	@${OBJDUMP} -S ${ELF} | less

.PHONY : clean
clean:
	@${RM} ${OUTPUT_PATH}

.PHONY : test
test: all
	@echo "OBJS_ASM: ${OBJS_ASM}"
	@echo "OBJS_C: ${OBJS_ASM}"
	@echo "ELF: ${ELF}"
	@echo "all: ${all}"
