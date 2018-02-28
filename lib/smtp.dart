library smtp;

import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:intl/intl.dart';

part 'src/protocol.dart';
part 'src/server.dart';

final DateFormat _fmt = new DateFormat('EEE, d MMM yyyy HH:mm:ss Z');