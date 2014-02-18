
#ifndef _load_h
#define _load_h

#include "screenlib/SDL_FrameBuf.h"
#include <string>

class DataDir {
  /* TODO:
   * Build a list of directories to look in.
   * In this way gamecontent can be overlayed.
   */
private:
	std::string path;
	int len;

public:
	DataDir();

	const char *FullPath(std::string filename);
	SDL_RWops *Open(std::string filename);
};

/* Functions exported from load.cc */
extern SDL_Surface *Load_Icon(char **xpm);
extern SDL_Surface *Load_Title(FrameBuf *screen, int title_id);
extern SDL_Surface *GetCIcon(FrameBuf *screen, short cicn_id);

#endif /* _load_h */
