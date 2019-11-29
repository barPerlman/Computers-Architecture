//3
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int iter=0; 
//struct fun_desc define:
struct fun_desc {
    char* name;
    char (*fun)(char);
};

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
    if(iter>0){
        free(array);
        array=NULL;
    }
    return mapped_array;
}

char quit(char c){
    exit(0);
    return 0;
}
//two-element array of "function descriptors"
struct fun_desc menu[] = { { "Censor", censor }, { "Encrypt", encrypt },{"Decrypt",decrypt},{"Print hex",xprt},{"Print string",cprt},{"Get string",my_get},{"Quit",quit},{ NULL, NULL } };

int main(int argc, char **argv){
    
    char tempArr[5]={'\0'};
    char* carray=tempArr;         //1
    char input[128]={'\0'};
    struct fun_desc *p=menu;                            // pointer to run over the menu functions array
    int lineNumber=0;                                   // the number of the line in the menu to print
    int bounds= (sizeof(menu)/ sizeof(menu[0]))-1;
    int intInputOption=-1;
    //the followin loop runs till the quit option is reached by the user
    while(1){
        //display a menu:
        fprintf(stdout,"Please choose a function:\n");
        while(*p->fun!=NULL){
            fprintf(stdout,"%d) %s\n",lineNumber,p->name);
            lineNumber++;
            p++;
        }
        lineNumber=0;
        p=menu;                                     //get the pointer back to the start of the functions array
        fprintf(stdout,"Option: ");                         //get selection from user
        fgets(input,128,stdin);
        intInputOption=atoi(input);             //convert string to integer
        if(intInputOption>=bounds||intInputOption<0){
           fprintf(stdout,"Not within bounds\n");
           free(carray);
           carray=NULL;
           quit('c');
        }
        fprintf(stdout,"Within bounds\n");
        carray=map(carray,5,menu[intInputOption].fun);     //Evaluate the appropriate function over 'carray'
        fprintf(stdout,"Done.\n\n");
        iter++;
    }

}

