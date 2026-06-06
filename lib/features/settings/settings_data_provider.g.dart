// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(allStaffStream)
final allStaffStreamProvider = AllStaffStreamProvider._();

final class AllStaffStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  AllStaffStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allStaffStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allStaffStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    return allStaffStream(ref);
  }
}

String _$allStaffStreamHash() => r'f21f8ad6565cd2fff082a132bd6f682e063f206d';

@ProviderFor(allPromotionsStream)
final allPromotionsStreamProvider = AllPromotionsStreamProvider._();

final class AllPromotionsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  AllPromotionsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPromotionsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPromotionsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    return allPromotionsStream(ref);
  }
}

String _$allPromotionsStreamHash() =>
    r'ee6812d7ef08c9e1b3592ffecb186d6f4e8f0567';

@ProviderFor(allUsersStream)
final allUsersStreamProvider = AllUsersStreamProvider._();

final class AllUsersStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  AllUsersStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allUsersStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allUsersStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    return allUsersStream(ref);
  }
}

String _$allUsersStreamHash() => r'64da2e225529d87148b3595e8ad58584cb71c983';
