/* Generic error message routines */

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include "myerror.h"


void error(const char *fmt, ...)
{
	char mesg[BUFSIZ];
	va_list ap;

	va_start(ap, fmt);
	vsnprintf(mesg, sizeof(mesg), fmt, ap);
	fputs(mesg, stderr);
	va_end(ap);
}

void mesg(const char *fmt, ...)
{
	char mesg[BUFSIZ];
	va_list ap;

	va_start(ap, fmt);
	vsnprintf(mesg, sizeof(mesg), fmt, ap);
	fputs(mesg, stdout);
	va_end(ap);
}

void myperror(const char *msg)
{
	char buffer[BUFSIZ];

	if ( *msg ) {
		snprintf(buffer, sizeof(buffer), "%s: %s\n", msg, strerror(errno));
		error("%s", buffer);
	} else
		error("%s", strerror(errno));
}
