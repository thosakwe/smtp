part of smtp;

abstract class SmtpRequest implements IOSink {
  String get method;
  List<String> get arguments;

  Future close({int statusCode: 221, String reasonPhrase: 'Bye'});
}

abstract class SmtpMailObject {
  SmtpConnectionInfo get connectionInfo;

  bool get supportsSmtpExtensions;

  SmtpEnvelope get envelope;

  String get content;

  Stream<MimeMultipart> get mimeMultiparts;

  Future close({int statusCode: 221, String reasonPhrase: 'Bye'});
}

abstract class SmtpEnvelope {
  String get originatorAddress;

  List<String> get recipientAddresses;

  SmtpHeaders get headers;
}

abstract class SmtpHeaders {
  MediaType get contentType;

  DateTime get date;

  String get from;

  String get to;

  List<String> get cc;

  List<String> get bcc;

  String get subject;

  Map<String, String> toMap();
}

abstract class SmtpConnectionInfo {
  InternetAddress get remoteAddress;

  String get remoteHostname;

  int get localPort;

  int get remotePort;
}

class _SmtpRequestImpl implements SmtpRequest {
  final String method;
  final List<String> arguments;
  final Socket socket;
  final StreamSubscription sub;

  _SmtpRequestImpl(this.method, this.arguments, this.socket, this.sub);

  @override
  Future close({int statusCode: 221, String reasonPhrase: 'Bye'}) async {
    socket.writeln('$statusCode $reasonPhrase');
    sub.resume();
  }

  @override
  Encoding get encoding => socket.encoding;

  void set encoding(Encoding encoding) {
    socket.encoding = encoding;
  }

  @override
  Future get done => socket.done;

  @override
  Future flush() => socket.flush();

  @override
  Future addStream(Stream<List<int>> stream) => socket.addStream(stream);

  @override
  void addError(error, [StackTrace stackTrace]) =>
      socket.addError(error, stackTrace);

  @override
  void writeCharCode(int charCode) => socket.writeCharCode(charCode);

  @override
  void writeln([Object obj = ""]) => socket.writeln(obj);

  @override
  void writeAll(Iterable objects, [String separator = ""]) =>
      socket.writeAll(objects, separator);

  @override
  void write(Object obj) => socket.write(obj);

  @override
  void add(List<int> data) => socket.add(data);
}

class _SmtpMailObjectImpl implements SmtpMailObject {
  final SmtpConnectionInfo connectionInfo;
  final bool supportsSmtpExtensions;
  final SmtpEnvelope envelope;
  final String content;
  final Socket socket;

  _SmtpMailObjectImpl(this.connectionInfo, this.supportsSmtpExtensions,
      this.envelope, this.content, this.socket);

  @override
  Future close({int statusCode: 221, String reasonPhrase: 'Bye'}) {
    // Send Bye
    socket.writeln('$statusCode $reasonPhrase');
    return socket.close();
  }

  @override
  Stream<MimeMultipart> get mimeMultiparts {
    if (envelope.headers.contentType?.type != 'multipart') {
      throw new FormatException(
          'Can only parse a multipart/* body into separate parts.');
    }

    var boundary = envelope.headers.contentType.parameters['boundary'];

    if (boundary?.trim()?.isNotEmpty != true) {
      throw new FormatException(
          'Cannot parse body into parts; no boundary parameter was specified in the `Content-Type` header.');
    }

    var stream = new Stream<List<int>>.fromIterable([utf8.encode(content)]);
    return stream.transform(new MimeMultipartTransformer(boundary));
  }
}

class _SmtpEnvelopeImpl implements SmtpEnvelope {
  final String originatorAddress;
  final List<String> recipientAddresses;
  final SmtpHeaders headers;

  _SmtpEnvelopeImpl(
      this.originatorAddress, this.recipientAddresses, this.headers);
}

class _SmtpHeadersImpl implements SmtpHeaders {
  final Map<String, String> headers;

  List<String> _cc, _bcc;
  MediaType _contentType;
  DateTime _date;

  _SmtpHeadersImpl(Map<String, String> headers)
      : this.headers = new CaseInsensitiveMap.from(headers);

  MediaType get contentType =>
      _contentType ??= (headers.containsKey('Content-Type')
          ? new MediaType.parse(headers['Content-Type'])
          : null);

  @override
  DateTime get date {
    return _date ??=
        (headers.containsKey('Date') ? HttpDate.parse(headers['Date']) : null);
  }

  @override
  String get from => headers['From'];

  @override
  String get to => headers['To'];

  @override
  String get subject => headers['subject'];

  @override
  List<String> get cc =>
      _cc ??= (headers.containsKey('Cc') ? headers['Cc'].split(',') : []);

  @override
  List<String> get bcc =>
      _bcc ??= (headers.containsKey('Bcc') ? headers['Bcc'].split(',') : []);

  @override
  Map<String, String> toMap() => headers;
}

class _SmtpConnectionInfoImpl implements SmtpConnectionInfo {
  final InternetAddress remoteAddress;
  final String remoteHostname;
  final int localPort, remotePort;

  _SmtpConnectionInfoImpl(
      this.remoteAddress, this.remoteHostname, this.localPort, this.remotePort);
}
