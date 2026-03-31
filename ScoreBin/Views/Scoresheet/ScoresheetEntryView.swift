import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ScoresheetEntryView: View {
    @Environment(\.modelContext) private var modelContext

    private let importService = ScoresheetImportService()

    @State private var viewModel = ScoresheetViewModel()
    @State private var showingExportAlert = false
    @State private var showingSaveAlert = false
    @State private var showingResetConfirmation = false
    @State private var activeImportSheet: ScoresheetImportSheet?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPDFImporter = false
    @State private var importDraftForReview: ScoresheetImportDraft?
    @State private var isImporting = false
    @State private var importErrorMessage = ""
    @State private var showingImportError = false

    /// Team must be selected before scoring and saving are allowed
    private var canEnterScores: Bool {
        viewModel.selectedTeam != nil
    }

    private var canSave: Bool {
        canEnterScores && !isImporting && importDraftForReview == nil
    }

    private var canImport: Bool {
        canEnterScores && !isImporting
    }

    private var reviewSheetPresented: Binding<Bool> {
        Binding(
            get: { importDraftForReview != nil },
            set: { newValue in
                if !newValue {
                    importDraftForReview = nil
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Info Bar
                        ScoresheetHeaderView(viewModel: viewModel)

                        // Validation: team required before scoring
                        if viewModel.selectedTeam == nil {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.overallYellow)
                                Text("Select a team above to enable score entry")
                                    .font(.subheadline)
                                    .foregroundColor(.overallYellow)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.overallYellow.opacity(0.1))
                            .cornerRadius(8)
                        }

                        if let importedAt = viewModel.scoresheet.importedAt {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.image")
                                    .foregroundColor(.scoreBinCyan)
                                Text(
                                    "Imported \(importedAt.formatted(date: .abbreviated, time: .shortened)) from \(viewModel.scoresheet.importSourceType ?? "source")"
                                )
                                .font(.subheadline)
                                .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.scoreBinCyan.opacity(0.12))
                            .cornerRadius(8)
                        }

                        // Judge Panels
                        judgeGridSection
                            .disabled(!canEnterScores)
                            .opacity(canEnterScores ? 1 : 0.45)

                        // Deductions
                        DeductionsSection(scoresheet: $viewModel.scoresheet)
                            .disabled(!canEnterScores)
                            .opacity(canEnterScores ? 1 : 0.45)

                        // Score Summary
                        ScoreSummaryView(viewModel: viewModel)
                            .opacity(canEnterScores ? 1 : 0.6)

                        // Bottom spacer so content isn't hidden behind sticky bar
                        Color.clear.frame(height: 60)
                    }
                    .padding()
                }

                // Sticky score bar - always visible at bottom
                StickyScoreBar(viewModel: viewModel)

                if isImporting {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.scoreBinCyan)
                        Text("Importing scoresheet…")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                }
            }
            .background(Color.scoreBinBackground)
            .navigationTitle("Scoresheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        showingResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Import") {
                        activeImportSheet = .sourceChooser
                    }
                    .disabled(!canImport)

                    Button("Save") {
                        viewModel.modelContext = modelContext
                        viewModel.save()
                        showingSaveAlert = true
                    }
                    .disabled(!canSave)
                }
            }
            .alert("Saved", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) {
                    viewModel.reset()
                }
            } message: {
                Text("Scoresheet saved successfully!")
            }
            .alert("Copied", isPresented: $showingExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Data copied to clipboard!")
            }
            .alert("Import Failed", isPresented: $showingImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage)
            }
            .alert("Reset Scoresheet", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.reset()
                }
            } message: {
                Text("Are you sure you want to reset all scores?")
            }
            .onAppear {
                viewModel.modelContext = modelContext
            }
            .sheet(item: $activeImportSheet) { sheet in
                switch sheet {
                case .sourceChooser:
                    ScoresheetImportSourceChooserView(
                        selectedPhotoItem: $selectedPhotoItem,
                        onScan: {
                            DispatchQueue.main.async {
                                activeImportSheet = .scanner
                            }
                        },
                        onPDF: {
                            DispatchQueue.main.async {
                                showingPDFImporter = true
                            }
                        }
                    )
                case .scanner:
                    ScoresheetDocumentScannerView { result in
                        activeImportSheet = nil
                        switch result {
                        case .success(let jpegData):
                            importScannedImageData(jpegData)
                        case .failure(let error):
                            presentImportError(error)
                        }
                    }
                    .ignoresSafeArea()
                }
            }
            .sheet(isPresented: reviewSheetPresented) {
                if importDraftForReview != nil {
                    ScoresheetImportReviewView(
                        draft: Binding(
                            get: { importDraftForReview! },
                            set: { importDraftForReview = $0 }
                        )
                    ) { resolvedDraft in
                        viewModel.applyImportDraft(resolvedDraft)
                        importDraftForReview = nil
                    }
                }
            }
            .fileImporter(
                isPresented: $showingPDFImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handlePDFImport(result)
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                importPhotoItem(item)
            }
        }
    }

    // MARK: - Judge Grid Section

    private var judgeGridSection: some View {
        VStack(spacing: 12) {
            BuildingJudgeSection(scoresheet: $viewModel.scoresheet)
            TumblingJudgeSection(scoresheet: $viewModel.scoresheet)
            OverallJudgeSection(scoresheet: $viewModel.scoresheet, viewModel: viewModel)
        }
    }

    private var importContext: ScoresheetImportContext {
        ScoresheetImportContext(
            teamID: viewModel.selectedTeam?.id,
            competitionID: viewModel.selectedCompetition?.id,
            round: viewModel.scoresheet.round,
            teamLevel: viewModel.selectedTeam?.level
        )
    }

    private func importPhotoItem(_ item: PhotosPickerItem) {
        startImport {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                throw ScoresheetImportError.fileLoadFailed
            }

            let utType = item.supportedContentTypes.first
            let fileExtension = utType?.preferredFilenameExtension ?? "jpg"
            return try await importService.importScoresheet(
                from: .image(
                    data: imageData,
                    sourceType: .photoLibrary,
                    suggestedFileName: "scoresheet-photo.\(fileExtension)",
                    utType: utType
                ),
                context: importContext
            )
        }
    }

    private func importScannedImageData(_ data: Data) {
        startImport {
            try await importService.importScoresheet(
                from: .image(
                    data: data,
                    sourceType: .cameraScan,
                    suggestedFileName: "scoresheet-scan.jpg",
                    utType: .jpeg
                ),
                context: importContext
            )
        }
    }

    private func handlePDFImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            startImport {
                try await importService.importScoresheet(from: .pdf(url: url), context: importContext)
            }
        case .failure(let error):
            presentImportError(error)
        }
    }

    private func startImport(_ operation: @escaping () async throws -> ScoresheetImportDraft) {
        Task {
            selectedPhotoItem = nil
            isImporting = true
            defer { isImporting = false }

            do {
                let draft = try await operation()
                if draft.hasUnresolvedFields {
                    importDraftForReview = draft
                } else {
                    viewModel.applyImportDraft(draft)
                }
            } catch {
                presentImportError(error)
            }
        }
    }

    private func presentImportError(_ error: Error) {
        importErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        showingImportError = true
    }
}

// MARK: - Header Subview

struct ScoresheetHeaderView: View {
    @Bindable var viewModel: ScoresheetViewModel

    @Query(sort: \Team.name) private var teams: [Team]
    @Query(sort: \Competition.date, order: .reverse) private var competitions: [Competition]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Team Picker
                Menu {
                    Button("No Team") {
                        viewModel.selectedTeam = nil
                    }
                    ForEach(teams) { team in
                        Button(team.name) {
                            viewModel.selectedTeam = team
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(viewModel.selectedTeam?.name ?? "Select Team")
                                .foregroundColor(viewModel.selectedTeam == nil ? .gray : .white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        if viewModel.selectedTeam == nil {
                            Text("(required)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.scoreBinCardBackground)
                    .cornerRadius(8)
                }

                // Competition Picker
                Menu {
                    Button("No Competition") {
                        viewModel.selectedCompetition = nil
                    }
                    ForEach(competitions) { competition in
                        Button(competition.name) {
                            viewModel.selectedCompetition = competition
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedCompetition?.name ?? "Select Competition")
                            .foregroundColor(viewModel.selectedCompetition == nil ? .gray : .white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.scoreBinCardBackground)
                    .cornerRadius(8)
                }
            }

            HStack(spacing: 12) {
                // Round Picker
                Menu {
                    ForEach(RoundType.allCases, id: \.self) { round in
                        Button(round.rawValue) {
                            viewModel.scoresheet.round = round.rawValue
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.scoresheet.round)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.scoreBinCardBackground)
                    .cornerRadius(8)
                }

                // Quantity Chart Display
                if let team = viewModel.selectedTeam {
                    HStack(spacing: 4) {
                        Text("\(team.athleteCount)")
                            .font(.headline)
                            .foregroundColor(.scoreBinCyan)
                        Text("athletes")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(viewModel.quantityChart.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.scoreBinCardBackground)
                    .cornerRadius(8)
                }
            }
        }
        .cardStyle()
        .padding(.horizontal, 4)
    }
}

#Preview {
    ScoresheetEntryView()
        .modelContainer(
            for: [Scoresheet.self, Team.self, Competition.self, Gym.self], inMemory: true)
}
