import 'package:cookie_store/src/cookie.dart';
import 'package:test/test.dart';

void main() {
  test('Cookie Store - Test the Set-Cookie header parsing', () {
    // A valid header
    CookieStore store = CookieStore();
    String name, value;
    Map<String, String> attrs;
    (name, value, attrs) = store.parseSetCookie(
        "<cookie-name>=<cookie-value>; Domain=<domain-value>; Secure; HttpOnly");
    expect(name, "<cookie-name>");
    expect(value, "<cookie-value>");
    expect(attrs, {'Domain': '<domain-value>', 'Secure': '', 'HttpOnly': ''});
    // What happens if the user forgets to strip the header name
    (name, value, attrs) = store.parseSetCookie(
        "Set-Cookie: <cookie-name>=<cookie-value>; Domain=<domain-value>; Secure; HttpOnly");
    expect(name, "Set-Cookie: <cookie-name>");
    expect(value, "<cookie-value>");
    expect(attrs, {'Domain': '<domain-value>', 'Secure': '', 'HttpOnly': ''});
    // Cookie values can be empty
    (name, value, attrs) = store.parseSetCookie(
        "<cookie-name>=; Domain=<domain-value>; Secure; HttpOnly");
    expect(name, "<cookie-name>");
    expect(value, "");
    expect(attrs, {'Domain': '<domain-value>', 'Secure': '', 'HttpOnly': ''});
    // Cookie names cannot be
    expect(
        () => store.parseSetCookie(
            "<cookie-value>;asdasdasd=asdasdasd;asdffds=asdfsf"),
        throwsFormatException);
  });
  test('Cookie Store - Test multiple cookies per header', () {
    /// TODO: Minimal test, expand on this
    CookieStore store = CookieStore();
    store.updateCookies("test=true,test2=true", "example.com", "/");
    expect(store.cookies.length, 2);
    // Make sure dates don't get split
    store.updateCookies(
        "asd=fgd;expires=Fri, 23 Apr 2800 13:45:56 GMT", "example.com", "/");
    expect(store.cookies.length, 3);
  });

  test('Cookie Store - domain cookies are accepted for matching subdomains',
      () {
    final store = CookieStore();

    expect(
      store.updateCookies("shared=true; Domain=example.com; Secure; HttpOnly",
          "sub.example.com", "/login"),
      isTrue,
    );

    expect(store.cookies, hasLength(1));
    expect(store.cookies.single.domain, "example.com");
    expect(store.cookies.single.hostOnly, isFalse);
    expect(store.cookies.single.path, "/");
    expect(store.cookies.single.secure, isTrue);
    expect(store.cookies.single.httpOnly, isTrue);
    expect(
      CookieStore.buildCookieHeader(
          store.getCookiesForRequest("example.com", "/")),
      "shared=true",
    );
    expect(
      CookieStore.buildCookieHeader(
          store.getCookiesForRequest("deep.sub.example.com", "/")),
      "shared=true",
    );
  });

  test('Cookie Store - host-only and mismatched domain cookies are isolated',
      () {
    final store = CookieStore();

    expect(
        store.updateCookies("hostOnly=true", "sub.example.com", "/"), isTrue);
    expect(
      store.updateCookies("wrong=true; Domain=other.com", "example.com", "/"),
      isFalse,
    );

    expect(store.cookies, hasLength(1));
    expect(store.cookies.single.hostOnly, isTrue);
    expect(
      CookieStore.buildCookieHeader(
          store.getCookiesForRequest("sub.example.com", "/")),
      "hostOnly=true",
    );
    expect(
      CookieStore.buildCookieHeader(
          store.getCookiesForRequest("example.com", "/")),
      "",
    );
  });
  test('Cookie Store - Test the canonicalisation method', () {
    CookieStore store = CookieStore();

    String result = store.toCanonical("öbb.at");
    expect(result, "xn--bb-eka.at");

    result = store.toCanonical("Bücher.example");
    expect(result, "xn--bcher-kva.example");

    result = store.toCanonical("example.com");
    expect("example.com", result);
  });

  /// LDH Label format defined in RFC 5890 Section 2.3.1:
  ///
  /// ASCII uppercase, lowercase, or numbers. Dashes allowed other than in the
  /// first and last position. Complete string must not be longer than
  /// 63 octets.
  test('Cookie Store - Test the LDH label regex', () {
    // Short strings are valid, so are dashes not in the last position
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("a"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("aa"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("a-a"));
    // Same, uppercase is allowed
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("A"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("AA"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("A-A"));
    // So is a mixture of upper and lowercase
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("aA"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("Aa"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("a-A"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("A-a"));
    // Short strings with dashes in the first and/or last positions are invalid
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("a-"));
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("-a"));
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("-a-"));
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("aa-"));
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("-aa"));
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("-aa-"));
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("-"));
    // Numbers are valid, on their own or as part of a larger string
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1a"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1aA"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1Aa"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("11"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("11a"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("11aA"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1a1"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1aA1"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1Aa1"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1a11"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1aA11"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("1Aa11"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("a11"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("aA11"));
    expect(true, RegExp(CookieStore.ldhLabelRegexString).hasMatch("111"));
    // Non-ASCII characters and non-alphanumeric ASCII characters are invalid
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("a a"));
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("aç a"));
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("aça"));
    expect(false, RegExp(CookieStore.ldhLabelRegexString).hasMatch("a ça"));
    expect(
        false,
        RegExp(CookieStore.ldhLabelRegexString)
            .hasMatch("aaaaaaaaaaaaaaaaaaaaaaaaaa ça"));
    expect(
        false,
        RegExp(CookieStore.ldhLabelRegexString)
            .hasMatch("a                   ça"));
    expect(false,
        RegExp(CookieStore.ldhLabelRegexString).hasMatch("a ççççççççççççça"));
    expect(
        false,
        RegExp(CookieStore.ldhLabelRegexString)
            .hasMatch("a çaaaaaaaaaaaaaaaaaaaa"));
    // A 63-octet string is valid
    expect(
        true,
        RegExp(CookieStore.ldhLabelRegexString).hasMatch(
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"));
    // But no longer
    expect(
        false,
        RegExp(CookieStore.ldhLabelRegexString).hasMatch(
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"));
  });

  test('Test cookie deletion', () {
    CookieStore store = CookieStore();
    for (int i = 0; i < 10; i++) {
      store.updateCookies("test$i=true", "example.com", "/");
    }
    expect(store.cookies.length, 10);
    store.reduceSize(0, false);
    expect(store.cookies.length, 10);
    store.reduceSize(0, false, numExcessive: 9);
    expect(store.cookies.length, 9);
    store.reduceSize(0, true);
    expect(store.cookies.length, 0);
  });

  test('reduceSize clears expired cookies and evicts oldest when forced', () {
    final store = CookieStore();
    final oldCookie = Cookie(
      "old",
      "true",
      creationTime: DateTime.utc(2024, 1, 1),
      lastAccessTime: DateTime.utc(2024, 1, 1),
    )
      ..domain = "example.com"
      ..path = "/";
    final newCookie = Cookie(
      "new",
      "true",
      creationTime: DateTime.utc(2024, 1, 2),
      lastAccessTime: DateTime.utc(2024, 1, 2),
    )
      ..domain = "example.com"
      ..path = "/";
    final expiredCookie = Cookie(
      "expired",
      "true",
      creationTime: DateTime.utc(2024, 1, 3),
      lastAccessTime: DateTime.utc(2024, 1, 3),
    )
      ..domain = "example.com"
      ..path = "/"
      ..persistent = true
      ..expiryTime = DateTime.now().subtract(const Duration(days: 1));

    store.cookies = [oldCookie, newCookie, expiredCookie];

    expect(store.reduceSize(1, true, numExcessive: 10), isTrue);
    expect(store.cookies, hasLength(1));
    expect(store.cookies.single.name, "new");
  });

  test('onSessionEnded removes only non-persistent cookies', () {
    final store = CookieStore();

    store.updateCookies("session_cookie=true", "example.com", "/");
    store.updateCookies(
        "persistent_cookie=true; Expires=Fri, 23 Apr 2800 13:45:56 GMT",
        "example.com",
        "/");

    expect(store.cookies.length, 2);

    store.onSessionEnded();

    expect(store.cookies.length, 1);
    expect(store.cookies.single.name, "persistent_cookie");
  });

  test('new cookies replace existing cookies with the same name/domain/path',
      () {
    final store = CookieStore();

    expect(store.updateCookies("session=first", "example.com", "/"), isTrue);
    expect(store.updateCookies("session=second", "example.com", "/"), isTrue);

    expect(store.cookies, hasLength(1));
    expect(store.cookies.single.value, "second");
  });

  test(
      'expires parsing accepts legacy weekday formats and rejects invalid dates',
      () {
    final validStore = CookieStore();
    final invalidStore = CookieStore();

    expect(
      validStore.updateCookies(
          "legacy=true; Expires=Thursday, 1 Jan 1970 23:59:59 GMT",
          "example.com",
          "/"),
      isTrue,
    );
    expect(
      invalidStore.updateCookies(
          "broken=true; Expires=definitely-not-a-date", "example.com", "/"),
      isFalse,
    );

    expect(validStore.cookies, isEmpty);
    expect(invalidStore.cookies, isEmpty);
  });

  test('End to end tests', () {
    CookieStore store = CookieStore();
    store.updateCookies("PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3", "example.com",
        "/sample-directory/sample.php");
    String cookieHeader = CookieStore.buildCookieHeader(
        store.getCookiesForRequest("example.com", "/"));
    // the cookie was set on "/sample-directory/" so should not be used for "/"
    expect("", cookieHeader);

    store.updateCookies("lang=en/ca", "example.com", "/");
    cookieHeader = CookieStore.buildCookieHeader(
        store.getCookiesForRequest("example.com", "/"));
    expect("lang=en/ca", cookieHeader);

    cookieHeader = CookieStore.buildCookieHeader(
        store.getCookiesForRequest("example.com", "/sample-directory"));
    expect("PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3;lang=en/ca", cookieHeader);

    store.updateCookies("test=true", "example.com", "/");
    cookieHeader = CookieStore.buildCookieHeader(
        store.getCookiesForRequest("example.com", "/example"));
    expect("lang=en/ca;test=true", cookieHeader);
  });

  group('Path handling', () {
    const requestDomain = 'example.com';
    late CookieStore store;

    void check(String requestPath, String expectedCookieHeader,
        [String? reason]) {
      final requestHeader = CookieStore.buildCookieHeader(
          store.getCookiesForRequest(requestDomain, requestPath));
      expect(requestHeader, expectedCookieHeader,
          reason: '$requestPath $reason');
    }

    setUp(() {
      store = CookieStore();
    });

    test('without explicit path attribute', () {
      store.updateCookies("PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3", requestDomain,
          "/sample-directory/sample.php");
      check("/", "", "Request path is root and not below /sample-directory");
      check("/sample-directory", "PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3");

      store.updateCookies("lang=en/ca", requestDomain, "/");
      check("/", "lang=en/ca");

      store.updateCookies("test=true", requestDomain, "/");
      check("/", "lang=en/ca;test=true");
    });

    test('with path attribute', () {
      assert(store.updateCookies(
          'PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3; Path=/example/',
          requestDomain,
          "/sample-directory/sample.php"));
      assert(store.updateCookies("lang=en/ca; Path=/login/path/page",
          requestDomain, "/sample-directory/sample.php"));
      assert(store.updateCookies(
          'test=true; Path=/', requestDomain, "/sample-directory/sample.php"));

      expect(
          store.cookies.firstWhere((cookie) => cookie.name == 'PHPSESSID').path,
          '/example/',
          reason: 'explicit Path attribute should be preserved');
      expect(store.cookies.firstWhere((cookie) => cookie.name == 'lang').path,
          '/login/path/page',
          reason: 'explicit Path attribute should be preserved');
      expect(
          store.cookies.firstWhere((cookie) => cookie.name == 'test').path, '/',
          reason: 'explicit Path attribute should be preserved');

      check('/example', 'test=true',
          'parent path should not match a valid explicit Path attribute');
      check('/example/', 'PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3;test=true',
          'exact path should match a valid explicit Path attribute');
      check(
          '/example/subpath/with/page',
          'PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3;test=true',
          'subpath of path attribute');
      check('/', 'test=true', 'not a subpath of path attribute');
      check('/login', 'test=true', 'path is below / but not part of example');
      check('/login/path', 'test=true',
          'parent path should not match a valid explicit Path attribute');
      check('/login/path/page', 'lang=en/ca;test=true',
          'exact path should match a valid explicit Path attribute');
    });

    test('prefixes only match on path segment boundaries', () {
      expect(store.pathMatches("/foobar", "/foo"), isFalse);
      expect(store.pathMatches("/foo/bar", "/foo"), isTrue);
      expect(store.pathMatches("/foo", "/foo"), isTrue);
    });

    test('path matching handles regex metachars correctly', () {
      expect(store.pathMatches('/a.bc/def', '/a.bc/'), isTrue);
      expect(store.pathMatches('/a.^\$bc/def', '/a.^\$bc/'), isTrue);
      expect(store.pathMatches('/a([]])\'\\bc/def', '/a([]])\'\\bc/'), isTrue);
    });
  });
}
