import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import Foundation
import PDFKit
import UIKit
@preconcurrency import Vision

struct RecognizedTextObservation: Equatable, Sendable {
    let text: String
    let confidence: Double
    let boundingBox: CGRect  // Normalized top-left coordinates
}

protocol ScoresheetTextRecognizing {
    func recognizeText(in cgImage: CGImage) async throws -> [RecognizedTextObservation]
}

struct ScoresheetFieldDefinition: Equatable, Sendable {
    let fieldID: ScoresheetFieldID
    let aliases: [String]
    let labelRegion: CGRect
    let valueRegion: CGRect

    var searchRegion: CGRect {
        labelRegion.union(valueRegion)
    }

    func labelRect(in canvasSize: CGSize) -> CGRect {
        labelRegion.scaled(to: canvasSize)
    }

    func valueRect(in canvasSize: CGSize) -> CGRect {
        valueRegion.scaled(to: canvasSize)
    }
}

struct VisionScoresheetTextRecognizer: ScoresheetTextRecognizing {
    func recognizeText(in cgImage: CGImage) async throws -> [RecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations =
                    (request.results as? [VNRecognizedTextObservation] ?? []).compactMap {
                        observation -> RecognizedTextObservation? in
                        guard let candidate = observation.topCandidates(1).first else { return nil }
                        let converted = CGRect(
                            x: observation.boundingBox.origin.x,
                            y: 1 - observation.boundingBox.origin.y - observation.boundingBox.height,
                            width: observation.boundingBox.width,
                            height: observation.boundingBox.height
                        )
                        return RecognizedTextObservation(
                            text: candidate.string,
                            confidence: Double(candidate.confidence),
                            boundingBox: converted
                        )
                    }

                continuation.resume(returning: observations)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.minimumTextHeight = 0.015
            request.revision = VNRecognizeTextRequestRevision3

            Task.detached {
                do {
                    try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

final class ScoresheetImportService: ScoresheetImporting {
    static let parserVersion = "ocr-v1"
    static let previewCanvasSize = CGSize(width: 1800, height: 2400)
    static let autoAcceptThreshold = 0.85
    static let fieldDefinitions = makeFieldDefinitions()

    private let storage: ScoresheetImportStorage
    private let textRecognizer: ScoresheetTextRecognizing
    private let ciContext = CIContext()

    init(
        storage: ScoresheetImportStorage = .shared,
        textRecognizer: ScoresheetTextRecognizing = VisionScoresheetTextRecognizer()
    ) {
        self.storage = storage
        self.textRecognizer = textRecognizer
    }

    func importScoresheet(from input: ScoresheetImportInput, context: ScoresheetImportContext) async
        throws -> ScoresheetImportDraft
    {
        guard context.teamID != nil else {
            throw ScoresheetImportError.teamSelectionRequired
        }

        let preparedDocument = try prepareDocument(from: input)
        let observations = try await textRecognizer.recognizeText(in: preparedDocument.previewCGImage)
        let trimmedObservations = observations.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !trimmedObservations.isEmpty else {
            throw ScoresheetImportError.noTextFound
        }

        let parsedFields = parseRecognizedFields(trimmedObservations, context: context)

        return ScoresheetImportDraft(
            id: preparedDocument.draftID,
            teamID: context.teamID,
            competitionID: context.competitionID,
            round: context.round,
            teamLevel: context.teamLevel,
            sourceType: preparedDocument.sourceType,
            sourceRelativePath: preparedDocument.sourceRelativePath,
            previewRelativePath: preparedDocument.previewRelativePath,
            sourceDisplayName: preparedDocument.sourceDisplayName,
            parserVersion: Self.parserVersion,
            createdAt: Date(),
            parsedFields: parsedFields
        )
    }

    func parseRecognizedFields(
        _ observations: [RecognizedTextObservation],
        context: ScoresheetImportContext
    ) -> [ScoresheetFieldID: ParsedField] {
        var parsedFields: [ScoresheetFieldID: ParsedField] = [:]

        for definition in Self.fieldDefinitions {
            if definition.fieldID.isTossField
                && !ScoringRules.isTossAllowed(forLevel: context.teamLevel)
            {
                parsedFields[definition.fieldID] = ParsedField(
                    fieldID: definition.fieldID,
                    rawText: "Level 1 toss restriction",
                    candidateValue: .score(0),
                    confidence: 1,
                    status: .accepted,
                    sourceRect: nil,
                    failureReason: nil
                )
                continue
            }

            let searchRegion = definition.searchRegion.insetBy(dx: -0.03, dy: -0.02)
            let relevantObservations = observations.filter {
                $0.boundingBox.intersects(searchRegion) || searchRegion.contains($0.boundingBox.center)
            }
            let labelConfidence = labelConfidence(for: definition, observations: relevantObservations)
            let candidates = buildCandidates(
                for: definition,
                observations: relevantObservations,
                teamLevel: context.teamLevel,
                labelConfidence: labelConfidence
            )

            guard let bestCandidate = candidates.first else {
                parsedFields[definition.fieldID] = ParsedField(
                    fieldID: definition.fieldID,
                    rawText: "",
                    candidateValue: nil,
                    confidence: 0,
                    status: .needsReview,
                    sourceRect: nil,
                    failureReason: "No OCR value matched this field"
                )
                continue
            }

            let isAmbiguous =
                bestCandidate.isAmbiguous
                || (candidates.count > 1 && abs(bestCandidate.compositeScore - candidates[1].compositeScore)
                    < 0.08)
            let finalConfidence =
                max(
                    0,
                    min(
                        1,
                        bestCandidate.compositeScore - (isAmbiguous ? 0.18 : 0)
                            - (bestCandidate.wasCorrected ? 0.16 : 0)
                    )
                )
            let status: ParsedFieldStatus =
                finalConfidence >= Self.autoAcceptThreshold && !isAmbiguous && !bestCandidate.wasCorrected
                ? .accepted : .needsReview
            let failureReason =
                status == .accepted
                ? nil
                : bestCandidate.failureReason
                    ?? (isAmbiguous
                        ? "Multiple OCR values matched this field"
                        : bestCandidate.wasCorrected
                            ? "OCR value was adjusted to the nearest valid score"
                            : "This field needs review")

            parsedFields[definition.fieldID] = ParsedField(
                fieldID: definition.fieldID,
                rawText: bestCandidate.rawText,
                candidateValue: bestCandidate.value,
                confidence: finalConfidence,
                status: status,
                sourceRect: bestCandidate.sourceRect,
                failureReason: failureReason
            )
        }

        return parsedFields
    }

    private func prepareDocument(from input: ScoresheetImportInput) throws -> PreparedImportDocument {
        let draftID = UUID()

        switch input {
        case .image(let data, let sourceType, let suggestedFileName, let utType):
            guard let image = UIImage(data: data) else {
                throw ScoresheetImportError.imageDecodeFailed
            }
            let normalizedImage = try normalizedPreviewImage(from: image)
            guard let previewCGImage = normalizedImage.cgImage else {
                throw ScoresheetImportError.previewGenerationFailed
            }

            let fileExtension = utType?.preferredFilenameExtension ?? "jpg"
            let sourceFileName = suggestedFileName.isEmpty
                ? "scoresheet.\(fileExtension)"
                : suggestedFileName
            let sourceRelativePath = try storage.storeSourceData(
                data,
                fileName: sourceFileName,
                draftID: draftID
            )
            let previewRelativePath = try storage.storePreviewImage(normalizedImage, draftID: draftID)
            return PreparedImportDocument(
                draftID: draftID,
                sourceType: sourceType,
                sourceDisplayName: sourceFileName,
                sourceRelativePath: sourceRelativePath,
                previewRelativePath: previewRelativePath,
                previewCGImage: previewCGImage
            )

        case .pdf(let url):
            let hasScopedAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasScopedAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            guard let document = PDFDocument(url: url) else {
                throw ScoresheetImportError.fileLoadFailed
            }
            guard document.pageCount == 1 else {
                throw ScoresheetImportError.unsupportedPDFPageCount(document.pageCount)
            }
            guard let page = document.page(at: 0) else {
                throw ScoresheetImportError.fileLoadFailed
            }

            let previewImage = renderPDFPage(page)
            guard let previewCGImage = previewImage.cgImage else {
                throw ScoresheetImportError.previewGenerationFailed
            }

            let sourceRelativePath = try storage.storeSourceFile(at: url, draftID: draftID)
            let previewRelativePath = try storage.storePreviewImage(previewImage, draftID: draftID)
            return PreparedImportDocument(
                draftID: draftID,
                sourceType: .pdf,
                sourceDisplayName: url.lastPathComponent,
                sourceRelativePath: sourceRelativePath,
                previewRelativePath: previewRelativePath,
                previewCGImage: previewCGImage
            )
        }
    }

    private func normalizedPreviewImage(from image: UIImage) throws -> UIImage {
        let orientedImage = image.normalizedOrientation()
        let perspectiveCorrected = correctedDocumentImage(from: orientedImage) ?? orientedImage
        let targetSize = Self.previewCanvasSize

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1

        return UIGraphicsImageRenderer(size: targetSize, format: rendererFormat).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))

            let drawRect = AVMakeRect(aspectRatio: perspectiveCorrected.size, insideRect: CGRect(origin: .zero, size: targetSize))
            perspectiveCorrected.draw(in: drawRect)
        }
    }

    private func correctedDocumentImage(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.5
        request.minimumSize = 0.5

        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            guard let rectangle = request.results?.first as? VNRectangleObservation else {
                return nil
            }

            let ciImage = CIImage(cgImage: cgImage)
            let extent = ciImage.extent
            let filter = CIFilter.perspectiveCorrection()
            filter.inputImage = ciImage
            filter.topLeft = rectangle.topLeft.scaled(to: extent.size)
            filter.topRight = rectangle.topRight.scaled(to: extent.size)
            filter.bottomLeft = rectangle.bottomLeft.scaled(to: extent.size)
            filter.bottomRight = rectangle.bottomRight.scaled(to: extent.size)

            guard let outputImage = filter.outputImage,
                let correctedCGImage = ciContext.createCGImage(outputImage, from: outputImage.extent)
            else {
                return nil
            }

            return UIImage(cgImage: correctedCGImage)
        } catch {
            return nil
        }
    }

    private func renderPDFPage(_ page: PDFPage) -> UIImage {
        let targetSize = Self.previewCanvasSize
        let pageBounds = page.bounds(for: .mediaBox)
        let scale = min(targetSize.width / pageBounds.width, targetSize.height / pageBounds.height)
        let scaledSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)
        let drawOrigin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1

        return UIGraphicsImageRenderer(size: targetSize, format: rendererFormat).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))

            context.cgContext.saveGState()
            context.cgContext.translateBy(x: drawOrigin.x, y: drawOrigin.y + scaledSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()
        }
    }

    private func buildCandidates(
        for definition: ScoresheetFieldDefinition,
        observations: [RecognizedTextObservation],
        teamLevel: String?,
        labelConfidence: Double
    ) -> [FieldCandidate] {
        let valueRegion = definition.valueRegion.insetBy(dx: -0.015, dy: -0.008)
        var candidates: [FieldCandidate] = []

        for observation in observations {
            guard
                observation.boundingBox.intersects(valueRegion)
                    || valueRegion.contains(observation.boundingBox.center)
            else {
                continue
            }

            let parsedCandidates = parseFieldValues(
                from: observation.text,
                fieldID: definition.fieldID,
                teamLevel: teamLevel
            )

            for parsed in parsedCandidates {
                let spatial = spatialConfidence(
                    observation.boundingBox,
                    expectedRegion: definition.valueRegion
                )
                let validity = parsed.wasCorrected ? 0.65 : 1.0
                let composite =
                    observation.confidence * 0.55 + labelConfidence * 0.2 + spatial * 0.15
                    + validity * 0.1

                candidates.append(
                    FieldCandidate(
                        value: parsed.value,
                        rawText: observation.text,
                        sourceRect: observation.boundingBox,
                        wasCorrected: parsed.wasCorrected,
                        isAmbiguous: parsed.isAmbiguous,
                        failureReason: parsed.failureReason,
                        compositeScore: composite
                    )
                )
            }
        }

        return candidates.sorted { lhs, rhs in
            if lhs.compositeScore == rhs.compositeScore {
                return lhs.rawText.count < rhs.rawText.count
            }
            return lhs.compositeScore > rhs.compositeScore
        }
    }

    private func parseFieldValues(
        from rawText: String,
        fieldID: ScoresheetFieldID,
        teamLevel: String?
    ) -> [ParsedValueCandidate] {
        if fieldID.isIntegerField {
            let matches = rawText.numericLikeMatches(
                for: #"(?<![\p{L}])[0-9OoIl]+(?![\p{L}])"#
            )
            let values = Array(Set(matches.compactMap(Int.init))).sorted()
            return values.map {
                ParsedValueCandidate(
                    value: .deduction($0),
                    wasCorrected: false,
                    isAmbiguous: values.count > 1,
                    failureReason: values.count > 1 ? "Multiple counts were detected" : nil
                )
            }
        }

        if fieldID.isTossField && !ScoringRules.isTossAllowed(forLevel: teamLevel) {
            return [
                ParsedValueCandidate(
                    value: .score(0),
                    wasCorrected: false,
                    isAmbiguous: false,
                    failureReason: nil
                )
            ]
        }

        guard let range = fieldID.scoreRange else { return [] }

        let matches = rawText.numericLikeMatches(
            for: #"(?<![\p{L}])[0-9OoIl]+(?:[.,][0-9OoIl]+)?(?![\p{L}])"#
        )
        let isAmbiguous = Set(matches).count > 1
        var candidates: [ParsedValueCandidate] = []
        for match in matches {
            guard let rawValue = Double(match) else { continue }
            candidates.append(
                contentsOf: validatedScoreCandidates(
                    from: rawValue,
                    range: range,
                    isAmbiguous: isAmbiguous
                )
            )
        }

        return candidates.uniqued()
    }

    private func validatedScoreCandidates(
        from rawValue: Double,
        range: ScoringRules.ScoreRange,
        isAmbiguous: Bool
    ) -> [ParsedValueCandidate] {
        let rawValueIsInRange = rawValue >= range.min - 0.001 && rawValue <= range.max + 0.001
        if rawValueIsInRange {
            let candidate = makeScoreCandidate(
                from: rawValue,
                originalRawValue: rawValue,
                range: range,
                isAmbiguous: isAmbiguous
            )
            return [candidate].compactMap { $0 }
        }

        let plausibleScaledValues = [rawValue / 10, rawValue / 100].filter { candidate in
            candidate >= range.min - range.step && candidate <= range.max + range.step
        }

        let candidates = plausibleScaledValues.compactMap { scaledValue in
            makeScoreCandidate(
                from: scaledValue,
                originalRawValue: rawValue,
                range: range,
                isAmbiguous: isAmbiguous
            )
        }

        if !candidates.isEmpty {
            return candidates.uniqued()
        }

        let fallbackCandidate = makeScoreCandidate(
            from: rawValue,
            originalRawValue: rawValue,
            range: range,
            isAmbiguous: isAmbiguous
        )

        return [fallbackCandidate].compactMap { $0 }.uniqued()
    }

    private func makeScoreCandidate(
        from candidateValue: Double,
        originalRawValue: Double,
        range: ScoringRules.ScoreRange,
        isAmbiguous: Bool
    ) -> ParsedValueCandidate? {
        let clampedValue = min(max(candidateValue, range.min), range.max)
        let snappedValue = snap(clampedValue, to: range)
        let inRange = candidateValue >= range.min - 0.001 && candidateValue <= range.max + 0.001
        let corrected = abs(snappedValue - originalRawValue) > 0.001 || !inRange

        guard range.contains(snappedValue) else { return nil }

        return ParsedValueCandidate(
            value: .score(snappedValue),
            wasCorrected: corrected,
            isAmbiguous: isAmbiguous,
            failureReason: {
                if isAmbiguous {
                    return "Multiple numeric candidates were detected"
                }
                if corrected {
                    return "OCR value was adjusted to the nearest valid score"
                }
                return nil
            }()
        )
    }

    private func labelConfidence(
        for definition: ScoresheetFieldDefinition,
        observations: [RecognizedTextObservation]
    ) -> Double {
        let labelRegion = definition.labelRegion.insetBy(dx: -0.05, dy: -0.03)
        let normalizedAliases = definition.aliases.map(\.normalizedForMatching)

        return observations.reduce(0) { currentBest, observation in
            guard
                observation.boundingBox.intersects(labelRegion)
                    || labelRegion.contains(observation.boundingBox.center)
            else {
                return currentBest
            }

            let normalizedText = observation.text.normalizedForMatching
            let score = normalizedAliases.reduce(0.0) { best, alias in
                if normalizedText.contains(alias) || alias.contains(normalizedText) {
                    return max(best, 1)
                }
                let aliasTokens = Set(alias.split(separator: " ").map(String.init))
                let textTokens = Set(normalizedText.split(separator: " ").map(String.init))
                if !aliasTokens.isEmpty && aliasTokens.isSubset(of: textTokens) {
                    return max(best, 0.75)
                }
                return best
            }
            return max(currentBest, score)
        }
    }

    private func spatialConfidence(_ rect: CGRect, expectedRegion: CGRect) -> Double {
        let center = rect.center
        let expectedCenter = expectedRegion.center
        let dx = abs(center.x - expectedCenter.x) / max(expectedRegion.width, 0.001)
        let dy = abs(center.y - expectedCenter.y) / max(expectedRegion.height, 0.001)
        return max(0, 1 - min(1, dx * 0.45 + dy * 0.7))
    }

    private func snap(_ value: Double, to range: ScoringRules.ScoreRange) -> Double {
        let stepCount = ((value - range.min) / range.step).rounded()
        let snapped = range.min + (stepCount * range.step)
        return snapped.roundedToStepPrecision(range.step)
    }

    private static func makeFieldDefinitions() -> [ScoresheetFieldDefinition] {
        var definitions: [ScoresheetFieldDefinition] = []

        func append(
            _ fieldID: ScoresheetFieldID,
            aliases: [String],
            labelRegion: CGRect,
            valueRegion: CGRect
        ) {
            definitions.append(
                ScoresheetFieldDefinition(
                    fieldID: fieldID,
                    aliases: aliases,
                    labelRegion: labelRegion,
                    valueRegion: valueRegion
                )
            )
        }

        let buildingLabelX = 0.055
        let buildingValueX = 0.255
        let tumblingLabelX = 0.37
        let tumblingValueX = 0.57
        let overallLabelX = 0.69
        let overallValueX = 0.88
        let labelWidth = 0.18
        let valueWidth = 0.08
        let rowHeight = 0.035

        func row(_ y: CGFloat, labelX: CGFloat, valueX: CGFloat) -> (CGRect, CGRect) {
            (
                CGRect(x: labelX, y: y, width: labelWidth, height: rowHeight),
                CGRect(x: valueX, y: y, width: valueWidth, height: rowHeight)
            )
        }

        let buildingRows: [(ScoresheetFieldID, [String], CGFloat)] = [
            (.stuntDifficulty, ["Stunt Difficulty"], 0.14),
            (.stuntExecution, ["Stunt Execution"], 0.19),
            (.stuntDriverDegree, ["Stunt DoD", "Stunt DOD"], 0.24),
            (.stuntDriverMaxPart, ["Stunt MPD", "Stunt Max Part"], 0.29),
            (.pyramidDifficulty, ["Pyramid Difficulty"], 0.38),
            (.pyramidExecution, ["Pyramid Execution"], 0.43),
            (.tossDifficulty, ["Toss Difficulty"], 0.52),
            (.tossExecution, ["Toss Execution"], 0.57),
            (.buildingCreativity, ["Building Creativity", "Creativity"], 0.66),
            (.buildingShowmanship, ["Building Showmanship", "Showmanship"], 0.71),
        ]

        for (fieldID, aliases, y) in buildingRows {
            let (labelRegion, valueRegion) = row(y, labelX: buildingLabelX, valueX: buildingValueX)
            append(fieldID, aliases: aliases, labelRegion: labelRegion, valueRegion: valueRegion)
        }

        let tumblingRows: [(ScoresheetFieldID, [String], CGFloat)] = [
            (.standingDifficulty, ["Standing Difficulty"], 0.14),
            (.standingExecution, ["Standing Execution"], 0.19),
            (.standingDrivers, ["Standing Drivers"], 0.24),
            (.runningDifficulty, ["Running Difficulty"], 0.34),
            (.runningExecution, ["Running Execution"], 0.39),
            (.runningDrivers, ["Running Drivers"], 0.44),
            (.runningDriverMaxPart, ["Running Max Part", "Running MPD"], 0.49),
            (.jumpsDifficulty, ["Jumps Difficulty"], 0.59),
            (.jumpsExecution, ["Jumps Execution"], 0.64),
            (.tumblingCreativity, ["Tumbling Creativity", "Creativity"], 0.73),
            (.tumblingShowmanship, ["Tumbling Showmanship", "Showmanship"], 0.78),
        ]

        for (fieldID, aliases, y) in tumblingRows {
            let (labelRegion, valueRegion) = row(y, labelX: tumblingLabelX, valueX: tumblingValueX)
            append(fieldID, aliases: aliases, labelRegion: labelRegion, valueRegion: valueRegion)
        }

        let overallRows: [(ScoresheetFieldID, [String], CGFloat)] = [
            (.danceDifficulty, ["Dance Difficulty"], 0.16),
            (.danceExecution, ["Dance Execution"], 0.26),
            (.formations, ["Formations"], 0.36),
            (.overallCreativity, ["Overall Creativity", "Creativity"], 0.52),
            (.overallShowmanship, ["Overall Showmanship", "Showmanship"], 0.62),
        ]

        for (fieldID, aliases, y) in overallRows {
            let (labelRegion, valueRegion) = row(y, labelX: overallLabelX, valueX: overallValueX)
            append(fieldID, aliases: aliases, labelRegion: labelRegion, valueRegion: valueRegion)
        }

        let deductionRows: [(ScoresheetFieldID, [String], CGFloat)] = [
            (.athleteFalls, ["Athlete Fall", "Athlete Falls"], 0.74),
            (.majorAthleteFalls, ["Major Athlete Fall", "Major Athlete Falls"], 0.775),
            (.buildingBobbles, ["Building Bobble", "Building Bobbles"], 0.81),
            (.buildingFalls, ["Building Fall", "Building Falls"], 0.845),
            (.majorBuildingFalls, ["Major Building Fall", "Major Building Falls"], 0.88),
            (.boundaryViolations, ["Boundary Violation", "Boundary Violations"], 0.915),
            (.timeLimitViolations, ["Time Limit Violation", "Time Limit Violations"], 0.95),
        ]

        for (fieldID, aliases, y) in deductionRows {
            append(
                fieldID,
                aliases: aliases,
                labelRegion: CGRect(x: 0.08, y: y, width: 0.38, height: rowHeight),
                valueRegion: CGRect(x: 0.79, y: y, width: 0.08, height: rowHeight)
            )
        }

        return definitions
    }
}

private struct PreparedImportDocument {
    let draftID: UUID
    let sourceType: ScoresheetImportSourceType
    let sourceDisplayName: String
    let sourceRelativePath: String
    let previewRelativePath: String
    let previewCGImage: CGImage
}

private struct ParsedValueCandidate: Equatable {
    let value: ScoresheetFieldValue
    let wasCorrected: Bool
    let isAmbiguous: Bool
    let failureReason: String?
}

private struct FieldCandidate: Equatable {
    let value: ScoresheetFieldValue
    let rawText: String
    let sourceRect: CGRect?
    let wasCorrected: Bool
    let isAmbiguous: Bool
    let failureReason: String?
    let compositeScore: Double
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    func scaled(to size: CGSize) -> CGRect {
        CGRect(
            x: origin.x * size.width,
            y: origin.y * size.height,
            width: size.width * width,
            height: size.height * height
        )
    }

    func contains(_ point: CGPoint) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }
}

private extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

private extension String {
    var normalizedForMatching: String {
        lowercased()
            .replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func matches(for pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let matchRange = Range(match.range, in: self) else { return nil }
            return String(self[matchRange])
        }
    }

    func numericLikeMatches(for pattern: String) -> [String] {
        matches(for: pattern).map { match in
            match
                .replacingOccurrences(of: ",", with: ".")
                .replacingOccurrences(of: "O", with: "0")
                .replacingOccurrences(of: "o", with: "0")
                .replacingOccurrences(of: "l", with: "1")
                .replacingOccurrences(of: "I", with: "1")
        }
    }
}

private extension Array where Element == ParsedValueCandidate {
    func uniqued() -> [ParsedValueCandidate] {
        var seen: [ScoresheetFieldValue: ParsedValueCandidate] = [:]
        for candidate in self {
            if let existing = seen[candidate.value] {
                let preferredCandidate =
                    existing.wasCorrected && !candidate.wasCorrected ? candidate : existing
                let mergedFailureReason = preferredCandidate.failureReason
                    ?? existing.failureReason
                    ?? candidate.failureReason
                seen[candidate.value] = ParsedValueCandidate(
                    value: preferredCandidate.value,
                    wasCorrected: preferredCandidate.wasCorrected,
                    isAmbiguous: existing.isAmbiguous || candidate.isAmbiguous,
                    failureReason: mergedFailureReason
                )
            } else {
                seen[candidate.value] = candidate
            }
        }
        return Array(seen.values)
    }
}

private extension Double {
    func roundedToStepPrecision(_ step: Double) -> Double {
        let decimals: Int
        switch step {
        case 0.01:
            decimals = 2
        case 0.1:
            decimals = 1
        case 0.5:
            decimals = 1
        default:
            decimals = 2
        }

        let multiplier = pow(10.0, Double(decimals))
        return (self * multiplier).rounded() / multiplier
    }
}

private extension ScoringRules.ScoreRange {
    func contains(_ value: Double) -> Bool {
        value >= min - 0.0001 && value <= max + 0.0001
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = scale

        return UIGraphicsImageRenderer(size: size, format: rendererFormat).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
