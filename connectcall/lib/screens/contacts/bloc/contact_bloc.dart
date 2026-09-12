import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/firebase/contact.service.dart';
import '../models/contact_model.dart';
import 'contact_event.dart';
import 'contact_state.dart';

export 'contact_event.dart';
export 'contact_state.dart';

/// BLoC managing contact list retrieval and states for ContactPage.
///
/// On init, fetches profiles from [ContactService.getContacts] and maps
/// them into [ContactModel] storing `{ otherUserId, otherUserName, otherUserAvatar }`
/// in [ContactState].
class ContactBloc extends Bloc<ContactEvent, ContactState> {
  ContactBloc({
    required ContactService contactService,
  })  : _contactService = contactService,
        super(const ContactState()) {
    on<ContactFetchRequested>(_onFetchRequested);
  }

  final ContactService _contactService;

  Future<void> _onFetchRequested(
    ContactFetchRequested event,
    Emitter<ContactState> emit,
  ) async {
    emit(state.copyWith(status: ContactStatus.loading, errorMessage: null));

    try {
      final profiles = await _contactService.getContacts();
      final contacts = profiles.map(ContactModel.fromProfile).toList();

      emit(state.copyWith(
        status: ContactStatus.success,
        contacts: contacts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ContactStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
