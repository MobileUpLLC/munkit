extension AsyncSequence {
    /// Преобразует исходный поток в поток, который активируется или деактивируется на основе другого потока активности.
    internal func makeActivableStream<T>(
        source: AsyncStream<T>,
        activeStream: AsyncStream<Bool>
    ) -> AsyncStream<T> {
        return AsyncStream { (continuation: AsyncStream<T>.Continuation) in
            var task: _Concurrency.Task<Void, Never>? = nil

            _Concurrency.Task {
                for await isActive in activeStream {
                    if isActive {
                        task = _Concurrency.Task {
                            for await value in source {
                                continuation.yield(value)
                            }
                        }
                    } else {
                        task?.cancel()
                        task = nil
                    }
                }
                task?.cancel()
            }
        }
    }
}
