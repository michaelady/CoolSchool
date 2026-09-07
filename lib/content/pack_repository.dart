import 'package:flutter/services.dart';

import '../l10n/app_locales.dart';
import 'models.dart';

abstract class PackRepository {
  Future<List<ContentPack>> loadAll(String locale);
  Future<ContentPack> loadPack(String topicId, String locale);
}

class AssetPackRepository implements PackRepository {
  const AssetPackRepository();

  static const topicIds = ['addition', 'subtraction', 'counting', 'vocab'];

  @override
  Future<List<ContentPack>> loadAll(String locale) async {
    final packs = <ContentPack>[];
    for (final id in topicIds) {
      packs.add(await loadPack(id, locale));
    }
    return packs;
  }

  @override
  Future<ContentPack> loadPack(String topicId, String locale) async {
    final code = AppLocales.normalize(locale);
    final source = await rootBundle.loadString(
      'assets/content/packs/${topicId}_$code.json',
    );
    return ContentPack.fromJsonString(source);
  }
}

class MemoryPackRepository implements PackRepository {
  MemoryPackRepository(ContentPack pack) : packs = [pack];

  MemoryPackRepository.all(this.packs);

  final List<ContentPack> packs;

  @override
  Future<List<ContentPack>> loadAll(String locale) async => packs;

  @override
  Future<ContentPack> loadPack(String topicId, String locale) async {
    return packs.firstWhere(
      (pack) => pack.id == topicId,
      orElse: () => packs.first,
    );
  }
}
