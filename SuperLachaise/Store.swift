//
//  Store.swift
//  SuperLachaise
//
//  Created by Maxime Le Moine on 29/05/2017.
//
//

import Foundation
import RxCocoa
import RxSwift

/**
 Redux-like store
 */
class Store<State, Action> {

    let state: Variable<State>
    let reducer: (Action, State) -> State

    private let actions = PublishSubject<Action>()
    private let dispatchQueue: DispatchQueue
    let disposeBag = DisposeBag()

    init(initialState: State,
         reducer: @escaping (Action, State) -> State,
         dispatchQueue: DispatchQueue = DispatchQueue.main) {
        self.state = Variable(initialState)
        self.reducer = reducer
        self.dispatchQueue = dispatchQueue

        actions
            .withLatestFrom(state.asObservable(), resultSelector: reducer)
            .bind(to: state)
            .disposed(by: disposeBag)

    }

    func dispatch(action: Action) {
        dispatchQueue.async {
            self.actions.onNext(action)
        }
    }

}
