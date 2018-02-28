part of smtp;

abstract class SmtpServer {
  String hostname = Platform.localHostname;
  String greeting;

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
}

class _SmtpServerImpl extends SmtpServer {
  final Stream<Socket> stream;
  final InternetAddress address;
  final int port;
  final Future Function() close;

  _SmtpServerImpl(this.stream, this.address, this.port, this.close);
}
