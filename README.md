# Cookie Store

[![Dart Tests](https://github.com/egefeyzioglu/cookie_store/actions/workflows/dart-tests.yml/badge.svg)](https://github.com/egefeyzioglu/cookie_store/actions/workflows/dart-tests.yml)

A Cookie management plugin for HTTP/HTTPS connections.

Parses Set-Cookie headers and generates Cookie headers for requests, in accordance with RFC 6265.

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
final String path + "/api/whatever";

List<Cookie> cookies = cookieStore.getCookiesForRequest(domain, path);

// Add cookies to your request in some custom way
// Send request
```

or have the cookie store build the header for you

```dart
final String domain = "example.com"
final String path + "/api/whatever";

String cookieHeader = CookieStore.buildCookieHeader(cookieStore.getCookiesForRequest(domain, path));

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