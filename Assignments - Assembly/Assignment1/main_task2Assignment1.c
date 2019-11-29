#include <stdio.h>


extern void assFunc(int x, int y);


int main() {

    int x,y;
    printf("Please enter 2 numbers: \n");
    scanf("%d %d",&x,&y);

    assFunc(x,y);
    
    return 0;
}
