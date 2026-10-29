import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:server/Controllers/UserController.dart';
import 'package:server/Models/UserModel.dart';
import 'package:server/Utilitys/Exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'lib/fakeUserService.dart';

const testJwtSecret = 'test-only-secret-for-user-auth-tests';

void main() {
  group('POST /user/register', () {
    test('registra um usuario com os dados enviados', () async {
      final service = FakeUserService();
      final controller = UserController(service);

      final response = await controller.Register(
        Request(
          'POST',
          Uri.parse('http://localhost/user/register'),
          body: jsonEncode({
            'nome': 'Ana Silva',
            'email': 'ana@example.com',
            'senha': 'senha-segura',
          }),
        ),
      );

      expect(response.statusCode, 200);
      final responseBody =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(responseBody['nome'], 'Ana Silva');
      expect(responseBody['email'], 'ana@example.com');
      expect(service.registerCalls, 1);
      expect(service.registeredUser, isA<UserModel>());
      expect(service.registeredUser?.nome, 'Ana Silva');
      expect(service.registeredUser?.email, 'ana@example.com');
      expect(service.registeredUser?.senha, 'senha-segura');
      expect(service.registeredUser?.peso, 0.0);
      expect(service.registeredUser?.altura, 0.0);
    });

    test('retorna 409 quando o usuario ja esta cadastrado', () async {
      final service = FakeUserService(userAlreadyExists: true);
      final controller = UserController(service);

      final response = await controller.Register(
        Request(
          'POST',
          Uri.parse('http://localhost/user/register'),
          body: jsonEncode({
            'nome': 'Ana Silva',
            'email': 'ana@example.com',
            'senha': 'senha-segura',
          }),
        ),
      );

      expect(response.statusCode, 409);
      final responseBody =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(responseBody['error'], UserAlreadyExistsException().message);
      expect(service.registerCalls, 1);
    });

    test('retorna 400 e nao chama o servico para JSON invalido', () async {
      final service = FakeUserService();
      final controller = UserController(service);

      final response = await controller.Register(
        Request('POST', Uri.parse('http://localhost/user/register'), body: '{'),
      );

      expect(response.statusCode, 400);
      expect(service.registerCalls, 0);
    });
  });

  group('POST /user/auth', () {
    test('autentica e retorna um token assinado sem expor a senha', () async {
      final service = FakeUserService();
      final userId = ObjectId();
      service.authenticatedUser = UserModel(
        id: userId,
        nome: 'Ana Silva',
        email: 'ana@example.com',
        senha: 'hash-da-senha',
        peso: 72.0,
        altura: 1.75,
      );
      final controller = UserController(service, jwtSecret: testJwtSecret);

      final response = await controller.Auth(
        Request(
          'POST',
          Uri.parse('http://localhost/user/auth'),
          body: jsonEncode({
            'email': 'ana@example.com',
            'senha': 'senha-segura',
          }),
        ),
      );

      expect(response.statusCode, 200);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['message'], 'Autenticado com sucesso');
      expect(body['token'], isA<String>());
      expect(body['token'], isNotEmpty);
      expect(body['response']['id'], userId.oid);
      expect(body['response']['email'], 'ana@example.com');
      expect(body['response'].containsKey('senha'), isFalse);
      expect(jsonEncode(body), isNot(contains('senha-segura')));

      final jwt = JWT.verify(body['token'] as String, SecretKey(testJwtSecret));
      expect(jwt.payload['id'], userId.oid);
      expect(jwt.payload['role'], 'user');
      expect(service.authCalls, 1);
      expect(service.authRequest?.email, 'ana@example.com');
      expect(service.authRequest?.senha, 'senha-segura');
    });

    test('retorna 401 para senha inválida', () async {
      final service = FakeUserService()..authError = InvalidPasswordException();
      final controller = UserController(service, jwtSecret: testJwtSecret);

      final response = await controller.Auth(
        Request(
          'POST',
          Uri.parse('http://localhost/user/auth'),
          body: jsonEncode({'email': 'ana@example.com', 'senha': 'incorreta'}),
        ),
      );

      expect(response.statusCode, 401);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['invalidPassoword'], InvalidPasswordException().message);
      expect(service.authCalls, 1);
    });

    test('retorna 401 quando o usuário não existe', () async {
      final service = FakeUserService()..authError = UserNotFoundException();
      final controller = UserController(service, jwtSecret: testJwtSecret);

      final response = await controller.Auth(
        Request(
          'POST',
          Uri.parse('http://localhost/user/auth'),
          body: jsonEncode({
            'email': 'inexistente@example.com',
            'senha': 'senha-segura',
          }),
        ),
      );

      expect(response.statusCode, 401);
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['userNotFound'], UserNotFoundException().message);
      expect(service.authCalls, 1);
    });

    test('retorna 400 sem chamar o serviço quando faltam parâmetros', () async {
      final service = FakeUserService();
      final controller = UserController(service, jwtSecret: testJwtSecret);

      final response = await controller.Auth(
        Request(
          'POST',
          Uri.parse('http://localhost/user/auth'),
          body: jsonEncode({'email': 'ana@example.com'}),
        ),
      );

      expect(response.statusCode, 400);
      expect(service.authCalls, 0);
    });
  });
}
