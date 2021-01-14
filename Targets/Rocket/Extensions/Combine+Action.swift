import Combine

public enum ActionError: Error {
    case notEnabled
    case underlyingError(Error)
}

public final class Action<Input, Element> {
    public typealias WorkFactory = (Input) -> AnyPublisher<Element, Error>

    public let workFactory: WorkFactory

    public let inputs: AnySubscriber<Input, Never>

    /// Errors aggrevated from invocations of execute().
    /// Delivered on whatever scheduler they were sent from.
    public let errors: AnyPublisher<ActionError, Never>

    /// Whether or not we're currently executing.
    /// Delivered on whatever scheduler they were sent from.
    public let elements: AnyPublisher<Element, Never>

    /// Whether or not we're currently executing.
    public let executing: AnyPublisher<Bool, Never>

    /// Whether or not we're enabled. Note that this is a *computed* sequence
    /// property based on enabledIf initializer and if we're currently executing.
    /// Always observed on MainScheduler.
    public let enabled: AnyPublisher<Bool, Never>

    private var cancellables: Set<AnyCancellable> = []

    public init<P0: Publisher>(
        enabledIf: P0,
        workFactory: @escaping WorkFactory
    ) where P0.Output == Bool, P0.Failure == Never {


        self.workFactory = workFactory

        let enabledSubject = CurrentValueSubject<Bool, Never>(false)
        enabled = enabledSubject.eraseToAnyPublisher()

        let errorsSubject = PassthroughSubject<ActionError, Never>()
        errors = errorsSubject.eraseToAnyPublisher()
        
        let inputsSubject = PassthroughSubject<Input, Never>()
        
        inputs = AnySubscriber<Input, Never>(receiveValue: {
            inputsSubject.send($0)
            return .unlimited
        })
        
        let executionObservables = inputsSubject
            .map { [enabledSubject] input in (input, enabledSubject.value) }
            .map { input, enabled -> AnyPublisher<Element, Never> in
                if enabled {
                    return workFactory(input).catch { error -> Empty<Element, Never> in
                        errorsSubject.send(.underlyingError(error))
                        return Empty()
                    }
                    .share()
                    .eraseToAnyPublisher()
                } else {
                    errorsSubject.send(.notEnabled)
                    return Empty<Element, Never>().eraseToAnyPublisher()
                }
            }
            .share()

        elements = executionObservables.flatMap { $0 }.eraseToAnyPublisher()
        
        executing = executionObservables.flatMap {
            execution -> AnyPublisher<Bool, Never> in
            let execution = execution
                .flatMap { _ in Empty<Bool, Never>() }
                .catch { _ in Empty<Bool, Never>() }
            
            return Just(true).append(execution).append(Just(false)).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
        .prepend(false)
        .eraseToAnyPublisher()
        
        executing.combineLatest(enabledIf)
            .map { !$0 && $1 }
            .sink(receiveValue: { enabledSubject.value = $0 })
            .store(in: &cancellables)
    }
}
