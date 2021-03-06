CFLAGS := $(shell pkg-config lua --cflags)
CFLAGS += -Isrc -fmax-errors=1 -Wall -Werror
CFLAGS += -O3 -finline-functions -fPIC
LDLIBS := $(shell pkg-config lua --libs)
LDLIBS += -lprotobuf -lpthread

LUA_VERSION	:= $(shell lua -e "_,_,v=string.find(_VERSION,'Lua (.+)');print(v)")
ifndef LUA_VERSION
  LUA_VERSION := 5.3
endif
LUA_LIBDIR := /usr/lib/lua/$(LUA_VERSION)

LUA_PROTOBUF_PATH ?= .
PROTOS := $(wildcard $(LUA_PROTOBUF_PATH)/*.proto)
PBSOURCES := $(patsubst $(LUA_PROTOBUF_PATH)/%.proto, src/%.pb.cc, $(PROTOS))
SOURCES := $(filter-out $(wildcard src/*.pb.cc), $(wildcard src/*.cc))
OBJECTS := $(patsubst %.cc, %.o, $(SOURCES) $(PBSOURCES))

ifdef LUA_PROTOBUF_SUFFIX
  CFLAGS += -DSUFFIX=_$(LUA_PROTOBUF_SUFFIX)
  OUTFILE := protobuf_$(LUA_PROTOBUF_SUFFIX).so
else
  OUTFILE := protobuf.so
endif

ifdef LUA_PROTOBUF_ENUM_AS_NUMBER
  CFLAGS += -DENUM_AS_NUMBER
endif

$(OUTFILE): $(OBJECTS)
	g++ -shared -o $(OUTFILE) $(OBJECTS) $(LDLIBS)

$(OBJECTS): src/%.o: src/%.cc | $(PBSOURCES)
	g++ $(CFLAGS) -c $< -o $@

$(PBSOURCES): src/%.pb.cc: $(LUA_PROTOBUF_PATH)/%.proto
	protoc --cpp_out=src --proto_path=$(LUA_PROTOBUF_PATH) $<

install:
	mkdir -p $(LUA_LIBDIR)
	cp $(OUTFILE) $(LUA_LIBDIR)

uninstall:
	rm -f $(LUA_LIBDIR)/$(OUTFILE)

clean:
	rm -f *.so src/*.o src/*.pb.*
