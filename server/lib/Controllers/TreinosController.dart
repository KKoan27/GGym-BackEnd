import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/Models/ExercicioModel.dart';
import 'package:server/Models/TreinoModel.dart';
import 'package:server/Services/TreinoService.dart';
import 'package:shelf/shelf.dart';
import 'package:server/Utilitys/Exceptions.dart';
import 'package:server/Utilitys/ReturnJson.dart';

class Treinoscontroller {
  TreinoService treinoservice;

  Treinoscontroller(this.treinoservice);

  Future<Response> listTreinos(Request request) async {
    try {
      String? userid = request.url.queryParameters['userid'];

      if (userid == null) throw MissingParametersException('userid faltante');
      List<TreinoModel> listatreinoresponse = await treinoservice.listTreinos(
        userid,
      );

      return Response.ok(jsonEncode(listatreinoresponse));
    } on TreinoNotFoundException catch (e) {
      return Response.ok("Usuario não tem treino cadastrado");
    } on MissingParametersException catch (e) {
      return Response.badRequest(body: jsonEncode({'erro': e.message}));
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'erro': e.toString()}));
    }
  }

  Future<Response> insertTreino(Request request) async {
    try {
      Map<String, dynamic>? bodyrequest = await returnjson(request);

      if (bodyrequest == null ||
          bodyrequest['userId'] == null ||
          bodyrequest['nomeTreino'] == null ||
          bodyrequest['exercicios'] == null)
        throw MissingParametersException();

      final exerciciosRequestDoBody =
          bodyrequest['exercicios'] as List<dynamic>;
      List<String> setNomeExercicios = exerciciosRequestDoBody
          .map((e) => e['nome'] as String)
          .toList();

      Set<ExercicioModel> setExercicios = await treinoservice.verifyExercicios(
        setNomeExercicios,
      );

      Map<String, ExercicioModel> dicExercicios = {
        for (var ex in setExercicios) ex.nome: ex,
      };

      List<ItemTreino> itemsTreino = exerciciosRequestDoBody.map((E) {
        return ItemTreino(
          exercicio: dicExercicios[E['nome']]!,
          intervalo: E['intervalo'],
          repeticoes: E['repeticoes'],
        );
      }).toList();

      TreinoModel treino = TreinoModel(
        itemTreino: itemsTreino,
        nome: bodyrequest['nomeTreino'],
        userId: ObjectId.parse(bodyrequest['userId']),
      );

      Map<String, dynamic> response = {
        'message': 'Treino inserido com sucesso',
        'id': (await treinoservice.insertTreino(treino)),
      };

      return Response(201, body: jsonEncode(response));
    } on ExercicioNotFoundException catch (e) {
      return Response.notFound(
        jsonEncode({'erro': e.message, 'exercicios': e.listExercicios}),
      );
    } catch (e, s) {
      print(s);
      return Response.badRequest(body: jsonEncode({'erro': e.toString()}));
    }
  }

  Future<Response> deleteTreino(Request request) async {
    try {
      String? treinoid = request.url.queryParameters['treinoId'];

      if (treinoid == null)
        throw MissingParametersException("treinoId não foi inserido na URL");

      Map<String, dynamic> response = {
        'message': "Deleção executada com sucesso",
        'id': await treinoservice.deleteTreino(treinoid),
      };

      return Response.ok(jsonEncode(response));
    } on TreinoNotFoundException catch (e) {
      return Response.notFound(jsonEncode({"message": e.message}));
    } on MissingParametersException catch (e) {
      return Response.badRequest(body: jsonEncode({'erro': e}));
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'erro': e}));
    }
  }

  Future<Response> updateTreino(Request request) async {
    try {
      final treinoId = request.url.queryParameters['TreinoId'];
      if (treinoId == null || treinoId.isEmpty) {
        throw MissingParametersException("TreinoId não foi inserido na URL");
      }

      final body = await returnjson(request);
      if (body == null ||
          body['nomeTreino'] is! String ||
          body['exercicios'] is! List) {
        throw MissingParametersException();
      }

      final userId = await treinoservice.findTreinoUserId(treinoId);
      final exerciciosRequest = body['exercicios'] as List<dynamic>;
      final nomesExercicios = exerciciosRequest
          .map((item) => (item as Map<String, dynamic>)['nome'] as String)
          .toList();

      final exercicios = await treinoservice.verifyExercicios(nomesExercicios);
      // Após verificação, aqui está anexando o objeto exercicio ao seu nome

      final exerciciosPorNome = {
        for (final exercicio in exercicios) exercicio.nome: exercicio,
      };
      final itensTreino = exerciciosRequest.map((item) {
        final itemMap = item as Map<String, dynamic>;
        return ItemTreino(
          exercicio: exerciciosPorNome[itemMap['nome'] as String]!,
          repeticoes: itemMap['repeticoes'] as int,
          intervalo: itemMap['intervalo'] as int,
        );
      }).toList();

      final treino = TreinoModel(
        nome: body['nomeTreino'] as String,
        userId: userId,
        itemTreino: itensTreino,
      );
      await treinoservice.updateTreino(treinoId, treino);

      return Response.ok(
        "A troca foi bem sucedida : \n TreinoID: $treinoId,\n Nome do Treino : ${treino.nome}",
      );
    } on ExercicioNotFoundException catch (e) {
      return Response.notFound(
        jsonEncode({'erro': e.message, 'exercicios': e.listExercicios}),
      );
    } on TreinoNotFoundException catch (e) {
      return Response.notFound(jsonEncode({'erro': e.message}));
    } on MissingParametersException catch (e) {
      return Response.badRequest(body: jsonEncode({'erro': e.message}));
    } on MongoDartError catch (e, s) {
      print("Erro ao atualizar treino: $e\n$s");
      return Response(
        502,
        body: jsonEncode({'erro': 'Não foi possível atualizar o treino'}),
      );
    } on DataBaseException catch (e) {
      return Response(502, body: jsonEncode({'erro': e.message}));
    } catch (e, s) {
      print("Erro ao atualizar treino: $e\n$s");
      return Response.badRequest(body: jsonEncode({'erro': e.toString()}));
    }
  }
}
