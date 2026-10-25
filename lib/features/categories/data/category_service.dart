import 'category_repository.dart';

/// Menjalankan perubahan kategori lalu menyegarkan konteks native.
class CategoryService {
  CategoryService({
    required this.repository,
    required this.refreshNativeContext,
  });

  final CategoryRepository repository;
  final Future<void> Function() refreshNativeContext;

  Future<void> add({
    required String name,
    required String type,
    String? keywords,
  }) async {
    await repository.add(name: name, type: type, keywords: keywords);
    await refreshNativeContext();
  }

  Future<void> update({
    required int id,
    required String name,
    String? keywords,
  }) async {
    await repository.update(id: id, name: name, keywords: keywords);
    await refreshNativeContext();
  }

  Future<void> delete({required int id, int? moveToId}) async {
    await repository.delete(id: id, moveToId: moveToId);
    await refreshNativeContext();
  }
}
