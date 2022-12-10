import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';

class ContactsUIService {
  ContactsUIService() {
    FlutterContacts.config.includeNonVisibleOnAndroid = true;
  }

  final Map<String, Contact> _cache = {};

  /// Returns the contact data for the contact with id [id]. If [id] is null, then
  /// null will be returned. This is so that handling situations with no contactId
  /// is easier.
  /// Null will also be returned if either no contact is found or the contact integration
  /// is disabled.
  Future<Contact?> getContact(String? id) async {
    if (id == null ||
        !GetIt.I.get<PreferencesBloc>().state.enableContactIntegration) return null;
    if (_cache.containsKey(id)) return _cache[id]!;

    final contact = await FlutterContacts.getContact(
      id,
      withPhoto: false,
      withProperties: false,
    );
    if (contact == null) return null;

    _cache[id] = contact;
    return contact;
  }
}
