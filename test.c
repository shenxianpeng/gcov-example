#include <stdio.h>

void test_zero() { printf("test 0 \n"); }

#if 0
int test_skip() {
  printf("this skip \n");
  return 0;
}
#endif
