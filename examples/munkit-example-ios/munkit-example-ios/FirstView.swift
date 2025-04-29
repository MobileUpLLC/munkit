//
//  FirstView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit
import munkit_example_core

struct FirstView: View {
    @Environment(DNDClassesRepository.self) private var dndClassesRepository
    @State private var replicaState: ReplicaState<DNDClassesListModel>?

    private let activityStreamBundle = AsyncStream<Bool>.makeStream()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                switch replicaState {
                case .some(let state) where state.loading && state.data == nil:
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                        Text("Loading D&D Classes...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                case .some(let state) where state.error != nil:
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 40))
                        Text("Error Loading Classes")
                            .font(.headline)
                        Text(state.error?.localizedDescription ?? "Unknown error")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task { print("Retry") }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                case .some(let state) where state.data != nil:
                    if let classes = state.data?.value.results, !classes.isEmpty {
                        List {
                            ForEach(classes, id: \.index) { dndClass in
                                ClassRowView(dndClass: dndClass)
                                    .listRowBackground(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemBackground))
                                            .padding(.vertical, 2)
                                    )
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            Task { await dndClassesRepository.getDNDClassesListReplica().revalidate() }
                        }
                        .overlay {
                            if !state.hasFreshData {
                                VStack {
                                    Text("Data may be outdated")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Spacer()
                                }
                                .padding(.top, 8)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "book.closed.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 40))
                            Text("No Classes Found")
                                .font(.headline)
                            Text("Try pulling to refresh")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                default:
                    EmptyView()
                }
            }
            .navigationTitle("D&D Classes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if replicaState?.hasFreshData == false {
                        Button {
                            Task { await dndClassesRepository.getDNDClassesListReplica().refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .task {
            let observer = await dndClassesRepository.getDNDClassesListReplica().observe(
                activityStream: activityStreamBundle.stream
            )

            Task {
                for await state in await observer.stateStream {
                    replicaState = state
                }
            }
        }
        .onAppear { Task { activityStreamBundle.continuation.yield(true) } }
        .onDisappear { Task { activityStreamBundle.continuation.yield(false) } }
    }
}

struct ClassRowView: View {
    let dndClass: DNDClassModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dndClass.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
    }
}

#Preview {
    FirstView()
        .environment(NetworkService())
}

#Preview {
    ClassRowView(
        dndClass: DNDClassModel(
            index: "barbarian",
            name: "Barbarian",
            url: URL(string: "123")!,
            isLiked: false
        )
    )
    .border(.red)
}
