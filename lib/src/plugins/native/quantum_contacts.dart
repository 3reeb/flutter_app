import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL CONTACT MODELS
// ────────────────────────────────────────────────────────────────────────────

class ContactData {
  final String id;
  final String name;
  final List<String> phoneNumbers;
  final List<String> emails;
  final Uint8List? photoBytes;

  const ContactData({
    required this.id,
    required this.name,
    this.phoneNumbers = const [],
    this.emails = const [],
    this.photoBytes,
  });

  factory ContactData.fromMap(Map<String, dynamic> map) {
    return ContactData(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phoneNumbers: List<String>.from(map['phoneNumbers'] ?? []),
      emails: List<String>.from(map['emails'] ?? []),
      photoBytes: map['photoBytes'] as Uint8List?,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// CODECS & BRIDGES
// ────────────────────────────────────────────────────────────────────────────

class _VoidContactListCodec extends QLChannelCodec<void, List<ContactData>> {
  const _VoidContactListCodec();
  @override dynamic encode(void args) => null;
  @override List<ContactData> decode(dynamic data) {
    if (data == null) return [];
    return (data as List).map((e) => ContactData.fromMap(Map<String, dynamic>.from(e))).toList();
  }
}

class _GetContactsBridge extends QLMethodBridge<void, List<ContactData>> {
  @override String get channelName => 'quantum_contacts/get_all';
  @override QLChannelCodec<void, List<ContactData>> get codec => const _VoidContactListCodec();
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// ────────────────────────────────────────────────────────────────────────────

class QuantumContacts {
  static final QuantumContacts instance = QuantumContacts._();

  QuantumContacts._() {
    QLNativeBridgeRegistry.instance.register('quantum_contacts/get_all', _getAll);
  }

  final _getAll = _GetContactsBridge();

  /// Retrieves all contacts from the device (useful for "Invite Friends" screens in Social/Chat apps).
  QLAsyncSignal<List<ContactData>> getAllContacts() {
    return _getAll(null);
  }
}
