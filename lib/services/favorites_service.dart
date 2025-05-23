import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  final Set<String> _favoriteIds = {};
  static const String _prefsKey = 'favorite_ids';
  late SharedPreferences _prefs;

  FavoritesService() {
    _loadFavorites();
  }

  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    final favoriteIdsList = _prefs.getStringList(_prefsKey) ?? [];
    _favoriteIds.addAll(favoriteIdsList);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    await _prefs.setStringList(_prefsKey, _favoriteIds.toList());
    notifyListeners();
  }
} 