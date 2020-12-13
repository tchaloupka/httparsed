CFLAGS += -Wall -Wextra -Werror -Wno-unused-parameter -Wno-unused-variable -O3 -march=native
CC?=gcc

all: picohttpparser.o http_parser.o llhttp.o

picohttpparser.o: picohttpparser/picohttpparser.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o picohttpparser.o -c picohttpparser/picohttpparser.c

http_parser.o: http_parser/http_parser.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o http_parser.o -c http_parser/http_parser.c

llhttp.o: llhttp/llhttp.c llhttp/http.o llhttp/api.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o llhttp.o -c llhttp/llhttp.c
	mv llhttp/*.o ./

llhttp/%.o: llhttp/%.c llhttp/llhttp.h llhttp/api.h
	$(CC) $(CFLAGS) $(LDFLAGS) -c $< -o $@

clean:
	find . -type f -name "*.o" -exec rm -f {} \;
