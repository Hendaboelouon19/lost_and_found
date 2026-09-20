abstract class HomeRepository {
  Future<List<Map<String, dynamic>>> getItems();
}

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl();

  @override
  Future<List<Map<String, dynamic>>> getItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {'id': '1', 'title': 'Item 1', 'description': 'Sample item'},
    ];
  }
}
