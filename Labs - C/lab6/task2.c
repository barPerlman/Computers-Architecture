//task2
#include <stdio.h>
#include <wait.h>
#include <zconf.h>
#include <stdlib.h>
#include <string.h>
int main(int argc,char **argv) {
    int isDebugMode=0;
    int i=0;
    for(;i<argc;i++){
        if(strncmp(argv[i],"-d",2)==0){
            isDebugMode=1;
        }
    }
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
        char* const command_array1[] = {
                "ls",
                "-l",
                NULL
        };
        if(isDebugMode){
            fprintf(stderr,"(child1>going to execute cmd: …)\n");
        }
        int exe1=execvp(command_array1[0],command_array1);
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
            char* const command_array2[] = {
                   "tail",
                   "-n",
                    "2",
                    NULL
            };
            if(isDebugMode){
                fprintf(stderr,"(child2>going to execute cmd: …)\n");
            }
            int exe=execvp(command_array2[0],command_array2);
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
    exit(0);
}
