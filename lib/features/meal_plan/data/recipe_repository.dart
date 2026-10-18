import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/features/meal_plan/data/recipes_seed_data.dart';
import 'package:lumina/features/meal_plan/domain/models/recipe_model.dart';

/// Supabase stores the user catalog (favorites, custom recipes). The bundled
/// catalog is the verified baseline: every recipe there owns its photo, so it
/// wins over a catalog row with the same title — that is how a stale
/// `image_url`/`image_path` in the database cannot bring a wrong photo back.
class RecipeRepository {
  final SupabaseService _supabase = SupabaseService();

  Future<List<Recipe>> loadRecipes() async {
    final bundled = buildSeedRecipes();
    final byTitle = {for (final r in bundled) _titleKey(r.title): r};

    try {
      final rows = await _supabase.client
          .from('recipes')
          .select(
            '*, recipe_categories(name), recipe_ingredients(*), recipe_steps(*)',
          )
          .eq('is_published', true)
          .order('title');
      final remote = (rows as List).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final category = row['recipe_categories'];
        row['category'] = category is Map ? category['name'] : row['category'];
        row['ingredients'] = row.remove('recipe_ingredients') ?? const [];
        row['steps'] = row.remove('recipe_steps') ?? const [];
        return Recipe.fromJson(row);
      }).where((r) => r.title.trim().isNotEmpty).toList();

      if (remote.isEmpty) return bundled;

      final merged = <Recipe>[...bundled];
      final seenIds = merged.map((r) => r.id).toSet();
      for (final recipe in remote) {
        if (byTitle.containsKey(_titleKey(recipe.title))) continue;
        if (seenIds.contains(recipe.id)) continue;
        seenIds.add(recipe.id);
        merged.add(recipe);
      }
      return List.unmodifiable(merged);
    } catch (e) {
      debugPrint('Recipe catalog uses bundled data: $e');
      return bundled;
    }
  }

  static String _titleKey(String title) =>
      title.toLowerCase().replaceAll(RegExp(r'[^a-zа-яё0-9]+'), ' ').trim();

  Future<Set<String>> loadFavoriteIds() async {
    final userId = AuthService().userId;
    final prefs = await SharedPreferences.getInstance();
    final local =
        prefs.getStringList('recipe_favorites_${userId ?? 'anon'}')?.toSet() ??
        <String>{};
    if (userId == null) return local;
    try {
      final rows = await _supabase.client
          .from('recipe_favorites')
          .select('recipe_id')
          .eq('user_id', userId);
      final remote = (rows as List)
          .map((e) => e['recipe_id'].toString())
          .toSet();
      return remote.isEmpty ? local : remote;
    } catch (e) {
      debugPrint('Recipe favorites use local cache: $e');
      return local;
    }
  }

  Future<void> setFavorite(String recipeId, bool favorite) async {
    final userId = AuthService().userId;
    if (userId == null) return;
    if (favorite) {
      await _supabase.client.from('recipe_favorites').upsert({
        'user_id': userId,
        'recipe_id': recipeId,
      });
    } else {
      await _supabase.client
          .from('recipe_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);
    }
  }
}
