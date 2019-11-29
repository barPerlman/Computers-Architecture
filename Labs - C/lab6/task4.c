//task4
#include <stdio.h>
#include "LineParser.h"
#include <linux/limits.h>
#include <zconf.h>
#include <stdlib.h>
#include <wait.h>
#include <string.h>
#include <fcntl.h>

#define MAX_LINE_SIZE 2048




typedef struct pair{
    char *name;
    char* value;
    struct pair *next;	                  /* next pair in list of internal vars */
} pair;


static pair* internalVarsList=NULL; /*list of pairs*/

int isDebugMode=0;  /*a flag tells if -d flag encountered in the command*/

void freePairsList();

int execute(cmdLine*);
void infinithLoop();
int launch1(cmdLine *pLine);
int launch2(cmdLine *pLine);

int cd(cmdLine*);   /*emulates the cd shell feature*/
int set(cmdLine*);  /*set x y creates a variable with name x and value y*/
int vars(cmdLine*);   /*prints the variables in the list*/
int delete(cmdLine*);   /*prints the variables in the list*/

/*shell features utilities*/
char* shellFeaturesStr[]={"cd","set","vars","delete"};
int (*shellFeaturesFunc[])(cmdLine*)={&cd,&set,&vars,&delete};

void updateRedirections(cmdLine *pLine);

void addVarToList(cmdLine *pLine);

void addNewVar(char *const string, char *const string1);

int overrideIfExist(char *const string, char *const string1);

void replaceCmdArguments(cmdLine *pLine);

char *getValue(char *const string);

void freeVar(pair *pPair);

int numOfShellFeatures(){
    return sizeof(shellFeaturesStr)/ sizeof(char*);
}


int main(int argc, char **argv) {
    int i;
    /*determine if debuf flag is set on cmd line*/
    for(i=0;i<argc;i++){
        if(strcmp(argv[i],"-d")==0){
            isDebugMode=1;
            break;
        }
    }
    infinithLoop();
    freePairsList();
    return 0;   /*exit normally*/
}



/**
 * this is the infinith loop that:
 * read, parse and execute the user commands
 */
void infinithLoop(){
    FILE* input = stdin;
    cmdLine *pcmd_line;
    char strLine[MAX_LINE_SIZE];
    int status;
    char cwdPath[PATH_MAX];


    do{

        getcwd(cwdPath,PATH_MAX);               /*get current dir path*/
        fprintf(stdout,"%s ",cwdPath);          /*print the path*/

        fgets(strLine,MAX_LINE_SIZE,input);     /*read*/
        pcmd_line=parseCmdLines(strLine);       /*parse*/
        replaceCmdArguments(pcmd_line);
        status=execute(pcmd_line);              /*execute*/

        //free allocated
        freeCmdLines(pcmd_line);

    }while(status);
}

void replaceCmdArguments(cmdLine *pLine) {
    int i=0;
    while(pLine->arguments[i]!=NULL){

        if(strncmp(pLine->arguments[i],"$",1)==0){
            char* newVal=getValue(pLine->arguments[i]);
            if(newVal==NULL){
                fprintf(stderr,"the value for the var name %s is not found in list\n",pLine->arguments[i]);
            }
            else {
                replaceCmdArg(pLine, i, newVal);
            }
        } else if(strncmp(pLine->arguments[i],"~",1)==0){
            replaceCmdArg(pLine,1,getenv("HOME"));
        }
        i++;
    }
	if(pLine->next!=NULL){
		replaceCmdArguments(pLine->next);
	}
}

char *getValue(char *const preffedName) {
    char* ans = NULL;
    int sizeOfS=strlen(preffedName)-1;
    char name[sizeOfS+1];
    memcpy(name,&preffedName[1],sizeOfS);
    name[sizeOfS]='\0';
    pair *p=internalVarsList;
    while(p!=NULL&&ans==NULL){
        if(strcmp(p->name,name)==0){
            ans=p->value;
        }
        p=p->next;
    }
    return ans;
}

/**
 * responsible to execute the user command
 */
int execute(cmdLine* pCmdLine){
    int i;
    if (pCmdLine->arguments[0] == NULL) {
        /* An empty command was entered.*/
        return 1;
    }
    /*check if user requested to quit*/
    if(strcmp(pCmdLine->arguments[0],"quit")==0){
        return 0;
    }

    for(i=0;i<numOfShellFeatures();i++){
        if(strcmp(pCmdLine->arguments[0],shellFeaturesStr[i])==0){
            return (*shellFeaturesFunc[i])(pCmdLine);
        }
    }

    return (pCmdLine->next==NULL)? launch1(pCmdLine) : launch2(pCmdLine);

}

int launch1(cmdLine *pLine) {

    pid_t curPid;
    int status;

    curPid=fork(); /*clone process*/
    if(isDebugMode&&curPid!=0){
        fprintf(stderr,"PID: %d\nExecuting command: %s\n",curPid,pLine->arguments[0]);
    }

    if(curPid==0){  /*run the command from the child process*/
        updateRedirections(pLine);
        int execRet=execvp(pLine->arguments[0],pLine->arguments);
        if(isDebugMode){
            fprintf(stderr,"PID: %d\nExecuting command: %s\n",curPid,pLine->arguments[0]);
        }
        if(execRet==-1){
            perror("error in execution attempt");
            _exit(EXIT_FAILURE);
        }
        exit(EXIT_FAILURE);
    }
    else if(curPid<0){
        perror("error forking");
    }else{
        if(pLine->blocking==1){
            do{
                waitpid(curPid,&status,WUNTRACED);
            }while(!WIFEXITED(status)&&!WIFSIGNALED((status)));
        }

    }

    return 1;   /*tells the calling function to prompt for input again*/
}
/*
 * reallocate file descriptors according parsed redirections
 * in case there are
 */
void updateRedirections(cmdLine *pLine) {
    int fdIn=0,fdOut=1,isRedIn=0,isRedOut=0;
    //check existance of redirections
    if(pLine->inputRedirect!=NULL){
        isRedIn=1;
    }
    if(pLine->outputRedirect!=NULL){
        isRedOut=1;
    }
    //update redirect in descriptor
    if(isRedIn){
        fdIn=open(pLine->inputRedirect,O_RDONLY,0);
        if(fdIn<0){
            perror("failed to open input file\n");
            exit(1);
        }
        dup2(fdIn,0);
        close(fdIn);
    }
    //update redirect out descriptor
    if(isRedOut){
        fdOut=open(pLine->outputRedirect,O_CREAT|O_RDWR,0666);
        if(fdOut<0){
            perror("failed to open output file\n");
            exit(1);
        }
        dup2(fdOut,1);
        close(fdOut);
    }

}

int cd(cmdLine* pcmdLine){
    if(pcmdLine->arguments[1]==NULL){
        fprintf(stderr,"destination dir is missing for cd command\n");
    } else{ /*execute cd command*/
        int resExec=chdir(pcmdLine->arguments[1]);
        if(resExec!=0){
            fprintf(stderr,"Couldn't go to %s\n",pcmdLine->arguments[1]);
        }
    }
    return 1;
}
int vars(cmdLine* pcmdLine){
    pair* p=internalVarsList;
    int i=1;

    if(p!=NULL){
        fprintf(stdout,"The followings are the variables in the list:\n");
    } else{
        fprintf(stderr,"The vars list is empty\n");
    }
    while(p!=NULL){
        fprintf(stdout,"%d. name: %s, value: %s\n",i,p->name,p->value);
        p=p->next;
        i++;
    }
    return 1;
}
int set(cmdLine* pcmdLine){
    if(pcmdLine->arguments[1]==NULL||pcmdLine->arguments[2]==NULL){
        fprintf(stderr,"name or value are missing in set command\n");
    } else{ /*execute cd command*/
        addVarToList(pcmdLine);
    }
    return 1;
}

void addVarToList(cmdLine *pLine) {

    //override the the value of the var name if exist
    int isOverrided=overrideIfExist(pLine->arguments[1],pLine->arguments[2]);

    if(!isOverrided){
        addNewVar(pLine->arguments[1],pLine->arguments[2]);
    }
}
/*if var 'name is exist in the list then update its value with 'newVal' */
int overrideIfExist(char *const name, char *const newVal) {
    int ans = 0;
    pair *p=internalVarsList;
    while (p!=NULL&&!ans){
        if(strcmp(p->name,name)==0){    //this var name is already exist
            ans=1;
            //update its value
            free(p->value);
            p->value=(char*)malloc(strlen(newVal)+1);
            strcpy(p->value,newVal);

        }
        p=p->next;
    }
    return ans;
}

/*add new var to list*/
void addNewVar(char *const name, char *const value) {

    /*create a new node*/
    pair* newNode=(pair*)malloc(sizeof(pair));
    newNode->next=NULL;
    newNode->name=(char*)malloc(strlen(name)+1);
    strcpy(newNode->name,name);
    newNode->value=(char*)malloc(strlen(value)+1);
    strcpy(newNode->value,value);
    /*list is null*/
    if(internalVarsList==NULL){
        internalVarsList=newNode;
    }
    else {  //add as the last node in the list
        pair* p=internalVarsList;
        /*p pointer will point to the last node*/
        while (p->next != NULL) {
            p = p->next;
        }
        /*update the new node to be the last node*/
        p->next = newNode;
    }

}

int launch2(cmdLine* pcmdLine){

    int status1=0;
    int status2=0;

    int pipefd[2];
    pid_t c1pid=-1,c2pid=-1;

    int resPipeOp=pipe(pipefd);     //create a pipe

    if(resPipeOp==-1){
        perror("error in pipe create\n");
        exit(EXIT_FAILURE);
    }
    if(isDebugMode){
        fprintf(stderr,"(parent_process>forking…)\n");
    }
    c1pid=fork();   //fork child #1
    if(isDebugMode&&c1pid>0){
        fprintf(stderr,"(parent_process>created process with id: %d)\n",c1pid);
    }
    if(c1pid==-1){
        perror("failed to fork child1\n");
        exit(EXIT_FAILURE);
    }
    if(c1pid==0){
        if(isDebugMode){
            fprintf(stderr,"(child1>redirecting stdout to the write end of the pipe…)\n");
        }
        //its child1
        close(STDOUT_FILENO);   //close stdout
        int duped=dup(pipefd[1]);     //duplicate
        if(duped==-1){
            perror("error in duplicating write end\n");
            exit(EXIT_FAILURE);
        }
        close(pipefd[1]);

        if(isDebugMode){
            fprintf(stderr,"(child1>going to execute cmd: …)\n");
        }
        updateRedirections(pcmdLine);
        int exe1=execvp(pcmdLine->arguments[0],pcmdLine->arguments);
        if(exe1==-1){
            perror("error occurred while executing in child1\n");
            exit(EXIT_FAILURE);
        }
        exit(EXIT_SUCCESS);

    }
    if(c1pid>0){    //its the parent
        if(isDebugMode){
            fprintf(stderr,"(parent_process>waiting for child processes to terminate…)\n");
        }
        do{
            waitpid(c1pid,&status1,WUNTRACED);
        }while(!WIFEXITED(status1)&&!WIFSIGNALED((status1)));
        if(isDebugMode){
            fprintf(stderr,"(parent_process>closing the write end of the pipe…)\n");
        }
        close(pipefd[1]);
        if(isDebugMode){
            fprintf(stderr,"(parent_process>forking…)\n");
        }
        c2pid=fork();
        if(isDebugMode&&c2pid>0){
            fprintf(stderr,"(parent_process>created process with id: %d)\n",c2pid);
        }
        if(c2pid==-1){
            perror("failed to fork child2\n");
            exit(EXIT_FAILURE);
        }
        if(c2pid==0){
            if(isDebugMode){
                fprintf(stderr,"(child2>redirecting stdin to the read end of the pipe…)\n");
            }
            //its child1
            close(STDIN_FILENO);   //close stdout
            int duped2=dup(pipefd[0]);     //duplicate
            if(duped2==-1){
                perror("error in duplicating read end\n");
                exit(EXIT_FAILURE);
            }
            close(pipefd[0]);

            if(isDebugMode){
                fprintf(stderr,"(child2>going to execute cmd: …)\n");
            }
            updateRedirections(pcmdLine->next);
            int exe=execvp(pcmdLine->next->arguments[0],pcmdLine->next->arguments);
            if(exe==-1){
                perror("error while executing in child2\n");
                exit(EXIT_FAILURE);
            }
            exit(EXIT_SUCCESS);
        }
        else if(c2pid>0){//its the parent - c2pid>0;
            if(isDebugMode){
                fprintf(stderr,"(parent_process>closing the read end of the pipe…)\n");
            }
            close(pipefd[0]);
            if(isDebugMode){
                fprintf(stderr,"(parent_process>waiting for child processes to terminate…)\n");
            }
            do{
                waitpid(c2pid,&status2,WUNTRACED);
            }while(!WIFEXITED(status2)&&!WIFSIGNALED((status2)));
        }
    }
    if(isDebugMode){
        fprintf(stderr,"(parent_process>exiting…)\n");
    }
    return 1;
}
int delete(cmdLine* pLine){
    pair* p=internalVarsList;
    int isFound=0;
    while (p!=NULL&&!isFound){
        if(strcmp(p->name,pLine->arguments[1])==0){
            //delete node
            if(p==internalVarsList){//delete the first node
                internalVarsList=internalVarsList->next;
                freeVar(p);
            } else{ //its not the first node in the list
                pair* prev=internalVarsList;
                while (prev->next!=p){
                    prev=prev->next;
                }
                //now the prev is the previous node of p
                prev->next=p->next;
                freeVar(p);
                p=NULL;
            }
            return 1;
        }
        if(p!=NULL){
            p=p->next;
        }
    }
    return 1;
}

void freeVar(pair *pPair) {
    free(pPair->name);
    free(pPair->value);
    free(pPair);
}
void freePairsList(){
    pair* p=internalVarsList;
    while(internalVarsList!=NULL){
        internalVarsList=internalVarsList->next;
        freeVar(p);
        p=internalVarsList;
    }
}
