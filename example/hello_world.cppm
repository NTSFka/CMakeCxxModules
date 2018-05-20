#include <stdio.h>

export module hello;

export void greeter(const char *name)
{
    printf("Hello %s!\n", name);
}
