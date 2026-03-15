//
//  LibraryView.swift
//  TuneGenius
//
//  Shows imported tracks and handles file picker
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \AudioTrack.dateImported, order: .reverse) private var tracks: [AudioTrack]
    @Environment(StoreKitManager.self) private var store

    @State private var vm = LibraryViewModel()
    @State private var showFilePicker = false
    @State private var selectedTrack: AudioTrack?
    @State private var showPaywall = false
    @State private var errorAlert: String?

    var body: some View {
        NavigationStack {
            ZStack {
                TGGradientBackground()
                VStack(spacing: 0) {
                    searchBar
                    if tracks.isEmpty {
                        emptyState
                    } else {
                        trackList
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio, .mp3, .wav, .aiff, .mpeg4Audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        vm.importFile(url: url, context: context)
                    }
                case .failure(let err):
                    errorAlert = err.localizedDescription
                }
            }
            .alert("Import Error", isPresented: Binding(
                get: { vm.importError != nil },
                set: { if !$0 { vm.importError = nil } }
            )) {
                Button("OK", role: .cancel) { vm.importError = nil }
            } message: {
                Text(vm.importError ?? "")
            }
            .sheet(item: $selectedTrack) { track in
                PlayerView(track: track)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search tracks…", text: $vm.searchText)
                .foregroundColor(.white)
            if !vm.searchText.isEmpty {
                Button { vm.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Track List
    private var trackList: some View {
        List {
            ForEach(vm.filtered(tracks)) { track in
                TrackRowView(track: track)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedTrack = track }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.white.opacity(0.1))
            }
            .onDelete { indexSet in
                for idx in indexSet {
                    vm.delete(track: vm.filtered(tracks)[idx], context: context)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))
            Text("No tracks yet")
                .font(.title3.bold())
                .foregroundColor(.secondary)
            Text("Import audio files from your Files app\nor Music library to get started.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button { showFilePicker = true } label: {
                Label("Import Audio", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showFilePicker = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.purple)
            }
        }
        ToolbarItem(placement: .navigationBarLeading) {
            if !store.isPremium {
                Button { showPaywall = true } label: {
                    Label("Pro", systemImage: "crown.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.yellow)
                }
            }
        }
    }
}

// MARK: - TrackRowView
struct TrackRowView: View {
    let track: AudioTrack

    var body: some View {
        HStack(spacing: 14) {
            // Artwork
            Group {
                if let data = track.artworkData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.purple.opacity(0.15))
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(track.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(track.format.uppercased())
                    .font(.caption2)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
