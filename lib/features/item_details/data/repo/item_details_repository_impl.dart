abstract class ItemDetailsRepository {
  Future<Map<String, dynamic>> getItemDetails(String id);
}

class ItemDetailsRepositoryImpl implements ItemDetailsRepository {
  const ItemDetailsRepositoryImpl();

  @override
  Future<Map<String, dynamic>> getItemDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'id': id,
      'title': 'Sample item',
      'description': 'Detailed description',
    };
  }
}
