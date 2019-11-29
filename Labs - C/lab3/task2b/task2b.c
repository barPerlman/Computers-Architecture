//2b
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#define MAX_SIZE 10000
char buffer[MAX_SIZE];
char *arg=NULL;
//struct fun_desc define:
struct fun_desc {
    char* name;
    void (*fun)();
};


/**
 * @Pre receive buffer with null terminator '\0' and length<= buffer.size
 * @param buffer
 * @param length
 */
void PrintHex(char *buffer,size_t length){
    char* p=buffer;
    if(p==NULL){
        exit(-1);
    }
    int i;
    for(i=0;i<length;i++) {
        printf("%.2hhX ", *p);
        p++;
    }
    printf("\n\n");
}

typedef struct virus {
    unsigned short SigSize;
    char virusName[16];
    char sig[];
} virus;



typedef struct link link;   //shortcut name for the link struct

struct link {
    link *nextVirus;
    virus *vir;
};

static link* viruses=NULL;  //init the viruses list

/* Print the data of every link in list. Each item followed by a newline character. */
void list_print(link *virus_list){
    link* p=virus_list;     //get the head
    while(p!=NULL){
        printf("Virus name: %s\n",p->vir->virusName);
        printf("Virus size: %d\n",p->vir->SigSize);
        printf("signature:\n");
        PrintHex(p->vir->sig,p->vir->SigSize);
        p=p->nextVirus;
    }
}
//append at the END of the list
link* list_appendLast(link* virus_list,virus* data){
    link* p=virus_list;     //p points to the list head
    //create a link for the new data
    link* newLink=(link*)malloc(sizeof(link));
    if(newLink==NULL){
        fprintf(stderr,"ran out of memory");
        exit(-1);
    }
    newLink->nextVirus=NULL;
    newLink->vir=data;

    //list is null
    if(virus_list==NULL)
        return newLink;
    //move the p pointer to point on the last link
    while(p->nextVirus!=NULL){
        p=p->nextVirus;
    }
    //update the last link with the new one
    p->nextVirus=newLink;
    return virus_list;

}

/*
//append at the start of the list
link* list_appendFirst(link* virus_list,virus* data){
    //create a link for the new data
    link* newLink=(link*)malloc(sizeof(link));
    if(newLink==NULL){
        fprintf(stderr,"ran out of memory");
        exit(-1);
    }
    newLink->nextVirus=virus_list;              //append to the start
    newLink->vir=data;
}
*/
/* Free the memory allocated by the list. */
void list_free(link* virus_list){
    
    link* p=virus_list;
    while(virus_list!=NULL){
        virus_list=virus_list->nextVirus;
        free(p->vir);
        free(p);
        p=virus_list;
        
    }
}

void quit(){
    list_free(viruses);
    exit(0);
}

void loadSigs(){
//get and read viruses file
    char fileName[128];      //file name with viruses desc.
    char c;
    int i=0;
    while((c = getchar()) != '\n' && c != EOF){         //get the file name
        fileName[i]=c;
        i++;
    }
    fileName[i]='\0';
    FILE* inputFile=fopen(fileName,"r");   //the input file
    if(inputFile==NULL){
        fprintf(stderr,"Couldn't open the signatures file\n");
    }
else {
        //read the structures into a list structure
        unsigned short endIndicator=0;                             //this get the size of the current virus or 0 if eof or error occurred

        for (; fread(&endIndicator, sizeof(unsigned short),1, inputFile) != 0;) {
            fseek(inputFile, -2, SEEK_CUR);                                     //correct the pointer of the file
            unsigned short sizeOfVirus = endIndicator;
            virus *v = (virus *) calloc(1, sizeOfVirus);
            if(v==NULL){
                fprintf(stderr,"no memory for virus");
                exit(-1);
            }
            // creating and reading virus from file
            fread(v, sizeOfVirus, 1, inputFile);
            v->SigSize = v->SigSize - (short) sizeof(virus);       //update the real size of the signature size
            viruses = list_appendLast(viruses, v);              //add the virus to the viruses list
        }
        fclose(inputFile);
    }
}
void printList(){
    if(viruses==NULL){
        printf("There's nothing to print");

    }
    list_print(viruses);

}
void detect_virus(char* buffer, unsigned int size){
    int j;
    link* curr=viruses;
    for(;curr!=NULL;curr=curr->nextVirus){
        for(j=0;j<size;j++){
            if(memcmp(buffer+j,curr->vir->sig,curr->vir->SigSize)==0){
                
                //print the virus:
                printf("Starting location in file: %d\n",j);
                printf("The virus name: %s\n",curr->vir->virusName);
                printf("The size of the virus signature: %d\n\n",curr->vir->SigSize);
            }
        }
    }
}

void detect_viruses(){
    FILE* suspectFile=fopen(arg,"r");
    if(suspectFile==NULL){
        fprintf(stderr,"something wrong with inserted argument");
    }
    else{       //the suspected file has been received
        char *p=buffer;
        int i;
        for(i=0;fread(p,1, sizeof(char),suspectFile)&&i<MAX_SIZE;i++,p++); //reading file into buffer
    }
    fseek(suspectFile,0,SEEK_END);
    int fileSize=ftell(suspectFile);

    fclose(suspectFile);

    int minSize=fileSize<MAX_SIZE? fileSize : MAX_SIZE;
    detect_virus(buffer,minSize);
}

void kill_virus(char *fileName,int signitureOffset,int signitureSize){
    char updateString[signitureSize];         //string of nop characters for updating the file
    int i;
    for(i=0;i<signitureSize;i++){
        updateString[i]=0x90;   //string NOP signs
    }
    
    FILE* file=fopen(fileName,"rb+");            //open infected file to update
    if(file!=NULL) {
        fseek(file, signitureOffset, SEEK_SET);         //point on the start index where the virus to fix begins
        fwrite(updateString,signitureSize,1, file);
        fclose(file);
    }
}

void fixFile(){
    int sigOffset,sigSize;      //this will hold the virus info from the user
    printf("Please enter the starting  byte location and then the virus signature size: \n");
    scanf("%d %d",&sigOffset,&sigSize);
    while(getchar()!='\n');
    kill_virus(arg,sigOffset,sigSize);

}



void map( void (*f) ()){
    f();
}


struct fun_desc menu[] = { {"Load signatures",loadSigs}, {"Print signatures",printList},{"Detect viruses",detect_viruses},{"Fix file",fixFile},{"Quit",quit},{ NULL, NULL } };

int main(int argc, char **argv){
    if(argc>1)
        arg=argv[1];    //for farther using in detect viruses option

    char input[128];
    struct fun_desc *p=menu;                            // pointer to run over the menu functions array
    int lineNumber=1;                                   // the number of the line in the menu to print
    int bounds= (sizeof(menu)/ sizeof(menu[0]));
    int intInputOption;
    //the following loop runs till the quit option is reached by the user

    while(1){
        //display a menu:

        while(*p->fun!=NULL){
            printf("%d) %s\n",lineNumber,p->name);
            lineNumber++;
            p++;
        }
        lineNumber=1;
        p=menu;                                     //get the pointer back to the start of the functions array
        fflush(stdin);
        fgets(input,128,stdin);
        intInputOption=atoi(input);             //convert string to integer

        if(intInputOption>=bounds||intInputOption<=0){
            printf("Not within bounds\n");
            quit();
        }
        map(menu[intInputOption-1].fun);       //activate the selected function
    }
}
