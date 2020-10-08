import std.conv;
import std.datetime.stopwatch;
import std.exception;
import std.range;
import std.stdio;

import httparsed.message;
import http_parser;
import picohttpparser;

immutable string requests = import("requests.txt");
enum REQNUM = 275; // number of requests in the requests.txt
enum LOOPS = 10_000;

void main()
{
    static void writeRes(string name, Duration dur)
    {
        immutable nsecs = dur.total!"nsecs";
        immutable secs = (cast(double)nsecs) / 1_000_000_000;
        enum bytes = requests.length * LOOPS;
        enum totalReq = REQNUM * LOOPS;
        writeln(
            name, ":",
            ' '.repeat(20-name.length).text,
            cast(double)nsecs/totalReq, " ns/req, ",
            cast(double)bytes/secs/1024/1024, " MB/s"
        );
    }

    auto res = benchmark!(
        testHttparsed!Msg,
        testHttparsed!NoopMsg,
        testPicoHttpParser,
        testHttpParser
    )(LOOPS);

    writeRes("httparsed", res[0]);
    writeRes("httparsed - noop", res[1]);
    writeRes("picohttp", res[2]);
    writeRes("http_parser", res[3]);
}

void testHttparsed(M)()
{
    const(char)[] data = requests;
    uint reqNum;
    auto p = initParser!M();
    while (data.length)
    {
        static if (is(M == Msg)) p.msg.m_headersLength = 0;
        immutable res = p.parseRequest(data);
        enforce(res > 0, "Unexpected response: " ~ res.to!string);
        ++reqNum;
        data = data[res..$];
    }
    enforce(reqNum == REQNUM, "Expected " ~ REQNUM.to!string ~ " requests parsed, but got: " ~ reqNum.to!string);
}

void testPicoHttpParser()
{
    const(char)* method;
    size_t method_len;
    const(char)* path;
    size_t path_len;
    int minor_version;
    phr_header[32] headers;
    size_t num_headers;

    const(char)[] data = requests;
    uint reqNum;
    while (data.length)
    {
        num_headers = headers.length;
        immutable ret = phr_parse_request(
            &data[0], data.length,
            &method, &method_len,
            &path, &path_len,
            &minor_version,
            &headers[0], &num_headers,
            0
        );
        enforce(ret > 0, "Unexpected response: " ~ ret.to!string);
        ++reqNum;
        data = data[ret..$];
    }
    enforce(reqNum == REQNUM, "Expected " ~ REQNUM.to!string ~ " requests parsed, but got: " ~ reqNum.to!string);
}

void testHttpParser()
{
    static uint reqNum;

    extern (C)
    static int onComplete(http_parser* p) {
        ++reqNum;
        return 0;
    }

    http_parser parser;
    http_parser_settings settings;
    settings.on_message_complete = &onComplete;

    reqNum = 0;
    const(char)[] data = requests;
    http_parser_init(&parser, http_parser_type.HTTP_REQUEST);
    immutable res = http_parser_execute(&parser, &settings, &data[0], data.length);
    enforce(res == requests.length, "Unexpected response: " ~ res.to!string);
    enforce(reqNum == REQNUM, "Expected " ~ REQNUM.to!string ~ " requests parsed, but got: " ~ reqNum.to!string);
}

struct Header
{
    const(char)[] name;
    const(char)[] value;
}

struct Msg
{
    nothrow @nogc @safe pure:
    void onMethod(const(char)[] method) { this.method = method; }
    void onUri(const(char)[] uri) { this.uri = uri; }
    void onVersion(const(char)[] ver) { this.ver = ver; }
    void onHeader(const(char)[] name, const(char)[] value) { this.m_headers[m_headersLength++] = Header(name, value); }
    void onStatus(int status) { this.status = status; }
    void onStatusMsg(const(char)[] statusMsg) { this.statusMsg = statusMsg; }

    const(char)[] method;
    const(char)[] uri;
    const(char)[] ver;
    int status;
    const(char)[] statusMsg;

    private {
        Header[10] m_headers;
        size_t m_headersLength;
    }

    Header[] headers() return { return m_headers[0..m_headersLength]; }
}

struct NoopMsg {}
