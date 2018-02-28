part of smtp;

abstract class SmtpRequest {
  SmtpHeaders get headers;

  SmtpConnectionInfo connectionInfo;
  String message;
}

abstract class SmtpHeaders {
  DateTime get date;

  String get from;

  String get to;

  String get cc;

  String get subject;
}

abstract class SmtpConnectionInfo {
  InternetAddress get remoteAddress;

  int get localPort;

  int get remotePort;
}

class _SmtpHeadersImpl implements SmtpHeaders {
  final Map<String, String> headers;

  DateTime _date;

  _SmtpHeadersImpl(this.headers);

  @override
  DateTime get date {
    return _date ??=
        (headers.containsKey('date') ? _fmt.parse(headers['date']) : null);
  }

  @override
  String get from => headers['from'];

  @override
  String get to => headers['to'];

  @override
  String get subject => headers['subject'];

  @override
  String get cc => headers['cc'];
}

class _SmtpConnectionInfoImpl implements SmtpConnectionInfo {
  final InternetAddress remoteAddress;
  final int localPort, remotePort;

  _SmtpConnectionInfoImpl(this.remoteAddress, this.localPort, this.remotePort);
}
