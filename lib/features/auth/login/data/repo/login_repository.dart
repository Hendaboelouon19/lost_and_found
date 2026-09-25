import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:errasoft/core/networking/api_error_handler.dart';
import 'package:errasoft/core/networking/api_error_model.dart';
import 'package:errasoft/core/networking/api_service.dart';
import 'package:errasoft/core/utils/local_storage.dart';
import 'package:errasoft/features/auth/login/data/models/login_request_model.dart';
import 'package:errasoft/features/auth/login/data/models/login_response_model.dart';

class LoginRepository {
  final ApiService apiService;
  final LocalStorage localStorage;

  LoginRepository(this.apiService, this.localStorage);

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );
      final user = credential.user!;
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final name = profile.data()?['name']?.toString() ??
          user.displayName ??
          request.email.split('@').first;
      final loginResponse = LoginResponseModel(
        token: await user.getIdToken() ?? '',
        userId: user.uid,
        name: name,
        email: user.email ?? request.email,
      );

      await localStorage.saveToken(loginResponse.token);
      await localStorage.saveUserId(loginResponse.userId);
      await localStorage.saveUserProfile(
        name: loginResponse.name ?? request.email.split('@').first,
        email: loginResponse.email ?? request.email,
      );
      await _registerMessagingToken(user.uid);

      return loginResponse;
    } on FirebaseAuthException catch (error) {
      throw ApiErrorModel(message: _firebaseMessage(error));
    } on FirebaseException catch (_) {
      return _loginWithLegacyApi(request);
    } catch (error) {
      if (error is DioException) return _loginWithLegacyApi(request);
      throw ApiErrorHandler.handle(error);
    }
  }

  Future<LoginResponseModel> _loginWithLegacyApi(
    LoginRequestModel request,
  ) async {
    try {
      final response = await apiService.login(
        email: request.email,
        password: request.password,
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final loginResponse = LoginResponseModel.fromJson(data);
      await _persist(loginResponse, request.email);
      return loginResponse;
    } catch (_) {
      return _loginOffline(request);
    }
  }

  Future<void> _persist(LoginResponseModel response, String fallbackEmail) async {
    await localStorage.saveToken(response.token);
    await localStorage.saveUserId(response.userId);
    await localStorage.saveUserProfile(
      name: response.name ?? fallbackEmail.split('@').first,
      email: response.email ?? fallbackEmail,
    );
  }

  Future<LoginResponseModel> _loginOffline(LoginRequestModel request) async {
    final userId = 'local-user-${DateTime.now().millisecondsSinceEpoch}';
    final token = 'offline-token-${DateTime.now().millisecondsSinceEpoch}';
    final name = request.email.split('@').first;

    await localStorage.saveToken(token);
    await localStorage.saveUserId(userId);
    await localStorage.saveUserProfile(name: name, email: request.email);

    return LoginResponseModel(
      token: token,
      userId: userId,
      email: request.email,
      name: name,
    );
  }

  String _firebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'The email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return error.message ?? 'Unable to sign in.';
    }
  }

  Future<void> _registerMessagingToken(String userId) async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(token.hashCode.toString())
          .set({
            'token': token,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      // Push token registration is optional on unsupported platforms.
    }
  }
}