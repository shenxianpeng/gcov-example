#include <stdio.h>

#include "foo.h"
#include "test.h"
#include "trigger.h"

int main(void) {
  printf("Start calling foo() ...\n");
  foo(1);
  foo(2);
  test_zero();
  trigger_action();
  return 0;
}
