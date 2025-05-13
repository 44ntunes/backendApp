import 'dart:convert'; 
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;

// Função para enviar e-mail
Future<void> enviarEmailViaBackend(String to, String subject, String body) async {
  // Lê usuário e senha do SMTP das variáveis de ambiente
  final smtpUser = Platform.environment['SMTP_USER'];
  final smtpPass = Platform.environment['SMTP_PASS'];
  if (smtpUser == null || smtpPass == null) {
    throw StateError('Variáveis SMTP_USER ou SMTP_PASS não definidas');
  }

  // Configuração do servidor SMTP com TLS na porta 587
  final smtpServer = SmtpServer(
    'smtp.gmail.com',
    username: smtpUser,
    password: smtpPass,
    port: 587,   // Porta para TLS
    ssl: false,  // desativa SSL, pois estamos usando TLS
  ); 

  final message = Message()
    ..from = Address(smtpUser, 'ImTrouble')
    ..recipients.add(to)
    ..subject = subject
    ..text = body;

  try {
    final sendReport = await send(message, smtpServer);
    print('E-mail enviado: ${sendReport.toString()}');
  } catch (e) {
    print('Erro ao enviar e-mail: $e');
  }
}

// Função que recebe dados via HTTP e envia o e-mail
Future<void> handleRequest(HttpRequest request) async {
  final data = await utf8.decoder.bind(request).join();
  final jsonBody = jsonDecode(data);

  final to = jsonBody['to'] as String;
  final subject = jsonBody['subject'] as String;
  final body = jsonBody['body'] as String;

  await enviarEmailViaBackend(to, subject, body);
}

// Função principal que configura o servidor HTTP
void main() async {
  // Lê a porta da variável de ambiente PORT, ou usa 8080 se não existir
  final portEnv = Platform.environment['PORT'];
  final port = portEnv != null ? int.parse(portEnv) : 8080;

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Servidor rodando na porta $port');

  await for (final request in server) {
    if (request.method == 'POST') {
      try {
        await handleRequest(request);
        request.response
          ..statusCode = HttpStatus.ok
          ..write('E-mail enviado com sucesso!')
          ..close();
      } catch (e) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Erro interno: $e')
          ..close();
      }
    } else {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Método não permitido')
        ..close();
    }
  }
}
