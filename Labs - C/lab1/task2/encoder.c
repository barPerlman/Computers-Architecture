//task2

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
void printEncodingByMode(int, char*,size_t,FILE*,FILE*,FILE*);

enum mode {
    lowerMode = 0,
    addEncMode = 1,
    subEncMode = 2,
};

int isDebugMode=0;


int main(int argc, char **argv) {

    size_t strSize; //holds the size of the key
    char *key;
    int i,j;

    
    int outputFileReceived=0;
    FILE *outFile;   //holds the file received by the user
    size_t outFileNameSize;
    char* outFileStr;


    FILE* errorStream=stderr;
    int inputFileReceived=0;   //flag which tells if input file inserted by the user
    FILE *input =stdin;   //holds the file received by the user
    size_t inFileNameSize;
    char* inFileStr;

    int mode=lowerMode;
    FILE * output=stdout;   //print in regular mode
    //update configurations
    if(argc>1) {
        for (i = 1; i < argc; i++) {
            if (strcmp(argv[i], "-D") == 0) {
                printf("-D\n");
                isDebugMode=1;                              //activate debug mode
            }else if(strncmp(argv[i],"+e",2)==0){
                strSize= strlen(argv[i]);
                strSize-=2;
                key=(char*)malloc(sizeof(char)*strSize);    //get the substring represents the key
                for(j=0;j<strSize;j++){
                    key[j]=(argv[i])[j+2];
                }
                //update mode
                mode=addEncMode;
            }else if(strncmp(argv[i],"-e",2)==0){
                strSize= strlen(argv[i]);
                strSize-=2;
                key=(char*)malloc(sizeof(char)*strSize);    //get the substring represents the key
                for(j=0;j<strSize;j++){
                    key[j]=(argv[i])[j+2];
                }
                //update mode
                mode=subEncMode;
            }else if(strncmp(argv[i],"-i",2)==0){
                inputFileReceived=1;    //a file name inserted by the user
                inFileNameSize= strlen(argv[i]);
                inFileNameSize-=2;
                inFileStr=(char*)malloc(sizeof(char)*inFileNameSize);    //get the substring represents the key
                for(j=0;j<inFileNameSize;j++){
                    inFileStr[j]=(argv[i])[j+2];
                }
                input=fopen(inFileStr,"r");
                if(input==NULL){
                    fprintf(stderr,"Cannot open the input file associated with the inserted file name!\n");
                    free(inFileStr);
                    return 0;
                }
            }else if(strncmp(argv[i],"-o",2)==0){
                outputFileReceived=1;    //a file name inserted by the user
                outFileNameSize= strlen(argv[i]);
                outFileNameSize-=2;
                outFileStr=(char*)malloc(sizeof(char)*outFileNameSize);    //get the substring represents the key
                for(j=0;j<outFileNameSize;j++){
                    outFileStr[j]=(argv[i])[j+2];
                }
                outFile=fopen(outFileStr,"w");
                if(outFile==NULL){
                    fprintf(stderr,"Cannot open the output file associated with the inserted file name!\n");
                    free(outFileStr);
                    return 0;
                }
                output=outFile; //update write destination
            }

            else {
                printf("invalid parameter - %s\n", argv[i]);
                return 1;
            }
        }
    }


    while (!feof(input)){
        printEncodingByMode(mode,key,strSize,output,input,errorStream);
    }

    //free allocated for key encryption
    if(mode==subEncMode||mode==addEncMode){
        free(key);
    }
    //close file allocation
    if(outputFileReceived==1){
        free(outFileStr);
        fclose(outFile);

    }

    if(inputFileReceived==1){
        free(inFileStr);
        fclose(input);
    }

    return 0;
}

void printEncodingByMode(int mode, char* key,size_t strSize,FILE *output,FILE* inputStream,FILE* errorStream) {
    int k;
    char origChar,modChar;
    if (mode == lowerMode) {   //regular mode
        while (!feof(inputStream)) {
            origChar = fgetc(inputStream);
            modChar=origChar;

            if (origChar >= 'A' && origChar <= 'Z') {
                modChar = modChar + 'a'-'A';
            }
            if (!feof(inputStream)) {
                if (isDebugMode) {
                    fprintf(errorStream, "0x%.2x    0x%.2x\n", origChar, modChar);
                    fputc(modChar, output);
                }
                else{
                    fputc(modChar, output);
                }
            }
        }
    }  else if (mode == addEncMode) {
        k = 0;
        while (!feof(inputStream)) {
            origChar = fgetc(inputStream);
            modChar=origChar;
            modChar += key[k % strSize];
            if (!feof(inputStream)) {
                if(isDebugMode){
                    fprintf(errorStream, "0x%.2x    0x%.2x\n", origChar, modChar);
                    fputc(modChar, output);
                    k++;
                    if(origChar=='\n'){
                        k=0;
                        printf("\n");
                    }
                }
                else{
                    fputc(modChar, output);
                    k++;
                    if(origChar=='\n'){
                        k=0;
                        printf("\n");
                    }
                }
            }
        }
    } else if (mode == subEncMode) {
        k = 0;
        while (!feof(inputStream)) {
            origChar = fgetc(inputStream);
            modChar=origChar;
            modChar -= key[k % strSize];
            if (!feof(inputStream)) {
                if(isDebugMode){
                    fprintf(errorStream, "0x%.2x    0x%.2x\n", origChar, modChar);
                    fputc(modChar, output);
                    k++;
                    if(origChar=='\n'){
                        k=0;
                        printf("\n");
                    }
                }
                else{
                    fputc(modChar, output);
                    k++;
                    if(origChar=='\n'){
                        k=0;
                        printf("\n");
                    }
                }
            }
        }
    }
}



