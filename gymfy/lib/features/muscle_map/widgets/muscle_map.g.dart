// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_map.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads (and caches) the raw SVG text for a body side. Kept in a provider so
/// the file is read once, not on every rebuild / accent change.

@ProviderFor(bodySvgTemplate)
final bodySvgTemplateProvider = BodySvgTemplateFamily._();

/// Loads (and caches) the raw SVG text for a body side. Kept in a provider so
/// the file is read once, not on every rebuild / accent change.

final class BodySvgTemplateProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Loads (and caches) the raw SVG text for a body side. Kept in a provider so
  /// the file is read once, not on every rebuild / accent change.
  BodySvgTemplateProvider._({
    required BodySvgTemplateFamily super.from,
    required BodySide super.argument,
  }) : super(
         retry: null,
         name: r'bodySvgTemplateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bodySvgTemplateHash();

  @override
  String toString() {
    return r'bodySvgTemplateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as BodySide;
    return bodySvgTemplate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BodySvgTemplateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bodySvgTemplateHash() => r'96182d972ec034daf695a95dd98feb1648357dec';

/// Loads (and caches) the raw SVG text for a body side. Kept in a provider so
/// the file is read once, not on every rebuild / accent change.

final class BodySvgTemplateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, BodySide> {
  BodySvgTemplateFamily._()
    : super(
        retry: null,
        name: r'bodySvgTemplateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads (and caches) the raw SVG text for a body side. Kept in a provider so
  /// the file is read once, not on every rebuild / accent change.

  BodySvgTemplateProvider call(BodySide side) =>
      BodySvgTemplateProvider._(argument: side, from: this);

  @override
  String toString() => r'bodySvgTemplateProvider';
}
