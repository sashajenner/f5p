CC       = gcc
CFLAGS  += -g -rdynamic -Wall -O2
LDFLAGS += -lpthread 

# Testing constants
NO_FILES            = 1
TIME_BETWEEN_FILES  = 0

DEPS = socket.h error.h f5pmisc.h

.PHONY: clean distclean format test

all: f5pd f5pl f5pl_realtime
	
f5pd : socket.c f5pd.c error.c $(DEPS)
	$(CC) $(CFLAGS) socket.c f5pd.c error.c $(LDFLAGS) -o $@

f5pl : socket.c f5pl.c error.c $(DEPS)
	$(CC) $(CFLAGS) socket.c f5pl.c error.c $(LDFLAGS) -o $@

f5pl_realtime : socket.c f5pl_realtime.c error.c $(DEPS)
	$(CC) $(CFLAGS) socket.c f5pl_realtime.c error.c $(LDFLAGS) -o $@
	
clean:
	rm -rf f5pd f5pl f5pl_realtime *.o *.out

# Autoformat code with clang format
format:
	./scripts/autoformat.sh	

test: all
	# execute simulator in the background giving time for monitor to set up
	(sleep 10; bash testing/simulator.sh ../../../scratch_nas/778/778-1500ng/778-1500ng_albacore-2.1.3/ testing/simulator_out $(TIME_BETWEEN_FILES) $(NO_FILES)) &
	# monitor the new file creation in fast5 folder and execute realtime f5 pipeline
	bash monitor/monitor.sh -n $(NO_FILES) testing/simulator_out/fast5/ | /usr/bin/time -v ./f5pl_realtime data/ip_list.cfg
	pkill inotifywait
		
rsync: all
	make clean
	rsync -rv --delete . rock64@129.94.14.121:~/f5p
	ssh rock64@129.94.14.121 'rsync -rv --delete ~/f5p/* rock1:~/f5p'
