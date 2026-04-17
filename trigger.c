#include <stdio.h>

#include "trigger.h"

void trigger_action(void) {
#ifdef TRIGGER_ON
  printf("TRIGGER is ON: running extra logic...\n");
#else
  printf("TRIGGER is OFF: running default logic...\n");
#endif
}
