extern (C):

enum LLHTTP_VERSION_MAJOR = 6;
enum LLHTTP_VERSION_MINOR = 0;
enum LLHTTP_VERSION_PATCH = 5;

enum LLHTTP_STRICT_MODE = 0;

alias llhttp__internal_t = llhttp__internal_s;

struct llhttp__internal_s
{
    int _index;
    void* _span_pos0;
    void* _span_cb0;
    int error;
    const(char)* reason;
    const(char)* error_pos;
    void* data;
    void* _current;
    ulong content_length;
    ubyte type;
    ubyte method;
    ubyte http_major;
    ubyte http_minor;
    ubyte header_state;
    ubyte lenient_flags;
    ubyte upgrade;
    ubyte finish;
    ushort flags;
    ushort status_code;
    void* settings;
}

int llhttp__internal_init (llhttp__internal_t* s);
int llhttp__internal_execute (llhttp__internal_t* s, const(char)* p, const(char)* endp);

/* extern "C" */

/* INCLUDE_LLHTTP_ITSELF_H_ */

enum llhttp_errno
{
    HPE_OK = 0,
    HPE_INTERNAL = 1,
    HPE_STRICT = 2,
    HPE_LF_EXPECTED = 3,
    HPE_UNEXPECTED_CONTENT_LENGTH = 4,
    HPE_CLOSED_CONNECTION = 5,
    HPE_INVALID_METHOD = 6,
    HPE_INVALID_URL = 7,
    HPE_INVALID_CONSTANT = 8,
    HPE_INVALID_VERSION = 9,
    HPE_INVALID_HEADER_TOKEN = 10,
    HPE_INVALID_CONTENT_LENGTH = 11,
    HPE_INVALID_CHUNK_SIZE = 12,
    HPE_INVALID_STATUS = 13,
    HPE_INVALID_EOF_STATE = 14,
    HPE_INVALID_TRANSFER_ENCODING = 15,
    HPE_CB_MESSAGE_BEGIN = 16,
    HPE_CB_HEADERS_COMPLETE = 17,
    HPE_CB_MESSAGE_COMPLETE = 18,
    HPE_CB_CHUNK_HEADER = 19,
    HPE_CB_CHUNK_COMPLETE = 20,
    HPE_PAUSED = 21,
    HPE_PAUSED_UPGRADE = 22,
    HPE_PAUSED_H2_UPGRADE = 23,
    HPE_USER = 24
}

alias llhttp_errno_t = llhttp_errno;

enum llhttp_flags
{
    F_CONNECTION_KEEP_ALIVE = 0x1,
    F_CONNECTION_CLOSE = 0x2,
    F_CONNECTION_UPGRADE = 0x4,
    F_CHUNKED = 0x8,
    F_UPGRADE = 0x10,
    F_CONTENT_LENGTH = 0x20,
    F_SKIPBODY = 0x40,
    F_TRAILING = 0x80,
    F_TRANSFER_ENCODING = 0x200
}

alias llhttp_flags_t = llhttp_flags;

enum llhttp_lenient_flags
{
    LENIENT_HEADERS = 0x1,
    LENIENT_CHUNKED_LENGTH = 0x2,
    LENIENT_KEEP_ALIVE = 0x4
}

alias llhttp_lenient_flags_t = llhttp_lenient_flags;

enum llhttp_type
{
    HTTP_BOTH = 0,
    HTTP_REQUEST = 1,
    HTTP_RESPONSE = 2
}

alias llhttp_type_t = llhttp_type;

enum llhttp_finish_
{
    HTTP_FINISH_SAFE = 0,
    HTTP_FINISH_SAFE_WITH_CB = 1,
    HTTP_FINISH_UNSAFE = 2
}

alias llhttp_finish_t = llhttp_finish_;

enum llhttp_method
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
    HTTP_SOURCE = 33,
    HTTP_PRI = 34,
    HTTP_DESCRIBE = 35,
    HTTP_ANNOUNCE = 36,
    HTTP_SETUP = 37,
    HTTP_PLAY = 38,
    HTTP_PAUSE = 39,
    HTTP_TEARDOWN = 40,
    HTTP_GET_PARAMETER = 41,
    HTTP_SET_PARAMETER = 42,
    HTTP_REDIRECT = 43,
    HTTP_RECORD = 44,
    HTTP_FLUSH = 45
}

alias llhttp_method_t = llhttp_method;

/* extern "C" */

/* LLLLHTTP_C_HEADERS_ */

alias llhttp_t = llhttp__internal_s;
alias llhttp_settings_t = llhttp_settings_s;

alias llhttp_data_cb = int function (llhttp_t*, const(char)* at, size_t length);
alias llhttp_cb = int function (llhttp_t*);

struct llhttp_settings_s
{
    /* Possible return values 0, -1, `HPE_PAUSED` */
    llhttp_cb on_message_begin;

    /* Possible return values 0, -1, HPE_USER */
    llhttp_data_cb on_url;
    llhttp_data_cb on_status;
    llhttp_data_cb on_header_field;
    llhttp_data_cb on_header_value;

    /* Possible return values:
     * 0  - Proceed normally
     * 1  - Assume that request/response has no body, and proceed to parsing the
     *      next message
     * 2  - Assume absence of body (as above) and make `llhttp_execute()` return
     *      `HPE_PAUSED_UPGRADE`
     * -1 - Error
     * `HPE_PAUSED`
     */
    llhttp_cb on_headers_complete;

    /* Possible return values 0, -1, HPE_USER */
    llhttp_data_cb on_body;

    /* Possible return values 0, -1, `HPE_PAUSED` */
    llhttp_cb on_message_complete;

    /* When on_chunk_header is called, the current chunk length is stored
     * in parser->content_length.
     * Possible return values 0, -1, `HPE_PAUSED`
     */
    llhttp_cb on_chunk_header;
    llhttp_cb on_chunk_complete;

    /* Information-only callbacks, return value is ignored */
    llhttp_cb on_url_complete;
    llhttp_cb on_status_complete;
    llhttp_cb on_header_field_complete;
    llhttp_cb on_header_value_complete;
}

/* Initialize the parser with specific type and user settings.
 *
 * NOTE: lifetime of `settings` has to be at least the same as the lifetime of
 * the `parser` here. In practice, `settings` has to be either a static
 * variable or be allocated with `malloc`, `new`, etc.
 */
void llhttp_init (
    llhttp_t* parser,
    llhttp_type_t type,
    const(llhttp_settings_t)* settings);

// defined(__wasm__)

/* Reset an already initialized parser back to the start state, preserving the
 * existing parser type, callback settings, user data, and lenient flags.
 */
void llhttp_reset (llhttp_t* parser);

/* Initialize the settings object */
void llhttp_settings_init (llhttp_settings_t* settings);

/* Parse full or partial request/response, invoking user callbacks along the
 * way.
 *
 * If any of `llhttp_data_cb` returns errno not equal to `HPE_OK` - the parsing
 * interrupts, and such errno is returned from `llhttp_execute()`. If
 * `HPE_PAUSED` was used as a errno, the execution can be resumed with
 * `llhttp_resume()` call.
 *
 * In a special case of CONNECT/Upgrade request/response `HPE_PAUSED_UPGRADE`
 * is returned after fully parsing the request/response. If the user wishes to
 * continue parsing, they need to invoke `llhttp_resume_after_upgrade()`.
 *
 * NOTE: if this function ever returns a non-pause type error, it will continue
 * to return the same error upon each successive call up until `llhttp_init()`
 * is called.
 */
llhttp_errno_t llhttp_execute (llhttp_t* parser, const(char)* data, size_t len);

/* This method should be called when the other side has no further bytes to
 * send (e.g. shutdown of readable side of the TCP connection.)
 *
 * Requests without `Content-Length` and other messages might require treating
 * all incoming bytes as the part of the body, up to the last byte of the
 * connection. This method will invoke `on_message_complete()` callback if the
 * request was terminated safely. Otherwise a error code would be returned.
 */
llhttp_errno_t llhttp_finish (llhttp_t* parser);

/* Returns `1` if the incoming message is parsed until the last byte, and has
 * to be completed by calling `llhttp_finish()` on EOF
 */
int llhttp_message_needs_eof (const(llhttp_t)* parser);

/* Returns `1` if there might be any other messages following the last that was
 * successfully parsed.
 */
int llhttp_should_keep_alive (const(llhttp_t)* parser);

/* Make further calls of `llhttp_execute()` return `HPE_PAUSED` and set
 * appropriate error reason.
 *
 * Important: do not call this from user callbacks! User callbacks must return
 * `HPE_PAUSED` if pausing is required.
 */
void llhttp_pause (llhttp_t* parser);

/* Might be called to resume the execution after the pause in user's callback.
 * See `llhttp_execute()` above for details.
 *
 * Call this only if `llhttp_execute()` returns `HPE_PAUSED`.
 */
void llhttp_resume (llhttp_t* parser);

/* Might be called to resume the execution after the pause in user's callback.
 * See `llhttp_execute()` above for details.
 *
 * Call this only if `llhttp_execute()` returns `HPE_PAUSED_UPGRADE`
 */
void llhttp_resume_after_upgrade (llhttp_t* parser);

/* Returns the latest return error */
llhttp_errno_t llhttp_get_errno (const(llhttp_t)* parser);

/* Returns the verbal explanation of the latest returned error.
 *
 * Note: User callback should set error reason when returning the error. See
 * `llhttp_set_error_reason()` for details.
 */
const(char)* llhttp_get_error_reason (const(llhttp_t)* parser);

/* Assign verbal description to the returned error. Must be called in user
 * callbacks right before returning the errno.
 *
 * Note: `HPE_USER` error code might be useful in user callbacks.
 */
void llhttp_set_error_reason (llhttp_t* parser, const(char)* reason);

/* Returns the pointer to the last parsed byte before the returned error. The
 * pointer is relative to the `data` argument of `llhttp_execute()`.
 *
 * Note: this method might be useful for counting the number of parsed bytes.
 */
const(char)* llhttp_get_error_pos (const(llhttp_t)* parser);

/* Returns textual name of error code */
const(char)* llhttp_errno_name (llhttp_errno_t err);

/* Returns textual name of HTTP method */
const(char)* llhttp_method_name (llhttp_method_t method);

/* Enables/disables lenient header value parsing (disabled by default).
 *
 * Lenient parsing disables header value token checks, extending llhttp's
 * protocol support to highly non-compliant clients/server. No
 * `HPE_INVALID_HEADER_TOKEN` will be raised for incorrect header values when
 * lenient parsing is "on".
 *
 * **(USE AT YOUR OWN RISK)**
 */
void llhttp_set_lenient_headers (llhttp_t* parser, int enabled);

/* Enables/disables lenient handling of conflicting `Transfer-Encoding` and
 * `Content-Length` headers (disabled by default).
 *
 * Normally `llhttp` would error when `Transfer-Encoding` is present in
 * conjunction with `Content-Length`. This error is important to prevent HTTP
 * request smuggling, but may be less desirable for small number of cases
 * involving legacy servers.
 *
 * **(USE AT YOUR OWN RISK)**
 */
void llhttp_set_lenient_chunked_length (llhttp_t* parser, int enabled);

/* Enables/disables lenient handling of `Connection: close` and HTTP/1.0
 * requests responses.
 *
 * Normally `llhttp` would error on (in strict mode) or discard (in loose mode)
 * the HTTP request/response after the request/response with `Connection: close`
 * and `Content-Length`. This is important to prevent cache poisoning attacks,
 * but might interact badly with outdated and insecure clients. With this flag
 * the extra request/response will be parsed normally.
 *
 * **(USE AT YOUR OWN RISK)**
 */
void llhttp_set_lenient_keep_alive (llhttp_t* parser, int enabled);

/* extern "C" */

/* INCLUDE_LLHTTP_API_H_ */

/* INCLUDE_LLHTTP_H_ */
