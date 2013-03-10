#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]){
    FILE *fp;
    if ((fp = fopen(argv[1], "r")) == NULL) {
        printf("Cannot open file.\n");
        exit(1);
    }
    char mers[100][18];
    float counts[100];
    int i = 0;
    while (fscanf(fp, "%s %f", mers[i], &counts[i]) != EOF) {
        printf("%s has count %f\n",mers[i],counts[i]);
        i++;
    }
    return 0;
}
