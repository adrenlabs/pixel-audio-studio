---
name: Flutter Dart clamp() num type pitfall
description: .clamp() returns num in Dart — must cast to double/int explicitly or the analyzer fails.
---

## Rule
In Dart, `.clamp(a, b)` returns `num`, not `double` or `int`, even if all three operands are typed. Assigning `num` to a `double` or `int` field causes an analyzer/compile error.

## Fix
Always append `.toDouble()` or `.toInt()` after `.clamp()`:

```dart
// WRONG — clamp returns num
state.copyWith(masterVolume: vol.clamp(0.0, 1.0));
_vScroll.jumpTo(offset.clamp(0, double.infinity));

// CORRECT
state.copyWith(masterVolume: vol.clamp(0.0, 1.0).toDouble());
_vScroll.jumpTo(offset.clamp(0.0, double.infinity).toDouble());
state.copyWith(bpm: bpm.clamp(20, 300).toInt());
```

**Why:** Dart's `num.clamp` signature returns `T extends num`, but the runtime type inference isn't tight enough for the static analyzer in all versions. Always make it explicit.

**How to apply:** After any `.clamp()` call that feeds into a `double`/`int` typed slot (widget prop, state field, `copyWith` param), add `.toDouble()` or `.toInt()`.
