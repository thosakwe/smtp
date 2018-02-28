# smtp
[![Pub](https://img.shields.io/pub/v/smtp.svg)](https://pub.dartlang.org/packages/smtp)
[![build status](https://travis-ci.org/thosakwe/smtp.svg)](https://travis-ci.org/thosakwe/smtp)

An
[SMTP 5321](https://tools.ietf.org/html/rfc5321)
server implementation in Dart.

## Usage
More documentation coming soon...

```dart
import 'package:smtp/smtp.dart';

main() async {
  var server = await SmtpServer.bind('127.0.0.1', 0);
  
  await for (var request in server) {
    print(request.envelope.originatorAddress);
    print(request.envelope.headers.cc);
  }
}
```