import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/bridge/ffi.dart' as bridge;

/// FRB-backed geocoding repository (typed-ready).
///
/// Currently this implementation calls the FRB shim method that returns raw
/// JSON (`RustBridge.geocodeSearch`) so it works before codegen is run. After
/// you run `flutter_rust_bridge_codegen`, replace the call below with the
/// generated typed binding (for example `geocodeSearchTyped`) which will return
/// typed objects and eliminate JSON parsing on the Dart side.
class GeocodingRepositoryFrbTypedImpl implements IGeocodingRepository {
  GeocodingRepositoryFrbTypedImpl();

  @override
  Future<List<GeocodingResult>> search(String query, {int limit = 10}) async {
    // Prefer typed shim (or generated typed binding) which returns parsed maps
    final list = await bridge.RustBridge.geocodeSearchTyped(query, limit);
    return list.map(GeocodingResult.fromJson).toList();
  }
}
