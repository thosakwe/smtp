import 'package:mailer/mailer.dart';
import 'package:smtp/smtp.dart';
import 'package:test/test.dart';

void main() {
  SmtpServer server;

  setUp(() async {
    server = await SmtpServer.bind('127.0.0.1', 0);
  });

  tearDown(() async {
    await server.close();
  });

  test('send simple email', () async {
    var smtp = new SmtpTransport(new SmtpOptions()
      ..hostName = server.address.address
      ..port = server.port);

    var envelope = new Envelope()
      ..from = 'foo@bar.com'
      ..recipients.add('someone@somewhere.com')
      ..recipients.add('someone_else@somewhere.com')
      ..bccRecipients.add('hidden@recipient.com')
      ..ccRecipients.add('also_hidden@recipient.com')
      ..ccRecipients.add('also_also_hidden@recipient.com')
      ..subject = 'Testing the Dart Mailer library 語'
      ..text = 'This is a cool email message. Whats up? 語';
      //..html = '<h1>Test</h1><p>Hey!</p>';

    smtp.send(envelope);

    var request = await server.first;
    expect(request.envelope.originatorAddress, envelope.from);
    expect(request.envelope.recipientAddresses, envelope.recipients.reversed.toList());
    expect(request.envelope.headers.bcc, envelope.bccRecipients);
    expect(request.envelope.headers.cc, envelope.ccRecipients);
    expect(request.envelope.headers.contentType.mimeType, 'multipart/mixed');
    expect(request.envelope.headers.subject, envelope.subject);
  });
}
