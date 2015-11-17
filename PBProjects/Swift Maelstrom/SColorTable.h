//
//  SColorTable.h
//  Maelstrom
//
//  Created by C.W. Betts on 11/16/15.
//
//

#ifndef SColorTable_h
#define SColorTable_h

#include <SDL_pixels.h>

#define MAX_GAMMA	8L

const SDL_Color *colorsAtGamma(int gamma);

#endif /* SColorTable_h */
