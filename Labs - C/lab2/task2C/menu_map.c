//2c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char censor(char c) {
    if(c == '!')
        return '.';
    else
        return c;
}
/* Gets a char c and returns its encrypted form by adding 3 to its value.
			If c is not between 0x20 and 0x7E it is returned unchanged */
char encrypt(char c){
    if(c>=0x20&&c<=0x7E){
        c+=3;
    }
    return c;
}
/* Gets a char c and returns its decrypted form by reducing 3 to its value.
				If c is not between 0x20 and 0x7E it is returned unchanged */
char decrypt(char c){
    if(c>=0x20&&c<=0x7E){
        c-=3;
    }
    return c;
}
/* xprt prints the value of c in a hexadecimal representation followed by a
           new line, and returns c unchanged. */
char xprt(char c){
    fprintf(stdout,"0x%x\n",c);
    return c;
}
/* If c is a number between 0x20 and 0x7E, cprt prints the character of ASCII value c followed
                    by a new line. Otherwise, cprt prints the dot ('.') character. After printing, cprt returns
                    the value of c unchanged. */
char cprt(char c){
    if(c>=0x20&&c<=0x7E){
        fprintf(stdout,"%c\n",c);
    }
    else{
        fprintf(stdout,".\n");
    }
    return c;
}
/* Ignores c, reads and returns a character from stdin using fgetc. */
char my_get(char c){
    char retChar=fgetc(stdin);
    return retChar;
}




char* map(char *array, int array_length, char (*f) (char)){
    char* mapped_array = (char*)(malloc(array_length*sizeof(char)));
    if(mapped_array==NULL){
        exit(-1);
    }
    char* p=array;	//a pointer to run on the received array
    size_t i=0;
    while(i<array_length){
        mapped_array[i]=f(*p);
        p++;
        i++;
    }
    mapped_array[array_length]='\0';
    return mapped_array;
}

char quit(char c){
	exit(0);
	return 0;
}

int main(int argc, char **argv){
    
    int base_len = 5;
    char arr1[base_len];
    fprintf(stdout,"Result:\n");
    char* arr2 = map(arr1, base_len, my_get);
    char* arr3 = map(arr2, base_len, encrypt);
    char* arr4 = map(arr3, base_len, xprt);
    char* arr5 = map(arr4, base_len, decrypt);
    char* arr6 = map(arr5, base_len, cprt);
    free(arr2);
    free(arr3);
    free(arr4);
    free(arr5);
    free(arr6);
    quit('c');
}
