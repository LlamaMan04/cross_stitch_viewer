/// Defines the common logical-pixel quantization used by picture caches.
abstract final class PatternScaleBucket {
  /// Number of quantization steps retained for each logical pixel.
  static const int unitsPerLogicalPixel = 4;

  /// Converts a positive logical size into the shared cache-bucket identity.
  static int quantize(double logicalSize) {
    assert(logicalSize > 0 && logicalSize.isFinite);
    return (logicalSize * unitsPerLogicalPixel).round().clamp(1, 1 << 30);
  }

  /// Returns the representative logical size recorded for [bucket].
  static double representativeSize(int bucket) {
    assert(bucket > 0);
    return bucket / unitsPerLogicalPixel;
  }
}
