import 'dart:math';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/Models/ExercicioModel.dart';
import 'package:server/Models/TreinoModel.dart';
import 'package:server/Models/UserModel.dart';
import 'package:server/Utilitys/Exceptions.dart';

class TreinoDAO {
  Db db;
  TreinoDAO(this.db);

  Future<UserModel> userFind(String userid) async {
    ObjectId useridparsed = ObjectId.parse(userid);
    Map<String, dynamic>? user = await db.collection('Usuarios').findOne({
      '_id': useridparsed,
    });

    if (user == null) {
      throw UserNotFoundException();
    }
    return UserModel(
      id: user['_id'] as ObjectId,
      email: user['email'],
      nome: user['nome'],
      senha: user['senha'],
      altura: user['altura'],
      peso: user['peso'],
    );
  }

  Future<String> treinoInsert(TreinoModel treino) async {
    WriteResult result = await db
        .collection('Treinos')
        .insertOne(treino.toJson());

    if (result.hasWriteErrors)
      throw DataBaseException("Db Error : ${result.writeError!.errmsg}");

    return result.id.oid;
  }

  Future<WriteResult> treinoUpdate(ObjectId id, TreinoModel treino) async {
    return await db
        .collection('Treinos')
        .updateOne({'_id': id}, {'\$set': treino.toJson()});
  }

  Future<ObjectId?> treinoUserId(ObjectId id) async {
    final treino = await db.collection('Treinos').findOne({'_id': id});
    return treino?['userId'] as ObjectId?;
  }

  Future<Set<ExercicioModel>> recoveryExercicios(
    List<String> setNomeExerciciosReq,
  ) async {
    List<Map<String, dynamic>> exerciciosDB = await db
        .collection('Exercicios')
        .find({
          'nome': {'\$in': setNomeExerciciosReq},
        })
        .toList();

    if (exerciciosDB.length != setNomeExerciciosReq.length) {
      Set<String> setNomesExerciciosDB = exerciciosDB
          .map((e) => e['nome'] as String)
          .toSet();

      throw ExercicioNotFoundException(
        setNomeExerciciosReq.where((e) {
          return !setNomesExerciciosDB.contains(e);
        }).toList(),
      );
    } else {
      return exerciciosDB.map((e) {
        if (e != null) {
          return ExercicioModel(
            nome: e['nome'],
            musculosAlvo: List<String>.from(e['musculosAlvo']),
            descricao: e['descricao'],
            execucao: e['execucao'],
            dicas: e['dicas'] == null ? null : List<String>.from(e['dicas']),
          );
        }
      }).toSet();
    }
  }

  Future<List<TreinoModel>> treinosFindByUserId(ObjectId id) async {
    List<Map<String, dynamic>> listTreinosDb = await db
        .collection('Treinos')
        .find({'userId': id})
        .toList();

    if (listTreinosDb.isEmpty) {
      throw TreinoNotFoundException();
    }

    return listTreinosDb.map((treinolinha) {
      var exerciciolinha = treinolinha['exercicios'] as List<dynamic>? ?? [];

      return TreinoModel(
        nome: treinolinha['nomeTreino'],
        userId: treinolinha['userId'] as ObjectId,
        itemTreino: exerciciolinha.map((itemT) {
          return ItemTreino(
            repeticoes: itemT['repeticoes'],
            intervalo: itemT['intervalo'],
            exercicio: ExercicioModel(
              nome: itemT['nome'],
              musculosAlvo: List<String>.from(itemT['musculosAlvo'] ?? []),
              descricao: itemT['descricao'],
              execucao: itemT['execucao'],
              dicas: itemT['dicas'] != null
                  ? List<String>.from(itemT['dicas'])
                  : null,
            ),
          );
        }).toList(),
      );
    }).toList();
  }

  Future<String> treinoDelete(String id) async {
    ObjectId objectid = ObjectId.parse(id);
    if ((await db.collection('Treinos').findOne({'_id': objectid}) == null))
      throw TreinoNotFoundException();
    WriteResult result = await db.collection('Treinos').deleteOne({
      '_id': objectid,
    });
    if (result.hasWriteErrors)
      throw DataBaseException(result.writeError!.errmsg);
    return "Treino Deletado";
  }

  // Future methods for other operations can be added here
}
