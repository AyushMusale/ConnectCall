import '../models/contact_model.dart';

enum ContactStatus {
  initial,
  loading,
  success,
  failure,
}

/// State representing contacts page data according to the whiteboard design:
/// Success state data holds a list of [ContactModel] with:
/// `[ { otherUserId, otherUserName, otherUserAvatar } ]`.
class ContactState {
  const ContactState({
    this.status = ContactStatus.initial,
    this.contacts = const [],
    this.errorMessage,
  });

  final ContactStatus status;
  final List<ContactModel> contacts;
  final String? errorMessage;

  bool get isInitial => status == ContactStatus.initial;
  bool get isLoading => status == ContactStatus.loading;
  bool get isSuccess => status == ContactStatus.success;
  bool get isFailure => status == ContactStatus.failure;

  ContactState copyWith({
    ContactStatus? status,
    List<ContactModel>? contacts,
    String? errorMessage,
  }) {
    return ContactState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'ContactState(status: $status, contactsCount: ${contacts.length}, error: $errorMessage)';
}
