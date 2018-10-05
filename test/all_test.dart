import 'dart:convert' show LineSplitter;
import 'dart:io';
import 'package:async/async.dart';
import 'package:dart2_constant/convert.dart';
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

  test('plain text', () async {
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

    var mailObject = await server.mailObjects.first;
    await mailObject.close();

    expect(mailObject.supportsSmtpExtensions, isTrue);
    expect(mailObject.envelope.originatorAddress, envelope.from);
    expect(mailObject.envelope.recipientAddresses, hasLength(5));
    print(mailObject.envelope.headers.toMap());
    // expect(mailObject.envelope.headers.bcc, envelope.bccRecipients);
    expect(mailObject.envelope.headers.cc, envelope.ccRecipients);
    expect(mailObject.envelope.headers.contentType.mimeType, 'multipart/mixed');
    expect(mailObject.envelope.headers.subject, envelope.subject);
  });
  test('read multipart', () async {
    var smtp = new SmtpTransport(new SmtpOptions()
      ..hostName = server.address.address
      ..port = server.port);

    var envelope = new Envelope()
      ..from = 'foo@bar.com'
      ..recipients.add('someone@somewhere.com')
      ..subject = 'Huh HTML'
      ..html = '<h1>Test</h1><p>Hey!</p>';

    smtp.send(envelope);

    var mailObject = await server.mailObjects.first;
    await mailObject.close();

    print(mailObject.content);

    var part = await mailObject.mimeMultiparts.first;
    expect(part.headers['Content-Type'], 'text/html');
    expect(mailObject.content, envelope.html);
  }, skip: 'Mailer package sends invalid MIME');

  test('require mail from', () async {
    var socket = await Socket.connect(server.address, server.port);
    var s = socket.asBroadcastStream();
    stdout.addStream(s);
    var lines = new StreamQueue<String>(
        s.transform(utf8.decoder).transform(const LineSplitter()));

    // Await 220
    await lines.next;

    socket.writeln('HELO dart_test');
    await lines.next; // Await 250

    // Send RCPT TO without MAIL FROM
    socket.writeln('RCPT TO:<foo@bar.com>');
    var line = await lines.next;
    expect(line, startsWith('503'));
    await socket.close();
  });

  test('require rcpt to', () async {
    var socket = await Socket.connect(server.address, server.port);
    var s = socket.asBroadcastStream();
    stdout.addStream(s);
    var lines = new StreamQueue<String>(
        s.transform(utf8.decoder).transform(const LineSplitter()));

    // Await 220
    await lines.next;

    socket.writeln('HELO dart_test');
    await lines.next; // Await 250

    socket.writeln('MAIL FROM:<foo@bar.com>');
    await lines.next; // Await 250

    // Send DATA without RCPT TO
    socket.writeln('DATA');
    var line = await lines.next;

    expect(line, startsWith('554'));
    await socket.close();
  });
}
