part of smtp;

abstract class SmtpServer extends Stream<SmtpRequest> {
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

  Stream<SmtpMailObject> get mailObjects;

  InternetAddress get address;

  int get port;

  Future close();
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
  final StreamController<SmtpMailObject> _mailObjects = new StreamController();
  final StreamController<SmtpRequest> _stream = new StreamController();
  StreamSubscription _sub;

  _SmtpServerImpl(this.stream, this.address, this.port, this.closeFunction) {
    _sub = stream.listen(handleSocket,
        onError: _mailObjects.addError, onDone: _mailObjects.close);
  }

  @override
  Stream<SmtpMailObject> get mailObjects {
    return _mailObjects.stream;
  }

  Future close() async {
    _sub.cancel();
    _mailObjects.close();
    _stream.close();
    await closeFunction();
  }

  @override
  StreamSubscription<SmtpRequest> listen(void onData(SmtpRequest event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _stream.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  handleSocket(Socket socket) async {
    // Send 220
    socket.writeln('220 $hostname $greeting'.trim());

    var lineStream =
        socket.transform(utf8.decoder).transform(const LineSplitter());

    var interceptedLines = new StreamController<String>();
    bool shouldIntercept = true, closed = false;

    StreamSubscription sub;

    sub = lineStream.listen((line) {
      if (!shouldIntercept)
        interceptedLines.add(line);
      else if (line.isNotEmpty) {
        var split = line.split(' ');
        var method = split[0].toUpperCase(), arguments = split.skip(1).toList();

        if (method == 'HELO' ||
            method == 'EHLO' ||
            method == 'MAIL' ||
            method == 'RCPT' ||
            method == 'RSET' ||
            method == 'DATA')
          interceptedLines.add(line);
        else if (method == 'QUIT') {
          closed = true;
          sub.cancel();
          interceptedLines.close();
          socket.close();
        } else if (method == 'NOOP') {
          // Do nothing; No-op.
        } else {
          var request = new _SmtpRequestImpl(method, arguments, socket, sub);
          sub.pause();
          _stream.add(request);
        }
      }
    }, onError: interceptedLines.addError, onDone: interceptedLines.close);

    var lines = new StreamQueue<String>(interceptedLines.stream);

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

    if (closed) return;

    if (connectionInfo == null) {
      // If HELO is never sent, just close the connection.
      socket.close();
      return;
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
          if (rcptTo.isEmpty) {
            socket.writeln('554 no valid recipients');
            await socket.close();
            return;
          }

          shouldIntercept = false;
          socket.writeln('354 End data with <CR><LF>.<CR><LF>');
          break;
        } else {
          // If we receive unrecognized data, close the socket.
          socket.close();
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
        // If something other than a header is sent, just close the socket.
        socket.close();
        return;
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

    _mailObjects.add(mailObject);
  }
}
