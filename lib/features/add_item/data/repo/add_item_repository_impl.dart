abstract class AddItemRepository {
  Future<String> addItem({required String title, required String description});
}

class AddItemRepositoryImpl implements AddItemRepository {
  const AddItemRepositoryImpl();

  @override
  Future<String> addItem({required String title, required String description}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Item added successfully';
  }
}
