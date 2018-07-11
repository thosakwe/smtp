import 'package:smtp/smtp.dart';

main() async {
  var server = await SmtpServer.bind('127.0.0.1', 0);

  await for (var mailObject in server.mailObjects) {
    print(mailObject.envelope.originatorAddress);
    print(mailObject.envelope.headers.cc);
    mailObject.close(statusCode: 221, reasonPhrase: 'Bye!');
  }
}
