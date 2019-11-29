#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <elf.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#define MAX 100
int debug_mode = 0;
char buffer[MAX];
int Currentfd = -1;
void *map_start; /* will point to the start of the memory mapped file */
struct stat fd_stat; /* this is needed to  the size of the file */
Elf32_Ehdr *header; /* this will point to the header structure */


struct fun_desc {
  char *name;
  void (*fun)();
};

void ToggleDebugMode() {
	if(debug_mode) {
		debug_mode = 0;
		fprintf(stdout, "%s\n", "Debug flag now off");
	}
	else {
		debug_mode = 1;
		fprintf(stdout, "%s\n", "Debug flag now on");
	}
}

char *getEncoding(unsigned char i);

char *getType(Elf32_Word type);

void ExamineELFFile() {
	char * filename;
	int i;
	fprintf(stdout, "%s\n", "Enter filename:");
	fgets(buffer, MAX, stdin);
    if (Currentfd != -1) {
        munmap(map_start, fd_stat.st_size);
        close(Currentfd);
    }
	for(i = 0; i < MAX; i++) {
		if(buffer[i] == '\n') {
			buffer[i] = '\0';
		}
	}
	filename = buffer;
	if( (Currentfd = open(filename, O_RDWR)) < 0 ) {
      perror("error in open");
      exit(-1);
   }
   if( fstat(Currentfd, &fd_stat) != 0 ) {
      perror("stat failed");
      exit(-1);
   }

   if ( (map_start = mmap(0, fd_stat.st_size, PROT_READ | PROT_WRITE , MAP_SHARED, Currentfd, 0)) == MAP_FAILED ) {
      perror("mmap failed");
      exit(-4);
   }

   /* now, the file is mapped starting at map_start.
    * all we need to do is tell *header to point at the same address:
    */

   header = (Elf32_Ehdr *) map_start;
   /* now we can do whatever we want with header!!!!
    * for example, the number of section hea
    der can be obtained like this:
    */
   fprintf(stdout, "%s %c %c %c\n", "bytes of magicmagic number:", header->e_ident[1], header->e_ident[2], header->e_ident[3]);
   fprintf(stdout, "%s %x\n", "Entry point:", header->e_entry);
   fprintf(stdout, "%s %s\n", "Encoding:", getEncoding(header->e_ident[EI_DATA]));
   fprintf(stdout, "%s %d\n", "The number of section header entries:", header->e_shnum);
	fprintf(stdout, "%s %d\n", "The size of each section header entry:", header->e_shentsize);
	fprintf(stdout, "%s %d\n", "The file offset in which the program header table resides:", header->e_phoff);
	fprintf(stdout, "%s %d\n", "The number of program header entries:", header->e_phnum);
	fprintf(stdout, "%s %d\n", "The size of each program header entry:", header->e_phentsize);
	if(debug_mode) {
		fprintf(stdout, "%s%s\n", "filename is: ", buffer);
	}
 }

void PrintSectionNames() {
    if (Currentfd == -1) {
        fprintf(stdout, "No open file\n");
        return;
    }
    int i;
    Elf32_Shdr *shdr = (Elf32_Shdr *)(map_start + header->e_shoff);
    int shnum = header->e_shnum;
    char* stringHeaderTable = map_start + (shdr +  header->e_shstrndx)->sh_offset;
    fprintf(stdout, "%-20s %-20s %-20s %-20s %-20s %-20s\n", "[index]", "section_name", "section_address" ,"section_offset" ,"section_size"  ,"section_type");
    for (i = 0; i < shnum; i++) {        
        fprintf(stdout, "%-20d %-20s %-20x %-20x %-20x %-20s\n", i, stringHeaderTable + shdr[i].sh_name, shdr[i].sh_addr, shdr[i].sh_offset, shdr[i].sh_size,getType(shdr[i].sh_type));
    }
}

char *getType(Elf32_Word type) {
    if (type == SHT_NULL) {
        return "SHT_NULL";
    }
    else if (type == SHT_PROGBITS) {
        return "SHT_NULL";
    }
    else if (type == SHT_SYMTAB) {
        return "SHT_SYMTAB";
    }
    else if (type == SHT_STRTAB) {
        return "SHT_STRTAB";
    }
    else if (type == SHT_RELA) {
        return "SHT_RELA";
    }
    else if (type == SHT_HASH) {
        return "SHT_HASH";
    }
    else if (type == SHT_DYNAMIC) {
        return "SHT_DYNAMIC";
    }
    else if (type == SHT_NOTE) {
        return "SHT_NOTE";
    }
    else if (type == SHT_NOBITS) {
        return "SHT_NOBITS";
    }
    else if (type == SHT_REL) {
        return "SHT_REL";
    }
    else if (type == SHT_SHLIB) {
        return "SHT_SHLIB";
    }
    else if (type == SHT_DYNSYM) {
        return "SHT_DYNSYM";
    }
    else if (type == SHT_FINI_ARRAY) {
        return "SHT_FINI_ARRAY";
    }
    else if (type == SHT_PREINIT_ARRAY) {
        return "SHT_PREINIT_ARRAY";
    }
    else if (type == SHT_GROUP) {
        return "SHT_GROUP";
    }
    else if (type == SHT_SYMTAB_SHNDX) {
        return "SHT_SYMTAB_SHNDX";
    }
    else if (type == SHT_NUM) {
        return "SHT_NUM";
    }
    else if (type == SHT_LOOS) {
        return "SHT_LOOS";
    }
    else if (type == SHT_GNU_HASH) {
        return "SHT_GNU_HASH";
    }
   else if (type == SHT_GNU_LIBLIST) {
       return "SHT_GNU_LIBLIST";
   }
   else if (type == SHT_CHECKSUM) {
       return "SHT_CHECKSUM";
   }
   else if (type == SHT_LOSUNW) {
       return "SHT_LOSUNW";
   }
   else if (type == SHT_SUNW_move) {
       return "SHT_SUNW_move";
   }
   else if (type == SHT_SUNW_COMDAT) {
       return "SHT_SUNW_COMDAT";
   }
   else if (type == SHT_SUNW_syminfo) {
       return "SHT_SUNW_syminfo";
   }
   else if (type == SHT_GNU_verdef) {
       return "SHT_GNU_verdef";
   }
   else if (type == SHT_GNU_verneed) {
       return "SHT_GNU_verneed";
   }
   else if (type == SHT_GNU_versym) {
       return "SHT_GNU_versym";
   }
   else if (type == SHT_HISUNW) {
       return "SHT_HISUNW";
   }
   else if (type == SHT_HIOS) {
       return "SHT_HIOS";
   }
   else if (type == SHT_LOPROC) {
       return "SHT_LOPROC";
   }
   else if (type == SHT_HIPROC) {
       return "SHT_HIPROC";
   }
   else if (type == SHT_LOUSER) {
       return "SHT_LOUSER";
   }
   else if (type == SHT_HIUSER) {
       return "SHT_HIUSER";
   }
    return "";
}
char *getEncoding(unsigned char i) {
	if (i == 1) {
		return "2's complement, little endian";
	}
	else if (i == 2) {
		return "2's complement, big endian";
	}
	else {
		return "Invalid";
	}
}

void quit() {
	if (debug_mode) {
		fprintf(stdout, "%s\n", "quitting");
	}
	munmap(map_start, fd_stat.st_size);
	exit(0);
}

void PrintSymbols() {
    if (Currentfd == -1) {
        fprintf(stdout, "No open file\n");
        return;
    }
    int i, dyn_size, dyn_entsize,k;
    int dyn_count = 0;
    char * section_name;
    char* stringTable;
    char * stringTableDyn;
    char * name;
    Elf32_Shdr *shdr = (Elf32_Shdr *)(map_start + header->e_shoff);
    char* stringHeaderTable = map_start + (shdr +  header->e_shstrndx)->sh_offset;
    Elf32_Sym * dyntab;
    for (i = 0; i < header->e_shnum; i++) {
        section_name = stringHeaderTable + shdr[i].sh_name;
        if (strcmp(section_name, ".strtab") == 0) {
            stringTable = map_start + shdr[i].sh_offset;
        }
        else if (strcmp(section_name, ".dynstr") == 0) {
            stringTableDyn = map_start + shdr[i].sh_offset;
        }
    }
    for (k = 0; k < header->e_shnum; k++) { 
        if (shdr[k].sh_type == SHT_SYMTAB || shdr[k].sh_type == SHT_DYNSYM) {
            section_name = stringHeaderTable + shdr[k].sh_name;
            dyntab = (Elf32_Sym *)((char *)map_start + shdr[k].sh_offset);
            dyn_size = shdr[k].sh_size;
            dyn_entsize = shdr[k].sh_entsize;
            dyn_count = dyn_size/ dyn_entsize;
            fprintf(stdout, "table name: %s\n", section_name);
            if (debug_mode) {
                fprintf(stdout, "table size: %d\tnum of entries: %d\n", dyn_size, dyn_count);
            }
            fprintf(stdout, "%-20s %-20s %-20s %-20s %-20s\n", "[index]" ,"value", "section_index" ,"section_name" ,"symbol_name");
            for (i = 0; i < dyn_count; i++) {
                int j = dyntab[i].st_shndx;
                if (j == 65521) {
                    section_name = "ABS";
                }
                else {
                    section_name = stringHeaderTable + shdr[j].sh_name;
                }
                if (shdr[k].sh_type == SHT_SYMTAB) {
                    name = stringTable + dyntab[i].st_name;
                }
                else {
                    name = stringTableDyn + dyntab[i].st_name;
                }
                if (strcmp(section_name, ".dynstr"))
                fprintf(stdout, "%-20d %-20x %-20d %-20s %-20s\n", i, dyntab[i].st_value, dyntab[i].st_shndx, section_name, name);
            }
        }
    }
}

struct fun_desc initmenu[] = { { "Toggle Debug Mode", ToggleDebugMode }, { "Examine ELF File", ExamineELFFile },
                               { "Print Section Names", PrintSectionNames },{ "Print Symbols", PrintSymbols },
                               { "Quit", quit }, { NULL, NULL } };

int main(int argc, char **argv){
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
		if (option >= 0 && option <= 4) {
			(menu[option].fun)();
		}
		else {
			fprintf(stdout, "%s\n", "Not within bounds");
            quit();	
		}
		fprintf(stdout, "%s\n\n", "DONE.");
	}
}
