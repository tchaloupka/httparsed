# httparsed

Push parser of HTTP/1.x requests and responses.
Also support another [internet message](https://tools.ietf.org/html/rfc5322) like protocols (ie [RTSP](https://tools.ietf.org/html/rfc7826)).

Inspired by [picohttpparser](https://github.com/h2o/picohttpparser).

## Features

* doesn't allocate anything on it's own (`nothrow @nogc`)
* works with `betterC`
* uses compile time introspection to pass parsed message parts to callbacks
* doesn't store any internal state (but the target message type)
* no dependencies

## Usage

```D
// TODO
```

## Performance

> TODO
