import std.algorithm;
import std.conv;
import std.datetime.stopwatch;
import std.exception;
import std.range;
import std.stdio;

import httparsed.message;
import http_parser;
import picohttpparser;
import llhttp;

immutable string requests = import("requests.txt");
enum REQNUM = 275; // number of requests in the requests.txt
enum LOOPS = 100_000;

void main()
{
    static void writeRes(string name, Duration dur)
    {
        immutable nsecs = dur.total!"nsecs";
        immutable secs = (cast(double)nsecs) / 1_000_000_000;
        enum bytes = requests.length * LOOPS;
        enum totalReq = REQNUM * LOOPS;
        writeln(
            name,
            cast(double)nsecs/totalReq, " ns/req, ",
            cast(double)bytes/secs/1024/1024, " MB/s, ",
            cast(size_t)(totalReq / secs), " rps"
        );
    }

    auto res = benchmark!(
        testHttparsed!Msg,
        testHttparsed!NoopMsg,
        testPicoHttpParser,
        testHttpParser,
        testLLHTTP
    )(LOOPS)[].zip(
        ["httparsed", "httparsed (noop)", "picohttp", "http_parser", "llhttp"]
    )
    .array.sort!((a,b) => a[0] < b[0]);

    immutable maxlen = res.maxElement!(a => a[1].length)[1].length;
    foreach (r; res)
        writeRes(
            r[1] ~ ": " ~ ' '.repeat(maxlen - r[1].length).text,
            r[0]
        );
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

void testLLHTTP()
{
    static uint reqNum;

    extern (C)
    static int onLLComplete(llhttp_t* p) {
        ++reqNum;
        return 0;
    }

    llhttp_t parser;
    llhttp_settings_t settings;
    settings.on_message_complete = &onLLComplete;

    reqNum = 0;
    const(char)[] data = requests;
    llhttp_init(&parser, llhttp_type.HTTP_REQUEST, &settings);
    immutable res = llhttp_execute(&parser, &data[0], data.length);
    enforce(res == llhttp_errno.HPE_OK, "Unexpected response: " ~ res.to!string);
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
    void onHeader(const(char)[] name, const(char)[] value)
    {
        this.m_headers[m_headersLength].name = name;
        this.m_headers[m_headersLength++].value = value;
    }
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
