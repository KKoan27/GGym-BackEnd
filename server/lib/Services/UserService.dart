import 'package:bcrypt/bcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/Models/UserModel.dart';
import 'package:server/data/DAO/UserDAO.dart';
import 'package:server/Utilitys/Exceptions.dart';

class UserService {
  UserDAO userdao;

  UserService(this.userdao);

  Future<UserModel> Register(UserModel usuario) async {
    if (await userdao.findUser(usuario) != null) {
      throw UserAlreadyExistsException();
    }
    usuario.senha = BCrypt.hashpw(usuario.senha!, BCrypt.gensalt());

    WriteResult resultInsert = await userdao.InsertUser(usuario);

    if (resultInsert.hasWriteErrors) throw Exception(" ${resultInsert.errmsg}");

    return UserModel.registerReponse(
      id: resultInsert.id,
      nome: usuario.nome,
      email: usuario.email,
    );
  }

  Future<UserModel> Auth(UserModel userRequest) async {
    UserModel? userResponse = await userdao.findUser(userRequest);

    if (userResponse == null) throw UserNotFoundException();

    if (!BCrypt.checkpw(userRequest.senha!, userResponse.senha!)) {
      throw InvalidPasswordException();
    }

    return userResponse;
  }

  Future<void> UpdateSettings(UserModel settings) async {
    final user = await userdao.findByEmail(settings.email!);
    if (user == null) throw UserNotFoundException();

    final result = await userdao.UpdateUser(user, settings);
    if (result.hasWriteErrors) {
      throw DataBaseException(result.writeError?.errmsg);
    }
  }
}
