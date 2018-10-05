# smtp
[![Pub](https://img.shields.io/pub/v/smtp.svg)](https://pub.dartlang.org/packages/smtp)
[![build status](https://travis-ci.org/thosakwe/smtp.svg)](https://travis-ci.org/thosakwe/smtp)

An
[SMTP 5321](https://tools.ietf.org/html/rfc5321)
server implementation in Dart.

## Usage
This SMTP server should not be used as your front-facing server,
especially in production. Consider setting up Postfix to relay e-mail
to this server; that way, you can be sure that only well-formed e-mail
messages will touch your Dart code.

Note that this includes no spam protection, etc., and is simply
a plain SMTP server library.

```dart

main() async {
  var server = await SmtpServer.bind('127.0.0.1', 0);

  await for (var mailObject in server.mailObjects) {
    print(mailObject.envelope.originatorAddress);
    print(mailObject.envelope.headers.cc);
    mailObject.close(statusCode: 221, reasonPhrase: 'Bye!');
  }
}
```