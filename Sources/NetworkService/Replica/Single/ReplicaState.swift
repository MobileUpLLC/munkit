import Foundation

public struct ReplicaState<T: AnyObject & Sendable> {
    var loading: Bool
    var data: ReplicaData<T>?
    var error: LoadingError?
    var observingState: ObservingState
    var dataRequested: Bool
    var preloading: Bool
    var loadingFromStorageRequired: Bool

    var hasFreshData: Bool {
        return data?.isFresh == true
    }

    static func createEmpty(hasStorage: Bool) -> ReplicaState<T> {
        return ReplicaState(
            loading: false,
            data: nil,
            error: nil,
            observingState: ObservingState(),
            dataRequested: false,
            preloading: false,
            loadingFromStorageRequired: hasStorage
        )
    }

    func getLoadable() -> LoadableReplicaState<T> {
        return LoadableReplicaState(
            loading: loading,
            data: data?.value,
            error: error.map { CombinedLoadingError(errors: [$0]) }
        )
    }
}
