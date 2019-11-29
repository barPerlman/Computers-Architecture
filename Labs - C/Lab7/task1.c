#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <libgen.h> // Prototype for basename() function
#define INT sizeof(int)
#define MAX 100
char buffer[MAX];
int unit_size = INT;

// char* unit_to_format(int unit) {
//     static char* formats[] = {"%#hhd\t%#hhx\n", "%#hd\t%#hx\n", "No such unit", "%#d\t%#x\n"};
//     return formats[unit-1];
// //     If the above is too confusing, this can also work:
// //    switch (unit_size) {
// //        case 1:
// //            return "%#hhx\n";
// //        case 2:
// //            return "%#hx\n";
// //        case 4:
// //            return "%#hhx\n";
// //        default:
// //            return "Unknown unit";
// //    }

// }


/************ These are the functions that actually do the work ***************/
/* Reads units from file */
void read_units_to_memory(FILE* input, char* buffer, int count) {
    fread(buffer, unit_size, count, input);

}

char* unit_to_format(int unit) {
    static char* formats[] = {"%#hhx\n", "%#hx\n", "No such unit", "%#x\n"};
    return formats[unit-1];
}

/* updated func from units.c. print the memory by the received units in hex and decimal representation  */
void print_units(FILE* output, char* buffer, int count,int unit_size) {
    char* end = buffer + unit_size*count;
    while (buffer < end) {

        if(unit_size==4) {//print ints
           unsigned int var = *((int *) (buffer));
            fprintf(output,"%d\t",var);
            fprintf(output, unit_to_format(unit_size), var);
        }
        else if(unit_size==2){//print short
           unsigned short var=*((short*)(buffer));
            fprintf(output,"%d\t",var);
            fprintf(output, unit_to_format(unit_size), var);
        }
        else if(unit_size==1){//print short
           unsigned char var=*((char*)(buffer));
            fprintf(output,"%d\t",var);
            fprintf(output, unit_to_format(unit_size), var);
        }
        buffer += unit_size;
    }
}
/* Prints the buffer to screen by converting it to text with printf */
// void print_units(FILE* output, char* buffer, int count, int unit_size) {
//     char* end = buffer + unit_size*count;
//     while (buffer < end) {
//         //print ints
//         unsigned int var = *((unsigned int*)(buffer));
//         fprintf(output, unit_to_format(unit_size), var,var);
//         buffer += unit_size;
//     }
// }

/* Writes buffer to file without converting it to text with write */
void write_units(FILE* output, char* buffer, int count) {
    fwrite(buffer, unit_size, count, output);
}
/*****************************************************************************/

typedef struct {
  char debug_mode;
  char file_name[128];
  int unit_size;
  unsigned char mem_buf[10000];
  size_t mem_count;
  /*
   .
   .
   Any additional fields you deem necessary
  */
} state;
state* thisState;
struct fun_desc {
  char *name;
  void (*fun)(state*);
};
void ToggleDebugMode(state* s) {
	if(s->debug_mode) {
		s->debug_mode = 0;
		fprintf(stdout, "%s\n", "Debug flag now off");
	}
	else {
		s->debug_mode = 1;
		fprintf(stdout, "%s\n", "Debug flag now on");
	}
}
 void SetFileName(state* s) {
 	int i;
    fprintf(stdout, "%s\n", "Enter filename:");
 	fgets(buffer, MAX, stdin);
 	for(i = 0; i < MAX; i++) {
 	    if(buffer[i] == '\n') {
            buffer[i] = '\0';
 	    }
 	}
 	strcpy(s->file_name, buffer);
 	if(s->debug_mode) {
		fprintf(stdout, "%s%s\n", "filename is: ", buffer);
	}
 }

 void SetUnitSize(state* s) {
	 char input[10];
	 int value;
	 fprintf(stdout, "%s\n", "Enter unit size:");
	 fgets(input, 10, stdin);
	 value = atoi(input);
	 if(value == 1 || value == 2 || value == 4) {
	 	s->unit_size = value;
	 	if(s->debug_mode) {
			fprintf(stdout, "%s%s\n", "Debug: set size to ", input);
		}
	 }
	 else {
		 fprintf(stdout, "%s\n", "Invalid size");
	 }
 }
void LoadIntoMemory(state* s) {
    FILE * file;
    char * filename;
    char input[50];
    int location = 0;
    int length = 0;
    if (strcmp(s->file_name, "") == 0) {
		fprintf(stdout, "%s\n", "No filename");
        return;
	}
    filename = s->file_name;
    file = fopen(filename, "rb");
    if (file == NULL) {
        fprintf(stdout, "%s\n", "error opening file");
        return;
    }
    fprintf(stdout, "%s\n", "Please enter <location> <length>");
    fgets(input, 50, stdin);
    sscanf(input, "%x %d", &location, &length);
    if (s->debug_mode) {
        fprintf(stdout, "Filename: %s\nLocation: %x\nLength: %d\n", filename, location, length);
    }
    fseek(file, location, SEEK_SET);
    fread(s->mem_buf, (size_t) length, (size_t) s->unit_size, file);
    fprintf(stdout, "Loaded %d units into memory\n", length);
    fclose(file);
}

void MemoryDisplay(state* s) {
    char input[50];
    int u;
    int p = 0;
    char * buf;
    fprintf(stdout, "%s\n", "Please enter <u> <addr>");
    fgets(input, 50, stdin);
    sscanf(input, "%d %x", &u, &p);
    if (p == 0) {
        buf = (char *) s->mem_buf;
    }
    else {
        buf = (char *) p;
    }
    fprintf (stdout, "Decimal\tHexadecimal\n");
    fprintf (stdout, "=============\n");
    print_units(stdout, buf, u, s->unit_size);

}

void SaveIntoFile(state* s) {
    long fileSize;
    FILE * file;
    char input[50];
    int location = 0;
    int length = 0;
    char * filename;
    char * buf = {'\0'};
    int p = 0;
    if (strcmp(s->file_name, "") == 0) {
        fprintf(stdout, "%s\n", "No filename");
        return;
    }
    filename = s->file_name;
    file = fopen(filename, "rb+");
    if (file == NULL) {
        fprintf(stdout, "%s\n", "error opening file");
        return;
    }
    fprintf(stdout, "%s\n", "Please enter <source-address> <target-location> <length>");
    fgets(input, 50, stdin);
    sscanf(input, "%x %x %d", &p, &location, &length);
    fseek(file, 0, SEEK_END);
    fileSize = ftell(file);
    if (location > fileSize) {
        fprintf(stdout, "%s\n", "location too big");
        return;
    }

    if (p == 0) {
        buf = (char *) s->mem_buf;
    }
    else {
        buf = (char *) p;
    }
    fseek(file, location, SEEK_SET);
    fwrite(buf, (size_t) length, (size_t) s->unit_size, file);
    fclose(file);
}
void quit(state* s) {
    if (s->debug_mode) {
        fprintf(stdout, "%s\n", "quitting");
    }
    free(thisState);
    exit(0);
}
void FileModify(state *s){
    char input[128];
    char targetOffset[78];  //target offset in hex
    unsigned long val[50];
    fprintf(stdout,"Please enter <location> <val>\n");
    fgets(input,128,stdin);
    sscanf(input,"%s %lx",targetOffset,val);
    if(s->debug_mode==1){
        fprintf(stdout,"inserted location: %s, val: %ln",targetOffset,val);
    }
    int tarOffsetInt=strtol(targetOffset,NULL,16);
    //open the file for writing
    FILE* targetFile=fopen(s->file_name,"rb+");
    if(targetFile==NULL){
        fprintf(stderr,"error while opening target file\n");
        if(s->debug_mode==1){
            fprintf(stderr,"couldn't open target file in: Save into file\n");
        }
        return;
    }

    //check the offset is not exceeding the file size
    //get the size of the target file
    fseek(targetFile,0L,SEEK_END);
    int size=ftell(targetFile);
    if(size<tarOffsetInt){
        fprintf(stderr,"offset is exceeding the size of the target file\n");
        fclose(targetFile);
        return;
    }
    rewind(targetFile); //seek back to the beginning of the file

    //perform the writing
    fseek(targetFile, tarOffsetInt, SEEK_SET);  //go to the place where we want start writing to
    fwrite(val,s->unit_size,1, targetFile);
    fclose(targetFile);
}
// void FileModify(state* s) {
//     long fileSize;
//     FILE * file;
//     char input[50];
//     char check[9];
//     int val = 0;
//     char valArray[s->unit_size];
//     char temp;
//     int location, i;
//     char * filename;
//     if (strcmp(s->file_name, "") == 0) {
//         fprintf(stdout, "%s\n", "No filename");
//         return;
//     }
//     filename = s->file_name;
//     file = fopen(filename, "rb+");
//     if (file == NULL) {
//         fprintf(stdout, "%s\n", "error opening file");
//         return;
//     }
//     fprintf(stdout, "%s\n", "Please enter <location> <val>");
//     fgets(input, 50, stdin);
//     sscanf(input, "%x %x", &location, &val);
//     sscanf(input, "%x %s", &location, check);
//     fseek(file, 0, SEEK_END);
//     fileSize = ftell(file);
//     if (location > fileSize) {
//         fprintf(stdout, "%s\n", "location too big");
//         return;
//     }
//     if (s->unit_size == 1) {
//         if (strlen((const char *) check) > 2) {
//             fprintf(stdout, "%s\n", "invalid size");
//             return;
//         }
//     }
//     else if (s->unit_size == 2) {
//         if (strlen((const char *) check) > 4) {
//             fprintf(stdout, "%s\n", "invalid size");
//             return;
//         }
//     }
//     else if (s->unit_size == 4) {
//         if (strlen((const char *) check) > 8) {
//             fprintf(stdout, "%s\n", "invalid size");
//             return;
//         }
//     }
//     memcpy(valArray, &val, (size_t) s->unit_size);
//     for (i = 0; i < s->unit_size/2; i++) {
//         temp = valArray[i];
//         valArray[i] = valArray[s->unit_size-i-1];
//         valArray[s->unit_size-i-1] = temp;
//     }
//     fseek(file, location, SEEK_SET);
//     fwrite(valArray, 1, (size_t) s->unit_size, file);
//     fclose(file);
// }

struct fun_desc initmenu[] = { { "Toggle Debug Mode", ToggleDebugMode }, { "Set File Name", SetFileName },
	{ "Set Unit Size", SetUnitSize }, { "Load Into Memory", LoadIntoMemory },
	{ "Memory Display", MemoryDisplay }, { "Save Into File", SaveIntoFile },
    { "File Modify", FileModify }, { "Quit", quit }, { NULL, NULL } };

int main(int argc, char **argv){
	thisState = (state*)(malloc(sizeof(state)));
	thisState->debug_mode = 0;
    thisState->unit_size = 1;
	int option;
	char input[1] = {'\0'};
    struct fun_desc * menu = initmenu;
	while (1) {
		fprintf(stdout, "%s\n", "Please choose a function:");
		for (int i = 0; menu[i].name !=  NULL && menu[i].fun !=  NULL ; i++) {
			fprintf(stdout, "%d) %s\n", i, menu[i].name);
		}
		fprintf(stdout, "%s", "Option: ");
		fgets(input, 5, stdin);
		option = atoi(input);
		if (option >= 0 && option <= 7) {
			(menu[option].fun)(thisState);
		}
		else {
			fprintf(stdout, "%s\n", "Not within bounds");
            quit(thisState);	
		}
		fprintf(stdout, "%s\n\n", "DONE.");
	}
}
