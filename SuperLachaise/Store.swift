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

typealias Dispatch<Action> = (Action) -> Void

/**
 Redux-like store
 */
class Store<State, Action> {

    typealias Reducer = (Action, State) -> State

    let state: Variable<State>
    let reducer: Reducer

    private let actions = PublishSubject<Action>()
    private let dispatchQueue: DispatchQueue
    let disposeBag = DisposeBag()

    init(initialState: State,
         reducer: @escaping Reducer,
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
