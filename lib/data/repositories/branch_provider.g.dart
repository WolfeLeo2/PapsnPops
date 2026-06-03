// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(branchRepository)
final branchRepositoryProvider = BranchRepositoryProvider._();

final class BranchRepositoryProvider
    extends
        $FunctionalProvider<
          BranchRepository,
          BranchRepository,
          BranchRepository
        >
    with $Provider<BranchRepository> {
  BranchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'branchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchRepositoryHash();

  @$internal
  @override
  $ProviderElement<BranchRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BranchRepository create(Ref ref) {
    return branchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BranchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BranchRepository>(value),
    );
  }
}

String _$branchRepositoryHash() => r'24be12b1ee51f506c7df6b39ea4f8e3f0fd67235';

@ProviderFor(branchesStream)
final branchesStreamProvider = BranchesStreamProvider._();

final class BranchesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Branch>>,
          List<Branch>,
          Stream<List<Branch>>
        >
    with $FutureModifier<List<Branch>>, $StreamProvider<List<Branch>> {
  BranchesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'branchesStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Branch>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Branch>> create(Ref ref) {
    return branchesStream(ref);
  }
}

String _$branchesStreamHash() => r'76e816c36b3337283fdad5ff759dd8d6126b6e3a';

@ProviderFor(CurrentBranchId)
final currentBranchIdProvider = CurrentBranchIdProvider._();

final class CurrentBranchIdProvider
    extends $NotifierProvider<CurrentBranchId, String?> {
  CurrentBranchIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentBranchIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentBranchIdHash();

  @$internal
  @override
  CurrentBranchId create() => CurrentBranchId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentBranchIdHash() => r'9a65ea133afa981b57b9231a8ab22fdbdb8b9c2c';

abstract class _$CurrentBranchId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(currentBranch)
final currentBranchProvider = CurrentBranchProvider._();

final class CurrentBranchProvider
    extends $FunctionalProvider<Branch?, Branch?, Branch?>
    with $Provider<Branch?> {
  CurrentBranchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentBranchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentBranchHash();

  @$internal
  @override
  $ProviderElement<Branch?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Branch? create(Ref ref) {
    return currentBranch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Branch? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Branch?>(value),
    );
  }
}

String _$currentBranchHash() => r'3f9289d32fcdd184d1b78ae524de1922dd2b8316';

@ProviderFor(openTabsCount)
final openTabsCountProvider = OpenTabsCountProvider._();

final class OpenTabsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  OpenTabsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openTabsCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openTabsCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return openTabsCount(ref);
  }
}

String _$openTabsCountHash() => r'8f338d394ed8ee7d675c7fb3805d7751a64f68c3';
