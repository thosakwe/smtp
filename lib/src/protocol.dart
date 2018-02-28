part of smtp;

abstract class SmtpRequest {
  String get mailFrom;

  List<String> get rcptTo;

  SmtpHeaders get headers;

  SmtpConnectionInfo get connectionInfo;

  String get message;
}

abstract class SmtpHeaders {
  ContentType get contentType;

  DateTime get date;

  String get from;

  String get to;

  String get cc;

  String get bcc;

  String get subject;
}

abstract class SmtpConnectionInfo {
  InternetAddress get remoteAddress;

  String get remoteHostname;

  int get localPort;

  int get remotePort;
}

class _SmtpRequestImpl implements SmtpRequest {
  final String mailFrom;
  final List<String> rcptTo;
  final SmtpHeaders headers;
  final SmtpConnectionInfo connectionInfo;
  final String message;

  _SmtpRequestImpl(this.mailFrom, this.rcptTo, this.headers,
      this.connectionInfo, this.message);
}

class _SmtpHeadersImpl implements SmtpHeaders {
  final Map<String, String> headers;

  ContentType _contentType;

  DateTime _date;

  _SmtpHeadersImpl(this.headers);

  ContentType get contentType => _contentType ??= (headers.containsKey('Content-Type') ? ContentType.parse(headers['Content-Type']) : null);

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
  String get subject => headers['Subject'];

  @override
  String get cc => headers['Cc'];

  @override
  String get bcc => headers['Bcc'];
}

class _SmtpConnectionInfoImpl implements SmtpConnectionInfo {
  final InternetAddress remoteAddress;
  final String remoteHostname;
  final int localPort, remotePort;

  _SmtpConnectionInfoImpl(
      this.remoteAddress, this.remoteHostname, this.localPort, this.remotePort);
}
