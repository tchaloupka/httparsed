DC = ldc2
DFLAGS += -release -O3 -boundscheck=off -ffast-math -mcpu=native
LIBS = extern/http_parser.o extern/picohttpparser.o extern/llhttp.o extern/api.o extern/http.o
SRC = bench.d ../source/httparsed.d \

# vibe-d deps
SRC += \
	-I .dub/packages/eventcore-0.9.11/eventcore/source \
	-I .dub/packages/mir-core-1.1.54/mir-core/source \
	-I .dub/packages/stdx-allocator-3.1.0-beta.2/stdx-allocator/source \
	-I .dub/packages/taggedalgebraic-0.11.18/taggedalgebraic/source \
	-I .dub/packages/vibe-core-1.10.1/vibe-core/source \
	-I .dub/packages/vibe-d-0.9.2/vibe-d/inet \
	-I .dub/packages/vibe-d-0.9.2/vibe-d/stream \
	-I .dub/packages/vibe-d-0.9.2/vibe-d/utils \
	.dub/packages/vibe-d-0.9.2/vibe-d/inet/libvibe-d_inet.a

.PHONY: all
all: bench
	./bench

.PHONY: bench
bench: extern
	dub fetch mir-core@1.1.54 --cache=local
	dub fetch stdx-allocator@3.1.0-beta.2 --cache=local
	dub fetch taggedalgebraic@0.11.18 --cache=local
	dub fetch eventcore@0.9.11 --cache=local
	dub fetch vibe-core@1.10.1 --cache=local
	dub fetch vibe-d@0.9.2 --cache=local
	dub build -b release --combined --compiler=$(DC) --root .dub/packages/vibe-d-0.9.2/vibe-d :inet
	$(DC) $(DFLAGS) -of bench $(SRC) $(LIBS) -J .

.PHONY: extern
extern:
	$(MAKE) -C extern

.PHONY: clean
clean:
	$(MAKE) -C extern clean
	rm -f bench
	rm -f *.o
	rm -f *.exe
	rm -rf .dub
