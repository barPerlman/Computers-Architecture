#this is a makefile

# All Targets
all: encoder

# Tool invocations
# Executable "t1tryexec" depends on the files numbers.o and main.o and add.s.
encoder: encoder.o
	gcc -g -Wall -o encoder encoder.o

encoder.o: encoder.c
	gcc -g -Wall -c -o encoder.o encoder.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o encoder
