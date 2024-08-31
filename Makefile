
ASM=nasm
ASMFLAGS=-f elf64
LD=ld
LDFLAGS=

# Targets
all: encrypt decrypt

encrypt: encrypt.o
	$(LD) $(LDFLAGS) -o encrypt encrypt.o

decrypt: decrypt.o
	$(LD) $(LDFLAGS) -o decrypt decrypt.o

encrypt.o: encrypt.asm
	$(ASM) $(ASMFLAGS) encrypt.asm -o encrypt.o

decrypt.o: decrypt.asm
	$(ASM) $(ASMFLAGS) decrypt.asm -o decrypt.o

clean:
	rm -f *.o encrypt decrypt

.PHONY: all clean
