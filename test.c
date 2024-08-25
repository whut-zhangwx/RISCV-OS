#include <stdio.h>

void hello() {
    printf("hello, world!\n");
}

int main() {
    char s[] = {'h', 'e', 'l', 'l', 'o', '\0'};
    printf("%s\n", s);
    
    return 0;
}

// gcc test.c -o test.out && ./test.out