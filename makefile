CC       = gcc
CFLAGS  += -g -rdynamic -Wall -O2
LDFLAGS += -lpthread 

# Testing constants
NO_FILES            = 1
TIME_BETWEEN_FILES  = 0

DEPS = socket.h error.h f5pmisc.h

.PHONY: clean distclean format test

all: f5pd webf5pd f5pl f5pl_realtime
	
f5pd : socket.c f5pd.c error.c $(DEPS)
	$(CC) $(CFLAGS) socket.c f5pd.c error.c $(LDFLAGS) -o $@

webf5pd : socket.c webf5pd.c error.c $(DEPS)
	$(CC) $(CFLAGS) socket.c webf5pd.c error.c $(LDFLAGS) -o $@

f5pl : socket.c f5pl.c error.c $(DEPS)
	$(CC) $(CFLAGS) socket.c f5pl.c error.c $(LDFLAGS) -o $@

f5pl_realtime : socket.c f5pl_realtime.c error.c $(DEPS)
	$(CC) $(CFLAGS) socket.c f5pl_realtime.c error.c $(LDFLAGS) -o $@
	
clean:
	rm -rf f5pd f5pl f5pl_realtime *.o *.out

# Autoformat code with clang format
format:
	./scripts/autoformat.sh	

rsync: all
	make clean
	rsync -rv --delete . rock64@129.94.14.121:~/f5p
	ssh rock64@129.94.14.121 'rsync -rv --delete ~/f5p/* rock1:~/f5p'
