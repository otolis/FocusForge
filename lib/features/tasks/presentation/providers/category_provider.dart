import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/category_repository.dart';
import '../../domain/category_model.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(),
);

final categoryListProvider = AsyncNotifierProvider<CategoryListNotifier, List<Category>>(
  CategoryListNotifier.new,
);

class CategoryListNotifier extends AsyncNotifier<List<Category>> {
  @override
  FutureOr<List<Category>> build() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getCategories(userId);
  }

  Future<void> addCategory(Category category) async {
    final repo = ref.read(categoryRepositoryProvider);
    final created = await repo.createCategory(category);
    state = AsyncData([...state.value ?? [], created]);
  }

  Future<void> updateCategory(Category category) async {
    final repo = ref.read(categoryRepositoryProvider);
    final updated = await repo.updateCategory(category);
    final categories = [...state.value ?? []];
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = updated;
      state = AsyncData(categories);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.deleteCategory(categoryId);
    state = AsyncData([...state.value ?? []]..removeWhere((c) => c.id == categoryId));
  }
}
