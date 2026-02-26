import 'package:cookie_store/src/cookie.dart';
import 'package:test/test.dart';

void main() {
  test('Cookie Store - Test the Set-Cookie header parsing', () {
    // A valid header
    CookieStore store = CookieStore();
    String name, value;
    Map<String, String> attrs;
    (name, value, attrs) = store.parseSetCookie(
      "<cookie-name>=<cookie-value>; Domain=<domain-value>; Secure; HttpOnly",
    );
    expect(name, "<cookie-name>");
    expect(value, "<cookie-value>");
    expect(attrs, {'Domain': '<domain-value>', 'Secure': '', 'HttpOnly': ''});
    // What happens if the user forgets to strip the header name
    (name, value, attrs) = store.parseSetCookie(
      "Set-Cookie: <cookie-name>=<cookie-value>; Domain=<domain-value>; Secure; HttpOnly",
    );
    expect(name, "Set-Cookie: <cookie-name>");
    expect(value, "<cookie-value>");
    expect(attrs, {'Domain': '<domain-value>', 'Secure': '', 'HttpOnly': ''});
    // Cookie values can be empty
    (name, value, attrs) = store.parseSetCookie(
      "<cookie-name>=; Domain=<domain-value>; Secure; HttpOnly",
    );
    expect(name, "<cookie-name>");
    expect(value, "");
    expect(attrs, {'Domain': '<domain-value>', 'Secure': '', 'HttpOnly': ''});
    // Cookie names cannot be
    expect(
      () => store.parseSetCookie(
        "<cookie-value>;asdasdasd=asdasdasd;asdffds=asdfsf",
      ),
      throwsFormatException,
    );
  });
  test('Cookie Store - Test multiple cookies per header', () {
    /// TODO: Minimal test, expand on this
    CookieStore store = CookieStore();
    store.updateCookies("test=true,test2=true", "example.com", "/");
    expect(store.cookies.length, 2);
    // Make sure dates don't get split
    store.updateCookies(
      "asd=fgd;expires=Fri, 23 Apr 2800 13:45:56 GMT",
      "example.com",
      "/",
    );
    expect(store.cookies.length, 3);
  });
  test('Cookie Store - Test the canonicalisation method', () {
    CookieStore store = CookieStore();

    String result = store.toCanonical("öbb.at");
    expect(result, "xn--bb-eka.at");

    result = store.toCanonical("Bücher.example");
    expect(result, "xn--bcher-kva.example");

    result = store.toCanonical("example.com");
    expect("example.com", result);

    // Test invalid domains (validation from punycoder)
    expect(() => store.toCanonical("a" * 64 + ".com"), throwsFormatException);
    expect(() => store.toCanonical("-example.com"), throwsFormatException);
    expect(() => store.toCanonical("example-.com"), throwsFormatException);
    expect(() => store.toCanonical("ex--ample.com"), throwsFormatException);
    expect(() => store.toCanonical("example..com"), throwsFormatException);
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

  test('End to end tests', () {
    CookieStore store = CookieStore();
    store.updateCookies(
      "PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3",
      "example.com",
      "/sample-directory/sample.php",
    );
    String cookieHeader = CookieStore.buildCookieHeader(
      store.getCookiesForRequest("example.com", "/"),
    );
    // the cookie was set on "/sample-directory/" so should not be used for "/"
    expect("", cookieHeader);

    store.updateCookies("lang=en/ca", "example.com", "/");
    cookieHeader = CookieStore.buildCookieHeader(
      store.getCookiesForRequest("example.com", "/"),
    );
    expect("lang=en/ca", cookieHeader);

    cookieHeader = CookieStore.buildCookieHeader(
      store.getCookiesForRequest("example.com", "/sample-directory"),
    );
    expect("PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3;lang=en/ca", cookieHeader);

    store.updateCookies("test=true", "example.com", "/");
    cookieHeader = CookieStore.buildCookieHeader(
      store.getCookiesForRequest("example.com", "/example"),
    );
    expect("lang=en/ca;test=true", cookieHeader);
  });

  group('Path handling', () {
    const requestDomain = 'example.com';
    late CookieStore store;

    void check(
      String requestPath,
      String expectedCookieHeader, [
      String? reason,
    ]) {
      final requestHeader = CookieStore.buildCookieHeader(
        store.getCookiesForRequest(requestDomain, requestPath),
      );
      expect(
        requestHeader,
        expectedCookieHeader,
        reason: '$requestPath $reason',
      );
    }

    setUp(() {
      store = CookieStore();
    });

    test('without explicit path attribute', () {
      store.updateCookies(
        "PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3",
        requestDomain,
        "/sample-directory/sample.php",
      );
      check("/", "", "Request path is root and not below /sample-directory");
      check("/sample-directory", "PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3");

      store.updateCookies("lang=en/ca", requestDomain, "/");
      check("/", "lang=en/ca");

      store.updateCookies("test=true", requestDomain, "/");
      check("/", "lang=en/ca;test=true");
    });

    test('with path attribute', () {
      assert(
        store.updateCookies(
          'PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3; Path=/example/',
          requestDomain,
          "/sample-directory/sample.php",
        ),
      );
      assert(
        store.updateCookies(
          "lang=en/ca; Path=/login/path/page",
          requestDomain,
          "/sample-directory/sample.php",
        ),
      );
      assert(
        store.updateCookies(
          'test=true; Path=/',
          requestDomain,
          "/sample-directory/sample.php",
        ),
      );

      check(
        '/example',
        'PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3;test=true',
        'exactly matches path attribute',
      );
      check(
        '/example/subpath/with/page',
        'PHPSESSID=el4ukv0kqbvoirg7nkp4dncpk3;test=true',
        'subpath of path attribute',
      );
      check('/', 'test=true', 'not a subpath of path attribute');
      check('/login', 'test=true', 'path is below / but not part of example');
      check(
        '/login/path',
        'lang=en/ca;test=true',
        'path is below / but not part of example',
      );
    });
  });
}
