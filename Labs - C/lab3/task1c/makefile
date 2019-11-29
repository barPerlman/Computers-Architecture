#this is a make file
#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: task1c

# Tool invocations
# Executable "count-words" depends on the file count-words.o
task1c: task1c.o
	gcc -g -Wall -o task1c task1c.o

task1c.o: task1c.c
	gcc -g -Wall -c -o task1c.o task1c.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o task1c
