/*task1b*/
#include "util.h"

#define SYS_CLOSE 6
#define SYS_WRITE 4
#define STDOUT 1
#define STDERR 2
#define SYS_OPEN 5
#define SYS_LSEEK 19
#define SYS_EXIT 1
#define O_RDONLY 0
#define O_WRNLY 1
#define O_RDRW 2
#define O_TRUNC 512
#define O_CREAT 64
#define MODE 0777
#define SEEK_END 2
#define SEEK_SET 0
#define SEEK_CUR 1
#define O_RDRW 2
#define SYS_READ 3
#define STDIN 0
#define EXIT 1
#define lowerMode 0

void printEncoding(char*,char*,int,int,int,int);

int main (int argc , char* argv[], char* envp[])
{
    int i,j;
	int realIn=0;
	int realOut=0;
    int outputFileReceived=0;
    int outFile;   /*holds the file received by the user*/
    int outFileNameSize=0;
	int argNumIn;
	int argNumOut;
    int errorStream=STDERR;
    int inputFileReceived=0;   /*flag which tells if input file inserted by the user*/
   
    int input =STDIN;   
    int inFileNameSize=0;

    int isDebugMode=0;
    int output=STDOUT;   /*print in regular mode*/
    
    char* in="stdin";
    char* out="stdout";
    
    /*update configurations*/
    if(argc>1) {
        for (i = 1; i < argc; i++) {
            if (strcmp(argv[i], "-D") == 0) {
                system_call(SYS_WRITE,output,"-D\n",3);
                isDebugMode=1;                              /*activate debug mode*/
            }else if(strncmp(argv[i],"-i",2)==0){
                inputFileReceived=1;    /*a file name inserted by the user*/
                inFileNameSize= strlen(argv[i]);	/*get the size of the input file + '-i'*/
                inFileNameSize-=2;
				argNumIn=i;
            }else if(strncmp(argv[i],"-o",2)==0){
                outputFileReceived=1;    /*a file name inserted by the user*/
                outFileNameSize= strlen(argv[i]);
                outFileNameSize-=2;
                argNumOut=i;
            }

            else {
                system_call(SYS_WRITE,output,"Some of the inserted params is wrong.\n",25);
                system_call(EXIT,0x55,"\n",1); /*exit with error*/
            }
        }
    }
    
    if(inputFileReceived||outputFileReceived){
	char inFileStr[inFileNameSize+1];    /*allocate memory for file name string*/
	char outFileStr[outFileNameSize+1];   /*get the name size inserted*/	
		/*create the string of the files names*/
		if(inputFileReceived){
			 realIn=1;
               for(j=0;j<inFileNameSize;j++){
                    inFileStr[j]=(argv[argNumIn])[j+2];
                }
				inFileStr[inFileNameSize]='\0';
				
		}
		if(outputFileReceived){
				realOut=1;
                for(j=0;j<outFileNameSize;j++){
                    outFileStr[j]=(argv[argNumOut])[j+2];
                }
                outFileStr[outFileNameSize]='\0';
                
			
		}
		/*check if need to open files to read and write*/
		if(realIn){
				in=inFileStr;
				input=system_call(SYS_OPEN,inFileStr,O_RDONLY,MODE);
                
                if(input<0){	/*check if file opened*/
                    system_call(SYS_WRITE,STDOUT,"Cannot open input file.\n",24);
                    system_call(EXIT,0x55,"\n",1); /*exit with error*/
                }
		}
		if(realOut){
			out=outFileStr;
            outFile=system_call(SYS_OPEN,outFileStr,O_RDRW|O_CREAT,MODE);
			if(outFile<0){
                    system_call(SYS_WRITE,output,"Cannot open output file.\n",25);
                    system_call(EXIT,0x55,"\n",1); /*exit with error*/
                }
                output=outFile; /*update write destination*/
		}
		printEncoding(in,out,isDebugMode,output,input,errorStream);	/*call tu function which prints to the suit place from the right place*/
	}
    else{
			printEncoding(in,out,isDebugMode,output,input,errorStream);	/*call tu function which prints to the suit place from the right place*/
  }
    /*close file allocation*/
    if(outputFileReceived==1){
        int error=system_call(SYS_CLOSE,outFile);
		if(error<0){
			system_call(SYS_WRITE,output,"failed to close out file.\n",26);
            system_call(EXIT,0x55,"\n",1); /*exit with error*/
		}
    }

    if(inputFileReceived==1){
        
        int error=system_call(SYS_CLOSE,input);
		if(error<0){
			system_call(SYS_WRITE,output,"failed to close in file.\n",25);
            system_call(EXIT,0x55,"\n",1); /*exit with error*/
		}
    }

    system_call(EXIT,0,"\n",1);	/*exit normally*/
	return 0;
}

void printEncoding(char* in,char* out,int isDebugMode,int output,int input,int errorStream) {
    char origChar,modChar;
    int reta,retb;
       if(!isDebugMode){
        while(system_call(SYS_READ,input,&origChar,1)==1){
            
            if(origChar>='A'&&origChar<='Z'){
                origChar=origChar +'a'-'A';
            }
            system_call(SYS_WRITE,output,&origChar,1);
            
        }
    } else{
        /*debug mode:*/
        system_call(SYS_WRITE,errorStream,"the input source: ",18);
        system_call(SYS_WRITE,errorStream,in,strlen(in));
        system_call(SYS_WRITE,errorStream,"\nthe output destination: ",25);
        system_call(SYS_WRITE,errorStream,out,strlen(out));
        system_call(SYS_WRITE,errorStream,"\n",1); 
        char *c;	/*holds the sysCallNum*/
        int i=0;	/*iteration num of print*/
        while((system_call(SYS_READ,input,&origChar,1))==1){
         i++;
         system_call(SYS_WRITE,errorStream,"System calls and chars in iteration ",36); 
         system_call(SYS_WRITE,errorStream,itoa(i),1); 
         system_call(SYS_WRITE,errorStream,":\n",2); 
            /*the sys details of read*/
            c=itoa(SYS_READ); 
            system_call(SYS_WRITE,errorStream,"sysNum: ",8);
            system_call(SYS_WRITE,errorStream,c,1);
            system_call(SYS_WRITE,errorStream," return: ",9);
            system_call(SYS_WRITE,errorStream,"\n",1); 
           
            
            modChar=origChar;
            /*update the character if necesarry*/
            if(origChar>='A'&&origChar<='Z'){
                modChar=modChar+'a'-'A';
            }
			/*print the chars before and after update*/
            system_call(SYS_WRITE,errorStream,"before: ",8);
            retb=system_call(SYS_WRITE,errorStream,&origChar,1);
			system_call(SYS_WRITE,errorStream," ",1);
			system_call(SYS_WRITE,errorStream,"after: ",7);
			reta=system_call(SYS_WRITE,errorStream,&modChar,1);
			system_call(SYS_WRITE,errorStream,"\n",1);
			/*print the sys details for call with origChar*/
			c=itoa(SYS_WRITE);
			system_call(SYS_WRITE,errorStream,"sysNum: ",8);
            system_call(SYS_WRITE,errorStream,c,1);
            system_call(SYS_WRITE,errorStream," returnb: ",9);
            system_call(SYS_WRITE,errorStream,itoa(retb),1);
            system_call(SYS_WRITE,errorStream,"\n",1); 
            /*print the sys details for call with modChar*/
			c=itoa(SYS_WRITE);
			system_call(SYS_WRITE,errorStream,"sysNum: ",8);
            system_call(SYS_WRITE,errorStream,c,1);
            system_call(SYS_WRITE,errorStream," returna: ",9);
            system_call(SYS_WRITE,errorStream,itoa(reta),1);
            system_call(SYS_WRITE,errorStream,"\n",1); 
            system_call(SYS_WRITE,errorStream,"------------------------------------\n",37);  
		}
	}
}
