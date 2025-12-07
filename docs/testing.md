# Testing Guide for nav-e Project

This project uses a comprehensive testing strategy that covers both repositories and BLoC components. The tests are organized following the same structure as the main codebase.

## Test Structure

```
test/
├── core/
│   ├── bloc/
│   │   └── location_bloc_test.dart        # Tests for LocationBloc
│   └── data/
│       └── remote/
│           └── map_source_repository_impl_test.dart  # Tests for MapSourceRepository
├── features/
│   └── map_layers/
│       └── presentation/
│           └── bloc/
│               └── map_bloc_test.dart     # Tests for MapBloc
├── helpers/
│   ├── test_helpers.dart                  # Test utility functions
│   └── mocks.dart                         # Mock classes
└── widget_test.dart                       # Widget tests
```

## Dependencies

The following testing dependencies are added to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7        # For testing BLoC components
  mocktail: ^1.0.4         # For creating mocks
  shared_preferences_web: ^2.5.2  # For testing SharedPreferences
```

## Test Categories

### 1. Repository Tests
- **MapSourceRepositoryImpl**: Tests CRUD operations, SharedPreferences integration, and edge cases
- Tests cover:
  - Getting current map source
  - Loading/saving preferences
  - Handling invalid data
  - Error scenarios

### 2. BLoC Tests
- **LocationBloc**: Tests location tracking functionality
- **MapBloc**: Tests map state management, source switching, and user interactions
- Tests cover:
  - Event handling
  - State transitions
  - Error handling
  - Async operations

### 3. Entity Tests
- Tests for data models and value objects
- Serialization/deserialization
- Edge cases and validation

## Running Tests

### Run all tests:
```bash
flutter test
```

### Run specific test files:
```bash
flutter test test/core/data/remote/map_source_repository_impl_test.dart
flutter test test/core/bloc/location_bloc_test.dart
flutter test test/features/map_layers/presentation/bloc/map_bloc_test.dart
```

### Run tests with coverage:
```bash
flutter test --coverage
```

### Run specific test groups:
```bash
flutter test --name "MapSourceRepositoryImpl"
flutter test --name "LocationBloc"
```

## Test Patterns

### Repository Tests
```dart
group('RepositoryImpl', () {
  late Repository repository;
  
  setUp(() {
    TestHelpers.setupSharedPreferences();
    repository = RepositoryImpl();
  });
  
  tearDown(() {
    TestHelpers.cleanupMethodChannels();
  });
  
  test('should perform expected operation', () async {
    // Arrange
    // Act
    // Assert
  });
});
```

### BLoC Tests
```dart
blocTest<MyBloc, MyState>(
  'should emit expected states when event is added',
  build: () => MyBloc(mockRepository),
  act: (bloc) => bloc.add(MyEvent()),
  expect: () => [expectedState1, expectedState2],
  verify: (_) {
    verify(() => mockRepository.method()).called(1);
  },
);
```

## Test Helpers

### TestHelpers Class
Provides utility functions for:
- Setting up SharedPreferences mocks
- Configuring method channel mocks
- Cleanup after tests

### Mock Classes
- `MockMapSourceRepository`
- `MockGeocodingRepository`
- `MockSavedPlacesRepository`

## Best Practices

1. **Isolation**: Each test should be independent and not rely on other tests
2. **AAA Pattern**: Arrange, Act, Assert structure for clarity
3. **Mocking**: Use mocks for external dependencies to ensure unit test isolation
4. **Coverage**: Aim for high test coverage, especially for business logic
5. **Descriptive Names**: Test names should clearly describe what is being tested
6. **Setup/Teardown**: Use setUp and tearDown for common test initialization and cleanup

## Common Issues

### SharedPreferences Tests
When testing code that uses SharedPreferences, ensure to call:
```dart
TestHelpers.setupSharedPreferences(values: {});
```

### Async Testing
For async operations that don't wait for completion (like repository initialization):
```dart
await Future.delayed(Duration(milliseconds: 10));
```

### Method Channel Mocks
Platform-specific code requires proper method channel mocking:
```dart
TestHelpers.setupMethodChannelMocks();
```

## Integration with CI/CD

Tests can be integrated into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Run tests
  run: flutter test --coverage
  
- name: Upload coverage
  uses: codecov/codecov-action@v1
  with:
    file: coverage/lcov.info
```

## Future Enhancements

- Add integration tests for complex workflows
- Add widget tests for UI components
- Add golden tests for visual regression testing
- Implement test data builders for complex entities
- Add performance tests for critical paths