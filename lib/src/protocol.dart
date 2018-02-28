part of smtp;

abstract class SmtpMailObject {
  SmtpConnectionInfo get connectionInfo;
  SmtpEnvelope get envelope;
  String get content;
}

abstract class SmtpEnvelope {
  String get originatorAddress;
  List<String> get recipientAddresses;
  SmtpHeaders get headers;
}

abstract class SmtpHeaders {
  ContentType get contentType;

  DateTime get date;

  String get from;

  String get to;

  List<String> get cc;

  List<String> get bcc;

  String get subject;
}

abstract class SmtpConnectionInfo {
  InternetAddress get remoteAddress;

  String get remoteHostname;

  int get localPort;

  int get remotePort;
}

class _SmtpMailObjectImpl implements SmtpMailObject {
  final SmtpConnectionInfo connectionInfo;
  final SmtpEnvelope envelope;
  final String content;

  _SmtpMailObjectImpl(this.connectionInfo, this.envelope, this.content);
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
  ContentType _contentType;
  DateTime _date;

  _SmtpHeadersImpl(Map<String, String> headers)
      : this.headers = new CaseInsensitiveMap.from(headers);

  ContentType get contentType =>
      _contentType ??= (headers.containsKey('Content-Type')
          ? ContentType.parse(headers['Content-Type'])
          : null);

  @override
  DateTime get date {
    return _date ??=
        (headers.containsKey('Date') ? _fmt.parse(headers['Date']) : null);
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
}

class _SmtpConnectionInfoImpl implements SmtpConnectionInfo {
  final InternetAddress remoteAddress;
  final String remoteHostname;
  final int localPort, remotePort;

  _SmtpConnectionInfoImpl(
      this.remoteAddress, this.remoteHostname, this.localPort, this.remotePort);
}
