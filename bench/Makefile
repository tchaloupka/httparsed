DC = ldc2
DFLAGS += -release -O3 -boundscheck=off -ffast-math -mcpu=native

.PHONY: all
all: bench
	./bench

.PHONY: bench
bench: extern
	$(DC) $(DFLAGS) -of bench bench.d ../source/httparsed/message.d ../source/httparsed/intrinsics.d extern/http_parser.o extern/picohttpparser.o -J .

.PHONY: extern
extern:
	$(MAKE) -C extern

.PHONY: clean
clean:
	$(MAKE) -C extern clean
	rm -f bench
	rm -f *.o
	rm -f *.exe
