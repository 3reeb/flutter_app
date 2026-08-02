/*
 * ============================================================================
 * File: qee_serializer.dart
 * 
 * Description:
 * Provides an ultra-compact, high-performance binary codec for translating 
 * QBaseNode objects to and from byte streams. Trades standard JSON overhead 
 * for speed and density, optimizing disk I/O and memory usage.
 * 
 * Key Components:
 * - QNodeEncoder / QEncodeBuffer: Mutable builders applying LEB128 varints and 
 *   string interning.
 * - QNodeDecoder / QDecodeBuffer: Stream parsers reassembling QBaseNode objects.
 * - QSerial: Definition of magic bytes and stable field tags.
 * 
 * Dependencies/Relationships:
 * Consumed strictly by QNodeRegistry immediately before sending payloads to 
 * QCryptoEngine and storage.
 * 
 * Notes:
 * Modifying field IDs in QSerial introduces breaking changes to existing binary 
 * stores. Fields should only be appended, never reordered or removed.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE SERIALIZER — qee_serializer.dart
//
// Ultra-compact binary codec for all QBaseNode subtypes.
//
// Binary Format:
//   [MAGIC: 3 bytes = 0x51 0x45 0x45]  ("QEE")
//   [VERSION: 1 byte]
//   [NODE_KIND: 1 byte]
//   [NODE_ID: 8 bytes, uint64 LE]
//   [VERSION_NUM: 4 bytes, uint32 LE]
//   [SEALED_AT: 8 bytes, int64 LE — unix ms]
//   [FLAGS: 4 bytes, uint32 LE]
//   [STR_TABLE_COUNT: 2 bytes, uint16 LE]
//   [STR_TABLE: each entry = 2-byte length + UTF-8 bytes]
//   [FIELD_COUNT: 2 bytes, uint16 LE]
//   [FIELDS: each field = 1-byte field_id + 1-byte type_tag + value]
//
// Value Types:
//   0x00 null
//   0x01 bool true
//   0x02 bool false
//   0x03 uint8  (1 byte)
//   0x04 uint16 (2 bytes LE)
//   0x05 uint32 (4 bytes LE)
//   0x06 uint64 (8 bytes LE)
//   0x07 int64  (8 bytes LE, two's complement)
//   0x08 float64 (8 bytes IEEE 754 LE)
//   0x09 string (2-byte index into STR_TABLE)
//   0x0A bytes  (4-byte length LE + raw bytes)
//   0x0B list   (2-byte count + items, each with their own type_tag)
//   0x0C nodeRef (8-byte nodeId uint64 LE)
//   0x0D nodeRefList (2-byte count + 8 bytes each)
//   0x0E map    (2-byte count + (string-ref, value) pairs)
//   0x0F varint (unsigned, LEB128)
//
// Goal: a typical PageNode encodes in < 256 bytes (vs 1–4 KB JSON).
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';

import 'qee_node_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

abstract final class QSerial {
  static const List<int> magic = [0x51, 0x45, 0x45]; // "QEE"
  static const int version = 0x01;

  // Field IDs — stable, never reorder, only append new ones
  static const int fNodeId       = 0x01;
  static const int fKind         = 0x02;
  static const int fVersion      = 0x03;
  static const int fSealedAt     = 0x04;
  static const int fFlags        = 0x05;
  static const int fRoutePath    = 0x06;
  static const int fAppId        = 0x07;
  static const int fAssetPath    = 0x08;
  static const int fParamNames   = 0x09;
  static const int fLayoutRef    = 0x0A;
  static const int fMetaRef      = 0x0B;
  static const int fMiddlewareRef= 0x0C;
  static const int fErrorRef     = 0x0D;
  static const int fLoadingRef   = 0x0E;
  static const int fNotFoundRef  = 0x0F;
  static const int fParentRef    = 0x10;
  static const int fNextRef      = 0x11;
  static const int fDirPath      = 0x12;
  static const int fTitle        = 0x13;
  static const int fTitleTpl     = 0x14;
  static const int fDescription  = 0x15;
  static const int fOpenGraph    = 0x16;
  static const int fTwitterCard  = 0x17;
  static const int fExtraMeta    = 0x18;
  static const int fRawMeta      = 0x19;
  static const int fSteps        = 0x1A;
  static const int fBody         = 0x1B;
  static const int fProps        = 0x1C;
  static const int fIsFullPage   = 0x1D;
  static const int fMinDisplayMs = 0x1E;
  static const int fIsCatchAll   = 0x1F;
  static const int fPolicy       = 0x20;
  static const int fSlices       = 0x21;
  static const int fDataSources  = 0x22;
  static const int fMacros       = 0x23;
  static const int fSchemas      = 0x24;
  static const int fActions      = 0x25;
  static const int fImports      = 0x26;
  static const int fBakedValues  = 0x27;
  static const int fPageRefs     = 0x28;
  static const int fPubModRefs   = 0x29;
  static const int fPrivModRefs  = 0x2A;
  static const int fSharedModRefs= 0x2B;
  static const int fRootLayoutRef= 0x2C;
  static const int fRootErrRef   = 0x2D;
  static const int fRootLoadRef  = 0x2E;
  static const int fRootNfRef    = 0x2F;
  static const int fRootMetaRef  = 0x30;
  static const int fRootMwRef    = 0x31;
  static const int fPagesDir     = 0x32;
  static const int fInitialRoute = 0x33;
  static const int fDeepLink     = 0x34;
  static const int fLayoutId     = 0x35;
  static const int fMiddlewareId = 0x36;
  static const int fMetaId       = 0x37;
  static const int fErrorId      = 0x38;
  static const int fLoadingId    = 0x39;
  static const int fNotFoundId   = 0x3A;
  static const int fModuleId     = 0x3B;
  static const int fRequireAuth  = 0x3C;
  static const int fAllowedApps  = 0x3D;

  // Value type tags
  static const int tNull         = 0x00;
  static const int tTrue         = 0x01;
  static const int tFalse        = 0x02;
  static const int tU8           = 0x03;
  static const int tU16          = 0x04;
  static const int tU32          = 0x05;
  static const int tU64          = 0x06;
  static const int tI64          = 0x07;
  static const int tF64          = 0x08;
  static const int tStr          = 0x09;
  static const int tBytes        = 0x0A;
  static const int tList         = 0x0B;
  static const int tNodeRef      = 0x0C;
  static const int tNodeRefList  = 0x0D;
  static const int tMap          = 0x0E;
  static const int tVarint       = 0x0F;
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — ENCODER (write buffer)
// ─────────────────────────────────────────────────────────────────────────────

/// Mutable write buffer for encoding a single node.
class QEncodeBuffer {
  final BytesBuilder _buf = BytesBuilder(copy: false);
  final List<String> _strings = []; // string intern table
  final Map<String, int> _stringIndex = {};

  // ── String intern table ──────────────────────────────────────────────────

  /// Intern a string — returns its index in the table.
  int _intern(String s) {
    final existing = _stringIndex[s];
    if (existing != null) return existing;
    final idx = _strings.length;
    _strings.add(s);
    _stringIndex[s] = idx;
    return idx;
  }

  // ── Primitive writers ─────────────────────────────────────────────────────

  void writeU8(int v) => _buf.addByte(v & 0xFF);

  void writeU16(int v) {
    _buf.addByte(v & 0xFF);
    _buf.addByte((v >> 8) & 0xFF);
  }

  void writeU32(int v) {
    _buf.addByte(v & 0xFF);
    _buf.addByte((v >> 8) & 0xFF);
    _buf.addByte((v >> 16) & 0xFF);
    _buf.addByte((v >> 24) & 0xFF);
  }

  void writeU64(int v) {
    // Dart int is 64-bit. Write as two 32-bit LE halves.
    writeU32(v & 0xFFFFFFFF);
    writeU32((v >> 32) & 0xFFFFFFFF);
  }

  void writeI64(int v) => writeU64(v); // same bit pattern

  void writeF64(double v) {
    final bd = ByteData(8);
    bd.setFloat64(0, v, Endian.little);
    _buf.add(bd.buffer.asUint8List());
  }

  void writeVarint(int v) {
    // Unsigned LEB128
    while (v > 0x7F) {
      _buf.addByte((v & 0x7F) | 0x80);
      v >>= 7;
    }
    _buf.addByte(v & 0x7F);
  }

  void writeBytes(Uint8List bytes) {
    writeU32(bytes.length);
    _buf.add(bytes);
  }

  void writeStringRaw(String s) {
    final encoded = utf8.encode(s);
    writeU16(encoded.length);
    _buf.add(encoded);
  }

  // ── Field writers ─────────────────────────────────────────────────────────

  void _field(int fieldId, void Function() writeValue) {
    writeU8(fieldId);
    writeValue();
  }

  void fieldNull(int id) {
    writeU8(id);
    writeU8(QSerial.tNull);
  }

  void fieldBool(int id, bool v) {
    writeU8(id);
    writeU8(v ? QSerial.tTrue : QSerial.tFalse);
  }

  void fieldU8(int id, int v) {
    writeU8(id);
    writeU8(QSerial.tU8);
    writeU8(v);
  }

  void fieldU32(int id, int v) {
    writeU8(id);
    writeU8(QSerial.tU32);
    writeU32(v);
  }

  void fieldU64(int id, int v) {
    writeU8(id);
    writeU8(QSerial.tU64);
    writeU64(v);
  }

  void fieldI64(int id, int v) {
    writeU8(id);
    writeU8(QSerial.tI64);
    writeI64(v);
  }

  void fieldString(int id, String s) {
    writeU8(id);
    writeU8(QSerial.tStr);
    writeU16(_intern(s));
  }

  void fieldStringOpt(int id, String? s) {
    if (s == null) return;
    fieldString(id, s);
  }

  void fieldNodeRef(int id, QNodeRef? ref) {
    if (ref == null) return;
    writeU8(id);
    writeU8(QSerial.tNodeRef);
    writeU64(ref.nodeId);
  }

  void fieldNodeRefList<T extends QBaseNode>(int id, List<QNodeRef<T>> refs) {
    if (refs.isEmpty) return;
    writeU8(id);
    writeU8(QSerial.tNodeRefList);
    writeU16(refs.length);
    for (final ref in refs) {
      writeU64(ref.nodeId);
    }
  }

  void fieldStringList(int id, List<String> list) {
    if (list.isEmpty) return;
    writeU8(id);
    writeU8(QSerial.tList);
    writeU16(list.length);
    for (final s in list) {
      writeU8(QSerial.tStr);
      writeU16(_intern(s));
    }
  }

  void fieldStringMap(int id, Map<String, String> map) {
    if (map.isEmpty) return;
    writeU8(id);
    writeU8(QSerial.tMap);
    writeU16(map.length);
    for (final e in map.entries) {
      writeU16(_intern(e.key));
      writeU8(QSerial.tStr);
      writeU16(_intern(e.value));
    }
  }

  void fieldBytes(int id, Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return;
    writeU8(id);
    writeU8(QSerial.tBytes);
    writeBytes(bytes);
  }

  void fieldDynamicMap(int id, Map<String, dynamic> map) {
    if (map.isEmpty) return;
    writeU8(id);
    writeU8(QSerial.tMap);
    // Encode as JSON string — for complex nested maps (macros, schemas, etc.)
    // We trade some space for correctness here. The string is interned.
    final json = _mapToJson(map);
    writeU16(_intern(json));
  }

  // ── Finalization ──────────────────────────────────────────────────────────

  /// Finalize the field section and return the complete encoded bytes.
  Uint8List finalize(int fieldCount) {
    // Build the full packet:
    // 1. String table
    final tableBuilder = BytesBuilder(copy: false);
    tableBuilder.addByte((_strings.length) & 0xFF);
    tableBuilder.addByte((_strings.length >> 8) & 0xFF);
    for (final s in _strings) {
      final enc = utf8.encode(s);
      tableBuilder.addByte(enc.length & 0xFF);
      tableBuilder.addByte((enc.length >> 8) & 0xFF);
      tableBuilder.add(enc);
    }

    // 2. Field count (2 bytes) + fields
    final fieldsBuilder = BytesBuilder(copy: false);
    fieldsBuilder.addByte(fieldCount & 0xFF);
    fieldsBuilder.addByte((fieldCount >> 8) & 0xFF);
    fieldsBuilder.add(_buf.toBytes());

    final result = BytesBuilder(copy: false);
    result.add(tableBuilder.toBytes());
    result.add(fieldsBuilder.toBytes());
    return result.toBytes();
  }

  static String _mapToJson(Map<String, dynamic> map) {
    try {
      return jsonEncode(map);
    } catch (_) {
      return '{}';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3 — NODE ENCODER
// ─────────────────────────────────────────────────────────────────────────────

/// Encodes any [QBaseNode] subtype to a binary packet.
///
/// The packet does NOT include the header (magic, version, kind, nodeId, etc.) —
/// those are written by [QNodeSerializer.encode] in the outer envelope.
abstract final class QNodeEncoder {
  /// Encode the full node (envelope + body) to bytes.
  static Uint8List encode(QBaseNode node) {
    final env = BytesBuilder(copy: false);

    // Header
    env.add(QSerial.magic);
    env.addByte(QSerial.version);
    env.addByte(node.kind.code);

    // Fixed header fields
    _writeU64(env, node.nodeId);
    _writeU32(env, node.version);
    _writeI64(env, node.sealedAt);
    _writeU32(env, node.flags);

    // Body (node-specific fields)
    final body = _encodeBody(node);
    env.add(body);

    return env.toBytes();
  }

  static Uint8List _encodeBody(QBaseNode node) {
    return switch (node) {
      QPageNode n => _encodePage(n),
      QLayoutNode n => _encodeLayout(n),
      QMiddlewareNode n => _encodeMiddleware(n),
      QMetaNode n => _encodeMeta(n),
      QErrorNode n => _encodeError(n),
      QLoadingNode n => _encodeLoading(n),
      QNotFoundNode n => _encodeNotFound(n),
      QModuleNode n => _encodeModule(n),
      QAppNode n => _encodeApp(n),
      _ => Uint8List(0),
    };
  }

  static Uint8List _encodePage(QPageNode n) {
    final buf = QEncodeBuffer();
    int fc = 0;

    buf.fieldString(QSerial.fRoutePath, n.routePath); fc++;
    if (n.appId != null) { buf.fieldString(QSerial.fAppId, n.appId!); fc++; }
    if (n.assetPath != null) { buf.fieldString(QSerial.fAssetPath, n.assetPath!); fc++; }
    if (n.paramNames.isNotEmpty) { buf.fieldStringList(QSerial.fParamNames, n.paramNames); fc++; }
    if (n.layoutRef != null) { buf.fieldNodeRef(QSerial.fLayoutRef, n.layoutRef); fc++; }
    if (n.metaRef != null) { buf.fieldNodeRef(QSerial.fMetaRef, n.metaRef); fc++; }
    if (n.middlewareRef != null) { buf.fieldNodeRef(QSerial.fMiddlewareRef, n.middlewareRef); fc++; }
    if (n.errorRef != null) { buf.fieldNodeRef(QSerial.fErrorRef, n.errorRef); fc++; }
    if (n.loadingRef != null) { buf.fieldNodeRef(QSerial.fLoadingRef, n.loadingRef); fc++; }
    if (n.notFoundRef != null) { buf.fieldNodeRef(QSerial.fNotFoundRef, n.notFoundRef); fc++; }
    if (n.body != null) { buf.fieldBytes(QSerial.fBody, n.body!.bytes); fc++; }

    return buf.finalize(fc);
  }

  static Uint8List _encodeLayout(QLayoutNode n) {
    final buf = QEncodeBuffer();
    int fc = 0;

    buf.fieldString(QSerial.fLayoutId, n.layoutId); fc++;
    buf.fieldString(QSerial.fDirPath, n.directoryPath); fc++;
    if (n.appId != null) { buf.fieldString(QSerial.fAppId, n.appId!); fc++; }
    if (n.assetPath != null) { buf.fieldString(QSerial.fAssetPath, n.assetPath!); fc++; }
    if (n.parentLayoutRef != null) { buf.fieldNodeRef(QSerial.fParentRef, n.parentLayoutRef); fc++; }
    if (n.body != null) { buf.fieldBytes(QSerial.fBody, n.body!.bytes); fc++; }

    return buf.finalize(fc);
  }

  static Uint8List _encodeMiddleware(QMiddlewareNode n) {
    final buf = QEncodeBuffer();
    int fc = 0;

    buf.fieldString(QSerial.fMiddlewareId, n.middlewareId); fc++;
    buf.fieldString(QSerial.fDirPath, n.directoryPath); fc++;
    if (n.appId != null) { buf.fieldString(QSerial.fAppId, n.appId!); fc++; }
    if (n.assetPath != null) { buf.fieldString(QSerial.fAssetPath, n.assetPath!); fc++; }
    if (n.nextRef != null) { buf.fieldNodeRef(QSerial.fNextRef, n.nextRef); fc++; }
    if (n.steps.isNotEmpty) {
      buf.fieldDynamicMap(QSerial.fSteps, {
        'steps': n.steps.map((s) => {'type': s.type, 'params': s.params, 'async': s.isAsync}).toList(),
      });
      fc++;
    }

    return buf.finalize(fc);
  }

  static Uint8List _encodeMeta(QMetaNode n) {
    final buf = QEncodeBuffer();
    int fc = 0;

    buf.fieldString(QSerial.fMetaId, n.metaId); fc++;
    buf.fieldString(QSerial.fDirPath, n.directoryPath); fc++;
    if (n.appId != null) { buf.fieldString(QSerial.fAppId, n.appId!); fc++; }
    if (n.assetPath != null) { buf.fieldString(QSerial.fAssetPath, n.assetPath!); fc++; }
    if (n.title != null) { buf.fieldString(QSerial.fTitle, n.title!); fc++; }
    if (n.titleTemplate != null) { buf.fieldString(QSerial.fTitleTpl, n.titleTemplate!); fc++; }
    if (n.description != null) { buf.fieldString(QSerial.fDescription, n.description!); fc++; }
    if (n.openGraph.isNotEmpty) { buf.fieldStringMap(QSerial.fOpenGraph, n.openGraph); fc++; }
    if (n.twitterCard.isNotEmpty) { buf.fieldStringMap(QSerial.fTwitterCard, n.twitterCard); fc++; }
    if (n.extra.isNotEmpty) { buf.fieldStringMap(QSerial.fExtraMeta, n.extra); fc++; }

    return buf.finalize(fc);
  }

  static Uint8List _encodeError(QErrorNode n) {
    final buf = QEncodeBuffer();
    int fc = 0;

    buf.fieldString(QSerial.fErrorId, n.errorId); fc++;
    buf.fieldString(QSerial.fDirPath, n.directoryPath); fc++;
    if (n.appId != null) { buf.fieldString(QSerial.fAppId, n.appId!); fc++; }
    if (n.assetPath != null) { buf.fieldString(QSerial.fAssetPath, n.assetPath!); fc++; }
    if (n.props.isNotEmpty) { buf.fieldDynamicMap(QSerial.fProps, n.props); fc++; }
    if (n.body != null) { buf.fieldBytes(QSerial.fBody, n.body!.bytes); fc++; }

    return buf.finalize(fc);
  }

  static Uint8List _encodeLoading(QLoadingNode n) {
    final buf = QEncodeBuffer();
    int fc = 0;

    buf.fieldString(QSerial.fLoadingId, n.loadingId); fc++;
    buf.fieldString(QSerial.fDirPath, n.directoryPath); fc++;
    if (n.appId != null) { buf.fieldString(QSerial.fAppId, n.appId!); fc++; }
    if (n.assetPath != null) { buf.fieldString(QSerial.fAssetPath, n.assetPath!); fc++; }
    buf.fieldBool(QSerial.fIsFullPage, n.isFullPage); fc++;
    if (n.minDisplayMs > 0) { buf.fieldU32(QSerial.fMinDisplayMs, n.minDisplayMs); fc++; }
    if (n.body != null) { buf.fieldBytes(QSerial.fBody, n.body!.bytes); fc++; }

    return buf.finalize(fc);
  }

  static Uint8List _encodeNotFound(QNotFoundNode n) {
    final buf = QEncodeBuffer();
    int fc = 0;

    buf.fieldString(QSerial.fNotFoundId, n.notFoundId); fc++;
    buf.fieldString(QSerial.fDirPath, n.directoryPath); fc++;
    if (n.appId != null) { buf.fieldString(QSerial.fAppId, n.appId!); fc++; }
    if (n.assetPath != null) { buf.fieldString(QSerial.fAssetPath, n.assetPath!); fc++; }
    buf.fieldBool(QSerial.fIsCatchAll, n.isCatchAll); fc++;
    if (n.body != null) { buf.fieldBytes(QSerial.fBody, n.body!.bytes); fc++; }

    return buf.finalize(fc);
  }

  static Uint8List _encodeModule(QModuleNode n) {
    final buf = QEncodeBuffer();
    int fc = 0;

    buf.fieldString(QSerial.fModuleId, n.moduleId); fc++;
    if (n.appId != null) { buf.fieldString(QSerial.fAppId, n.appId!); fc++; }
    if (n.assetPath != null) { buf.fieldString(QSerial.fAssetPath, n.assetPath!); fc++; }
    buf.fieldU8(QSerial.fPolicy, n.policy.kind.index); fc++;
    if (n.policy.allowedAppIds.isNotEmpty) {
      buf.fieldStringList(QSerial.fAllowedApps, n.policy.allowedAppIds); fc++;
    }
    if (n.policy.requireAuth) { buf.fieldBool(QSerial.fRequireAuth, true); fc++; }
    if (n.imports.isNotEmpty) { buf.fieldStringList(QSerial.fImports, n.imports); fc++; }
    if (n.macros.isNotEmpty) { buf.fieldDynamicMap(QSerial.fMacros, n.macros); fc++; }
    if (n.schemas.isNotEmpty) { buf.fieldDynamicMap(QSerial.fSchemas, n.schemas); fc++; }
    if (n.actions.isNotEmpty) { buf.fieldDynamicMap(QSerial.fActions, n.actions); fc++; }

    // Baked static values — encode as JSON for now (mixed types)
    if (n.bakedStaticValues.isNotEmpty) {
      try {
        final json = jsonEncode({'values': n.bakedStaticValues});
        buf.fieldBytes(QSerial.fBakedValues, Uint8List.fromList(utf8.encode(json)));
        fc++;
      } catch (_) {}
    }

    return buf.finalize(fc);
  }

  static Uint8List _encodeApp(QAppNode n) {
    final buf = QEncodeBuffer();
    int fc = 0;

    buf.fieldString(QSerial.fAppId, n.appId); fc++;
    if (n.assetPath != null) { buf.fieldString(QSerial.fAssetPath, n.assetPath!); fc++; }
    buf.fieldString(QSerial.fInitialRoute, n.routerConfig.initialRoute); fc++;
    buf.fieldString(QSerial.fPagesDir, n.routerConfig.pagesDir); fc++;
    buf.fieldBool(QSerial.fDeepLink, n.routerConfig.deepLinkEnabled); fc++;
    if (n.pageRefs.isNotEmpty) { buf.fieldNodeRefList(QSerial.fPageRefs, n.pageRefs); fc++; }
    if (n.publicModuleRefs.isNotEmpty) { buf.fieldNodeRefList(QSerial.fPubModRefs, n.publicModuleRefs); fc++; }
    if (n.privateModuleRefs.isNotEmpty) { buf.fieldNodeRefList(QSerial.fPrivModRefs, n.privateModuleRefs); fc++; }
    if (n.sharedModuleRefs.isNotEmpty) { buf.fieldNodeRefList(QSerial.fSharedModRefs, n.sharedModuleRefs); fc++; }
    if (n.rootLayoutRef != null) { buf.fieldNodeRef(QSerial.fRootLayoutRef, n.rootLayoutRef); fc++; }
    if (n.rootErrorRef != null) { buf.fieldNodeRef(QSerial.fRootErrRef, n.rootErrorRef); fc++; }
    if (n.rootLoadingRef != null) { buf.fieldNodeRef(QSerial.fRootLoadRef, n.rootLoadingRef); fc++; }
    if (n.rootNotFoundRef != null) { buf.fieldNodeRef(QSerial.fRootNfRef, n.rootNotFoundRef); fc++; }
    if (n.rootMetaRef != null) { buf.fieldNodeRef(QSerial.fRootMetaRef, n.rootMetaRef); fc++; }
    if (n.rootMiddlewareRef != null) { buf.fieldNodeRef(QSerial.fRootMwRef, n.rootMiddlewareRef); fc++; }

    return buf.finalize(fc);
  }

  // ── Header helpers ────────────────────────────────────────────────────────
  static void _writeU32(BytesBuilder b, int v) {
    b.addByte(v & 0xFF);
    b.addByte((v >> 8) & 0xFF);
    b.addByte((v >> 16) & 0xFF);
    b.addByte((v >> 24) & 0xFF);
  }

  static void _writeU64(BytesBuilder b, int v) {
    _writeU32(b, v & 0xFFFFFFFF);
    _writeU32(b, (v >> 32) & 0xFFFFFFFF);
  }

  static void _writeI64(BytesBuilder b, int v) => _writeU64(b, v);
}

// ─────────────────────────────────────────────────────────────────────────────
// §4 — DECODER (read buffer)
// ─────────────────────────────────────────────────────────────────────────────

class QDecodeBuffer {
  final Uint8List _data;
  int _pos;
  late final List<String> _strings;

  QDecodeBuffer(this._data, {int start = 0}) : _pos = start;

  bool get hasMore => _pos < _data.length;
  int get position => _pos;

  // ── Primitive readers ─────────────────────────────────────────────────────

  int readU8() => _data[_pos++];

  int readU16() {
    final v = _data[_pos] | (_data[_pos + 1] << 8);
    _pos += 2;
    return v;
  }

  int readU32() {
    final v = _data[_pos] |
        (_data[_pos + 1] << 8) |
        (_data[_pos + 2] << 16) |
        (_data[_pos + 3] << 24);
    _pos += 4;
    return v;
  }

  int readU64() {
    final lo = readU32();
    final hi = readU32();
    return lo | (hi << 32);
  }

  int readI64() => readU64();

  double readF64() {
    final bd = ByteData.sublistView(_data, _pos, _pos + 8);
    _pos += 8;
    return bd.getFloat64(0, Endian.little);
  }

  Uint8List readBytes() {
    final len = readU32();
    final slice = Uint8List.sublistView(_data, _pos, _pos + len);
    _pos += len;
    return slice;
  }

  String readStringRaw() {
    final len = readU16();
    final s = utf8.decode(_data.sublist(_pos, _pos + len));
    _pos += len;
    return s;
  }

  // ── String table ──────────────────────────────────────────────────────────

  void loadStringTable() {
    final count = readU16();
    _strings = List.generate(count, (_) => readStringRaw());
  }

  String stringAt(int idx) => _strings[idx];

  // ── Value reader ──────────────────────────────────────────────────────────

  dynamic readValue() {
    final tag = readU8();
    return switch (tag) {
      QSerial.tNull  => null,
      QSerial.tTrue  => true,
      QSerial.tFalse => false,
      QSerial.tU8    => readU8(),
      QSerial.tU16   => readU16(),
      QSerial.tU32   => readU32(),
      QSerial.tU64   => readU64(),
      QSerial.tI64   => readI64(),
      QSerial.tF64   => readF64(),
      QSerial.tStr   => stringAt(readU16()),
      QSerial.tBytes => readBytes(),
      QSerial.tNodeRef => readU64(), // returns raw int64 nodeId
      QSerial.tNodeRefList => _readNodeRefList(),
      QSerial.tList  => _readList(),
      QSerial.tMap   => _readMap(),
      _              => null,
    };
  }

  List<int> _readNodeRefList() {
    final count = readU16();
    return List.generate(count, (_) => readU64());
  }

  List<dynamic> _readList() {
    final count = readU16();
    return List.generate(count, (_) => readValue());
  }

  Map<String, dynamic> _readMap() {
    final count = readU16();
    final map = <String, dynamic>{};
    for (int i = 0; i < count; i++) {
      final key = stringAt(readU16());
      final value = readValue();
      map[key] = value;
    }
    return map;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §5 — NODE DECODER
// ─────────────────────────────────────────────────────────────────────────────

abstract final class QNodeDecoder {
  /// Decode bytes produced by [QNodeEncoder.encode] back to a [QBaseNode].
  static QBaseNode decode(Uint8List bytes) {
    final buf = QDecodeBuffer(bytes);

    // Validate magic
    final m0 = buf.readU8();
    final m1 = buf.readU8();
    final m2 = buf.readU8();
    if (m0 != 0x51 || m1 != 0x45 || m2 != 0x45) {
      throw const FormatException('Invalid QEE magic bytes');
    }

    final fileVersion = buf.readU8();
    if (fileVersion != QSerial.version) {
      throw FormatException('Unsupported QEE version: $fileVersion');
    }

    final kindCode = buf.readU8();
    final kind = QNodeKind.fromCode(kindCode);
    final nodeId = buf.readU64();
    final version = buf.readU32();
    final sealedAt = buf.readI64();
    final flags = buf.readU32();

    // Load string table
    buf.loadStringTable();

    // Read field count
    final fieldCount = buf.readU16();

    // Read all fields into a raw map for the node-specific decoder
    final fields = <int, dynamic>{};
    for (int i = 0; i < fieldCount; i++) {
      if (!buf.hasMore) break;
      final fieldId = buf.readU8();
      final value = buf.readValue();
      fields[fieldId] = value;
    }

    return _decodeNode(
      kind: kind,
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      fields: fields,
    );
  }

  static QBaseNode _decodeNode({
    required QNodeKind kind,
    required int nodeId,
    required int version,
    required int sealedAt,
    required int flags,
    required Map<int, dynamic> fields,
  }) {
    return switch (kind) {
      QNodeKind.page       => _decodePage(nodeId, version, sealedAt, flags, fields),
      QNodeKind.layout     => _decodeLayout(nodeId, version, sealedAt, flags, fields),
      QNodeKind.middleware => _decodeMiddleware(nodeId, version, sealedAt, flags, fields),
      QNodeKind.meta       => _decodeMeta(nodeId, version, sealedAt, flags, fields),
      QNodeKind.error      => _decodeError(nodeId, version, sealedAt, flags, fields),
      QNodeKind.loading    => _decodeLoading(nodeId, version, sealedAt, flags, fields),
      QNodeKind.notFound   => _decodeNotFound(nodeId, version, sealedAt, flags, fields),
      QNodeKind.module     => _decodeModule(nodeId, version, sealedAt, flags, fields),
      QNodeKind.app        => _decodeApp(nodeId, version, sealedAt, flags, fields),
    };
  }

  static QPageNode _decodePage(int nodeId, int version, int sealedAt, int flags, Map<int, dynamic> f) {
    final bodyBytes = f[QSerial.fBody] as Uint8List?;
    return QPageNode(
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      routePath: (f[QSerial.fRoutePath] as String?) ?? '/',
      appId: f[QSerial.fAppId] as String?,
      assetPath: f[QSerial.fAssetPath] as String?,
      paramNames: _toStringList(f[QSerial.fParamNames]),
      layoutRef: _toRef<QLayoutNode>(f[QSerial.fLayoutRef]),
      metaRef: _toRef<QMetaNode>(f[QSerial.fMetaRef]),
      middlewareRef: _toRef<QMiddlewareNode>(f[QSerial.fMiddlewareRef]),
      errorRef: _toRef<QErrorNode>(f[QSerial.fErrorRef]),
      loadingRef: _toRef<QLoadingNode>(f[QSerial.fLoadingRef]),
      notFoundRef: _toRef<QNotFoundNode>(f[QSerial.fNotFoundRef]),
      body: bodyBytes != null ? QPageBody(bodyBytes) : null,
    );
  }

  static QLayoutNode _decodeLayout(int nodeId, int version, int sealedAt, int flags, Map<int, dynamic> f) {
    final bodyBytes = f[QSerial.fBody] as Uint8List?;
    return QLayoutNode(
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      layoutId: (f[QSerial.fLayoutId] as String?) ?? '',
      directoryPath: (f[QSerial.fDirPath] as String?) ?? '',
      appId: f[QSerial.fAppId] as String?,
      assetPath: f[QSerial.fAssetPath] as String?,
      parentLayoutRef: _toRef<QLayoutNode>(f[QSerial.fParentRef]),
      body: bodyBytes != null ? QPageBody(bodyBytes) : null,
    );
  }

  static QMiddlewareNode _decodeMiddleware(int nodeId, int version, int sealedAt, int flags, Map<int, dynamic> f) {
    final stepsData = f[QSerial.fSteps];
    final steps = <QMiddlewareStep>[];
    if (stepsData is Map<String, dynamic>) {
      final stepsRaw = stepsData['steps'];
      if (stepsRaw is List) {
        for (final s in stepsRaw) {
          if (s is Map<String, dynamic>) {
            steps.add(QMiddlewareStep(
              type: s['type']?.toString() ?? '',
              params: s['params'] is Map
                  ? Map<String, dynamic>.from(s['params'] as Map)
                  : const {},
              isAsync: s['async'] == true,
            ));
          }
        }
      }
    }
    return QMiddlewareNode(
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      middlewareId: (f[QSerial.fMiddlewareId] as String?) ?? '',
      directoryPath: (f[QSerial.fDirPath] as String?) ?? '',
      appId: f[QSerial.fAppId] as String?,
      assetPath: f[QSerial.fAssetPath] as String?,
      nextRef: _toRef<QMiddlewareNode>(f[QSerial.fNextRef]),
      steps: List.unmodifiable(steps),
    );
  }

  static QMetaNode _decodeMeta(int nodeId, int version, int sealedAt, int flags, Map<int, dynamic> f) {
    return QMetaNode(
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      metaId: (f[QSerial.fMetaId] as String?) ?? '',
      directoryPath: (f[QSerial.fDirPath] as String?) ?? '',
      appId: f[QSerial.fAppId] as String?,
      assetPath: f[QSerial.fAssetPath] as String?,
      title: f[QSerial.fTitle] as String?,
      titleTemplate: f[QSerial.fTitleTpl] as String?,
      description: f[QSerial.fDescription] as String?,
      openGraph: _toStringMap(f[QSerial.fOpenGraph]),
      twitterCard: _toStringMap(f[QSerial.fTwitterCard]),
      extra: _toStringMap(f[QSerial.fExtraMeta]),
      raw: const {},
    );
  }

  static QErrorNode _decodeError(int nodeId, int version, int sealedAt, int flags, Map<int, dynamic> f) {
    final bodyBytes = f[QSerial.fBody] as Uint8List?;
    final propsRaw = f[QSerial.fProps];
    return QErrorNode(
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      errorId: (f[QSerial.fErrorId] as String?) ?? '',
      directoryPath: (f[QSerial.fDirPath] as String?) ?? '',
      appId: f[QSerial.fAppId] as String?,
      assetPath: f[QSerial.fAssetPath] as String?,
      props: propsRaw is Map<String, dynamic> ? propsRaw : const {},
      body: bodyBytes != null ? QPageBody(bodyBytes) : null,
    );
  }

  static QLoadingNode _decodeLoading(int nodeId, int version, int sealedAt, int flags, Map<int, dynamic> f) {
    final bodyBytes = f[QSerial.fBody] as Uint8List?;
    return QLoadingNode(
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      loadingId: (f[QSerial.fLoadingId] as String?) ?? '',
      directoryPath: (f[QSerial.fDirPath] as String?) ?? '',
      appId: f[QSerial.fAppId] as String?,
      assetPath: f[QSerial.fAssetPath] as String?,
      isFullPage: f[QSerial.fIsFullPage] as bool? ?? true,
      minDisplayMs: f[QSerial.fMinDisplayMs] as int? ?? 0,
      body: bodyBytes != null ? QPageBody(bodyBytes) : null,
    );
  }

  static QNotFoundNode _decodeNotFound(int nodeId, int version, int sealedAt, int flags, Map<int, dynamic> f) {
    final bodyBytes = f[QSerial.fBody] as Uint8List?;
    return QNotFoundNode(
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      notFoundId: (f[QSerial.fNotFoundId] as String?) ?? '',
      directoryPath: (f[QSerial.fDirPath] as String?) ?? '',
      appId: f[QSerial.fAppId] as String?,
      assetPath: f[QSerial.fAssetPath] as String?,
      isCatchAll: f[QSerial.fIsCatchAll] as bool? ?? true,
      body: bodyBytes != null ? QPageBody(bodyBytes) : null,
    );
  }

  static QModuleNode _decodeModule(int nodeId, int version, int sealedAt, int flags, Map<int, dynamic> f) {
    final kindIdx = f[QSerial.fPolicy] as int? ?? 1;
    final kind = QModuleKind.values[kindIdx.clamp(0, QModuleKind.values.length - 1)];
    final allowedApps = _toStringList(f[QSerial.fAllowedApps]);
    final policy = QModulePolicy(
      kind: kind,
      allowedAppIds: allowedApps,
      requireAuth: f[QSerial.fRequireAuth] as bool? ?? false,
    );

    final bakedRaw = f[QSerial.fBakedValues] as Uint8List?;
    List<dynamic> baked = const [];
    if (bakedRaw != null) {
      try {
        final map = jsonDecode(utf8.decode(bakedRaw)) as Map<String, dynamic>;
        baked = map['values'] as List<dynamic>? ?? const [];
      } catch (_) {}
    }

    final macros = _toDynamicMap(f[QSerial.fMacros]);
    final schemas = _toDynamicMap(f[QSerial.fSchemas]);
    final actions = _toDynamicMap(f[QSerial.fActions]);

    return QModuleNode(
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      moduleId: (f[QSerial.fModuleId] as String?) ?? '',
      appId: f[QSerial.fAppId] as String?,
      assetPath: f[QSerial.fAssetPath] as String?,
      policy: policy,
      slices: const [], // Slices are reconstructed from baked values + schemas
      dataSources: const [],
      macros: macros,
      schemas: schemas,
      actions: actions,
      imports: _toStringList(f[QSerial.fImports]),
      bakedStaticValues: List.unmodifiable(baked),
    );
  }

  static QAppNode _decodeApp(int nodeId, int version, int sealedAt, int flags, Map<int, dynamic> f) {
    final pageRefIds = f[QSerial.fPageRefs] as List<int>? ?? const [];
    final pubRefIds = f[QSerial.fPubModRefs] as List<int>? ?? const [];
    final privRefIds = f[QSerial.fPrivModRefs] as List<int>? ?? const [];
    final sharedRefIds = f[QSerial.fSharedModRefs] as List<int>? ?? const [];

    return QAppNode(
      nodeId: nodeId,
      version: version,
      sealedAt: sealedAt,
      flags: flags,
      appId: (f[QSerial.fAppId] as String?) ?? '',
      assetPath: f[QSerial.fAssetPath] as String?,
      routerConfig: QAppRouterConfig(
        initialRoute: (f[QSerial.fInitialRoute] as String?) ?? '/',
        pagesDir: (f[QSerial.fPagesDir] as String?) ?? 'pages',
        deepLinkEnabled: f[QSerial.fDeepLink] as bool? ?? false,
      ),
      pageRefs: pageRefIds.map((id) => QNodeRef<QPageNode>(id)).toList(growable: false),
      publicModuleRefs: pubRefIds.map((id) => QNodeRef<QModuleNode>(id)).toList(growable: false),
      privateModuleRefs: privRefIds.map((id) => QNodeRef<QModuleNode>(id)).toList(growable: false),
      sharedModuleRefs: sharedRefIds.map((id) => QNodeRef<QModuleNode>(id)).toList(growable: false),
      rootLayoutRef: _toRef<QLayoutNode>(f[QSerial.fRootLayoutRef]),
      rootErrorRef: _toRef<QErrorNode>(f[QSerial.fRootErrRef]),
      rootLoadingRef: _toRef<QLoadingNode>(f[QSerial.fRootLoadRef]),
      rootNotFoundRef: _toRef<QNotFoundNode>(f[QSerial.fRootNfRef]),
      rootMetaRef: _toRef<QMetaNode>(f[QSerial.fRootMetaRef]),
      rootMiddlewareRef: _toRef<QMiddlewareNode>(f[QSerial.fRootMwRef]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static QNodeRef<T>? _toRef<T extends QBaseNode>(dynamic raw) {
    if (raw is! int || raw == 0) return null;
    return QNodeRef<T>(raw);
  }

  static List<String> _toStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e?.toString() ?? '').toList(growable: false);
  }

  static Map<String, String> _toStringMap(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }

  static Map<String, dynamic> _toDynamicMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return const {};
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §6 — STABLE HASH (deterministic node ID)
// ─────────────────────────────────────────────────────────────────────────────

/// Generates a deterministic 64-bit node ID from its type key.
///
/// The hash is stable across restarts — same input always produces same output.
/// Uses DJB2a (xor variant) over the UTF-8 bytes of the combined key.
abstract final class QNodeIdGen {
  static int pageId(String routePath, {String? appId}) =>
      _hash('page:${appId ?? ''}:$routePath');

  static int appId(String appId) => _hash('app:$appId');

  static int moduleId(String moduleId, {String? appId}) =>
      _hash('module:${appId ?? ''}:$moduleId');

  static int layoutId(String directoryPath, {String? appId}) =>
      _hash('layout:${appId ?? ''}:$directoryPath');

  static int metaId(String directoryPath, {String? appId}) =>
      _hash('meta:${appId ?? ''}:$directoryPath');

  static int middlewareId(String directoryPath, {String? appId}) =>
      _hash('middleware:${appId ?? ''}:$directoryPath');

  static int errorId(String directoryPath, {String? appId}) =>
      _hash('error:${appId ?? ''}:$directoryPath');

  static int loadingId(String directoryPath, {String? appId}) =>
      _hash('loading:${appId ?? ''}:$directoryPath');

  static int notFoundId(String directoryPath, {String? appId}) =>
      _hash('notfound:${appId ?? ''}:$directoryPath');

  /// DJB2a hash — fast, deterministic, good distribution.
  static int hash(String key) {
    int hash = 5381;
    for (final unit in utf8.encode(key)) {
      hash = ((hash << 5) + hash) ^ unit;
      hash &= 0xFFFFFFFFFFFFFFFF; // keep 64-bit
    }
    return hash;
  }

  static int _hash(String key) => hash(key);
}
