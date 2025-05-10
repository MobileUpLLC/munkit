//
//  AsyncStreamBundle.swift
//  NetworkService
//
//  Created by Ilia Chub on 07.04.2025.
//

public typealias AsyncStreamBundle<T> = (stream: AsyncStream<T>, continuation: AsyncStream<T>.Continuation)
