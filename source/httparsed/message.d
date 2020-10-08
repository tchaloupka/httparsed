module httparsed.message;

import httparsed.intrinsics;
import std.algorithm : among;
import std.format : format;

nothrow @safe @nogc:

enum Error : int
{
    partial = 1,    /// not enough data to parse message
    newLine,        /// invalid character in new line
    headerName,     /// invalid character in header name
    status,         /// invalid character in response status
    token,          /// invalid character in token
    noHeaderName,   /// empty header name
    noMethod,       /// no method in request line
    noVersion,      /// no version in request line / response status line
    noUri,          /// no URI in request line
    invalidVersion, /// invalid version for the protocol message
}

/// Helper function to initialize message parser
auto initParser(Parser, Args...)(Args args) { return MsgParser!Parser(args); }

/++
    HTTP/RTSP message parser.
+/
struct MsgParser(Parser)
{
    import std.traits : ForeachType, isArray, Unqual;
    import std.string : representation;

    this(Args...)(Args args)
    {
        this.msg = Parser(args);
    }

    auto parseRequest(T)(T buffer, ref uint lastPos)
        if (isArray!T && (is(Unqual!(ForeachType!T) == char) || is(Unqual!(ForeachType!T) == ubyte)))
    {
        static if (is(Unqual!(ForeachType!T) == char)) return parse!parseRequestLine(buffer.representation, lastPos);
        else return parse!parseRequestLine(buffer, lastPos);
    }

    auto parseRequest(T)(T buffer)
        if (isArray!T && (is(Unqual!(ForeachType!T) == char) || is(Unqual!(ForeachType!T) == ubyte)))
    {
        uint lastPos;
        static if (is(Unqual!(ForeachType!T) == char)) return parse!parseRequestLine(buffer.representation, lastPos);
        else return parse!parseRequestLine(buffer, lastPos);
    }

    auto parseResponse(T)(T buffer, ref uint lastPos)
        if (isArray!T && (is(Unqual!(ForeachType!T) == char) || is(Unqual!(ForeachType!T) == ubyte)))
    {
        static if (is(Unqual!(ForeachType!T) == char)) return parse!parseStatusLine(buffer.representation, lastPos);
        else return parse!parseStatusLine(buffer, lastPos);
    }

    auto parseResponse(T)(T buffer)
        if (isArray!T && (is(Unqual!(ForeachType!T) == char) || is(Unqual!(ForeachType!T) == ubyte)))
    {
        uint lastPos;
        static if (is(Unqual!(ForeachType!T) == char)) return parse!parseStatusLine(buffer.representation, lastPos);
        else return parse!parseStatusLine(buffer, lastPos);
    }

    ref Parser msg() return { return m_msg; }

private:

    Parser m_msg;

    int parse(alias pred)(const(ubyte)[] buffer, ref uint lastPos)
    {
        assert(buffer.length >= lastPos);
        immutable l = buffer.length;

        if (_expect(!lastPos, true))
        {
            if (_expect(!buffer.length, false)) return err(Error.partial);

            // skip first empty line (some clients add CRLF after POST content)
            if (_expect(buffer[0] == '\r', false))
            {
                if (_expect(buffer.length == 1, false)) return err(Error.partial);
                if (_expect(buffer[1] != '\n', false)) return err(Error.newLine);
                lastPos += 2;
                buffer = buffer[lastPos..$];
            }
            else if (_expect(buffer[0] == '\n', false))
                buffer = buffer[++lastPos..$];

            immutable res = pred(buffer);
            if (_expect(res < 0, false)) return res;

            lastPos = cast(int)(l - buffer.length); // store index of last parsed line
        }
        else buffer = buffer[lastPos..$]; // skip already parsed lines

        immutable hdrRes = parseHeaders(buffer);
        lastPos = cast(int)(l - buffer.length); // store index of last parsed line

        if (_expect(hdrRes < 0, false)) return hdrRes;
        return lastPos; // finished
    }

    int parseHeaders(ref const(ubyte)[] buffer)
    {
        static immutable bool[256] validCharsMap = buildHeaderNameValidCharMap();

        bool hasHeader;
        size_t start, i;
        const(ubyte)[] name, value;
        while (true)
        {
            assert(i == 0);
            if (_expect(buffer.length == 0, false)) return err(Error.partial);
            if (buffer[0] == '\r')
            {
                if (_expect(buffer.length == 1, false)) return err(Error.partial);
                if (_expect(buffer[1] != '\n', false)) return err(Error.newLine);

                buffer = buffer[2..$];
                return 0;
            }
            if (_expect(buffer[0] == '\n', false))
            {
                buffer = buffer[1..$];
                return 0;
            }

            if (!hasHeader || !buffer[i].among(' ', '\t'))
            {
                // read header name
                while (true)
                {
                    if (i+1 == buffer.length) return err(Error.partial);
                    if (buffer[i] == ':') break;
                    if (!validCharsMap[buffer[i]]) return err(Error.headerName);
                    ++i;
                }
                if (start == i) return err(Error.noHeaderName);
                name = buffer[start..i]; // store header name
                start = i = i+1; // move indexes after colon
                while (true) // skip over SP and tabs
                {
                    if (i+1 >= buffer.length) return err(Error.partial); // not enough data (>= because of increment above)
                    if (!buffer[i].among(' ', '\t')) break;
                    start = i = i+1;
                }
            }
            else name = null; // multiline header

            // parse value
            mixin(readTokenToEol!("value = buffer[start..i];", true, [' ', '\t']));

            hasHeader = true; // flag to define that we can now accept multiline header values
            static if (__traits(hasMember, m_msg, "onHeader"))
            {
                import std.algorithm : stripRight;
                value = value.stripRight!(a => a == '\t' || a == ' '); // remove trailing SPs and HTABs
                static if (is(typeof(m_msg.onHeader("", "")) == void))
                    m_msg.onHeader(cast(const(char)[])name, cast(const(char)[])value);
                else {
                    auto r = m_msg.onHeader(cast(const(char)[])name, cast(const(char)[])value);
                    if (r < 0) return r;
                }
            }

            // header line completed -> advance buffer
            buffer = buffer[i..$];
            start = i = 0;
        }
    }

    auto parseRequestLine(ref const(ubyte)[] buffer)
    {
        size_t start, i;
        mixin(readToken!false);
        if (_expect(start == i, false)) return err(Error.noMethod);
        static if (__traits(hasMember, m_msg, "onMethod"))
        {
            static if (is(typeof(m_msg.onMethod("")) == void))
                m_msg.onMethod(cast(const(char)[])buffer[start..i]);
            else {
                auto r = m_msg.onMethod(cast(const(char)[])buffer[start..i]);
                if (r < 0) return r;
            }
        }
        start = i = i+1; // skip SP

        mixin(readToken!true);
        if (_expect(start == i, false)) return err(Error.noUri);
        static if (__traits(hasMember, m_msg, "onUri"))
        {
            static if (is(typeof(m_msg.onUri("")) == void))
                m_msg.onUri(cast(const(char)[])buffer[start..i]);
            else {
                auto ur = m_msg.onUri(cast(const(char)[])buffer[start..i]);
                if (ur < 0) return ur;
            }
        }
        start = i = i+1; // skip SP

        mixin(readTokenToEol!(q{
            if (_expect(start == i, false)) return err(Error.noVersion);
            static if (__traits(hasMember, m_msg, "onVersion"))
            {
                static if (is(typeof(m_msg.onVersion("")) == void))
                    m_msg.onVersion(cast(const(char)[])buffer[start..i]);
                else {
                    auto vr = m_msg.onVersion(cast(const(char)[])buffer[start..i]);
                    if (vr < 0) return vr;
                }
            }
        }, false));

        // advance buffer after the request line
        buffer = buffer[i..$];
        return 0;
    }

    auto parseStatusLine(ref const(ubyte)[] buffer)
    {
        size_t start, i;
        mixin(readToken!false);
        if (_expect(start == i, false)) return err(Error.noVersion);
        static if (__traits(hasMember, m_msg, "onVersion"))
        {
            static if (is(typeof(m_msg.onVersion("")) == void))
                m_msg.onVersion(cast(const(char)[])buffer[start..i]);
            else {
                auto r = m_msg.onVersion(cast(const(char)[])buffer[start..i]);
                if (r < 0) return r;
            }
        }
        start = i = i+1; // skip SP

        if (_expect(i+3 >= buffer.length, false)) return err(Error.partial); // not enough data - we want at least [:digit:][:digit:][:digit:]<other char> to try to parse
        int code;
        foreach (j, m; [100, 10, 1])
        {
            if (buffer[i+j] < '0' || buffer[i+j] > '9') return err(Error.status);
            code += (buffer[start+j] - '0') * m;
        }
        start = i = i + 3; // keep the SP or other character (to check invalid character later)
        static if (__traits(hasMember, m_msg, "onStatus"))
        {
            static if (is(typeof(m_msg.onStatus(code)) == void))
                m_msg.onStatus(code);
            else {
                auto sr = m_msg.onStatus(code);
                if (sr < 0) return sr;
            }
        }

        mixin(readTokenToEol!(q{
            if (start == i) {/*ok*/}
            else if (buffer[start] == ' ') ++start;
            else return err(Error.status); // Garbage after status
            static if (__traits(hasMember, m_msg, "onStatusMsg"))
            {
                if (start != i)
                {
                    static if (is(typeof(m_msg.onStatusMsg("")) == void))
                        m_msg.onStatusMsg(cast(const(char)[])buffer[start..i]);
                    else {
                        auto smr = m_msg.onStatusMsg(cast(const(char)[])buffer[start..i]);
                        if (smr < 0) return smr;
                    }
                }
            }
        }, false));

        // advance buffer after the status line
        buffer = buffer[i..$];
        return 0;
    }

    // advances buffer index to next SP
    // extended is used to switch between 7bit ASCII or 8bit extended ascii as valid chars
    template readToken(bool extended)
    {
        enum readToken = format!(q{
            while (true)
            {
                if (_expect(i == buffer.length, false)) return err(Error.partial);
                if (buffer[i] == ' ') break;
                if (_expect(!isPrintableAscii!%s(buffer[i]), false)) return err(Error.token);
                ++i;
            }
        })(extended ? "true" : "false");
    }

    // advances buffer index to end of line
    // handles token value with provided code snipet (using %s as placeholder for the actual value)
    // consumes the eol chars too
    template readTokenToEol(string handler, bool extended, char[] exceptions = null)
    {
        import std.algorithm : map, joiner;
        import std.conv : text, to;

        enum readTokenToEol = format!q{
            while (true)
            {
                if (_expect(i == buffer.length, false)) return err(Error.partial);
                if (!isPrintableAscii!%s(buffer[i])%s)
                {
                    if (buffer[i] == '\r')
                    {
                        %s
                        if (i+1 == buffer.length) return err(Error.partial);
                        else if (buffer[i+1] != '\n') return err(Error.newLine);
                        i+=2;
                        break;
                    }
                    if (buffer[i] == '\n')
                    {
                        %s
                        ++i;
                        break;
                    }
                    return err(Error.token);
                }
                ++i;
            }
        }(
            extended ? "true" : "false",
            exceptions is null ? "" : ("&& " ~ exceptions.map!(`"buffer[i] != " ~ (cast(ubyte)a).to!string`).joiner(" && ").text), // see https://issues.dlang.org/show_bug.cgi?id=17547
            handler, handler
        );
    }
}

private int err(Error e) { pragma(inline, true); return -(cast(int)e); }

private bool isPrintableAscii(bool extended)(ubyte c) pure
{
    pragma(inline, true);
    static if (extended) return c >= 0x80 || cast(ubyte)(c - 0x20u) < 0x5fu;
    else return cast(ubyte)(c - 0x20u) < 0x5fu;
}

bool[256] buildHeaderNameValidCharMap()()
{
    bool[256] res;
    foreach (i; 0..256)
    {
        ubyte ch = cast(ubyte)i;
        switch (ch)
        {
            case '\0': ..case ' ':   /* control chars and up to SP */
            case '"':                /* 0x22 */
            case '(': ..case ')':    /* 0x28,0x29 */
            case ',':                /* 0x2c */
            case '/':                /* 0x2f */
            case ':': ..case '@':    /* 0x3a-0x40 */
            case '[': ..case ']':    /* 0x5b-0x5d */
            case '{': ..case '\377': /* 0x7b-0xff */
                continue;
            default: res[i] = true; break;
        }
    }

    return res;
}

version (unittest)
{
    struct Header
    {
        const(char)[] name;
        const(char)[] value;
    }

    struct Msg
    {
        nothrow @nogc:
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

    enum Test { err, complete, partial }

    void writeln(Args...)(Args args) nothrow
    {
        import std.stdio : w = writeln;
        try w(args); catch (Exception ex){}
    }
}

// Tests from https://github.com/h2o/picohttpparser/blob/master/test.c

@("Request")
unittest
{
    auto parse(string data, Test test = Test.complete, int additional = 0) @safe nothrow @nogc
    {
        auto parser = initParser!Msg();
        auto res = parser.parseRequest(data);
        final switch (test)
        {
            case Test.err: assert(res < -Error.partial); break;
            case Test.partial: assert(res == -Error.partial); break;
            case Test.complete: assert(res == data.length - additional); break;
        }

        return parser.msg;
    }

    // simple
    {
        auto req = parse("GET / HTTP/1.0\r\n\r\n");
        assert(req.headers.length == 0);
        assert(req.method == "GET");
        assert(req.uri == "/");
        assert(req.ver == "HTTP/1.0");
    }

    // parse headers
    {
        auto req = parse("GET /hoge HTTP/1.1\r\nHost: example.com\r\nCookie: \r\n\r\n");
        assert(req.method == "GET");
        assert(req.uri == "/hoge");
        assert(req.ver == "HTTP/1.1");
        assert(req.headers.length == 2);
        assert(req.headers[0] == Header("Host", "example.com"));
        assert(req.headers[1] == Header("Cookie", ""));
    }

    // multibyte included
    {
        auto req = parse("GET /hoge HTTP/1.1\r\nHost: example.com\r\nUser-Agent: \343\201\262\343/1.0\r\n\r\n");
        assert(req.method == "GET");
        assert(req.uri == "/hoge");
        assert(req.ver == "HTTP/1.1");
        assert(req.headers.length == 2);
        assert(req.headers[0] == Header("Host", "example.com"));
        assert(req.headers[1] == Header("User-Agent", "\343\201\262\343/1.0"));
    }

    //multiline
    {
        auto req = parse("GET / HTTP/1.0\r\nfoo: \r\nfoo: b\r\n  \tc\r\n\r\n");
        assert(req.method == "GET");
        assert(req.uri == "/");
        assert(req.ver == "HTTP/1.0");
        assert(req.headers.length == 3);
        assert(req.headers[0] == Header("foo", ""));
        assert(req.headers[1] == Header("foo", "b"));
        assert(req.headers[2] == Header(null, "  \tc"));
    }

    // header name with trailing space
    parse("GET / HTTP/1.0\r\nfoo : ab\r\n\r\n", Test.err);

    // incomplete
    assert(parse("\r", Test.partial).method == null);
    assert(parse("\r\n", Test.partial).method == null);
    assert(parse("\r\nGET", Test.partial).method == null);
    assert(parse("GET", Test.partial).method == null);
    assert(parse("GET ", Test.partial).method == "GET");
    assert(parse("GET /", Test.partial).uri == null);
    assert(parse("GET / ", Test.partial).uri == "/");
    assert(parse("GET / foo", Test.partial).ver == null);
    assert(parse("GET / foo\r", Test.partial).ver == "foo");
    assert(parse("GET / foo\r\n", Test.partial).ver == "foo");
    parse("GET / foo\r\n\r", Test.partial);
    parse("GET / HTTP/1.0\r\n\r\n", Test.complete);
    parse(" / HTTP/1.0\r\n\r\n", Test.err); // empty method
    parse("GET  HTTP/1.0\r\n\r\n", Test.err); // empty request target
    parse("GET / \r\n\r\n", Test.err); // empty version
    parse("GET / HTTP/1.0\r\n:a\r\n\r\n", Test.err); // empty header name
    parse("GET / HTTP/1.0\r\n :a\r\n\r\n", Test.err); // empty header name (space only)
    parse("G\0T / HTTP/1.0\r\n\r\n", Test.err); // NUL in method
    parse("G\tT / HTTP/1.0\r\n\r\n", Test.err); // tab in method
    parse("GET /\x7f HTTP/1.0\r\n\r\n", Test.err); // DEL in uri
    parse("GET / HTTP/1.0\r\na\0b: c\r\n\r\n", Test.err); // NUL in header name
    parse("GET / HTTP/1.0\r\nab: c\0d\r\n\r\n", Test.err); // NUL in header value
    parse("GET / HTTP/1.0\r\na\033b: c\r\n\r\n", Test.err); // CTL in header name
    parse("GET / HTTP/1.0\r\nab: c\033\r\n\r\n", Test.err); // CTL in header value
    parse("GET / HTTP/1.0\r\n/: 1\r\n\r\n", Test.err); // invalid char in header value

    // accept MSB chars
    {
        auto res = parse("GET /\xa0 HTTP/1.0\r\nh: c\xa2y\r\n\r\n");
        assert(res.method == "GET");
        assert(res.uri == "/\xa0");
        assert(res.ver == "HTTP/1.0");
        assert(res.headers.length == 1);
        assert(res.headers[0] == Header("h", "c\xa2y"));
    }

    parse("GET / HTTP/1.0\r\n\x7b: 1\r\n\r\n", Test.err); // disallow '{'

    // exclude leading and trailing spaces in header value
    {
        auto req = parse("GET / HTTP/1.0\r\nfoo:  a \t \r\n\r\n");
        assert(req.headers[0].value == "a");
    }

    // leave the body intact
    parse("GET / RTSP/2.0\r\n\r\nfoo bar baz", Test.complete, "foo bar baz".length);

    // realworld
    {
        auto req = parse("GET /cookies HTTP/1.1\r\nHost: 127.0.0.1:8090\r\nConnection: keep-alive\r\nCache-Control: max-age=0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nUser-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.56 Safari/537.17\r\nAccept-Encoding: gzip,deflate,sdch\r\nAccept-Language: en-US,en;q=0.8\r\nAccept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3\r\nCookie: name=wookie\r\n\r\n");
        assert(req.method == "GET");
        assert(req.uri == "/cookies");
        assert(req.ver == "HTTP/1.1");
        assert(req.headers[0] == Header("Host", "127.0.0.1:8090"));
        assert(req.headers[1] == Header("Connection", "keep-alive"));
        assert(req.headers[2] == Header("Cache-Control", "max-age=0"));
        assert(req.headers[3] == Header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"));
        assert(req.headers[4] == Header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.56 Safari/537.17"));
        assert(req.headers[5] == Header("Accept-Encoding", "gzip,deflate,sdch"));
        assert(req.headers[6] == Header("Accept-Language", "en-US,en;q=0.8"));
        assert(req.headers[7] == Header("Accept-Charset", "ISO-8859-1,utf-8;q=0.7,*;q=0.3"));
        assert(req.headers[8] == Header("Cookie", "name=wookie"));
    }

    // newline
    {
        auto req = parse("GET / HTTP/1.0\nfoo: a\n\n");
    }
}

@("Response")
// Tests from https://github.com/h2o/picohttpparser/blob/master/test.c
unittest
{
    auto parse(string data, Test test = Test.complete, int additional = 0) @safe nothrow
    {
        auto parser = initParser!Msg();

        auto res = parser.parseResponse(data);
        // if (res.hasError) writeln(res.error, ": ", msg);
        final switch (test)
        {
            case Test.err: assert(res < -Error.partial); break;
            case Test.partial: assert(res == -Error.partial); break;
            case Test.complete: assert(res == data.length - additional); break;
        }

        return parser.msg;
    }

    // simple
    {
        auto res = parse("HTTP/1.0 200 OK\r\n\r\n");
        assert(res.headers.length == 0);
        assert(res.status == 200);
        assert(res.ver == "HTTP/1.0");
        assert(res.statusMsg == "OK");
    }

    parse("HTTP/1.0 200 OK\r\n\r", Test.partial); // partial

    // parse headers
    {
        auto res = parse("HTTP/1.1 200 OK\r\nHost: example.com\r\nCookie: \r\n\r\n");
        assert(res.headers.length == 2);
        assert(res.ver == "HTTP/1.1");
        assert(res.status == 200);
        assert(res.statusMsg == "OK");
        assert(res.headers[0] == Header("Host", "example.com"));
        assert(res.headers[1] == Header("Cookie", ""));
    }

    // parse multiline
    {
        auto res = parse("HTTP/1.0 200 OK\r\nfoo: \r\nfoo: b\r\n  \tc\r\n\r\n");
        assert(res.headers.length == 3);
        assert(res.ver == "HTTP/1.0");
        assert(res.status == 200);
        assert(res.statusMsg == "OK");
        assert(res.headers[0] == Header("foo", ""));
        assert(res.headers[1] == Header("foo", "b"));
        assert(res.headers[2] == Header(null, "  \tc"));
    }

    // internal server error
    {
        auto res = parse("HTTP/1.0 500 Internal Server Error\r\n\r\n");
        assert(res.headers.length == 0);
        assert(res.ver == "HTTP/1.0");
        assert(res.status == 500);
        assert(res.statusMsg == "Internal Server Error");
    }

    parse("H", Test.partial); // incomplete 1
    parse("HTTP/1.", Test.partial); // incomplete 2
    assert(parse("HTTP/1.1", Test.partial).ver is null); // incomplete 3 - differs from picohttpparser as we don't parse exact version
    assert(parse("HTTP/1.1 ", Test.partial).ver == "HTTP/1.1"); // incomplete 4
    parse("HTTP/1.1 2", Test.partial); // incomplete 5
    assert(parse("HTTP/1.1 200", Test.partial).status == 0); // incomplete 6
    assert(parse("HTTP/1.1 200 ", Test.partial).status == 200); // incomplete 7
    assert(parse("HTTP/1.1 200\r", Test.partial).status == 200); // incomplete 7.1
    parse("HTTP/1.1 200 O", Test.partial); // incomplete 8
    assert(parse("HTTP/1.1 200 OK\r", Test.partial).statusMsg == "OK"); // incomplete 9 - differs from picohttpparser
    assert(parse("HTTP/1.1 200 OK\r\n", Test.partial).statusMsg == "OK"); // incomplete 10
    assert(parse("HTTP/1.1 200 OK\n", Test.partial).statusMsg == "OK"); // incomplete 11
    assert(parse("HTTP/1.1 200 OK\r\nA: 1\r", Test.partial).headers.length == 0); // incomplete 11

    // incomplete 12
    {
        auto res = parse("HTTP/1.1 200 OK\r\nA: 1\r\n", Test.partial);
        assert(res.headers.length == 1);
        assert(res.headers[0] == Header("A", "1"));
    }

    // slowloris (incomplete)
    {
        auto parser = initParser!Msg();
        assert(parser.parseResponse("HTTP/1.0 200 OK\r\n") == -Error.partial);
        assert(parser.parseResponse("HTTP/1.0 200 OK\r\n\r") == -Error.partial);
        assert(parser.parseResponse("HTTP/1.0 200 OK\r\n\r\nblabla") == "HTTP/1.0 200 OK\r\n\r\n".length);
    }

    parse("HTTP/1. 200 OK\r\n\r\n"); // invalid http version - but we don't check that here
    parse("HTTP/1.2z 200 OK\r\n\r\n"); // invalid http version 2 - but we don't check that here
    parse("HTTP/1.1  OK\r\n\r\n", Test.err); // no status code

    assert(parse("HTTP/1.1 200\r\n\r\n").statusMsg == ""); // accept missing trailing whitespace in status-line
    parse("HTTP/1.1 200X\r\n\r\n", Test.err); // garbage after status 1
    parse("HTTP/1.1 200X \r\n\r\n", Test.err); // garbage after status 2
    parse("HTTP/1.1 200X OK\r\n\r\n", Test.err); // garbage after status 3

    assert(parse("HTTP/1.1 200 OK\r\nbar: \t b\t \t\r\n\r\n").headers[0].value == "b"); // exclude leading and trailing spaces in header value
}

@("With HTTP version validation")
unittest
{
    static struct HTTPMsg
    {
        nothrow @nogc:
        int onVersion(const(char)[] ver)
        {
            if (ver != "HTTP/1.0" && ver != "HTTP/1.1") return err(Error.invalidVersion);
            this.ver = ver;
            return 0;
        }
        const(char)[] ver;
    }

    auto parser = initParser!HTTPMsg();
    auto res = parser.parseResponse("HTTP/1.0 200 OK\r\n\r\n");
    assert(res);
    assert(res != -Error.partial);

    parser = initParser!HTTPMsg();
    res = parser.parseResponse("HTTP/3.0 200 OK\r\n\r\n");
    assert(res == -Error.invalidVersion);
}

@("Incremental")
unittest
{
    string req = "GET /cookies HTTP/1.1\r\nHost: 127.0.0.1:8090\r\nConnection: keep-alive\r\nCache-Control: max-age=0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nUser-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.56 Safari/537.17\r\nAccept-Encoding: gzip,deflate,sdch\r\nAccept-Language: en-US,en;q=0.8\r\nAccept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3\r\nCookie: name=wookie\r\n\r\n";
    auto parser = initParser!Msg();
    uint parsed;
    auto res = parser.parseRequest(req[0.."GET /cookies HTTP/1.1\r\nHost: 127.0.0.1:8090\r\nConn".length], parsed);
    assert(res == -Error.partial);
    assert(parser.msg.method == "GET");
    assert(parser.msg.uri == "/cookies");
    assert(parser.msg.ver == "HTTP/1.1");
    assert(parser.msg.headers.length == 1);
    assert(parser.msg.headers[0] == Header("Host", "127.0.0.1:8090"));

    res = parser.parseRequest(req, parsed);
    assert(res == req.length);
    assert(parser.msg.method == "GET");
    assert(parser.msg.uri == "/cookies");
    assert(parser.msg.ver == "HTTP/1.1");
    assert(parser.msg.headers[0] == Header("Host", "127.0.0.1:8090"));
    assert(parser.msg.headers[1] == Header("Connection", "keep-alive"));
    assert(parser.msg.headers[2] == Header("Cache-Control", "max-age=0"));
    assert(parser.msg.headers[3] == Header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"));
    assert(parser.msg.headers[4] == Header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.56 Safari/537.17"));
    assert(parser.msg.headers[5] == Header("Accept-Encoding", "gzip,deflate,sdch"));
    assert(parser.msg.headers[6] == Header("Accept-Language", "en-US,en;q=0.8"));
    assert(parser.msg.headers[7] == Header("Accept-Charset", "ISO-8859-1,utf-8;q=0.7,*;q=0.3"));
    assert(parser.msg.headers[8] == Header("Cookie", "name=wookie"));
}
