
#ifndef __maelstrom_fastrand_h_
#define __maelstrom_fastrand_h_

/* Declarations for the fast random functions */

#include <SDL_types.h>

#ifdef __cplusplus
extern "C" {
#endif

extern void   SeedRandom(Uint32 seed);
extern Uint16 FastRandom(Uint16 range);
extern Uint32 GetRandSeed(void);

#ifdef __cplusplus
}
#endif
	
#endif
