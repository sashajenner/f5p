#include <stdio.h>

int main() {
    printf("ASfasfasfasf\n");
    int ret = 1;
    while (ret>0) {
        /*char *buffer;
        int read;
        unsigned int len;

        read = getline(&buffer, &len, stdin);

        if (-1 != read) {
            puts(buffer);
        } else {
            printf("No line read\n");
        }*/

        int x=0;

        ret=scanf("%d", &x);
        //x = getchar();

        printf("%d\n", x+1);
    }

    return 0;
}
