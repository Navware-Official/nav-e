#!/bin/bash

echo "Running all tests..."

# Run repository tests
echo "Testing MapSourceRepository..."
flutter test test/core/data/remote/map_source_repository_impl_test.dart

# Run BLoC tests
echo "Testing LocationBloc..."
flutter test test/core/bloc/location_bloc_test.dart

echo "Testing MapBloc..."
flutter test test/features/map_layers/presentation/bloc/map_bloc_test.dart

echo "Running all tests together..."
flutter test

echo "Test run completed!"