
#ifndef _myerror_h
#define _myerror_h

/* Generic error message routines */

#ifdef __cplusplus
extern "C" {
#endif

extern void error(const char *fmt, ...);
extern void mesg(const char *fmt, ...);
extern void myperror(const char *msg);

#ifdef __cplusplus
}
#endif

#endif /* _myerror_h */

