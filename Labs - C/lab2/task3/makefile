#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: menu

# Tool invocations
# Executable "menu" depends on the file menu.o
menu: menu_map.o
	gcc -g -Wall -o menu menu_map.o

menu.o: menu.c
	gcc -g -Wall -c -o menu_map.o menu_map.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o menu
