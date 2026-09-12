import 'package:connectcall/injection.dart';
import 'package:connectcall/models/profile_model.dart';
import 'package:connectcall/screens/contacts/bloc/contact_bloc.dart';
import 'package:connectcall/screens/contacts/contact_page.dart';
import 'package:connectcall/screens/contacts/models/contact_model.dart';
import 'package:connectcall/screens/contacts/widgets/contact_list_item.dart';
import 'package:connectcall/services/firebase/contact.service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSuccessContactService extends ContactService {
  MockSuccessContactService(this.profiles);

  final List<ProfileModel> profiles;

  @override
  Future<List<ProfileModel>> getContacts() async {
    return profiles;
  }
}

class MockFailureContactService extends ContactService {
  @override
  Future<List<ProfileModel>> getContacts() async {
    throw Exception('Firestore network timeout');
  }
}

void main() {
  setUp(() {
    configureDependencies();
  });

  group('ContactBloc Unit Tests', () {
    test('Emits [loading, success] with mapped ContactModel on fetch success', () async {
      final mockService = MockSuccessContactService([
        const ProfileModel(
          id: 'usr_1',
          name: 'Aditi Sharma',
          email: 'aditi@example.com',
          avatar: 'https://example.com/aditi.png',
        ),
        const ProfileModel(
          id: 'usr_2',
          name: 'Rohan Mehta',
          email: 'rohan@example.com',
          avatar: null,
        ),
      ]);

      final bloc = ContactBloc(contactService: mockService);

      bloc.add(const ContactFetchRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ContactState>((s) => s.isLoading),
          predicate<ContactState>((s) {
            if (!s.isSuccess || s.contacts.length != 2) return false;
            // Validate whiteboard schema: { otherUserId, otherUserName, otherUserAvatar }
            final first = s.contacts[0];
            final second = s.contacts[1];
            return first.otherUserId == 'usr_1' &&
                first.otherUserName == 'Aditi Sharma' &&
                first.otherUserAvatar == 'https://example.com/aditi.png' &&
                second.otherUserId == 'usr_2' &&
                second.otherUserName == 'Rohan Mehta' &&
                second.otherUserAvatar == null;
          }),
        ]),
      );
    });

    test('Emits [loading, failure] on fetch error', () async {
      final mockService = MockFailureContactService();
      final bloc = ContactBloc(contactService: mockService);

      bloc.add(const ContactFetchRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ContactState>((s) => s.isLoading),
          predicate<ContactState>((s) =>
              s.isFailure &&
              (s.errorMessage?.contains('Firestore network timeout') ?? false)),
        ]),
      );
    });
  });

  group('ContactPage UI State Rendering Tests', () {
    testWidgets('While loading shows magnify icon with skeleton animation', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = ContactBloc(
        contactService: MockSuccessContactService([]),
      );
      // Manually emit loading state to test UI in loading state
      bloc.emit(const ContactState(status: ContactStatus.loading));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ContactBloc>.value(
            value: bloc,
            child: const ContactPage(),
          ),
        ),
      );

      // Verify ContactLoadingSkeleton is displayed
      expect(find.byType(ContactLoadingSkeleton), findsOneWidget);

      // Verify magnify icon is displayed
      expect(find.byIcon(Icons.search_rounded), findsWidgets);
      expect(find.text('Loading contacts...'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      bloc.close();
    });

    testWidgets('If failure shows grey cross with failed text', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = ContactBloc(
        contactService: MockSuccessContactService([]),
      );
      bloc.emit(const ContactState(
        status: ContactStatus.failure,
        errorMessage: 'Network error occurred',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ContactBloc>.value(
            value: bloc,
            child: const ContactPage(),
          ),
        ),
      );

      // Verify grey cross icon
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      final crossIcon = tester.widget<Icon>(find.byIcon(Icons.close_rounded));
      expect(crossIcon.color, const Color(0xFF9CA3AF));

      // Verify failed text
      expect(find.text('Failed to load contacts'), findsOneWidget);
      expect(find.text('Network error occurred'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      bloc.close();
    });

    testWidgets('If success and list is empty shows no contacts available', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = ContactBloc(
        contactService: MockSuccessContactService([]),
      );
      bloc.emit(const ContactState(
        status: ContactStatus.success,
        contacts: [],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ContactBloc>.value(
            value: bloc,
            child: const ContactPage(),
          ),
        ),
      );

      expect(find.text('No contacts available'), findsOneWidget);
      expect(find.byType(ContactListItem), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      bloc.close();
    });

    testWidgets('If success displays contact list', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = ContactBloc(
        contactService: MockSuccessContactService([]),
      );
      bloc.emit(const ContactState(
        status: ContactStatus.success,
        contacts: [
          ContactModel(
            otherUserId: 'u1',
            otherUserName: 'Sneha Patil',
            otherUserAvatar: null,
          ),
          ContactModel(
            otherUserId: 'u2',
            otherUserName: 'Karan Desai',
            otherUserAvatar: null,
          ),
        ],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ContactBloc>.value(
            value: bloc,
            child: const ContactPage(),
          ),
        ),
      );

      expect(find.byType(ContactListItem), findsNWidgets(2));
      expect(find.text('Sneha Patil'), findsOneWidget);
      expect(find.text('Karan Desai'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      bloc.close();
    });
  });
}
