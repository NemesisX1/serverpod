// Add your modules' endpoints to the `endpoints` directory. Run
// `serverpod generate` to produce the modules server and client code. Refer to
// the documentation on how to add endpoints to your server.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/module.dart';

import '../generated/protocol.dart';

const _configFilePath = 'config/google_client_secret.json';

/// Endpoint for handling Sign in with Google.
class EmailEndpoint extends Endpoint {

  Future<AuthenticationResponse> authenticate(Session session, String email, String password) async {
    email = email.toLowerCase();
    password = password.trim();

    print('authenticate $email / $password');

    // Fetch password entry
    var entry = (await session.db.findSingleRow(tEmailAuth, where: tEmailAuth.email.equals(email))) as EmailAuth?;
    if (entry == null)
      return AuthenticationResponse(success: false);

    print(' - found entry ');

    // Check that password is correct
    if (entry.hash != Emails.generatePasswordHash(password)) {
      print(' - ${Emails.generatePasswordHash(password)} saved: ${entry.hash}');
      return AuthenticationResponse(success: false);
    }

    print(' - password is correct, userId: ${entry.userId})');

    var userInfo = await Users.findUserByUserId(session, entry.userId);
    if (userInfo == null)
      return AuthenticationResponse(success: false);

    print(' - user found');

    // Sign in user and return user info
    var auth = await session.auth.signInUser(entry.userId, 'email');

    print(' - user signed in');

    return AuthenticationResponse(
      success: true,
      userInfo: userInfo,
      key: auth.key,
      keyId: auth.id,
    );
  }
}
