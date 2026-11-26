import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/presentation/pattern_renderer/cache/pattern_glyph_picture_cache.dart';

/// Verifies bounded, leased ownership of reusable glyph display lists.
void main() {
  test('quantizes nearby font sizes into stable quarter-pixel buckets', () {
    expect(PatternGlyphPictureCache.quantizeFontSize(12.01), 48);
    expect(PatternGlyphPictureCache.quantizeFontSize(12.11), 48);
    expect(PatternGlyphPictureCache.quantizeFontSize(12.14), 49);
    expect(PatternGlyphPictureCache.fontSizeForBucket(49), 12.25);
  });

  test('promotes glyph hits and evicts the least-recently-used entry', () {
    final cache = PatternGlyphPictureCache(
      maximumEntries: 2,
      maximumEstimatedBytes: 200,
    );
    addTearDown(cache.dispose);
    final firstKey = _key('A');
    final secondKey = _key('B');
    final thirdKey = _key('C');

    cache.putAndAcquire(firstKey, _picture(100))!.release();
    cache.putAndAcquire(secondKey, _picture(100))!.release();
    cache.acquire(firstKey)!.release();
    cache.putAndAcquire(thirdKey, _picture(100))!.release();

    expect(cache.entryCount, 2);
    expect(cache.estimatedBytes, 200);
    expect(cache.evictionCount, 1);
    expect(cache.acquire(secondKey), isNull);
    expect(cache.hitCount, 1);
    expect(cache.missCount, 1);
    cache.acquire(firstKey)!.release();
  });

  test('defers eviction disposal until an active glyph lease is released', () {
    final cache = PatternGlyphPictureCache(
      maximumEntries: 1,
      maximumEstimatedBytes: 200,
    );
    addTearDown(cache.dispose);
    final firstPicture = _picture(100);
    final firstLease = cache.putAndAcquire(_key('A'), firstPicture)!;

    cache.putAndAcquire(_key('B'), _picture(100))!.release();

    expect(cache.entryCount, 1);
    expect(cache.evictionCount, 1);
    expect(() => firstPicture.picture.toImageSync(1, 1), returnsNormally);
    firstLease.release();
  });

  test('rejects a picture that exceeds the byte budget', () {
    final cache = PatternGlyphPictureCache(maximumEstimatedBytes: 99);
    addTearDown(cache.dispose);
    final rejectedPicture = _picture(100);
    addTearDown(rejectedPicture.dispose);

    final lease = cache.putAndAcquire(_key('A'), rejectedPicture);

    expect(lease, isNull);
    expect(cache.entryCount, 0);
    expect(cache.estimatedBytes, 0);
  });

  test('distinguishes every glyph appearance input in cache keys', () {
    final key = _key('A');

    expect(key, isNot(_key('B')));
    expect(key, isNot(_key('A', foreground: Colors.white)));
    expect(key, isNot(_key('A', fontSizeBucket: 65)));
    expect(key, isNot(_key('A', fontFamily: 'Roboto')));
    expect(key, isNot(_key('A', fontWeight: 700)));
    expect(key, isNot(_key('A', textDirection: TextDirection.rtl)));
    expect(key, isNot(_key('A', rendererGeneration: 1)));
  });
}

/// Creates one representative glyph key with caller-selectable visual inputs.
PatternGlyphPictureKey _key(
  String glyph, {
  Color foreground = Colors.black,
  int fontSizeBucket = 64,
  String? fontFamily,
  int fontWeight = 600,
  TextDirection textDirection = TextDirection.ltr,
  int rendererGeneration = 0,
}) => PatternGlyphPictureKey(
  glyph: glyph,
  foreground: foreground,
  fontSizeBucket: fontSizeBucket,
  fontFamily: fontFamily,
  fontWeight: fontWeight,
  textDirection: textDirection,
  rendererGeneration: rendererGeneration,
);

/// Creates a minimal recorded glyph picture with a caller-controlled estimate.
PatternGlyphPicture _picture(int estimatedByteSize) {
  final recorder = PictureRecorder();
  Canvas(recorder)
      .drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = Colors.black);
  return PatternGlyphPicture(
    picture: recorder.endRecording(),
    width: 1,
    height: 1,
    estimatedByteSize: estimatedByteSize,
  );
}
