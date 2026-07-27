// quantum_schema.dart
library quantum_schema;

import 'dart:collection';
import 'dart:typed_data';
import '../../quantum.dart';

class QLBlockPayload {
  final String blockType;
  final Map<String, dynamic> data;
  const QLBlockPayload({required this.blockType, required this.data});

  dynamic operator [](String key) => data[key];
  bool containsKey(String key) => data.containsKey(key);
  Map<String, dynamic> toMap() => <String, dynamic>{
        'blockType': blockType,
        'data': Map<String, dynamic>.from(data),
      };
}

class QLSchemaFieldSpec {
  final String name;
  final String path;
  final int type;
  final int flags;
  final String? relationTarget;
  final List<String> options;
  final double? min;
  final double? max;
  final Map<String, dynamic> meta;
  final List<QLSchemaFieldSpec> children;
  final QLSchemaFieldSpec? itemSpec;
  final List<String> allowedBlocks;
  final String? mediaType;
  final List<String> allowedMimeTypes;
  final int? minSizeBytes;
  final int? maxSizeBytes;
  final String? thumbnailIcon;
  final String? thumbnailPath;
  final Map<String, dynamic> mediaPolicy;
  final Map<String, dynamic> qualityPolicy;
  final Map<String, dynamic> streamingPolicy;
  final Map<String, dynamic> cachePolicy;
  final dynamic Function(Map<String, dynamic> record)? compute;
  int index;

  QLSchemaFieldSpec({
    required this.name,
    required this.path,
    required this.type,
    required this.flags,
    this.relationTarget,
    this.options = const [],
    this.min,
    this.max,
    this.meta = const {},
    this.children = const [],
    this.itemSpec,
    this.allowedBlocks = const [],
    this.mediaType,
    this.allowedMimeTypes = const [],
    this.minSizeBytes,
    this.maxSizeBytes,
    this.thumbnailIcon,
    this.thumbnailPath,
    this.mediaPolicy = const {},
    this.qualityPolicy = const {},
    this.streamingPolicy = const {},
    this.cachePolicy = const {},
    this.compute,
    this.index = -1,
  });

  bool get isVirtual => (flags & QLFieldFlags.isVirtual) != 0;
  bool get isComputed => (flags & QLFieldFlags.isComputed) != 0;
  bool get isRequired => (flags & QLFieldFlags.isRequired) != 0;
  bool get hasMany => (flags & QLFieldFlags.hasMany) != 0;
  bool get isReadOnly => (flags & QLFieldFlags.isReadOnly) != 0;
  bool get isMedia =>
      type == QLFieldType.media ||
      mediaType != null ||
      mediaPolicy.isNotEmpty ||
      allowedMimeTypes.isNotEmpty;
  bool get supportsAdaptiveQuality =>
      streamingPolicy['adaptiveQuality'] == true ||
      streamingPolicy['adaptive'] == true;
  bool get supportsRangeCaching =>
      cachePolicy['rangeCaching'] == true || cachePolicy['reels'] == true;
  bool get supportsLazyLoad =>
      isMedia ||
      hasMany ||
      mediaPolicy['lazyLoad'] == true ||
      mediaPolicy['lazy'] == true ||
      cachePolicy['lazyLoad'] == true ||
      cachePolicy['lazy'] == true;
}

class QLSchemaBlueprint {
  final String name;
  final List<QLSchemaFieldSpec> rootFields;
  final List<QLSchemaFieldSpec> fields;
  final Map<String, QLSchemaFieldSpec> byPath;

  QLSchemaBlueprint._(
    this.name,
    this.rootFields,
    this.fields,
    this.byPath,
  );

  int get fieldCount => fields.length;

  QLProjection createProjection(List<String> paths) {
    final p = QLProjection(fieldCount);
    final expanded = expandSelection(paths);
    for (final path in expanded) {
      final spec = byPath[path];
      if (spec != null && spec.index >= 0) p.select(spec.index);
    }
    return p;
  }

  List<String> expandSelection(List<String> paths) {
    if (paths.isEmpty) return const <String>[];
    final selected = <String>{};
    final normalized = paths
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);

    for (final spec in fields) {
      if (spec.isVirtual || spec.isComputed) continue;
      for (final path in normalized) {
        if (_matchesSelectPath(spec.path, path)) {
          selected.add(spec.path);
          break;
        }
      }
    }

    return selected.toList(growable: false);
  }

  static bool _matchesSelectPath(String fieldPath, String selectPath) {
    final field = fieldPath.replaceAll('[]', '');
    final select = selectPath.replaceAll('[]', '');
    if (field == select) return true;
    if (field.startsWith(select + '.')) return true;
    if (select.startsWith(field + '.')) return true;
    return false;
  }

  int getIndex(String path) => byPath[path]?.index ?? -1;

  QLSchemaFieldSpec? field(String path) => byPath[path];

  List<String> fieldPaths() =>
      fields.map((e) => e.path).toList(growable: false);

  dynamic _parseFieldValue(QLSchemaFieldSpec spec, dynamic raw) {
    if (spec.type == QLFieldType.array) {
      return _parseValue(spec, raw);
    }
    if (spec.type == QLFieldType.block) {
      return _parseBlockValue(spec, raw);
    }
    if (spec.hasMany) {
      if (raw is List) {
        final parsed = raw
            .map((e) => _parseItem(spec, e))
            .where((e) => e != null)
            .toList(growable: false);
        return parsed;
      }
      final parsed = _parseItem(spec, raw);
      return parsed == null ? null : <dynamic>[parsed];
    }
    return _parseValue(spec, raw);
  }

  dynamic _serializeFieldValue(QLSchemaFieldSpec spec, dynamic raw) {
    if (spec.type == QLFieldType.array) {
      return _serializeValue(spec, raw);
    }
    if (spec.type == QLFieldType.block) {
      return _serializeBlockValue(spec, raw);
    }
    if (spec.hasMany) {
      if (raw is List) {
        final serialized = raw
            .map((e) => _serializeItem(spec, e))
            .where((e) => e != null)
            .toList(growable: false);
        return serialized;
      }
      final serialized = _serializeItem(spec, raw);
      return serialized == null ? null : <dynamic>[serialized];
    }
    return _serializeValue(spec, raw);
  }

  List<String> _validateFieldValue(
    QLSchemaFieldSpec spec,
    dynamic value,
    String basePath,
  ) {
    final errs = <String>[];

    if (spec.isRequired && _isEmpty(value)) {
      errs.add('$basePath: required');
      return errs;
    }

    if (value == null) return errs;

    if (spec.hasMany && value is List) {
      for (int i = 0; i < value.length; i++) {
        errs.addAll(_validateItem(spec, value[i], '$basePath[$i]'));
      }
      return errs;
    }

    if (spec.type == QLFieldType.array &&
        value is List &&
        spec.itemSpec != null) {
      for (int i = 0; i < value.length; i++) {
        errs.addAll(_validateItem(spec.itemSpec!, value[i], '$basePath[$i]'));
      }
      return errs;
    }

    if ((spec.type == QLFieldType.block || spec.hasMany) && value is List) {
      for (int i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is Map) {
          final blockType = item['blockType']?.toString();
          final data = item['data'];
          if (blockType == null) {
            errs.add('$basePath[$i]: missing blockType');
            continue;
          }
          if (spec.allowedBlocks.isNotEmpty &&
              !spec.allowedBlocks.contains(blockType)) {
            errs.add('$basePath[$i]: invalid blockType');
            continue;
          }
          if (data is Map) {
            final blockSchema =
                QLSchemaRegistry.instance.getSchema(blockType) ??
                    QLSchemaCompiler.resolveSchema(blockType);
            if (blockSchema != null) {
              final blockErrs =
                  blockSchema.validate(Map<String, dynamic>.from(data));
              errs.addAll(blockErrs.map((e) => '$basePath[$i].data.$e'));
            } else if (spec.itemSpec != null) {
              errs.addAll(_validateItem(
                spec.itemSpec!,
                data,
                '$basePath[$i].data',
              ));
            }
          }
        } else {
          errs.add('$basePath[$i]: invalid block payload');
        }
      }
      return errs;
    }

    errs.addAll(_validateItem(spec, value, basePath));
    return errs;
  }

  Map<String, dynamic> parse(
    Map<String, dynamic> json, {
    QLProjection? projection,
  }) {
    final out = <String, dynamic>{};

    for (final spec in fields) {
      if (projection != null && !projection.isSelected(spec.index)) continue;
      if (spec.isVirtual) continue;
      if (spec.isComputed) continue;

      if (spec.path.contains('[]'))
        continue; // Array items are handled by the array spec natively

      final raw = _readAt(json, QLPathUtils.resolve(spec.path));
      if (raw == null) continue;

      if (spec.children.isNotEmpty &&
          spec.type == QLFieldType.object &&
          !spec.hasMany) {
        continue; // Objects are flattened, their children are processed individually
      }

      final parsed = _parseFieldValue(spec, raw);
      if (parsed == null && raw != null)
        continue; // Drop garbage types completely
      if (parsed == null && spec.isRequired) continue;
      _writeAt(out, QLPathUtils.resolve(spec.path), parsed);
    }

    for (final spec in fields) {
      if (!spec.isComputed || spec.compute == null) continue;
      final current = Map<String, dynamic>.from(out);
      final computed = spec.compute!(current);
      if (computed != null) {
        _writeAt(out, QLPathUtils.resolve(spec.path), computed);
      }
    }

    return out;
  }

  Map<String, dynamic> serialize(
    Map<String, dynamic> data, {
    QLProjection? projection,
  }) {
    final out = <String, dynamic>{};

    for (final spec in fields) {
      if (projection != null && !projection.isSelected(spec.index)) continue;
      if (spec.isVirtual) continue;
      if (spec.isComputed) continue;

      if (spec.path.contains('[]')) continue;

      final raw = _readAt(data, QLPathUtils.resolve(spec.path));
      if (raw == null) continue;

      if (spec.children.isNotEmpty &&
          spec.type == QLFieldType.object &&
          !spec.hasMany) {
        continue;
      }

      final encoded = _serializeFieldValue(spec, raw);
      if (encoded == null && raw != null) continue;
      if (encoded == null) continue;
      _writeAt(out, QLPathUtils.resolve(spec.path), encoded);
    }

    return out;
  }

  List<String> validate(
    Map<String, dynamic> record, {
    QLProjection? projection,
  }) {
    final errs = <String>[];

    for (final spec in fields) {
      if (projection != null && !projection.isSelected(spec.index)) continue;
      if (spec.isVirtual) continue;
      if (spec.isComputed) continue;
      if (spec.path.contains('[]')) continue;

      final val = _readAt(record, QLPathUtils.resolve(spec.path));
      errs.addAll(_validateFieldValue(spec, val, spec.path));
    }

    return errs;
  }

  List<String> _validateItem(
    QLSchemaFieldSpec spec,
    dynamic value,
    String basePath,
  ) {
    final errs = <String>[];

    if (value == null) return errs;

    if (value is List &&
        spec.type != QLFieldType.array &&
        spec.type != QLFieldType.block) {
      for (int i = 0; i < value.length; i++) {
        errs.addAll(_validateItem(spec, value[i], '$basePath[$i]'));
      }
      return errs;
    }

    if (spec.type == QLFieldType.enumeration && spec.options.isNotEmpty) {
      if (!spec.options.contains(value.toString())) {
        errs.add('$basePath: invalid option');
      }
    }

    if (spec.type == QLFieldType.char) {
      final text = value.toString();
      if (text.isEmpty) {
        errs.add('$basePath: empty char');
      } else if (text.length != 1) {
        errs.add('$basePath: must be a single character');
      }
    } else if (spec.type == QLFieldType.smallInt) {
      final intValue = value is int ? value : int.tryParse(value.toString());
      if (intValue == null) {
        errs.add('$basePath: invalid smallInt');
      } else if (intValue < -32768 || intValue > 32767) {
        errs.add('$basePath: out of range (-32768..32767)');
      }
    } else if (spec.type == QLFieldType.bigInt) {
      final big = value is BigInt
          ? value
          : (value is num
              ? BigInt.from(value.toInt())
              : BigInt.tryParse(value.toString()));
      if (big == null) {
        errs.add('$basePath: invalid bigInt');
      }
    } else if (spec.type == QLFieldType.decimal) {
      final text = value.toString().trim();
      if (text.isEmpty || double.tryParse(text) == null) {
        errs.add('$basePath: invalid decimal');
      }
    } else if (spec.type == QLFieldType.flags) {
      final normalized = _normalizeFlagsValue(value, spec: spec);
      if (normalized == null) {
        errs.add('$basePath: invalid flags');
      }
    } else if (spec.type == QLFieldType.media) {
      if (value is Map) {
        final media = Map<String, dynamic>.from(value);
        final mimeType =
            (media['mimeType'] ?? media['contentType'] ?? media['type'])
                ?.toString();
        final rawSize = media['sizeBytes'] ?? media['size'] ?? media['length'];
        final sizeBytes =
            rawSize is num ? rawSize : num.tryParse(rawSize?.toString() ?? '');
        if (spec.allowedMimeTypes.isNotEmpty &&
            (mimeType == null || !spec.allowedMimeTypes.contains(mimeType))) {
          errs.add('$basePath: invalid mimeType');
        }
        if (spec.minSizeBytes != null &&
            sizeBytes != null &&
            sizeBytes < spec.minSizeBytes!) {
          errs.add('$basePath: minBytes ${spec.minSizeBytes}');
        }
        if (spec.maxSizeBytes != null &&
            sizeBytes != null &&
            sizeBytes > spec.maxSizeBytes!) {
          errs.add('$basePath: maxBytes ${spec.maxSizeBytes}');
        }
      }
    } else if (value is num) {
      if (spec.min != null && value < spec.min!) {
        errs.add('$basePath: min ${spec.min}');
      }
      if (spec.max != null && value > spec.max!) {
        errs.add('$basePath: max ${spec.max}');
      }
    } else if (value is String) {
      if (spec.min != null && value.length < spec.min!) {
        errs.add('$basePath: min length ${spec.min}');
      }
      if (spec.max != null && value.length > spec.max!) {
        errs.add('$basePath: max length ${spec.max}');
      }
    }

    if (spec.type == QLFieldType.block && value is Map) {
      final blockType = value['blockType']?.toString();
      final data = value['data'];
      if (blockType == null) {
        errs.add('$basePath: missing blockType');
      } else if (spec.allowedBlocks.isNotEmpty &&
          !spec.allowedBlocks.contains(blockType)) {
        errs.add('$basePath: invalid blockType');
      } else if (data is Map) {
        final blockSchema = QLSchemaRegistry.instance.getSchema(blockType) ??
            QLSchemaCompiler.resolveSchema(blockType);
        if (blockSchema != null) {
          final blockErrs =
              blockSchema.validate(Map<String, dynamic>.from(data));
          errs.addAll(blockErrs.map((e) => '$basePath.data.$e'));
        } else if (spec.itemSpec != null) {
          errs.addAll(_validateItem(spec.itemSpec!, data, '$basePath.data'));
        }
      }
    }

    if (spec.type == QLFieldType.array &&
        value is List &&
        spec.itemSpec != null) {
      for (int i = 0; i < value.length; i++) {
        errs.addAll(_validateItem(spec.itemSpec!, value[i], '$basePath[$i]'));
      }
    }

    if (spec.children.isNotEmpty && value is Map) {
      for (final child in spec.children) {
        final childVal = _readAt(
            Map<String, dynamic>.from(value), QLPathUtils.resolve(child.name));
        errs.addAll(_validateItem(child, childVal, '$basePath.${child.name}'));
      }
    }

    return errs;
  }

  dynamic _parseValue(QLSchemaFieldSpec spec, dynamic raw) {
    switch (spec.type) {
      case QLFieldType.number:
        if (raw is num) return raw.toDouble();
        return double.tryParse(raw.toString());
      case QLFieldType.bigInt:
        if (raw is BigInt) return raw;
        if (raw is int) return BigInt.from(raw);
        if (raw is num) return BigInt.from(raw.toInt());
        return BigInt.tryParse(raw.toString());
      case QLFieldType.smallInt:
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        return int.tryParse(raw.toString());
      case QLFieldType.decimal:
        return raw is String ? raw.trim() : raw.toString();
      case QLFieldType.char:
        final text = raw.toString();
        return text.isEmpty ? null : text.substring(0, 1);
      case QLFieldType.flags:
        return _normalizeFlagsValue(raw, spec: spec);
      case QLFieldType.media:
        return _normalizeMediaValue(spec, raw);
      case QLFieldType.boolean:
        if (raw is bool) return raw;
        return raw.toString().toLowerCase() == 'true';
      case QLFieldType.date:
        if (raw is DateTime) return raw;
        return DateTime.tryParse(raw.toString());
      case QLFieldType.enumeration:
      case QLFieldType.string:
      case QLFieldType.textarea:
      case QLFieldType.secure:
      case QLFieldType.lookup:
      case QLFieldType.relation:
      case QLFieldType.relationship:
        return raw.toString();
      case QLFieldType.json:
        return raw;
      case QLFieldType.object:
        return raw is Map ? Map<String, dynamic>.from(raw) : null;
      case QLFieldType.array:
        if (raw is! List) return null;
        if (spec.itemSpec == null) return List<dynamic>.from(raw);
        return raw
            .map((e) => _parseItem(spec.itemSpec!, e))
            .where((e) => e != null)
            .toList(growable: false);
      case QLFieldType.block:
        return _parseBlockValue(spec, raw);
      case QLFieldType.tree:
        return raw;
      default:
        return raw;
    }
  }

  dynamic _serializeValue(QLSchemaFieldSpec spec, dynamic raw) {
    switch (spec.type) {
      case QLFieldType.number:
        if (raw is num) return raw.toDouble();
        return double.tryParse(raw.toString());
      case QLFieldType.bigInt:
        if (raw is BigInt) return raw.toString();
        if (raw is int) return raw.toString();
        if (raw is num) return raw.toInt().toString();
        final parsed = BigInt.tryParse(raw.toString());
        return parsed?.toString() ?? raw.toString();
      case QLFieldType.smallInt:
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        return int.tryParse(raw.toString());
      case QLFieldType.decimal:
        return raw is String ? raw.trim() : raw.toString();
      case QLFieldType.char:
        final text = raw.toString();
        return text.isEmpty ? null : text.substring(0, 1);
      case QLFieldType.flags:
        return _normalizeFlagsValue(raw, spec: spec);
      case QLFieldType.media:
        return _serializeMediaValue(spec, raw);
      case QLFieldType.boolean:
        if (raw is bool) return raw;
        return raw.toString().toLowerCase() == 'true';
      case QLFieldType.date:
        if (raw is DateTime) return raw.toIso8601String();
        return raw.toString();
      case QLFieldType.block:
        return _serializeBlockValue(spec, raw);
      case QLFieldType.array:
        if (raw is! List) return null;
        if (spec.itemSpec == null) return raw;
        return raw
            .map((e) => _serializeItem(spec.itemSpec!, e))
            .where((e) => e != null)
            .toList(growable: false);
      case QLFieldType.object:
        return raw is Map ? Map<String, dynamic>.from(raw) : null;
      default:
        return raw;
    }
  }

  Map<String, dynamic>? _normalizeMediaValue(
    QLSchemaFieldSpec spec,
    dynamic raw,
  ) {
    if (raw == null) return null;
    if (raw is Map) {
      final media = Map<String, dynamic>.from(raw);
      media.putIfAbsent('mediaType', () => spec.mediaType);
      media.putIfAbsent('type', () => spec.mediaType ?? media['type']);
      final src = media['src'] ?? media['url'] ?? media['path'];
      if (src != null) {
        media.putIfAbsent('src', () => src);
        media.putIfAbsent('url', () => src);
      }
      if (media['mimeType'] == null && spec.allowedMimeTypes.isNotEmpty) {
        media['mimeType'] = spec.allowedMimeTypes.first;
      }
      final rawSize = media['sizeBytes'] ?? media['size'] ?? media['length'];
      if (rawSize is num) {
        media.putIfAbsent('sizeBytes', () => rawSize.toInt());
      } else if (rawSize != null) {
        final parsed = num.tryParse(rawSize.toString());
        if (parsed != null) media['sizeBytes'] = parsed.toInt();
      }
      return media;
    }
    if (raw is String) {
      return <String, dynamic>{
        'src': raw,
        'url': raw,
        if (spec.mediaType != null) 'mediaType': spec.mediaType,
      };
    }
    if (raw is Uint8List) {
      return <String, dynamic>{
        'bytes': raw,
        'sizeBytes': raw.lengthInBytes,
        if (spec.mediaType != null) 'mediaType': spec.mediaType,
      };
    }
    return <String, dynamic>{
      'value': raw,
      if (spec.mediaType != null) 'mediaType': spec.mediaType,
    };
  }

  dynamic _serializeMediaValue(QLSchemaFieldSpec spec, dynamic raw) {
    final media = _normalizeMediaValue(spec, raw);
    if (media == null) return null;
    return media;
  }

  int? _normalizeFlagsValue(dynamic raw, {QLSchemaFieldSpec? spec}) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is BigInt) return raw.toInt();
    if (raw is num) return raw.toInt();
    if (raw is bool) return raw ? 1 : 0;
    if (raw is List) {
      var out = 0;
      for (final item in raw) {
        final normalized = _normalizeFlagsValue(item, spec: spec);
        if (normalized != null) out |= normalized;
      }
      return out;
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return 0;
    final parsed = int.tryParse(text);
    if (parsed != null) return parsed;
    final options = spec?.options ?? const <String>[];
    final index =
        options.indexWhere((opt) => opt.toLowerCase() == text.toLowerCase());
    if (index >= 0) return 1 << index;
    final flagMap = spec?.meta['flagMap'];
    if (flagMap is Map) {
      final dynamic mapped = flagMap[text] ?? flagMap[text.toLowerCase()];
      if (mapped is int) return mapped;
      if (mapped is num) return mapped.toInt();
      if (mapped is String) return int.tryParse(mapped);
    }
    return 0;
  }

  dynamic _parseItem(QLSchemaFieldSpec spec, dynamic raw) {
    if (raw == null) return null;
    if (spec.type == QLFieldType.array && spec.itemSpec != null) {
      if (raw is List) {
        return raw
            .map((e) => _parseItem(spec.itemSpec!, e))
            .where((e) => e != null)
            .toList(growable: false);
      }
      return null;
    }
    if (spec.type == QLFieldType.block) {
      return _parseBlockValue(spec, raw);
    }
    if (spec.type == QLFieldType.object && spec.children.isNotEmpty) {
      if (raw is! Map) return null;
      final parsedMap = <String, dynamic>{};
      for (final child in spec.children) {
        final childRaw = raw[child.name];
        if (childRaw != null) {
          final p = _parseItem(child, childRaw);
          if (p != null) parsedMap[child.name] = p;
        }
      }
      return parsedMap;
    }
    return _parseValue(spec, raw);
  }

  dynamic _serializeItem(QLSchemaFieldSpec spec, dynamic raw) {
    if (raw == null) return null;
    if (spec.type == QLFieldType.array && spec.itemSpec != null) {
      if (raw is List) {
        return raw
            .map((e) => _serializeItem(spec.itemSpec!, e))
            .where((e) => e != null)
            .toList(growable: false);
      }
      return null;
    }
    if (spec.type == QLFieldType.block) {
      return _serializeBlockValue(spec, raw);
    }
    if (spec.type == QLFieldType.object && spec.children.isNotEmpty) {
      if (raw is! Map) return null;
      final serializedMap = <String, dynamic>{};
      for (final child in spec.children) {
        final childRaw = raw[child.name];
        if (childRaw != null) {
          final s = _serializeItem(child, childRaw);
          if (s != null) serializedMap[child.name] = s;
        }
      }
      return serializedMap;
    }
    return _serializeValue(spec, raw);
  }

  dynamic _parseBlockValue(QLSchemaFieldSpec spec, dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => _parseSingleBlock(spec, e))
          .where((e) => e != null)
          .toList(growable: false);
    }
    return _parseSingleBlock(spec, raw);
  }

  dynamic _serializeBlockValue(QLSchemaFieldSpec spec, dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => _serializeSingleBlock(spec, e))
          .where((e) => e != null)
          .toList(growable: false);
    }
    return _serializeSingleBlock(spec, raw);
  }

  QLBlockPayload? _parseSingleBlock(QLSchemaFieldSpec spec, dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final blockType = map['blockType']?.toString();
    if (blockType == null) return null;
    if (spec.allowedBlocks.isNotEmpty &&
        !spec.allowedBlocks.contains(blockType)) {
      return null;
    }
    final data = map['data'];
    final blockSchema = QLSchemaRegistry.instance.getSchema(blockType) ??
        QLSchemaCompiler.resolveSchema(blockType);

    if (data is Map && blockSchema != null) {
      return QLBlockPayload(
        blockType: blockType,
        data: blockSchema.parse(Map<String, dynamic>.from(data)),
      );
    }
    return QLBlockPayload(
      blockType: blockType,
      data: data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
  }

  Map<String, dynamic>? _serializeSingleBlock(
      QLSchemaFieldSpec spec, dynamic raw) {
    if (raw is QLBlockPayload) {
      final blockSchema = QLSchemaRegistry.instance.getSchema(raw.blockType) ??
          QLSchemaCompiler.resolveSchema(raw.blockType);
      return {
        'blockType': raw.blockType,
        'data': blockSchema != null
            ? blockSchema.serialize(raw.data)
            : Map<String, dynamic>.from(raw.data),
      };
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final blockType = map['blockType']?.toString();
      if (blockType == null) return null;
      final data = map['data'];
      final blockSchema = QLSchemaRegistry.instance.getSchema(blockType) ??
          QLSchemaCompiler.resolveSchema(blockType);
      return {
        'blockType': blockType,
        'data': data is Map && blockSchema != null
            ? blockSchema.serialize(Map<String, dynamic>.from(data))
            : (data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{}),
      };
    }
    return null;
  }

  bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  dynamic _readAt(Map<String, dynamic> root, List<dynamic> path) {
    dynamic current = root;
    for (final seg in path) {
      if (current is Map && current.containsKey(seg.toString())) {
        current = current[seg.toString()];
      } else if (current is List &&
          seg is int &&
          seg >= 0 &&
          seg < current.length) {
        current = current[seg];
      } else {
        return null;
      }
    }
    return current;
  }

  void _writeAt(Map<String, dynamic> root, List<dynamic> path, dynamic value) {
    if (path.isEmpty) return;
    dynamic current = root;

    for (int i = 0; i < path.length - 1; i++) {
      final seg = path[i];
      final next = path[i + 1];
      if (current is Map) {
        final key = seg.toString();
        current.putIfAbsent(
            key, () => next is int ? <dynamic>[] : <String, dynamic>{});
        current = current[key];
      } else if (current is List) {
        final idx = seg is int ? seg : int.tryParse(seg.toString()) ?? 0;
        while (current.length <= idx) {
          current.add(next is int ? <dynamic>[] : <String, dynamic>{});
        }
        current = current[idx];
      } else {
        return;
      }
    }

    final last = path.last;
    if (current is Map) {
      current[last.toString()] = value;
    } else if (current is List) {
      final idx = last is int ? last : int.tryParse(last.toString()) ?? 0;
      while (current.length <= idx) {
        current.add(null);
      }
      current[idx] = value;
    }
  }
}

abstract final class QLSchemaCompiler {
  static final Map<String, Map<String, dynamic>> _rawDefinitions = {};
  static final Map<String, QLSchemaBlueprint> _compiled = {};

  static void registerRaw(String name, Map<String, dynamic> definition) {
    _rawDefinitions[name] = Map<String, dynamic>.from(definition);
  }

  static QLSchemaBlueprint compile(
    String schemaName,
    Map<String, dynamic> definition,
  ) {
    // 🚀 FIX: Automatically unwrap root-level object schemas globally
    if (definition['type'] == 'object' && definition['fields'] is Map) {
      definition = Map<String, dynamic>.from(definition['fields'] as Map);
    }

    registerRaw(schemaName, definition);
    if (_compiled.containsKey(schemaName)) {
      return _compiled[schemaName]!;
    }

    final roots = <QLSchemaFieldSpec>[];
    for (final entry in definition.entries) {
      roots.add(_compileField(entry.key, entry.value, entry.key, const []));
    }

    final flat = <QLSchemaFieldSpec>[];
    final byPath = <String, QLSchemaFieldSpec>{};

    void flatten(QLSchemaFieldSpec spec) {
      spec.index = flat.length;
      flat.add(spec);
      byPath[spec.path] = spec;
      for (final child in spec.children) {
        flatten(child);
      }
      if (spec.itemSpec != null) {
        flatten(spec.itemSpec!);
      }
    }

    for (final r in roots) {
      flatten(r);
    }

    final blueprint = QLSchemaBlueprint._(schemaName, roots, flat, byPath);
    _compiled[schemaName] = blueprint;
    return blueprint;
  }

  static QLSchemaFieldSpec _compileField(
    String name,
    dynamic raw,
    String path,
    List<String> ancestry,
  ) {
    final Map<String, dynamic> asMap = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{'type': raw};

    final typeLabel = (asMap['type'] ?? 'string').toString().toLowerCase();
    final type = _parseType(typeLabel);

    final int flags = _parseFlags(asMap);
    final relationTarget = asMap['schema']?.toString();
    final options = (asMap['options'] as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];
    final min = (asMap['min'] as num?)?.toDouble();
    final max = (asMap['max'] as num?)?.toDouble();

    final children = <QLSchemaFieldSpec>[];
    if ((type == QLFieldType.object || type == QLFieldType.tree) &&
        asMap['fields'] is Map) {
      final childMap = Map<String, dynamic>.from(asMap['fields'] as Map);
      for (final entry in childMap.entries) {
        final childPath = '$path.${entry.key}';
        children.add(_compileField(
            entry.key, entry.value, childPath, [...ancestry, name]));
      }
    }

    QLSchemaFieldSpec? itemSpec;
    if (type == QLFieldType.array && asMap['items'] != null) {
      itemSpec = _compileField(
        '${name}[]',
        asMap['items'],
        '$path[]',
        [...ancestry, name],
      );
    }

    final allowedBlocks = <String>[];
    final blocks = asMap['blocks'] ?? asMap['allowedBlocks'];

    final mediaRaw = asMap['media'];
    final mediaPolicy = mediaRaw is Map
        ? Map<String, dynamic>.from(mediaRaw)
        : <String, dynamic>{};
    final mediaType = (asMap['mediaType'] ?? mediaPolicy['type'])?.toString();
    final allowedMimeTypes = <String>{
      if (asMap['mimeTypes'] is List)
        ...(asMap['mimeTypes'] as List).map((e) => e.toString()),
      if (asMap['allowedMimeTypes'] is List)
        ...(asMap['allowedMimeTypes'] as List).map((e) => e.toString()),
      if (mediaPolicy['mimeTypes'] is List)
        ...(mediaPolicy['mimeTypes'] as List).map((e) => e.toString()),
      if (mediaPolicy['allowedMimeTypes'] is List)
        ...(mediaPolicy['allowedMimeTypes'] as List).map((e) => e.toString()),
    }.toList(growable: false);
    final minSizeBytes = _intFromAny(asMap['minSizeBytes'] ??
        asMap['minBytes'] ??
        mediaPolicy['minBytes'] ??
        mediaPolicy['minSizeBytes']);
    final maxSizeBytes = _intFromAny(asMap['maxSizeBytes'] ??
        asMap['maxBytes'] ??
        mediaPolicy['maxBytes'] ??
        mediaPolicy['maxSizeBytes']);
    final thumbnailIcon =
        (asMap['thumbnailIcon'] ?? mediaPolicy['thumbnailIcon'])?.toString();
    final thumbnailPath =
        (asMap['thumbnailPath'] ?? mediaPolicy['thumbnailPath'])?.toString();
    final qualityPolicy = _mergeMaps(asMap['quality'], mediaPolicy['quality']);
    final streamingPolicy =
        _mergeMaps(asMap['streaming'], mediaPolicy['streaming']);
    final cachePolicy = _mergeMaps(asMap['cache'], mediaPolicy['cache']);
    if (blocks != null) {
      if (blocks is List) {
        for (final b in blocks) {
          if (b is String) {
            allowedBlocks.add(b);
            if (_rawDefinitions.containsKey(b)) {
              compile(b, _rawDefinitions[b]!);
            }
          } else if (b is Map) {
            final blockName = b['name']?.toString() ?? b['type']?.toString();
            if (blockName != null) {
              allowedBlocks.add(blockName);
              final safeMap = Map<String, dynamic>.from(b);
              final schemaToCompile =
                  (safeMap['type'] == 'object' && safeMap['fields'] is Map)
                      ? Map<String, dynamic>.from(safeMap['fields'] as Map)
                      : safeMap;
              registerRaw(blockName, schemaToCompile);
              compile(blockName, schemaToCompile);
            }
          }
        }
      } else if (blocks is Map) {
        final safeBlocks = Map<String, dynamic>.from(blocks);
        for (final entry in safeBlocks.entries) {
          allowedBlocks.add(entry.key);
          if (entry.value is Map) {
            final childMap = Map<String, dynamic>.from(entry.value as Map);
            final schemaToCompile =
                (childMap['type'] == 'object' && childMap['fields'] is Map)
                    ? Map<String, dynamic>.from(childMap['fields'] as Map)
                    : childMap;
            registerRaw(entry.key, schemaToCompile);
            compile(entry.key, schemaToCompile);
          }
        }
      }
    }

    final compute = asMap['compute'] is Function
        ? asMap['compute'] as dynamic Function(Map<String, dynamic>)
        : null;

    return QLSchemaFieldSpec(
      name: name,
      path: path,
      type: type,
      flags: flags,
      relationTarget: relationTarget,
      options: options,
      min: min,
      max: max,
      meta: Map<String, dynamic>.from(asMap),
      children: children,
      itemSpec: itemSpec,
      allowedBlocks: allowedBlocks,
      mediaType: mediaType,
      allowedMimeTypes: allowedMimeTypes,
      minSizeBytes: minSizeBytes,
      maxSizeBytes: maxSizeBytes,
      thumbnailIcon: thumbnailIcon,
      thumbnailPath: thumbnailPath,
      mediaPolicy: mediaPolicy,
      qualityPolicy: qualityPolicy,
      streamingPolicy: streamingPolicy,
      cachePolicy: cachePolicy,
      compute: compute,
    );
  }

  static int? _intFromAny(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static Map<String, dynamic> _mergeMaps(dynamic a, dynamic b) {
    final out = <String, dynamic>{};
    if (a is Map) out.addAll(Map<String, dynamic>.from(a));
    if (b is Map) out.addAll(Map<String, dynamic>.from(b));
    return out;
  }

  static int _parseFlags(Map<String, dynamic> val) {
    var flags = QLFieldFlags.none;
    if (val['virtual'] == true) flags |= QLFieldFlags.isVirtual;
    if (val['computed'] != null) flags |= QLFieldFlags.isComputed;
    if (val['required'] == true) flags |= QLFieldFlags.isRequired;
    if (val['hasMany'] == true ||
        val['many'] == true ||
        val['multiple'] == true) {
      flags |= QLFieldFlags.hasMany;
    }
    if (val['unique'] == true) flags |= QLFieldFlags.isUnique;
    if (val['index'] == true || val['indexed'] == true) {
      flags |= QLFieldFlags.isIndexed;
    }
    if (val['hidden'] == true) flags |= QLFieldFlags.isHidden;
    if (val['readOnly'] == true) flags |= QLFieldFlags.isReadOnly;
    return flags;
  }

  static int _parseType(String t) {
    final type = t.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
    switch (type) {
      case 'string':
      case 'text':
        return QLFieldType.string;
      case 'textarea':
        return QLFieldType.textarea;
      case 'number':
      case 'float':
      case 'int':
      case 'int32':
      case 'double':
        return QLFieldType.number;
      case 'bigint':
      case 'biginteger':
      case 'int64':
      case 'long':
        return QLFieldType.bigInt;
      case 'smallint':
      case 'short':
      case 'int16':
        return QLFieldType.smallInt;
      case 'decimal':
      case 'numeric':
      case 'money':
      case 'currency':
        return QLFieldType.decimal;
      case 'char':
      case 'character':
        return QLFieldType.char;
      case 'flags':
      case 'bitflags':
      case 'bitmask':
      case 'mask':
        return QLFieldType.flags;
      case 'media':
      case 'asset':
      case 'file':
        return QLFieldType.media;
      case 'bool':
      case 'boolean':
        return QLFieldType.boolean;
      case 'date':
        return QLFieldType.date;
      case 'json':
        return QLFieldType.json;
      case 'object':
      case 'group':
      case 'map':
        return QLFieldType.object;
      case 'relation':
        return QLFieldType.relation;
      case 'relationship':
        return QLFieldType.relationship;
      case 'block':
        return QLFieldType.block;
      case 'enum':
      case 'enumeration':
        return QLFieldType.enumeration;
      case 'array':
      case 'list':
        return QLFieldType.array;
      case 'tree':
        return QLFieldType.tree;
      case 'secure':
      case 'password':
        return QLFieldType.secure;
      case 'lookup':
        return QLFieldType.lookup;
      default:
        return QLFieldType.string;
    }
  }

  static QLSchemaBlueprint? resolveSchema(String name) {
    if (_compiled.containsKey(name)) return _compiled[name]!;
    if (_rawDefinitions.containsKey(name)) {
      return compile(name, _rawDefinitions[name]!);
    }
    return null;
  }
}

class QLSchemaRegistry {
  static final QLSchemaRegistry instance = QLSchemaRegistry._();
  QLSchemaRegistry._();

  final Map<String, QLSchemaBlueprint> _schemas = {};
  final Map<String, Map<String, dynamic>> _rawBlueprints = {};

  void register(QLSchemaBlueprint schema) {
    _schemas[schema.name] = schema;
  }

  void registerRaw(String name, Map<String, dynamic> definition) {
    _rawBlueprints[name] = Map<String, dynamic>.from(definition);
    QLSchemaCompiler.registerRaw(name, definition);
  }

  QLSchemaBlueprint? getSchema(String name) {
    if (_schemas.containsKey(name)) return _schemas[name]!;
    if (_rawBlueprints.containsKey(name)) {
      return compile(name, _rawBlueprints[name]!);
    }
    return null;
  }

  bool hasSchema(String name) => _schemas.containsKey(name);

  QLSchemaBlueprint compile(String name, Map<String, dynamic> definition) {
    final schema = QLSchemaCompiler.compile(name, definition);
    _schemas[name] = schema;
    return schema;
  }

  Map<String, dynamic>? describe(String name) {
    final schema = getSchema(name);
    if (schema == null) return null;
    return {
      'id': name,
      'kind': 'schema',
      'name': name,
      'description': _rawBlueprints[name]?['description']?.toString() ?? '',
      'engine': 'QLSchemaRegistry',
      'tags': (_rawBlueprints[name]?['tags'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      'params': {
        'fieldCount': schema.fieldCount,
        'paths': schema.fieldPaths(),
      },
      'metadata': _rawBlueprints[name] ?? const {},
      'fields': schema.fields
          .map((f) => {
                'name': f.name,
                'path': f.path,
                'type': f.type,
                'flags': f.flags,
                'meta': f.meta,
              })
          .toList(growable: false),
    };
  }

  Map<String, dynamic> snapshot() => {
        'count': _schemas.length + _rawBlueprints.length,
        'items': allSchemaNames
            .map((n) => describe(n))
            .whereType<Map<String, dynamic>>()
            .toList(growable: false),
      };

  void compileAllPending() {
    for (final entry in _rawBlueprints.entries) {
      if (!_schemas.containsKey(entry.key)) {
        _schemas[entry.key] = QLSchemaCompiler.compile(entry.key, entry.value);
      }
    }
  }

  void clear() {
    _schemas.clear();
    _rawBlueprints.clear();
    QLSchemaCompiler._compiled.clear();
    QLSchemaCompiler._rawDefinitions.clear();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// QEE INSPECTION EXTENSION  (added for quantum_embodiment_engine.dart)
// ════════════════════════════════════════════════════════════════════════════

/// Read-only inspector extension on [QLSchemaRegistry] for the QEE.
extension QLSchemaRegistryInspector on QLSchemaRegistry {
  /// All currently registered schema names.
  List<String> get allSchemaNames => List<String>.unmodifiable(_schemas.keys);
}

class QLSchemaReadPlan {
  final String schemaName;
  final List<String> requested;
  final List<String> expanded;
  final List<String> satisfied;
  final List<String> missing;

  const QLSchemaReadPlan({
    required this.schemaName,
    required this.requested,
    required this.expanded,
    required this.satisfied,
    required this.missing,
  });

  bool get needsNetwork => missing.isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'schema': schemaName,
        'requested': requested,
        'expanded': expanded,
        'satisfied': satisfied,
        'missing': missing,
        'needsNetwork': needsNetwork,
      };
}

extension QLSchemaBlueprintSmartSelect on QLSchemaBlueprint {
  List<String> normalizeSelection(Iterable<String>? select) {
    final raw = select
            ?.map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    if (raw.isEmpty) {
      return fieldPaths().where((path) {
        final spec = field(path);
        return spec != null && !spec.isVirtual && !spec.isComputed;
      }).toList(growable: false);
    }
    return expandSelection(raw);
  }

  List<String> missingSelection({
    Map<String, dynamic>? cachedRecord,
    Iterable<String>? select,
  }) {
    final desired = normalizeSelection(select);
    if (desired.isEmpty) return const <String>[];
    if (cachedRecord == null || cachedRecord.isEmpty) return desired;

    final missing = <String>[];
    for (final path in desired) {
      final value = _readAt(cachedRecord, QLPathUtils.resolve(path));
      if (value == null) {
        missing.add(path);
      }
    }
    return missing.toList(growable: false);
  }

  QLSchemaReadPlan buildReadPlan({
    Map<String, dynamic>? cachedRecord,
    Iterable<String>? select,
  }) {
    final requested =
        select?.map((e) => e.toString()).toList(growable: false) ??
            const <String>[];
    final expanded = normalizeSelection(requested);
    final satisfied = <String>[];
    final missing = <String>[];

    for (final path in expanded) {
      final value = cachedRecord == null
          ? null
          : _readAt(cachedRecord, QLPathUtils.resolve(path));
      if (value == null) {
        missing.add(path);
      } else {
        satisfied.add(path);
      }
    }

    return QLSchemaReadPlan(
      schemaName: name,
      requested: requested,
      expanded: expanded,
      satisfied: satisfied,
      missing: missing,
    );
  }

  Map<String, dynamic> projectRecord(
    Map<String, dynamic> record, {
    Iterable<String>? select,
    bool includeComputed = false,
  }) {
    final projection = QLProjection(fieldCount);
    for (final path in normalizeSelection(select)) {
      final spec = field(path);
      if (spec != null && spec.index >= 0) {
        projection.select(spec.index);
      }
    }
    final out = parse(record, projection: projection);
    if (!includeComputed) return out;

    final full = parse(record);
    return _qlDeepMergeSchemaMaps(out, full);
  }

  Map<String, dynamic> mergeProjectedRecord(
    Map<String, dynamic> cached,
    Map<String, dynamic> incoming, {
    Iterable<String>? select,
  }) {
    final desired = normalizeSelection(select);
    if (desired.isEmpty) {
      return _qlDeepMergeSchemaMaps(cached, incoming);
    }

    final merged = Map<String, dynamic>.from(cached);
    for (final path in desired) {
      final value = _readAt(incoming, QLPathUtils.resolve(path));
      if (value == null) continue;
      _writeAt(merged, QLPathUtils.resolve(path), value);
    }
    return _qlDeepMergeSchemaMaps(merged, incoming);
  }
}

Map<String, dynamic> _qlDeepMergeSchemaMaps(
  Map<String, dynamic> left,
  Map<String, dynamic> right,
) {
  final out = Map<String, dynamic>.from(left);
  for (final entry in right.entries) {
    final key = entry.key;
    final next = entry.value;
    final current = out[key];
    if (current is Map && next is Map) {
      out[key] = _qlDeepMergeSchemaMaps(
        Map<String, dynamic>.from(current),
        Map<String, dynamic>.from(next),
      );
    } else if (current is List && next is List) {
      final merged = List<dynamic>.from(current);
      for (final item in next) {
        merged.add(item);
      }
      out[key] = merged;
    } else {
      out[key] = next;
    }
  }
  return out;
}
