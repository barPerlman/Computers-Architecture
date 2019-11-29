#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: task3

# Tool invocations
# Executable "hello" depends on the files hello.o and run.o.
task3: task3.o
	gcc -g -m32 -Wall -o task3 task3.o

task3.o: task3.c
	gcc -m32 -g -Wall -c -o task3.o task3.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o task3
