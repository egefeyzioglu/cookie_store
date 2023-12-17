# Cookie Store

[![Dart Tests](https://github.com/egefeyzioglu/cookie_store/actions/workflows/dart-tests.yml/badge.svg)](https://github.com/egefeyzioglu/cookie_store/actions/workflows/dart-tests.yml) [![Dart Analyze](https://github.com/egefeyzioglu/cookie_store/actions/workflows/dart-analyze.yml/badge.svg)](https://github.com/egefeyzioglu/cookie_store/actions/workflows/dart-analyze.yml)

A Cookie management plugin for HTTP/HTTPS connections.

Parses Set-Cookie headers and generates Cookie headers for requests, in accordance with RFC 6265[^1].

## Usage

Initialise a cookie store

```dart
CookieStore cookieStore = new CookieStore();
```

When you get a Set-Cookie header, pass it to the cookie store after stripping the "Set-Cookie:" portion

```dart
for(header in responseHeaders){
    if(header.key == "Set-Cookie"){
        cookieStore.updateCookies(header.value, requestDomain, requestPath);
    }
    //...
}
```

When you're making a request, either get the cookies and add them to your request

```dart
final String domain = "example.com"
final String path = domain + "/api/whatever";

List<Cookie> cookies = cookieStore.getCookiesForRequest(domain, path);

// Add cookies to your request in some custom way
// Send request
```

or have the cookie store build the header for you

```dart
final String domain = "example.com"
final String path = domain + "/api/whatever";

String cookieHeader = CookieStore.buildCookieHeader(
  cookieStore.getCookiesForRequest(domain, path));

// Send request
```

When you're done with the current session, call the `onSessionEnded()` method. What this means is up to you. On a browser, it usually means when all tabs from that domain are closed.

If the cookie storage is taking up too much memory, you may call the `reduceSize(numCookies, force)` method to shrink the cookie storage. This will try to clean up any expired or excessive cookies and return true if successful. See the method documentation for more details.

### The `Cookie` object
The `Cookie` object has a fairly simple structure:

```dart
class Cookie {
  String name;
  String value;
  DateTime? expiryTime;
  String domain = "";
  late String path;
  DateTime creationTime;
  DateTime lastAccessTime;
  bool persistent = false;
  bool hostOnly = false;
  bool secure = false;
  bool httpOnly = false;

  Cookie(
    this.name,
    this.value, {
    DateTime? creationTime,
    DateTime? lastAccessTime,
  })  : creationTime = creationTime ?? DateTime.now(),
        lastAccessTime = lastAccessTime ?? DateTime.now();
}
```

## Acceptable date formats

This library is very permissive with respect to parsing date formats provided by the server. The following are acceptable formats:

- RFC 6265
  - `23:59:59 1 jan 1970`
  - `23:59:59 1 jan 70`
- HTTP ([RFC 2616](https://datatracker.ietf.org/doc/html/rfc2616#section-3.3.1))
  - `Thu, 1 Jan 1970 23:59:59 GMT`
  - `Thursday, 1-Jan-1970 23:59:59 GMT`
  - `Thu Jan  1 23:59:59 1970`
- Incorrect HTTP ([RFC 2616](https://datatracker.ietf.org/doc/html/rfc2616#section-3.3.1), but with the wrong style day of week)
  - `Thursday, 1 Jan 1970 23:59:59 GMT`
  - `Thu, 1-Jan-1970 23:59:59 GMT`
  - `Thursday Jan  1 23:59:59 1970`

  
[^1]: Well, kind of. The internet is an awful, awful place where literally nobody abides by RFC's so this library is _very_ persmissive, especially with respect to date parsing. It is guaranteed, however, that an RFC 6265-compliant server will work correctly with this library. Please see [above](#acceptable-date-formats) for the date formats that are allowed. If your server (or a server you want to talk to) uses another form of nonstandard date format, please create an issue or a pull request. I will try to implement it.
