import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/domain/barcode_logic.dart';

// Flashlight state
final flashStateProvider = StateProvider<bool>((ref) => false);

// Scan loading state
final scanLoadingProvider = StateProvider<bool>((ref) => false);

// BarcodeLogic service
final barcodeLogicProvider = Provider((ref) {
  final isFlashOn = ref.watch(flashStateProvider);
  return BarcodeLogic(isFlashOn: isFlashOn);
});
