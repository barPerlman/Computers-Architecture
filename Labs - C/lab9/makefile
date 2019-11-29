#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: task4

# Tool invocations
# Executable "hello" depends on the files numbers.o and main.o and add.s.
task4:  task4.o
	ld -m elf_i386 -o task4 task4.o

task4.o: task4.s
	nasm -g -f elf -w+all -o task4.o task4.s


#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o task4

