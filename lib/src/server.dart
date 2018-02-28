part of smtp;

abstract class SmtpServer extends Stream<SmtpMailObject> {
  String hostname = Platform.localHostname;
  String greeting = '';

  static Future<SmtpServer> bind(address, int port,
      {int backlog: 0, bool v6Only: false, bool shared: false}) async {
    var socket = await ServerSocket.bind(address, port,
        backlog: backlog, v6Only: v6Only, shared: shared);
    return new _SmtpServerImpl(
        socket, socket.address, socket.port, socket.close);
  }

  static Future<SmtpServer> bindSecure(
      address, int port, SecurityContext context,
      {int backlog: 0,
      bool v6Only: false,
      bool shared: false,
      bool requestClientCertificate: false,
      bool requireClientCertificate: false,
      List<String> supportedProtocols}) async {
    var socket = await SecureServerSocket.bind(address, port, context,
        backlog: backlog,
        v6Only: v6Only,
        shared: shared,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate,
        supportedProtocols: supportedProtocols);
    return new _SmtpServerImpl(
        socket, socket.address, socket.port, socket.close);
  }

  InternetAddress get address;

  int get port;

  Future close({bool force: false});
}

class _SmtpServerImpl extends SmtpServer {
  static final RegExp _header = new RegExp(r'([^:]+): ([^$]+)');
  static final RegExp _helo =
      new RegExp(r'(HELO|EHLO) ([^$]+)', caseSensitive: false);
  static final RegExp _mailFrom =
      new RegExp(r'MAIL FROM:<([^>]+)>', caseSensitive: false);
  static final RegExp _rcptTo =
      new RegExp(r'RCPT TO:<([^>]+)>', caseSensitive: false);
  final Stream<Socket> stream;
  final InternetAddress address;
  final int port;
  final Future Function() closeFunction;
  final StreamController<SmtpMailObject> _stream = new StreamController();
  StreamSubscription _sub;

  _SmtpServerImpl(this.stream, this.address, this.port, this.closeFunction) {
    _sub = stream.listen(handleSocket,
        onError: _stream.addError, onDone: _stream.close);
  }

  Future close({bool force: false}) async {
    // TODO: apply `force`
    _sub.cancel();
    await closeFunction();
  }

  @override
  StreamSubscription<SmtpMailObject> listen(void onData(SmtpMailObject event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _stream.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  handleSocket(Socket socket) async {
    var lines = new StreamQueue<String>(
        socket.transform(UTF8.decoder).transform(const LineSplitter()));

    // Send 220
    socket.writeln('220 $hostname $greeting'.trim());

    // Wait for HELO
    SmtpConnectionInfo connectionInfo;
    bool supportsSmtpExtensions;

    while (await lines.hasNext) {
      var line = await lines.next;
      var heloMatch = _helo.firstMatch(line);

      if (heloMatch != null) {
        connectionInfo = new _SmtpConnectionInfoImpl(
            socket.remoteAddress, heloMatch[2], port, socket.remotePort);
        supportsSmtpExtensions = heloMatch[1].toLowerCase() == 'ehlo';
        break;
      }
    }

    if (connectionInfo == null) {
      // TODO: What happens if HELO is never sent?
    }

    // Send a greeting
    socket.writeln('250 $hostname, I am glad to meet you');

    String mailFrom;
    List<String> rcptTo = [];

    while (await lines.hasNext) {
      var line = await lines.next;

      if (mailFrom == null) {
        var m = _mailFrom.firstMatch(line);

        if (m == null) {
          socket.writeln('503 command out of sequence');
          await socket.close();
          return;
        }

        mailFrom = m[1];
        socket.writeln('250 Ok');
      } else {
        var m = _rcptTo.firstMatch(line);
        if (m != null) {
          rcptTo.add(m[1]);
          socket.writeln('250 Ok');
        } else if (line == 'DATA') {
          socket.writeln('354 End data with <CR><LF>.<CR><LF>');
          break;
        } else {
          // TODO: What happens if we receive unrecognized data?
        }
      }
    }

    // Read headers
    Map<String, String> headers = {};

    while (await lines.hasNext) {
      var line = await lines.next;

      if (line.isEmpty) break;

      var m = _header.firstMatch(line);

      if (m == null) {
        // TODO: What if something other than a header is sent?
      } else {
        headers[m[1]] = m[2];
      }
    }

    // Read message
    var message = new StringBuffer();

    while (await lines.hasNext) {
      var line = await lines.next;

      if (line == '.')
        break;
      else if (line.startsWith('.'))
        message.writeln(line.substring(1));
      else
        message.writeln(line);
    }

    // Create request
    var mailObject = new _SmtpMailObjectImpl(
      connectionInfo,
      supportsSmtpExtensions,
      new _SmtpEnvelopeImpl(
        mailFrom,
        rcptTo,
        new _SmtpHeadersImpl(headers),
      ),
      message.toString(),
      socket,
    );

    _stream.add(mailObject);
  }
}
