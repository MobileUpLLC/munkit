//
//  DNDMonstersListView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit
import munkit_example_core

struct DNDMonstersListView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(DNDMonstersRepository.self) private var dndMonstersRepository

    @State private var replicaState: ReplicaState<DNDMonstersListModel>?
    @State private var replicaSetupped = false

    private let activityStream = AsyncStream<Bool>.makeStream()

    var body: some View {
        ReplicaStateView(
            replicaState: replicaState,
            refreshAction: {
                await dndMonstersRepository.getDNDMonstersListReplica().revalidate()
            },
            content: { data in
                List {
                    ForEach(data.results, id: \.index) { monster in
                        DNDMonsterListRowView(monster: monster)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemBackground))
                                    .padding(.vertical, 2)
                            )
                    }
                }
                .listStyle(.plain)
            },
            emptyContent: {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 40))
                    Text("No Monsters Found")
                        .font(.headline)
                    Text("Try pulling to refresh")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        )
        .navigationTitle("D&D Monsters")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if replicaState?.hasFreshData == false {
                    Button {
                        Task { await dndMonstersRepository.getDNDMonstersListReplica().refresh() }
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

                let observer = await dndMonstersRepository.getDNDMonstersListReplica().observe(
                    activityStream: activityStream.stream
                )
                activityStream.continuation.yield(true)

                for await state in await observer.stateStream {
                    replicaState = state
                }
            }
        }
    }
}
