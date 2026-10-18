import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/Models/UserModel.dart';

class UserDAO {
  Db db;
  UserDAO(this.db);

  Future<WriteResult> InsertUser(UserModel usuario) async {
    return await db.collection('Usuarios').insertOne(usuario.toRegister());
  }

  Future<UserModel?> findUser(UserModel user) async {
    try {
      List<Map<String, dynamic>> orFilters = [
        {'email': user.email},
        {'nome': user.nome},
      ];

      // A MÁGICA DA EDIÇÃO:
      // Se o objeto já tem um ID, queremos buscar conflitos com OUTROS usuários

      Map<String, dynamic> query = {r'$or': orFilters};

      if (user.id != null) {
        query['_id'] = {r'$ne': user.id};

        //     {
        //   "$or": [
        //     {"email": "vini@academia.com"},
        //     {"nome": "vinicius_arquiteto"}
        //   ],
        //   "_id": {
        //     "$ne": ObjectId("65f123abc456def789012345")
        //   }
        // }
      }

      final result = await db.collection('Usuarios').findOne(query);
      return result == null
          ? null
          : UserModel(
              id: result['_id'],
              email: result['email'],
              nome: result['nome'],
              senha: result['senha'],
              altura: result['altura'],
              peso: result['peso'],
            );
    } on MongoDartError catch (e) {
      throw e;
    } catch (e, s) {
      print("$e, $s");
      throw e;
    }
    // Criamos um mapa para o $or (Email ou Nome)
  }

  Future<UserModel?> findByEmail(String email) async {
    final result = await db.collection('Usuarios').findOne({'email': email});
    if (result == null) return null;

    return UserModel(
      id: result['_id'] as ObjectId,
      email: result['email'],
      nome: result['nome'],
      senha: result['senha'],
      altura: result['altura'],
      peso: result['peso'],
    );
  }

  // TALVEZ NEM PRECISE

  // Future<UserModel?> findByEmail(UserModel usuario) async {
  //   var user = await db.collection('Usuarios').findOne(
  //     {"email": usuario.email},
  // );

  // if(user == null){
  //   return null;
  // }
  //   return UserModel(email: user['email'], nome: user['nome'], senha: user['senha']);
  // }

  Future<WriteResult> UpdateUser(
    UserModel usuario,
    UserModel updateuser,
  ) async {
    return await db
        .collection('Usuarios')
        .updateOne({'_id': usuario.id}, {'\$set': updateuser.toSetting()});
  }
}
