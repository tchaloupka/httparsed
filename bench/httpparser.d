module httpparser;

/* Copyright Joyent, Inc. and other Node contributors. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

import core.stdc.config;

extern (C):

/* Also update SONAME in the Makefile whenever you change these. */
enum HTTP_PARSER_VERSION_MAJOR = 2;
enum HTTP_PARSER_VERSION_MINOR = 9;
enum HTTP_PARSER_VERSION_PATCH = 4;

/* Compile with -DHTTP_PARSER_STRICT=0 to make less checks, but run
 * faster
 */

enum HTTP_PARSER_STRICT = 1;

/* Maximium header size allowed. If the macro is not defined
 * before including this header then the default is used. To
 * change the maximum header size, define the macro in the build
 * environment (e.g. -DHTTP_MAX_HEADER_SIZE=<value>). To remove
 * the effective limit on the size of the header, define the macro
 * to a very large number (e.g. -DHTTP_MAX_HEADER_SIZE=0x7fffffff)
 */

enum HTTP_MAX_HEADER_SIZE = 80 * 1024;

/* Callbacks should return non-zero to indicate an error. The parser will
 * then halt execution.
 *
 * The one exception is on_headers_complete. In a HTTP_RESPONSE parser
 * returning '1' from on_headers_complete will tell the parser that it
 * should not expect a body. This is used when receiving a response to a
 * HEAD request which may contain 'Content-Length' or 'Transfer-Encoding:
 * chunked' headers that indicate the presence of a body.
 *
 * Returning `2` from on_headers_complete will tell parser that it should not
 * expect neither a body nor any futher responses on this connection. This is
 * useful for handling responses to a CONNECT request which may not contain
 * `Upgrade` or `Connection: upgrade` headers.
 *
 * http_data_cb does not return data chunks. It will be called arbitrarily
 * many times for each string. E.G. you might get 10 callbacks for "on_url"
 * each providing just a few characters more data.
 */
alias http_data_cb = int function (http_parser*, const(char)* at, size_t length);
alias http_cb = int function (http_parser*);

/* Status Codes */

enum http_status
{
    HTTP_STATUS_CONTINUE = 100,
    HTTP_STATUS_SWITCHING_PROTOCOLS = 101,
    HTTP_STATUS_PROCESSING = 102,
    HTTP_STATUS_OK = 200,
    HTTP_STATUS_CREATED = 201,
    HTTP_STATUS_ACCEPTED = 202,
    HTTP_STATUS_NON_AUTHORITATIVE_INFORMATION = 203,
    HTTP_STATUS_NO_CONTENT = 204,
    HTTP_STATUS_RESET_CONTENT = 205,
    HTTP_STATUS_PARTIAL_CONTENT = 206,
    HTTP_STATUS_MULTI_STATUS = 207,
    HTTP_STATUS_ALREADY_REPORTED = 208,
    HTTP_STATUS_IM_USED = 226,
    HTTP_STATUS_MULTIPLE_CHOICES = 300,
    HTTP_STATUS_MOVED_PERMANENTLY = 301,
    HTTP_STATUS_FOUND = 302,
    HTTP_STATUS_SEE_OTHER = 303,
    HTTP_STATUS_NOT_MODIFIED = 304,
    HTTP_STATUS_USE_PROXY = 305,
    HTTP_STATUS_TEMPORARY_REDIRECT = 307,
    HTTP_STATUS_PERMANENT_REDIRECT = 308,
    HTTP_STATUS_BAD_REQUEST = 400,
    HTTP_STATUS_UNAUTHORIZED = 401,
    HTTP_STATUS_PAYMENT_REQUIRED = 402,
    HTTP_STATUS_FORBIDDEN = 403,
    HTTP_STATUS_NOT_FOUND = 404,
    HTTP_STATUS_METHOD_NOT_ALLOWED = 405,
    HTTP_STATUS_NOT_ACCEPTABLE = 406,
    HTTP_STATUS_PROXY_AUTHENTICATION_REQUIRED = 407,
    HTTP_STATUS_REQUEST_TIMEOUT = 408,
    HTTP_STATUS_CONFLICT = 409,
    HTTP_STATUS_GONE = 410,
    HTTP_STATUS_LENGTH_REQUIRED = 411,
    HTTP_STATUS_PRECONDITION_FAILED = 412,
    HTTP_STATUS_PAYLOAD_TOO_LARGE = 413,
    HTTP_STATUS_URI_TOO_LONG = 414,
    HTTP_STATUS_UNSUPPORTED_MEDIA_TYPE = 415,
    HTTP_STATUS_RANGE_NOT_SATISFIABLE = 416,
    HTTP_STATUS_EXPECTATION_FAILED = 417,
    HTTP_STATUS_MISDIRECTED_REQUEST = 421,
    HTTP_STATUS_UNPROCESSABLE_ENTITY = 422,
    HTTP_STATUS_LOCKED = 423,
    HTTP_STATUS_FAILED_DEPENDENCY = 424,
    HTTP_STATUS_UPGRADE_REQUIRED = 426,
    HTTP_STATUS_PRECONDITION_REQUIRED = 428,
    HTTP_STATUS_TOO_MANY_REQUESTS = 429,
    HTTP_STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE = 431,
    HTTP_STATUS_UNAVAILABLE_FOR_LEGAL_REASONS = 451,
    HTTP_STATUS_INTERNAL_SERVER_ERROR = 500,
    HTTP_STATUS_NOT_IMPLEMENTED = 501,
    HTTP_STATUS_BAD_GATEWAY = 502,
    HTTP_STATUS_SERVICE_UNAVAILABLE = 503,
    HTTP_STATUS_GATEWAY_TIMEOUT = 504,
    HTTP_STATUS_HTTP_VERSION_NOT_SUPPORTED = 505,
    HTTP_STATUS_VARIANT_ALSO_NEGOTIATES = 506,
    HTTP_STATUS_INSUFFICIENT_STORAGE = 507,
    HTTP_STATUS_LOOP_DETECTED = 508,
    HTTP_STATUS_NOT_EXTENDED = 510,
    HTTP_STATUS_NETWORK_AUTHENTICATION_REQUIRED = 511
}

/* Request Methods */

/* pathological */

/* WebDAV */

/* subversion */

/* upnp */

/* RFC-5789 */

/* CalDAV */

/* RFC-2068, section 19.6.1.2 */

/* icecast */

enum http_method
{
    HTTP_DELETE = 0,
    HTTP_GET = 1,
    HTTP_HEAD = 2,
    HTTP_POST = 3,
    HTTP_PUT = 4,
    HTTP_CONNECT = 5,
    HTTP_OPTIONS = 6,
    HTTP_TRACE = 7,
    HTTP_COPY = 8,
    HTTP_LOCK = 9,
    HTTP_MKCOL = 10,
    HTTP_MOVE = 11,
    HTTP_PROPFIND = 12,
    HTTP_PROPPATCH = 13,
    HTTP_SEARCH = 14,
    HTTP_UNLOCK = 15,
    HTTP_BIND = 16,
    HTTP_REBIND = 17,
    HTTP_UNBIND = 18,
    HTTP_ACL = 19,
    HTTP_REPORT = 20,
    HTTP_MKACTIVITY = 21,
    HTTP_CHECKOUT = 22,
    HTTP_MERGE = 23,
    HTTP_MSEARCH = 24,
    HTTP_NOTIFY = 25,
    HTTP_SUBSCRIBE = 26,
    HTTP_UNSUBSCRIBE = 27,
    HTTP_PATCH = 28,
    HTTP_PURGE = 29,
    HTTP_MKCALENDAR = 30,
    HTTP_LINK = 31,
    HTTP_UNLINK = 32,
    HTTP_SOURCE = 33
}

enum http_parser_type
{
    HTTP_REQUEST = 0,
    HTTP_RESPONSE = 1,
    HTTP_BOTH = 2
}

/* Flag values for http_parser.flags field */
enum flags
{
    F_CHUNKED = 1 << 0,
    F_CONNECTION_KEEP_ALIVE = 1 << 1,
    F_CONNECTION_CLOSE = 1 << 2,
    F_CONNECTION_UPGRADE = 1 << 3,
    F_TRAILING = 1 << 4,
    F_UPGRADE = 1 << 5,
    F_SKIPBODY = 1 << 6,
    F_CONTENTLENGTH = 1 << 7
}

/* Map for errno-related constants
 *
 * The provided argument should be a macro that takes 2 arguments.
 */

/* No error */

/* Callback-related errors */

/* Parsing-related errors */

/* Define HPE_* values for each errno value above */
enum http_errno
{
    HPE_OK = 0,
    HPE_CB_message_begin = 1,
    HPE_CB_url = 2,
    HPE_CB_header_field = 3,
    HPE_CB_header_value = 4,
    HPE_CB_headers_complete = 5,
    HPE_CB_body = 6,
    HPE_CB_message_complete = 7,
    HPE_CB_status = 8,
    HPE_CB_chunk_header = 9,
    HPE_CB_chunk_complete = 10,
    HPE_INVALID_EOF_STATE = 11,
    HPE_HEADER_OVERFLOW = 12,
    HPE_CLOSED_CONNECTION = 13,
    HPE_INVALID_VERSION = 14,
    HPE_INVALID_STATUS = 15,
    HPE_INVALID_METHOD = 16,
    HPE_INVALID_URL = 17,
    HPE_INVALID_HOST = 18,
    HPE_INVALID_PORT = 19,
    HPE_INVALID_PATH = 20,
    HPE_INVALID_QUERY_STRING = 21,
    HPE_INVALID_FRAGMENT = 22,
    HPE_LF_EXPECTED = 23,
    HPE_INVALID_HEADER_TOKEN = 24,
    HPE_INVALID_CONTENT_LENGTH = 25,
    HPE_UNEXPECTED_CONTENT_LENGTH = 26,
    HPE_INVALID_CHUNK_SIZE = 27,
    HPE_INVALID_CONSTANT = 28,
    HPE_INVALID_INTERNAL_STATE = 29,
    HPE_STRICT = 30,
    HPE_PAUSED = 31,
    HPE_UNKNOWN = 32,
    HPE_INVALID_TRANSFER_ENCODING = 33
}

/* Get an http_errno value from an http_parser */

struct http_parser
{
    import std.bitmanip : bitfields;

    mixin(bitfields!(
        uint, "type", 2,
        uint, "flags", 8,
        uint, "state", 7,
        uint, "header_state", 7,
        uint, "index", 5,
        uint, "uses_transfer_encoding", 1,
        uint, "allow_chunked_length", 1,
        uint, "lenient_http_headers", 1));

    /** PRIVATE **/
    /* enum http_parser_type */
    /* F_* values from 'flags' enum; semi-public */
    /* enum state from http_parser.c */
    /* enum header_state from http_parser.c */
    /* index into current matcher */
    /* Transfer-Encoding header is present */
    /* Allow headers with both
     * `Content-Length` and
     * `Transfer-Encoding: chunked` set */

    uint nread; /* # bytes read in various scenarios */
    ulong content_length; /* # bytes in body. `(uint64_t) -1` (all bits one)
     * if no Content-Length header.
     */

    /** READ-ONLY **/
    ushort http_major;
    ushort http_minor;

    mixin(bitfields!(
        uint, "status_code", 16,
        uint, "method", 8,
        uint, "http_errno", 7,
        uint, "upgrade", 1));

    /* responses only */
    /* requests only */

    /* 1 = Upgrade header was present and the parser has exited because of that.
     * 0 = No upgrade header present.
     * Should be checked when http_parser_execute() returns in addition to
     * error checking.
     */

    /** PUBLIC **/
    void* data; /* A pointer to get hook to the "connection" or "socket" object */
}

struct http_parser_settings
{
    http_cb on_message_begin;
    http_data_cb on_url;
    http_data_cb on_status;
    http_data_cb on_header_field;
    http_data_cb on_header_value;
    http_cb on_headers_complete;
    http_data_cb on_body;
    http_cb on_message_complete;
    /* When on_chunk_header is called, the current chunk length is stored
     * in parser->content_length.
     */
    http_cb on_chunk_header;
    http_cb on_chunk_complete;
}

enum http_parser_url_fields
{
    UF_SCHEMA = 0,
    UF_HOST = 1,
    UF_PORT = 2,
    UF_PATH = 3,
    UF_QUERY = 4,
    UF_FRAGMENT = 5,
    UF_USERINFO = 6,
    UF_MAX = 7
}

/* Result structure for http_parser_parse_url().
 *
 * Callers should index into field_data[] with UF_* values iff field_set
 * has the relevant (1 << UF_*) bit set. As a courtesy to clients (and
 * because we probably have padding left over), we convert any port to
 * a uint16_t.
 */
struct http_parser_url
{
    ushort field_set; /* Bitmask of (1 << UF_*) values */
    ushort port; /* Converted UF_PORT string */

    /* Offset into buffer in which field starts */
    /* Length of run in buffer */
    struct _Anonymous_0
    {
        ushort off;
        ushort len;
    }

    _Anonymous_0[http_parser_url_fields.UF_MAX] field_data;
}

/* Returns the library version. Bits 16-23 contain the major version number,
 * bits 8-15 the minor version number and bits 0-7 the patch level.
 * Usage example:
 *
 *   unsigned long version = http_parser_version();
 *   unsigned major = (version >> 16) & 255;
 *   unsigned minor = (version >> 8) & 255;
 *   unsigned patch = version & 255;
 *   printf("http_parser v%u.%u.%u\n", major, minor, patch);
 */
c_ulong http_parser_version ();

void http_parser_init (http_parser* parser, http_parser_type type);

/* Initialize http_parser_settings members to 0
 */
void http_parser_settings_init (http_parser_settings* settings);

/* Executes the parser. Returns number of parsed bytes. Sets
 * `parser->http_errno` on error. */
size_t http_parser_execute (
    http_parser* parser,
    const(http_parser_settings)* settings,
    const(char)* data,
    size_t len);

/* If http_should_keep_alive() in the on_headers_complete or
 * on_message_complete callback returns 0, then this should be
 * the last message on the connection.
 * If you are the server, respond with the "Connection: close" header.
 * If you are the client, close the connection.
 */
int http_should_keep_alive (const(http_parser)* parser);

/* Returns a string version of the HTTP method. */
const(char)* http_method_str (http_method m);

/* Returns a string version of the HTTP status code. */
const(char)* http_status_str (http_status s);

/* Return a string name of the given error */
const(char)* http_errno_name (http_errno err);

/* Return a string description of the given error */
const(char)* http_errno_description (http_errno err);

/* Initialize all http_parser_url members to 0 */
void http_parser_url_init (http_parser_url* u);

/* Parse a URL; return nonzero on failure */
int http_parser_parse_url (
    const(char)* buf,
    size_t buflen,
    int is_connect,
    http_parser_url* u);

/* Pause or un-pause the parser; a nonzero value pauses */
void http_parser_pause (http_parser* parser, int paused);

/* Checks if this is the final chunk of the body. */
int http_body_is_final (const(http_parser)* parser);

/* Change the maximum header size provided at compile time. */
void http_parser_set_max_header_size (uint size);

