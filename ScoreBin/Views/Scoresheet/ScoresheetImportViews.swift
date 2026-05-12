import PhotosUI
import QuickLook
import SwiftUI
import UIKit
import VisionKit

enum ScoresheetImportSheet: String, Identifiable {
    case sourceChooser
    case scanner

    var id: String { rawValue }
}

struct ScoresheetImportSourceChooserView: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let onScan: () -> Void
    let onPDF: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                importButton(
                    title: "Scan Scoresheet",
                    subtitle: "Use the device camera to scan one paper scoresheet.",
                    systemImage: "camera.viewfinder"
                ) {
                    dismiss()
                    onScan()
                }

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    importLabel(
                        title: "Import Photo",
                        subtitle: "Choose a captured scoresheet image from the photo library.",
                        systemImage: "photo.on.rectangle"
                    )
                }
                .buttonStyle(.plain)

                importButton(
                    title: "Import PDF",
                    subtitle: "Choose a single-page scoresheet PDF from Files.",
                    systemImage: "doc.richtext"
                ) {
                    dismiss()
                    onPDF()
                }

                Spacer(minLength: 0)
            }
            .padding()
            .background(Color.scoreBinBackground)
            .navigationTitle("Import Scoresheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onChange(of: selectedPhotoItem) { _, item in
            if item != nil {
                dismiss()
            }
        }
    }

    private func importButton(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            importLabel(title: title, subtitle: subtitle, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func importLabel(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.scoreBinCyan)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.scoreBinCardBackground)
        .cornerRadius(12)
    }
}

struct ScoresheetImportReviewView: View {
    @Binding var draft: ScoresheetImportDraft
    let onApply: (ScoresheetImportDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    var previewImage: UIImage? {
        ScoresheetImportStorage.shared.image(forRelativePath: draft.previewRelativePath)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let previewImage {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview")
                                .font(.headline)
                                .foregroundColor(.white)

                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                        }
                        .cardStyle()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review Low-Confidence Fields")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(
                            "Only the flagged values need confirmation. Accepted fields will be applied automatically."
                        )
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    .cardStyle()

                    VStack(spacing: 12) {
                        ForEach(draft.unresolvedFieldIDs, id: \.self) { fieldID in
                            ScoresheetImportReviewRow(
                                field: draft.parsedField(for: fieldID),
                                teamLevel: draft.teamLevel
                            ) { confirmedValue in
                                draft.confirmManualValue(confirmedValue, for: fieldID)
                            } onAcceptSuggestion: {
                                draft.confirmSuggestedValue(for: fieldID)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.scoreBinBackground)
            .navigationTitle("Review Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(draft)
                        dismiss()
                    }
                    .disabled(draft.hasUnresolvedFields)
                }
            }
        }
    }
}

private struct ScoresheetImportReviewRow: View {
    let field: ParsedField
    let teamLevel: String?
    let onConfirm: (ScoresheetFieldValue) -> Void
    let onAcceptSuggestion: () -> Void

    @State private var inputText: String
    @State private var errorMessage: String?

    init(
        field: ParsedField,
        teamLevel: String?,
        onConfirm: @escaping (ScoresheetFieldValue) -> Void,
        onAcceptSuggestion: @escaping () -> Void
    ) {
        self.field = field
        self.teamLevel = teamLevel
        self.onConfirm = onConfirm
        self.onAcceptSuggestion = onAcceptSuggestion
        _inputText = State(initialValue: field.candidateValue?.displayString ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(field.fieldID.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int((field.confidence * 100).rounded()))%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.overallYellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.overallYellow.opacity(0.15))
                    .cornerRadius(8)
            }

            if !field.rawText.isEmpty {
                Text("OCR: \(field.rawText)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let failureReason = field.failureReason, !failureReason.isEmpty {
                Text(failureReason)
                    .font(.caption)
                    .foregroundColor(.overallYellow)
            }

            TextField(field.fieldID.reviewHint, text: $inputText)
                .keyboardType(field.fieldID.isIntegerField ? .numberPad : .decimalPad)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack(spacing: 8) {
                if field.candidateValue != nil {
                    Button("Use Suggested") {
                        onAcceptSuggestion()
                    }
                    .buttonStyle(.bordered)
                    .tint(.scoreBinCyan)
                }

                Button("Confirm") {
                    guard let confirmedValue = field.fieldID.manualValue(from: inputText, teamLevel: teamLevel) else {
                        errorMessage = field.fieldID.reviewHint
                        return
                    }

                    errorMessage = nil
                    onConfirm(confirmedValue)
                }
                .buttonStyle(.borderedProminent)
                .tint(.scoreBinEmerald)
            }
        }
        .padding()
        .background(Color.scoreBinCardBackground)
        .cornerRadius(12)
    }
}

struct ImportedScoresheetPreviewCard: View {
    let scoresheet: Scoresheet

    @State private var quickLookItem: QuickLookItem?

    var previewImage: UIImage? {
        ScoresheetImportStorage.shared.image(forRelativePath: scoresheet.importPreviewRelativePath)
    }

    var sourceURL: URL? {
        ScoresheetImportStorage.shared.url(forRelativePath: scoresheet.importSourceRelativePath)
    }

    var body: some View {
        if let previewImage {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Imported Scoresheet")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    if let sourceType = scoresheet.importSourceType {
                        Text(sourceType.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)

                if let sourceURL {
                    Button("Open Original Source") {
                        quickLookItem = QuickLookItem(url: sourceURL)
                    }
                    .buttonStyle(.bordered)
                    .tint(.scoreBinCyan)
                }
            }
            .padding()
            .background(Color.scoreBinBackground.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .sheet(item: $quickLookItem) { item in
                ImportedSourceQuickLookView(url: item.url)
            }
        }
    }
}

private struct QuickLookItem: Identifiable {
    let url: URL
    var id: String { url.path }
}

struct ImportedSourceQuickLookView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            url as NSURL
        }
    }
}

struct ScoresheetDocumentScannerView: UIViewControllerRepresentable {
    let onComplete: (Result<Data, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: (Result<Data, Error>) -> Void

        init(onComplete: @escaping (Result<Data, Error>) -> Void) {
            self.onComplete = onComplete
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            controller.dismiss(animated: true)
            onComplete(.failure(error))
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            controller.dismiss(animated: true)

            guard scan.pageCount == 1 else {
                onComplete(.failure(ScoresheetImportError.unsupportedScanPageCount(scan.pageCount)))
                return
            }

            let image = scan.imageOfPage(at: 0)
            guard let jpegData = image.jpegData(compressionQuality: 0.95) else {
                onComplete(.failure(ScoresheetImportError.previewGenerationFailed))
                return
            }

            onComplete(.success(jpegData))
        }
    }
}
