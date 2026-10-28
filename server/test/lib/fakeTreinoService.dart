import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/Models/ExercicioModel.dart';
import 'package:server/Models/TreinoModel.dart';
import 'package:server/Services/TreinoService.dart';
import 'package:server/data/DAO/TreinoDAO.dart';

class FakeTreinoService extends TreinoService {
  FakeTreinoService() : super(TreinoDAO(Db('mongodb://localhost/test')));

  final ObjectId userId = ObjectId.fromHexString('65f123abc456def789012346');
  TreinoModel? updatedTreino;
  String? updatedId;

  @override
  Future<ObjectId> findTreinoUserId(String treinoId) async => userId;

  @override
  Future<Set<ExercicioModel>> verifyExercicios(
    List<String> listaNomesExercicios,
  ) async {
    return {
      ExercicioModel(
        nome: 'Supino',
        musculosAlvo: ['Peito'],
        descricao: 'Empurrar a barra',
        execucao: 'Deitado no banco',
      ),
    };
  }

  @override
  Future<void> updateTreino(String treinoId, TreinoModel treino) async {
    updatedId = treinoId;
    updatedTreino = treino;
  }
}
