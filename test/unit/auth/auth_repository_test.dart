import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:focusforge/features/auth/data/auth_repository.dart';

@GenerateNiceMocks([
  MockSpec<SupabaseClient>(),
  MockSpec<GoTrueClient>(),
])
import 'auth_repository_test.mocks.dart';

void main() {
  late AuthRepository repository;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(mockClient.auth).thenReturn(mockAuth);
    repository = AuthRepository(mockClient);
  });

  group('AuthRepository', () {
    test('signUpWithEmail calls supabase auth.signUp with correct email and password', () async {
      final mockResponse = AuthResponse(session: null, user: null);
      when(mockAuth.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        data: anyNamed('data'),
      )).thenAnswer((_) async => mockResponse);

      await repository.signUpWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      verify(mockAuth.signUp(
        email: 'test@example.com',
        password: 'password123',
        data: null,
      )).called(1);
    });

    test('signUpWithEmail passes displayName as full_name in metadata', () async {
      final mockResponse = AuthResponse(session: null, user: null);
      when(mockAuth.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        data: anyNamed('data'),
      )).thenAnswer((_) async => mockResponse);

      await repository.signUpWithEmail(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'John Doe',
      );

      verify(mockAuth.signUp(
        email: 'test@example.com',
        password: 'password123',
        data: {'full_name': 'John Doe'},
      )).called(1);
    });

    test('signInWithEmail calls supabase auth.signInWithPassword with correct email and password', () async {
      final mockResponse = AuthResponse(session: null, user: null);
      when(mockAuth.signInWithPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockResponse);

      await repository.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      verify(mockAuth.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('signOut calls supabase auth.signOut', () async {
      when(mockAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(mockAuth.signOut()).called(1);
    });

    test('resetPassword calls supabase auth.resetPasswordForEmail with correct email', () async {
      when(mockAuth.resetPasswordForEmail(any))
          .thenAnswer((_) async {});

      await repository.resetPassword('test@example.com');

      verify(mockAuth.resetPasswordForEmail('test@example.com')).called(1);
    });

    test('currentUser returns supabase auth.currentUser', () {
      when(mockAuth.currentUser).thenReturn(null);

      final user = repository.currentUser;

      expect(user, isNull);
      verify(mockAuth.currentUser).called(1);
    });

    test('currentSession returns supabase auth.currentSession', () {
      when(mockAuth.currentSession).thenReturn(null);

      final session = repository.currentSession;

      expect(session, isNull);
      verify(mockAuth.currentSession).called(1);
    });
  });
}
