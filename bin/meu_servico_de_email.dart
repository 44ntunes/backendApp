import 'dart:convert';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Função para enviar e-mail
Future<void> enviarEmailViaBackend(String to, String subject, {String? textBody, String? htmlBody}) async {
  final smtpUser = Platform.environment['SMTP_USER'];
  final smtpPass = Platform.environment['SMTP_PASS'];
  if (smtpUser == null || smtpPass == null) {
    throw StateError('Variáveis SMTP_USER ou SMTP_PASS não definidas');
  }

  final smtpServer = SmtpServer(
    'smtp.gmail.com',
    username: smtpUser,
    password: smtpPass,
    port: 587,
    ssl: false,
  );

  final message = Message()
    ..from = Address(smtpUser, 'InTrouble')
    ..recipients.add(to)
    ..subject = subject;

  if (textBody != null && textBody.isNotEmpty) {
    message.text = textBody;
  }
  if (htmlBody != null && htmlBody.isNotEmpty) {
    message.html = htmlBody;
  }

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
  final textBody = jsonBody['text'] as String?;
  final htmlBody = jsonBody['html'] as String?;

  if ((textBody == null || textBody.isEmpty) && (htmlBody == null || htmlBody.isEmpty)) {
    throw ArgumentError('Nenhum conteúdo para enviar: texto ou html deve ser informado.');
  }

  await enviarEmailViaBackend(to, subject, textBody: textBody, htmlBody: htmlBody);
}

// Função principal que configura o servidor HTTP
void main() async {
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
