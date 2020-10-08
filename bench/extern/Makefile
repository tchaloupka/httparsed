CFLAGS += -Wall -Wextra -Werror -O3 -march=native
CC?=gcc

all: picohttpparser.o http_parser.o

picohttpparser.o: picohttpparser.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o picohttpparser.o -c picohttpparser.c

http_parser.o: http_parser.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o http_parser.o -c http_parser.c

clean:
	rm -f *.o
