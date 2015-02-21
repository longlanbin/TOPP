SHELL=/bin/bash

EXTRA_FLAGS=-DWITH_OPENRAVE
prefix = /usr/local
target = full
srcdir = .

COMMON_CFLAGS=-Wall -fPIC -std=c++0x $(EXTRA_FLAGS)
COMMON_LIBS=-lboost_python -llapack
INSTALL_PATH=$(prefix)/lib/python2.7/dist-packages/TOPP
SOFILE=TOPPbindings.so

# Standalone
# 
SALONE_PATTERN=src/KinematicLimits.zz src/TOPP.zz src/TorqueLimits.zz src/Trajectory.zz 
SALONE_SOURCE=$(SALONE_PATTERN:.zz=.cpp) src/TOPPbindings.cpp
SALONE_HEADERS=$(SALONE_PATTERN:.zz=.h)
SALONE_OBJECTS=$(SALONE_SOURCE:.cpp=.standalone.o)
SALONE_NDEBUG=-DNDEBUG -DBOOST_UBLAS_NDEBUG
SALONE_INC_PATH=$(shell python-config --includes)
SALONE_CFLAGS=$(COMMON_CFLAGS) $(SALONE_NDEBUG) $(SALONE_INC_PATH)
SALONE_LDFLAGS=$(COMMON_LIBS)
SALONE_CC=g++ $(SALONE_CFLAGS) -O2

# Full 
#
FULL_SOURCE=$(wildcard src/*.cpp)
FULL_HEADERS=$(wildcard src/*.h)
FULL_OBJECTS=$(FULL_SOURCE:.cpp=.full.o)
FULL_NDEBUG=-DNDEBUG -DBOOST_UBLAS_NDEBUG
FULL_INC_PATH=$(shell python-config --includes) $(shell openrave-config --cflags-only-I)
FULL_CFLAGS=$(COMMON_CFLAGS) $(FULL_NDEBUG) $(FULL_INC_PATH)
FULL_SO=$(shell openrave-config --python-dir)/openravepy/_openravepy_/openravepy_int.so
FULL_LDFLAGS=$(COMMON_LIBS) $(FULL_SO) -lopenrave0.9-core 
FULL_CC=g++ $(FULL_CFLAGS) -O2

# Debug
# 
DEBUG_SOURCE=$(FULL_SOURCE)
DEBUG_HEADERS=$(FULL_HEADERS)
DEBUG_OBJECTS=$(DEBUG_SOURCE:.cpp=.debug.o)
DEBUG_CFLAGS=$(COMMON_CFLAGS) $(FULL_INC_PATH)
DEBUG_LDFLAGS=$(FULL_LDFLAGS)
DEBUG_CC=g++ $(DEBUG_CFLAGS) -g


all: $(target)

%.standalone.o: %.cpp $(HEADERS)
	$(SALONE_CC) -c $< -o $@

%.full.o: %.cpp $(HEADERS)
	$(FULL_CC) -c $< -o $@

%.debug.o: %.cpp $(HEADERS)
	$(DEBUG_CC) -c $< -o $@

standalone: $(SALONE_OBJECTS)
	$(SALONE_CC) $(SALONE_OBJECTS) $(SALONE_LDFLAGS) -shared -o $(SOFILE)

full: $(FULL_OBJECTS)
	$(FULL_CC) $(FULL_OBJECTS) $(FULL_LDFLAGS) -shared -o $(SOFILE)

debug: $(DEBUG_OBJECTS)
	$(DEBUG_CC) $(DEBUG_OBJECTS) $(DEBUG_LDFLAGS) -shared -o $(SOFILE)

install:
	rm -rf $(INSTALL_PATH)
	cp -r -f src/python $(INSTALL_PATH)
	cp -f $(SOFILE) $(INSTALL_PATH)/$(SOFILE)

clean:
	find . -name '*.pyc' -delete
	find . -name '*.o' -delete
	find . -name '*~' -delete

distclean: clean
	rm -f $(SOFILE)

help:
	@echo 'Usage:                                                              '
	@echo '                                                                    '
	@echo '    make standalone -- standalone version (no OpenRAVE integration) '
	@echo '    make full -- full version (with OpenRAVE integration)           '
	@echo '                                                                    '
	@echo 'Installation to $(prefix):                                          '
	@echo '                                                                    '
	@echo '    make install                                                    '
	@echo '                                                                    '
	@echo 'Other rules:                                                        '
	@echo '                                                                    '
	@echo '    make debug -- full version with debug symbols                   '
	@echo '    make clean -- clean temporary files                             '
	@echo '    make distclean -- clean all generated files                     '
	@echo '                                                                    '

.PHONY: standalone full debug install clean distclean
