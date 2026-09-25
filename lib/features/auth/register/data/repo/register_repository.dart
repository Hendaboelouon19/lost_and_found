import 'package:errasoft/core/networking/api_error_handler.dart';
import 'package:errasoft/core/networking/api_error_model.dart';
import 'package:errasoft/core/networking/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:errasoft/features/auth/register/data/models/register_request_model.dart';

class RegisterRepository {
  final ApiService apiService;

  RegisterRepository(this.apiService);

  Future<void> register(RegisterRequestModel request) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: request.email,
            password: request.password,
          );
      final user = credential.user!;
      await user.updateDisplayName(request.name);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': request.name,
        'email': request.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (error) {
      throw ApiErrorModel(message: _firebaseMessage(error));
    } on FirebaseException {
      await apiService.register(
        name: request.name,
        email: request.email,
        password: request.password,
      );
    } catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  String _firebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      default:
        return error.message ?? 'Unable to create your account.';
    }
  }
}
