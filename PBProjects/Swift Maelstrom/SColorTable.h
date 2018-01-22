//
//  SColorTable.h
//  Maelstrom
//
//  Created by C.W. Betts on 11/16/15.
//
//

#ifndef SColorTable_h
#define SColorTable_h

#include <SDL2/SDL_pixels.h>

#define MAX_GAMMA	8L

const SDL_Color * _Nonnull colorsAtGamma(unsigned char gamma) __attribute__((swift_private));

#endif /* SColorTable_h */
