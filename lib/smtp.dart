library smtp;

import 'dart:async';
import 'dart:convert' show Encoding, LineSplitter;
import 'dart:io';
import 'package:async/async.dart';
import 'package:dart2_constant/convert.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

part 'src/protocol.dart';
part 'src/server.dart';

final DateFormat _fmt = new DateFormat('EEE, d MMM yyyy HH:mm:ss Z');
