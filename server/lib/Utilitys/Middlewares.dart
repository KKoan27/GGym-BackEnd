import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:server/Utilitys/custom_env.dart';

const Map<String, String> corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

Middleware verifyJWT() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        String secret = Platform.environment['JWTsecret'] ?? await Customenv.get<String>(key: 'JWTsecret');

        String? authorization = request.headers['Authorization'];

        if (authorization == null || !authorization.startsWith('Bearer ')) {
          return Response.unauthorized(
            jsonEncode({'Erro': 'JWT ausente ou mal formatado'}),
          );
        }

        String token = authorization.split(' ')[1];

        JWT validacao = JWT.verify(token, SecretKey(secret));

        final requestComToken = request.change(
          context: {'jwt_payload': validacao.payload},
        );

        return innerHandler(requestComToken);
      } on JWTInvalidException catch (e) {
        return Response.unauthorized(
          jsonEncode({'Erro': "JWT Invalido", ' body': e.message}),
        );
      } on JWTExpiredException catch (e) {
        return Response.unauthorized(
          jsonEncode({'Erro': "JWT Expirou", ' body': e.message}),
        );
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'Erro': '{$e}'}));
      }
    };
  };
}

Middleware standardRespondeMiddleware() {
  return createMiddleware(
    requestHandler: (request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      return null;
    },

    responseHandler: (originalresponse) async {
      String originalResponseString = await originalresponse.readAsString();
      dynamic responseBody;
      if (originalResponseString.isNotEmpty) {
        try {
          responseBody = jsonDecode(originalResponseString);
        } catch (_) {
          responseBody = originalResponseString;
        }
      } else {
        responseBody = {};
      }

      return originalresponse.change(
        headers: {
          ...corsHeaders,
          ...originalresponse.headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'statusCode': originalresponse.statusCode,
          'body': responseBody,
        }),
      );
    },
    errorHandler: (e, stack) => Response.internalServerError(
      headers: {...corsHeaders, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'statusCode': 500,
        'body': {
          'error': 'Ocorreu um erro interno no servidor.',
          'details': e.toString(),
          'stack': stack.toString(),
        },
      }),
    ),
  );
}
