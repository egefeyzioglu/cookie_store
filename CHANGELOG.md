## 0.1.0
Extract the cookie store into its own package

## 0.2.0
Allow RFC2109-style multi-cookie Set-Cookie headers

## 0.2.1
Add test badge to the README

## 0.2.2
Fix crash when force shrinking cookie store.

Also delete only excessive cookies (not all cookies from excessive domains) when shrinking with `force=false`. (This was the intended behaviour.)

## 0.2.3
Downgrade meta package to ^1.9.0

## 0.3.0
Fix path matching when returning cookies

## 0.3.1
Allow HTTP-style dates for the expires attribute

## 0.3.2
Some bugfixes, be even more permissive when parsing dates in the expires attribute

# 0.3.3
Be even more permissive when parsing dates, also mention this in the README
