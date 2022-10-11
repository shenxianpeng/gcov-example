#include <stdio.h>

void foo(int num) {
  if (num == 1) {
    printf("when num is equal to 1...\n");
  } else if (num == 2) {
    printf("when num is equal to 2...\n");
  } else {
    printf("when num is equal to %d...\n", num);
  }
}
