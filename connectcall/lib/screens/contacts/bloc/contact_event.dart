/// Events for ContactBloc.
sealed class ContactEvent {
  const ContactEvent();
}

/// Triggered on init in ContactPage to fetch contacts from ContactService.
class ContactFetchRequested extends ContactEvent {
  const ContactFetchRequested();
}
