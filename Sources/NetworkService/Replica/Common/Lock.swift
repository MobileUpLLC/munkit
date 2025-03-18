/// Потокобезопасный объект для синхронизации доступа к ресурсам.
actor Lock {
    private var isLocked = false

    /// Блокирует доступ, ожидая, пока блокировка не станет доступной.
    func lock() async {
        while isLocked {
            await _Concurrency.Task.yield() 
        }
        isLocked = true
    }

    /// Снимает блокировку.
    func unlock() {
        precondition(isLocked, "Попытка разблокировать уже разблокированный Lock")
        isLocked = false
    }

    /// Пытается заблокировать без ожидания.
    /// - Returns: `true`, если блокировка успешна, `false` — если уже заблокировано.
    func tryLock() -> Bool {
        if isLocked {
            return false
        } else {
            isLocked = true
            return true
        }
    }

    /// Выполняет блок кода с гарантированной синхронизацией.
    /// - Parameter block: Асинхронный блок кода для выполнения.
    /// - Returns: Результат выполнения блока.
    func withLock<T: Sendable>(_ block: @Sendable () async throws -> T) async rethrows -> T {
        await lock()
        defer { unlock() } // Автоматически снимаем блокировку после выполнения
        return try await block()
    }
}
