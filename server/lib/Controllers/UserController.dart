// ignore: file_names
import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/Controllers/JWTController.dart';
import 'package:server/Models/UserModel.dart';
import 'package:server/Services/UserService.dart';
import 'package:server/Utilitys/custom_env.dart';
import 'package:shelf/shelf.dart';
import 'package:server/Utilitys/ReturnJson.dart';
import 'package:server/Utilitys/Exceptions.dart';

class UserController {
  UserService userservice;
  final String? _jwtSecret;

  UserController(this.userservice, {String? jwtSecret})
    : _jwtSecret = jwtSecret;

  // Arquitetura do Handler - Entra um request no parametro e retorna uma Response (promessa)
  Future<Response> Register(Request request) async {
    try {
      Map<String, dynamic>? body = await returnjson(request);

      //Verificação do body da requisição
      if (body == null) {
        return Response.badRequest(body: "Corpo de requisição nulo");
      }
      UserModel usuario = UserModel(
        nome: body['nome'],
        email: body['email'],
        senha: body['senha'],
        peso: 0.0,
        altura: 0.0,
      );

      // Mandando para o service
      UserModel userResponse = await userservice.Register(usuario);

      // PENDENTE: Inserir um message "Usuário cadastrado com sucesso"
      return Response.ok(jsonEncode(userResponse.toRegister()));

      // Exceções
    } on UserAlreadyExistsException catch (e) {
      return Response(409, body: jsonEncode({'error': e.message}));
    } catch (e, s) {
      print("Erro: $e \n $s");
      return Response.badRequest(body: "Erro ao cadastrar o usuario : $e ");
    }
  }

  Future<Response> Auth(Request request) async {
    try {
      Map<String, dynamic>? body = await returnjson(request);

      if (body == null) throw MissingParametersException();
      final secret =
          _jwtSecret ??
          Platform.environment['JWTsecret'] ??
          await Customenv.get<String>(key: 'JWTsecret');

      UserModel userRequest = UserModel.auth(
        email: body['email'],
        senha: body['senha'],
      );

      if (userRequest.email == null || userRequest.senha == null) {
        throw MissingParametersException();
      }

      UserModel userResponse = await userservice.Auth(userRequest);

      Map<String, dynamic> payload = {'id': userResponse.id, 'role': 'user'};

      String token = JWTController.signer(payload, secret);

      return Response.ok(
        jsonEncode({
          'message': 'Autenticado com sucesso',
          'token': token,
          'response': userResponse.toJson(),
        }),
      );
    } on InvalidPasswordException catch (e) {
      return Response.unauthorized(jsonEncode({'invalidPassoword': e.message}));
    } on UserNotFoundException catch (e) {
      return Response.unauthorized(jsonEncode({'userNotFound': e.message}));
    } on MissingParametersException catch (e) {
      return Response.badRequest(body: jsonEncode({'error': e.message}));
    } catch (e, s) {
      print(s);
      return Response.badRequest(body: jsonEncode({'error': e}));
    }
  }

  Future<Response> updateSettings(Request request) async {
    try {
      final body = await returnjson(request);
      if (body == null ||
          body['email'] is! String ||
          body['altura'] is! num ||
          body['peso'] is! num) {
        throw MissingParametersException();
      }

      final settings = UserModel.setting(
        email: body['email'] as String,
        altura: (body['altura'] as num).toDouble(),
        peso: (body['peso'] as num).toDouble(),
      );

      await userservice.UpdateSettings(settings);
      return Response.ok("Configurações executadas");
    } on UserNotFoundException catch (e) {
      return Response.notFound(jsonEncode({'erro': e.message}));
    } on MissingParametersException catch (e) {
      return Response.badRequest(body: jsonEncode({'erro': e.message}));
    } on MongoDartError catch (e) {
      print("Erro ao atualizar configurações do usuário: $e");
      return Response(
        502,
        body:
            "A requisição passou para o banco de dados, mas a alteração não foi executada",
      );
    } on DataBaseException catch (e) {
      return Response(502, body: jsonEncode({'erro': e.message}));
    } catch (e, s) {
      print("Erro ao atualizar configurações do usuário: $e\n$s");
      return Response.badRequest(body: jsonEncode({'erro': e.toString()}));
    }
  }
}
