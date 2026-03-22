import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/category_model.dart';
import '../providers/category_provider.dart';
import '../widgets/category_color_picker.dart';

/// Screen for managing user categories (create, rename, recolor, delete).
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Could not load categories.'),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildCategoryList(context, ref, categories);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: context.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first category',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Create Category',
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: category.color,
            ),
          ),
          title: Text(category.name),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _showRenameDialog(context, ref, category);
                case 'color':
                  _showColorDialog(context, ref, category);
                case 'delete':
                  _showDeleteDialog(context, ref, category);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'color', child: Text('Change color')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          onTap: () => _showRenameDialog(context, ref, category),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    int selectedColorIndex = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Category name',
                controller: nameController,
              ),
              const SizedBox(height: 16),
              CategoryColorPicker(
                selectedIndex: selectedColorIndex,
                onColorSelected: (index) {
                  setDialogState(() => selectedColorIndex = index);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final userId =
                    Supabase.instance.client.auth.currentUser!.id;
                final category = Category(
                  id: const Uuid().v4(),
                  userId: userId,
                  name: name,
                  colorIndex: selectedColorIndex,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                ref
                    .read(categoryListProvider.notifier)
                    .addCategory(category);
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    final nameController = TextEditingController(text: category.name);
    int selectedColorIndex = category.colorIndex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rename Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Category name',
                controller: nameController,
              ),
              const SizedBox(height: 16),
              CategoryColorPicker(
                selectedIndex: selectedColorIndex,
                onColorSelected: (index) {
                  setDialogState(() => selectedColorIndex = index);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                ref.read(categoryListProvider.notifier).updateCategory(
                      category.copyWith(
                        name: name,
                        colorIndex: selectedColorIndex,
                      ),
                    );
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    int selectedColorIndex = category.colorIndex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Choose Color'),
          content: CategoryColorPicker(
            selectedIndex: selectedColorIndex,
            onColorSelected: (index) {
              setDialogState(() => selectedColorIndex = index);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(categoryListProvider.notifier).updateCategory(
                      category.copyWith(colorIndex: selectedColorIndex),
                    );
                Navigator.of(ctx).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          "Tasks using '${category.name}' will have their category removed. "
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(categoryListProvider.notifier)
                  .deleteCategory(category.id);
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
