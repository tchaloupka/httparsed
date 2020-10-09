DC = ldc2
DFLAGS += -release -O3 -boundscheck=off -ffast-math -mcpu=native
LIBS = extern/http_parser.o extern/picohttpparser.o extern/llhttp.o extern/api.o extern/http.o
SRC = bench.d ../source/httparsed/message.d ../source/httparsed/intrinsics.d

.PHONY: all
all: bench
	./bench

.PHONY: bench
bench: extern
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
