#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: myShell

# Tool invocations
# Executable "hello" depends on the files numbers.o and main.o and add.s.
myShell: main.o LineParser.o
	gcc -g -Wall -o myShell main.o LineParser.o

main.o: main.c
	gcc -g -Wall -c -o main.o main.c

LineParser.o: LineParser.c
	gcc -g -Wall -c -o LineParser.o LineParser.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o myShell

