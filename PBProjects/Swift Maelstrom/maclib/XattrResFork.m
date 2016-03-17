//
//  XattrResFork.m
//  Maelstrom
//
//  Created by C.W. Betts on 11/19/15.
//
//

#import "XattrResFork.h"
#include <sys/xattr.h>

typedef struct  {
	ssize_t pos;
	char *buffer;
	size_t size;
} fmem;

static int readfn(void * handler, char *buf, int size)
{
	fmem *mem = handler;
	size_t available = mem->size - mem->pos;
	
	if (size > available) {
		size = (int)available;
	}
	memcpy(buf, mem->buffer + mem->pos, sizeof(char) * size);
	mem->pos += size;
	
	return size;
}

static fpos_t seekfn(void *handler, fpos_t offset, int whence)
{
	size_t pos;
	fmem *mem = handler;
	
	switch (whence) {
		case SEEK_SET: {
			if (offset >= 0) {
				pos = (size_t)offset;
			} else {
				pos = 0;
			}
			break;
		}
		case SEEK_CUR: {
			if (offset >= 0 || (size_t)(-offset) <= mem->pos) {
				pos = mem->pos + (size_t)offset;
			} else {
				pos = 0;
			}
			break;
		}
		case SEEK_END: pos = mem->size + (size_t)offset; break;
		default: return -1;
	}
	
	if (pos > mem->size) {
		return -1;
	}
	
	mem->pos = pos;
	return (fpos_t)pos;
}

static int closefn(void *handler)
{
	fmem *f = handler;
	free(f->buffer);
	free(f);
	
	return 0;
}

FILE *fileFromResourceFork(NSURL *url)
{
	const char* fsr = url.absoluteURL.fileSystemRepresentation;
	ssize_t rsrcSize = getxattr(fsr, XATTR_RESOURCEFORK_NAME, NULL, 0, 0, 0);
	if (rsrcSize <= 0) {
		return NULL;
	}
	NSMutableData *mutData = [[NSMutableData alloc] initWithLength:rsrcSize];
	ssize_t gotBytes = getxattr(fsr, XATTR_RESOURCEFORK_NAME, mutData.mutableBytes, mutData.length, 0, 0);
	if (gotBytes == -1) {
		return NULL;
	}
	
	NSCAssert(rsrcSize == gotBytes, @"Different sizes?");
	
	char *bytes = malloc(mutData.length);
	[mutData getBytes:bytes length:mutData.length];
	
	fmem *aMem = malloc(sizeof(fmem));
	
	aMem->buffer = bytes;
	aMem->size = mutData.length;
	aMem->pos = 0;
	
	return funopen(aMem, readfn, NULL, seekfn, closefn);
}
