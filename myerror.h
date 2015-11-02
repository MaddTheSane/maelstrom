
#ifndef _myerror_h
#define _myerror_h

/* Generic error message routines */

#include <sys/cdefs.h>

#ifdef __cplusplus
extern "C" {
#endif

extern void error(const char *fmt, ...) __printflike(1, 2);
extern void mesg(const char *fmt, ...) __printflike(1, 2);
extern void myperror(const char *msg);

#ifdef __cplusplus
}
#endif

#endif /* _myerror_h */

