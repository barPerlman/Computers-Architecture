/*task2c*/
#include "util.h"
#include <dirent.h>

#define STDERR 2
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
#define GETDENTS 141
#define BUF_SIZE 8191
#define DT_UNKNOWN 0
# define DT_FIFO 1
# define DT_CHR 2
# define DT_DIR 4
# define DT_BLK 6
# define DT_REG 8
# define DT_LNK 10
# define DT_SOCK 12
# define DT_WHT 14

extern int system_call(int,...);

extern void code_start();

void runDebugMode(char*,int,int,int);
void runRegularMode(char*,int,int,int);

int main (int argc , char* argv[], char* envp[])
{
	int alreadyInPref=0;
	char* p_pref;
	int isPrefix=0;
    int i,j,prefixSize;		
    int isDebugMode=0;
    int argIndex;
    int isAppend=0;
   
   
   
    /*update configurations*/
   
    if(argc>1) {
        for (i = 1; i < argc; i++) {
            if (strcmp(argv[i], "-D") == 0) {
                system_call(SYS_WRITE,STDOUT,"-D\n",3);
                isDebugMode = 1;
            }
            else if(strncmp(argv[i],"-p",2)==0){
                isPrefix=1;    /*a file name inserted by the user*/
                prefixSize= strlen(argv[i]);	/*get the size of the prefix + '-p'*/
                prefixSize-=2;
				argIndex=i;
				
				 
			}else if(strncmp(argv[i],"-a",2)==0){
                isAppend=1;    /*a file name inserted by the user*/
                prefixSize= strlen(argv[i]);	/*get the size of the prefix + '-p'*/
                prefixSize-=2;
				argIndex=i;
				isPrefix=1;
				
				 
			}else {
                system_call(SYS_WRITE,STDOUT,"invalid parameter: ",19);
                system_call(SYS_WRITE,STDOUT,argv[i],strlen(argv[i]));
                system_call(EXIT,0x55,"\n",1); /*exit with error*/
            }
		}
	}
	
	if(isPrefix||isAppend){
		  alreadyInPref=1;
		  char prefix[prefixSize+1];    /*allocate memory for file name string*/
          for(j=0;j<prefixSize;j++){
               prefix[j]=(argv[argIndex])[j+2];
          }
		  prefix[prefixSize]='\0';
		  p_pref=prefix;
		  
		  if(!isDebugMode){
			  runRegularMode(p_pref,isPrefix,prefixSize,isAppend);
		  }else{
			 runDebugMode(p_pref,isPrefix,prefixSize,isAppend); 
		  }
		
		
	}

    if(!isDebugMode&&!alreadyInPref){
		runRegularMode(p_pref,isPrefix,prefixSize,isAppend);
	}
	else{
		if(!alreadyInPref)
			runDebugMode(p_pref,isPrefix,prefixSize,isAppend);
	}
	
	
	system_call(EXIT,0,"\n",1); /*exit normally*/ 
	return 0;
}

/***************************************************************************************************************************/

void runDebugMode(char* p_pref,int isPrefix,int prefixSize,int isAppend){
	int res;
	int fd, nread;		/*file descriptor and amount of readed chars variables*/
	char buf[BUF_SIZE];	/* buffer with max size */
	struct dirent *d;	/*pointer to current file structure*/
	int bpos;			/*navigator sign in buffer*/
    char d_type;     
	fd=system_call(SYS_OPEN,".",O_RDONLY,MODE);
	
	system_call(SYS_WRITE,STDERR,"sysNum: ",8);
	system_call(SYS_WRITE,STDERR,itoa(SYS_WRITE),1);
	system_call(SYS_WRITE,STDERR,"\nreturnVal: ",12);
	system_call(SYS_WRITE,STDERR,itoa(fd),1);
	system_call(SYS_WRITE,STDERR,"\n------------------------------\n",32);
	
	
    if (fd < 0)  /* open dir failed */
    { 
        system_call(SYS_WRITE,STDOUT,"Couldn't open current directory.",32); 
        system_call(EXIT,0x55,"\n",1); /*exit with error*/ 
    } 
  
           for ( ; ; ) {
               nread = system_call(GETDENTS, fd, buf, BUF_SIZE);	/*get dir content into buf*/
               
                system_call(SYS_WRITE,STDERR,"sysNum: ",8);
				system_call(SYS_WRITE,STDERR,itoa(GETDENTS),1);
				system_call(SYS_WRITE,STDERR,"\nreturnVal: ",12);
				system_call(SYS_WRITE,STDERR,itoa(nread),1);
				system_call(SYS_WRITE,STDERR,"\n------------------------------\n",32);
               
               
               if (nread == -1){	/*error occurred*/
                    system_call(SYS_WRITE,STDOUT,"getdents returned error.",32); 
					system_call(EXIT,0x55,"\n",1); /*exit with error*/ 
				}	
               if (nread == 0)		/*nothing left to read*/
                   break;

               
               for (bpos = 0; bpos < nread;) {	/*for each file print it's name*/
                   d = (struct dirent *) (buf + bpos);	/*update location of dirent pointer to the next file structure*/
                   d_type = *(buf + bpos + (d->d_reclen)-1);
                  if(isPrefix){ /*need to compare prefix*/
                   if(strncmp(p_pref,(d->d_name)-1,strlen(p_pref))==0){
						
						res=system_call(SYS_WRITE,STDERR,(d->d_name)-1,strlen(d->d_name)+1); /*print the file name*/
						system_call(SYS_WRITE,STDERR," length:",8);
						system_call(SYS_WRITE,STDERR,(itoa(d->d_reclen))-1,strlen(itoa(d->d_reclen))); /*print the file length*/
						
						system_call(SYS_WRITE,STDERR," type: ",7);
						
						if(d_type==DT_UNKNOWN)
							system_call(SYS_WRITE,STDERR,"unknown\n",8);
							
						else if(d_type==DT_REG)
							system_call(SYS_WRITE,STDERR,"regular file\n",13);
						else if(d_type==DT_DIR)
							system_call(SYS_WRITE,STDERR,"directory\n",10);
						else if(d_type==DT_FIFO)
							system_call(SYS_WRITE,STDERR,"FIFO\n",5);
						 	
						else if(d_type==DT_SOCK)
							system_call(SYS_WRITE,STDERR,"socket\n",7);
							
						else if(d_type==DT_CHR)
							system_call(SYS_WRITE,STDERR,"char device\n",13);
							
						else if(d_type==DT_BLK)
							system_call(SYS_WRITE,STDERR,"block\n",6);	
						
						else if(d_type==DT_LNK)
							system_call(SYS_WRITE,STDERR,"symbolic link\n",14);	
						
								
						system_call(SYS_WRITE,STDERR,"\n",1);
						
						if(isAppend){
							code_start((d->d_name)-1);
						}
                        system_call(SYS_WRITE,STDERR,"sysNum: ",8);
                        system_call(SYS_WRITE,STDERR,itoa(SYS_WRITE),1);
                        system_call(SYS_WRITE,STDERR,"\nreturnVal: ",12);
                        system_call(SYS_WRITE,STDERR,itoa(res),1);
                        system_call(SYS_WRITE,STDERR,"\n------------------------------\n",32);
                   
			   }
		   }
		   else{
						res=system_call(SYS_WRITE,STDERR,(d->d_name)-1,strlen(d->d_name)+1); /*print the file name*/
						system_call(SYS_WRITE,STDERR," length:",8);
						system_call(SYS_WRITE,STDERR,(itoa(d->d_reclen))-1,strlen(itoa(d->d_reclen))); /*print the file length*/
						
						system_call(SYS_WRITE,STDERR," type: ",7);
						
						if(d_type==DT_UNKNOWN)
							system_call(SYS_WRITE,STDERR,"unknown\n",8);
							
						else if(d_type==DT_REG)
							system_call(SYS_WRITE,STDERR,"regular file\n",13);
						else if(d_type==DT_DIR)
							system_call(SYS_WRITE,STDERR,"directory\n",10);
						else if(d_type==DT_FIFO)
							system_call(SYS_WRITE,STDERR,"FIFO\n",5);
						 	
						else if(d_type==DT_SOCK)
							system_call(SYS_WRITE,STDERR,"socket\n",7);
							
						else if(d_type==DT_CHR)
							system_call(SYS_WRITE,STDERR,"char device\n",13);
							
						else if(d_type==DT_BLK)
							system_call(SYS_WRITE,STDERR,"block\n",6);	
						
						else if(d_type==DT_LNK)
							system_call(SYS_WRITE,STDERR,"symbolic link\n",14);	
                        
                        system_call(SYS_WRITE,STDERR,"sysNum: ",8);
                        system_call(SYS_WRITE,STDERR,itoa(SYS_WRITE),1);
                        system_call(SYS_WRITE,STDERR,"\nreturnVal: ",12);
                        system_call(SYS_WRITE,STDERR,itoa(res),1);
                        system_call(SYS_WRITE,STDERR,"\n------------------------------\n",32);
						
						system_call(SYS_WRITE,STDERR,"\n",1);
		   }
                   bpos += d->d_reclen;		/*update navigation sign to hold the size of the amount to proceed*/
               }
               system_call(SYS_WRITE,STDERR,"\n------------------------------\n",32);
           }
  
}


	
	/***************************************************************************************************************************/
	void runRegularMode(char* p_pref,int isPrefix,int prefixSize,int isAppend){
	
	 char d_type;
	int fd, nread;		/*file descriptor and amount of readed chars variables*/
	char buf[BUF_SIZE];	/* buffer with max size */
	struct dirent *d;	/*pointer to current file structure*/
	int bpos;			/*navigator sign in buffer*/
         
	fd=system_call(SYS_OPEN,".",O_RDONLY,MODE);
    if (fd < 0)  /* open dir failed */
    { 
        system_call(SYS_WRITE,STDOUT,"Couldn't open current directory.",32); 
        system_call(EXIT,0x55,"\n",1); /*exit with error*/ 
    } 
  
           for ( ; ; ) {
               nread = system_call(GETDENTS, fd, buf, BUF_SIZE);	/*get dir content into buf*/
               if (nread == -1){	/*error occurred*/
                    system_call(SYS_WRITE,STDOUT,"getdents returned error.",32); 
					system_call(EXIT,0x55,"\n",1); /*exit with error*/ 
				}	
               if (nread == 0)		/*nothing left to read*/
                   break;

               
               for (bpos = 0; bpos < nread;) {	/*for each file print it's name*/
                   d = (struct dirent *) (buf + bpos);	/*update location of dirent pointer to the next file structure*/
					d_type = *(buf + bpos + (d->d_reclen)-1);
               if(isPrefix){	/*need to compare prefix*/
				
					if(strncmp(p_pref,(d->d_name)-1,strlen(p_pref))==0){  
						system_call(SYS_WRITE,STDOUT,(d->d_name)-1,strlen(d->d_name)+1); /*print the file name*/
						system_call(SYS_WRITE,STDOUT," type: ",7);
						
						if(d_type==DT_UNKNOWN)
							system_call(SYS_WRITE,STDERR,"unknown\n",8);
							
						else if(d_type==DT_REG)
							system_call(SYS_WRITE,STDERR,"regular file\n",13);
						else if(d_type==DT_DIR)
							system_call(SYS_WRITE,STDERR,"directory\n",10);
						else if(d_type==DT_FIFO)
							system_call(SYS_WRITE,STDERR,"FIFO\n",5);
						 	
						else if(d_type==DT_SOCK)
							system_call(SYS_WRITE,STDERR,"socket\n",7);
							
						else if(d_type==DT_CHR)
							system_call(SYS_WRITE,STDERR,"char device\n",13);
							
						else if(d_type==DT_BLK)
							system_call(SYS_WRITE,STDERR,"block\n",6);	
						
						else if(d_type==DT_LNK)
							system_call(SYS_WRITE,STDERR,"symbolic link\n",14);	
						 	
						system_call(SYS_WRITE,STDOUT,"\n",1);
						
						if(isAppend){
							code_start((d->d_name)-1);
						}
			   }
		   }
		   else{
						system_call(SYS_WRITE,STDOUT,(d->d_name)-1,strlen(d->d_name)+1); /*print the file name*/
						system_call(SYS_WRITE,STDOUT," type: ",7);
						
						if(d_type==DT_UNKNOWN)
							system_call(SYS_WRITE,STDERR,"unknown\n",8);
							
						else if(d_type==DT_REG)
							system_call(SYS_WRITE,STDERR,"regular file\n",13);
						else if(d_type==DT_DIR)
							system_call(SYS_WRITE,STDERR,"directory\n",10);
						else if(d_type==DT_FIFO)
							system_call(SYS_WRITE,STDERR,"FIFO\n",5);
						 	
						else if(d_type==DT_SOCK)
							system_call(SYS_WRITE,STDERR,"socket\n",7);
							
						else if(d_type==DT_CHR)
							system_call(SYS_WRITE,STDERR,"char device\n",13);
							
						else if(d_type==DT_BLK)
							system_call(SYS_WRITE,STDERR,"block\n",6);	
						
						else if(d_type==DT_LNK)
							system_call(SYS_WRITE,STDERR,"symbolic link\n",14);	
							
						system_call(SYS_WRITE,STDOUT,"\n",1);
		   }
                   bpos += d->d_reclen;		/*update navigation sign to hold the size of the amount to proceed*/
               }
           }
 
}
