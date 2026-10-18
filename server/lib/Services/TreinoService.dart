import 'dart:collection';
import 'dart:core';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/Models/ExercicioModel.dart';
import 'package:server/Models/TreinoModel.dart';
import 'package:server/data/DAO/TreinoDAO.dart';
import 'package:server/Utilitys/Exceptions.dart';
import 'package:server/Models/UserModel.dart';

class TreinoService {
  TreinoDAO treinodao;

  TreinoService(this.treinodao);

  Future<Set<ExercicioModel>> verifyExercicios(
    List<String> listaNomesExercicios,
  ) async {
    return await treinodao.recoveryExercicios(listaNomesExercicios);
  }

  Future<List<TreinoModel>> listTreinos(String userid) async {
    //Verificando se o usuario existe no BD
    UserModel user = await treinodao.userFind(userid);

    return await treinodao.treinosFindByUserId(user.id!);
  }

  Future<String> insertTreino(TreinoModel treino) async {
    return treinodao.treinoInsert(treino);
  }

  Future<String> deleteTreino(String treinoid) async {
    //PENDENTE VALIDAÇÃO  se o treino é realmente do usuario que solicitou
    return await treinodao.treinoDelete(treinoid);
  }

  Future<ObjectId> findTreinoUserId(String treinoId) async {
    final userId = await treinodao.treinoUserId(ObjectId.parse(treinoId));
    if (userId == null) throw TreinoNotFoundException();
    return userId;
  }

  Future<void> updateTreino(String treinoId, TreinoModel treino) async {
    final result = await treinodao.treinoUpdate(
      ObjectId.parse(treinoId),
      treino,
    );
    if (result.hasWriteErrors) {
      throw DataBaseException(result.writeError?.errmsg);
    }
  }

  // Future<Response> updateTreino(Request request)async{

  // }
}
