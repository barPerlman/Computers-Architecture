#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: task1

# Tool invocations
# Executable "hello" depends on the files hello.o and run.o.
task1: task1.o
	gcc -g -m32 -Wall -o task1 task1.o

task1.o: task1.c
	gcc -m32 -g -Wall -c -o task1.o task1.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o task1
