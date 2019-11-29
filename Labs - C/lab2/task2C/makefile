#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: oop

# Tool invocations
# Executable "count-words" depends on the file count-words.o
oop: menu_map.o
	gcc -g -Wall -o oop menu_map.o

menu_map.o: menu_map.c
	gcc -g -Wall -c -o menu_map.o menu_map.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o oop
