import 'package:flutter/services.dart';

import 'models.dart';

abstract class PackRepository {
  Future<ContentPack> loadAddition(String locale);
}

class AssetPackRepository implements PackRepository {
  const AssetPackRepository();

  @override
  Future<ContentPack> loadAddition(String locale) async {
    final code = locale.startsWith('fr') ? 'fr' : 'de';
    final source = await rootBundle.loadString(
      'assets/content/packs/addition_$code.json',
    );
    return ContentPack.fromJsonString(source);
  }
}

class MemoryPackRepository implements PackRepository {
  const MemoryPackRepository(this.pack);

  final ContentPack pack;

  @override
  Future<ContentPack> loadAddition(String locale) async => pack;
}
