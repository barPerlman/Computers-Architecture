#this is a makefile
#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: task2b

# Tool invocations
# Executable "count-words" depends on the file count-words.o
task2b: task2b.o
	gcc -g -Wall -o task2b task2b.o

task2b.o: task2b.c
	gcc -g -Wall -c -o task2b.o task2b.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o task2b
