//
//  DNDMonsterDetailView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 15.05.2025.
//

import SwiftUI
import munkit
import munkit_example_core

struct DNDMonsterDetailView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(DNDMonstersRepository.self) private var dndMonstersRepository

    @State private var replicaState: ReplicaState<DNDMonsterModel>?
    @State private var replicaSetupped = false

    private let monsterIndexStream: AsyncStreamBundle<String>

    private let activityStream = AsyncStream<Bool>.makeStream()
    private let monsterIndex: String

    init(monsterIndex: String) {
        self.monsterIndex = monsterIndex
        self.monsterIndexStream = AsyncStream<String>.makeStream()
    }

    var body: some View {
        ReplicaStateView(
            replicaState: replicaState,
            refreshAction: {
                await dndMonstersRepository.getDNDMonstersReplica().revalidate(key: monsterIndex)
            },
            content: { monster in
                DNDMonsterDetailDataView(monster: monster)
            },
            emptyContent: {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 40))
                    Text("Monster Not Found")
                        .font(.headline)
                    Text("Try refreshing or check the monster index")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        )
        .navigationTitle(replicaState?.data?.value.name ?? "Monster Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if replicaState?.hasFreshData == false {
                    Button {
                        Task { await dndMonstersRepository.getDNDMonstersReplica().refresh(key: monsterIndex) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            guard !replicaSetupped else {
                activityStream.continuation.yield(true)
                return
            }

            replicaSetupped = true

            Task {
                navigationModel.performActionAfterPop { activityStream.continuation.finish() }

                let observer = await dndMonstersRepository
                    .getDNDMonstersReplica()
                    .observe(activityStream: activityStream.stream, keyStream: monsterIndexStream.stream)

                activityStream.continuation.yield(true)
                monsterIndexStream.continuation.yield(monsterIndex)

                for await state in await observer.stateStream {
                    replicaState = state
                }
            }
        }
    }
}

#Preview {
    DNDMonsterDetailView(monsterIndex: "dragon")
        .environment(DNDMonstersRepository(networkService: NetworkService()))
        .environment(NavigationModel())
}
