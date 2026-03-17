import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/category_model.dart';

class CategoryRepository {
  CategoryRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<List<Category>> getCategories(String userId) async {
    final data = await _client
        .from('categories')
        .select()
        .eq('user_id', userId)
        .order('name', ascending: true);
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<Category> createCategory(Category category) async {
    final data = await _client.from('categories').insert(category.toJson()).select().single();
    return Category.fromJson(data);
  }

  Future<Category> updateCategory(Category category) async {
    final data = await _client.from('categories').update(category.toJson()).eq('id', category.id).select().single();
    return Category.fromJson(data);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _client.from('categories').delete().eq('id', categoryId);
  }
}
