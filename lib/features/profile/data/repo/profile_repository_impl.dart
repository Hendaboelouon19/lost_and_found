abstract class ProfileRepository {
  Future<Map<String, dynamic>> getProfile();
}

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl();

  @override
  Future<Map<String, dynamic>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'userId': '1',
      'name': 'John Doe',
      'bio': 'Flutter developer',
    };
  }
}
