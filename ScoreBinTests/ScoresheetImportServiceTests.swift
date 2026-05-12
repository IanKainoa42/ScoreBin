import PDFKit
import UIKit
import XCTest

@testable import ScoreBin

final class ScoresheetImportServiceTests: XCTestCase {
    func testImportCleanImageProducesResolvedDraft() async throws {
        let values = SampleScoresheetValues.standard.values
        let observations = StubObservationFactory.makeObservations(values: values, confidence: 0.98)
        let service = ScoresheetImportService(textRecognizer: StubTextRecognizer(observations: observations))
        let imageData = try FixtureDocumentFactory.cleanImageData(values: values)

        let draft = try await service.importScoresheet(
            from: .image(
                data: imageData,
                sourceType: .photoLibrary,
                suggestedFileName: "clean-sheet.jpg",
                utType: .jpeg
            ),
            context: makeContext(level: "L3")
        )

        XCTAssertFalse(
            draft.hasUnresolvedFields,
            "Unresolved fields: \(draft.unresolvedFieldIDs.map(\.rawValue))"
        )
        XCTAssertEqual(draft.parsedFields[.stuntDifficulty]?.candidateValue, .score(3.5))
        XCTAssertEqual(draft.parsedFields[.runningDriverMaxPart]?.candidateValue, .score(0.3))
        XCTAssertEqual(draft.parsedFields[.overallShowmanship]?.candidateValue, .score(1.82))
        XCTAssertEqual(draft.parsedFields[.boundaryViolations]?.candidateValue, .deduction(1))
        XCTAssertEqual(draft.sourceType, .photoLibrary)
        XCTAssertFalse(draft.sourceRelativePath.isEmpty)
        XCTAssertFalse(draft.previewRelativePath.isEmpty)
    }

    func testImportSinglePagePDFProducesResolvedDraft() async throws {
        let values = SampleScoresheetValues.standard.values
        let observations = StubObservationFactory.makeObservations(values: values, confidence: 0.95)
        let service = ScoresheetImportService(textRecognizer: StubTextRecognizer(observations: observations))
        let pdfURL = try FixtureDocumentFactory.singlePagePDF(values: values)

        let draft = try await service.importScoresheet(
            from: .pdf(url: pdfURL),
            context: makeContext(level: "L4")
        )

        XCTAssertFalse(
            draft.hasUnresolvedFields,
            "Unresolved fields: \(draft.unresolvedFieldIDs.map(\.rawValue))"
        )
        XCTAssertEqual(draft.sourceType, .pdf)
        XCTAssertEqual(draft.parsedFields[.majorBuildingFalls]?.candidateValue, .deduction(1))
    }

    func testLowConfidenceImageRequiresReview() async throws {
        let values = SampleScoresheetValues.standard.values
        let observations = StubObservationFactory.makeObservations(values: values, confidence: 0.58)
        let service = ScoresheetImportService(textRecognizer: StubTextRecognizer(observations: observations))
        let imageData = try FixtureDocumentFactory.lowLightImageData(values: values)

        let draft = try await service.importScoresheet(
            from: .image(
                data: imageData,
                sourceType: .cameraScan,
                suggestedFileName: "low-light.jpg",
                utType: .jpeg
            ),
            context: makeContext(level: "L5")
        )

        XCTAssertTrue(draft.hasUnresolvedFields)
        XCTAssertTrue(draft.unresolvedFieldIDs.contains(.stuntDifficulty))
    }

    func testMissingFieldIsMarkedForReview() {
        let observations = StubObservationFactory.makeObservations(
            values: SampleScoresheetValues.standard.values.filter { $0.key != .danceExecution },
            confidence: 0.96
        )
        let service = ScoresheetImportService()

        let parsed = service.parseRecognizedFields(observations, context: makeContext(level: "L3"))

        XCTAssertEqual(parsed[.danceExecution]?.status, .needsReview)
        XCTAssertNil(
            parsed[.danceExecution]?.candidateValue,
            "Parsed danceExecution: \(String(describing: parsed[.danceExecution]))"
        )
    }

    func testAmbiguousNumericCandidateNeedsReview() {
        let service = ScoresheetImportService()
        let observations = StubObservationFactory.makeObservations(values: SampleScoresheetValues.standard.values, confidence: 0.96)
            + [
                RecognizedTextObservation(
                    text: "3.9 3.8",
                    confidence: 0.96,
                    boundingBox: region(for: .stuntExecution).valueRegion
                )
            ]

        let parsed = service.parseRecognizedFields(observations, context: makeContext(level: "L3"))

        XCTAssertEqual(parsed[.stuntExecution]?.status, .needsReview)
        XCTAssertNotNil(parsed[.stuntExecution]?.failureReason)
    }

    func testOutOfRangeValueIsSnappedAndFlagged() {
        let service = ScoresheetImportService()
        var observations = StubObservationFactory.makeObservations(values: SampleScoresheetValues.standard.values, confidence: 0.96)
        observations.removeAll { $0.boundingBox == region(for: .stuntDifficulty).valueRegion }
        observations.append(
            RecognizedTextObservation(
                text: "39",
                confidence: 0.96,
                boundingBox: region(for: .stuntDifficulty).valueRegion
            )
        )

        let parsed = service.parseRecognizedFields(observations, context: makeContext(level: "L3"))

        XCTAssertEqual(
            parsed[.stuntDifficulty]?.candidateValue,
            .score(4.0),
            "Parsed stuntDifficulty: \(String(describing: parsed[.stuntDifficulty]))"
        )
        XCTAssertEqual(parsed[.stuntDifficulty]?.status, .needsReview)
    }

    func testLevelOneSuppressesTossFields() {
        let service = ScoresheetImportService()
        let observations = StubObservationFactory.makeObservations(values: SampleScoresheetValues.standard.values, confidence: 0.96)

        let parsed = service.parseRecognizedFields(observations, context: makeContext(level: "L1"))

        XCTAssertEqual(parsed[.tossDifficulty]?.candidateValue, .score(0))
        XCTAssertEqual(parsed[.tossExecution]?.candidateValue, .score(0))
        XCTAssertEqual(parsed[.tossDifficulty]?.status, .accepted)
        XCTAssertEqual(parsed[.tossExecution]?.status, .accepted)
    }

    func testConfirmingReviewFieldsClearsDraftState() async throws {
        let values = SampleScoresheetValues.standard.values
        let observations = StubObservationFactory.makeObservations(values: values, confidence: 0.6)
        let service = ScoresheetImportService(textRecognizer: StubTextRecognizer(observations: observations))
        let imageData = try FixtureDocumentFactory.cleanImageData(values: values)

        var draft = try await service.importScoresheet(
            from: .image(
                data: imageData,
                sourceType: .photoLibrary,
                suggestedFileName: "review.jpg",
                utType: .jpeg
            ),
            context: makeContext(level: "L4")
        )

        XCTAssertTrue(draft.hasUnresolvedFields)
        for fieldID in draft.unresolvedFieldIDs {
            if draft.parsedField(for: fieldID).candidateValue != nil {
                draft.confirmSuggestedValue(for: fieldID)
            }
        }

        XCTAssertFalse(draft.hasUnresolvedFields)
    }

    private func makeContext(level: String) -> ScoresheetImportContext {
        ScoresheetImportContext(
            teamID: UUID(),
            competitionID: UUID(),
            round: RoundType.day1.rawValue,
            teamLevel: level
        )
    }
}

private struct StubTextRecognizer: ScoresheetTextRecognizing {
    let observations: [RecognizedTextObservation]

    func recognizeText(in cgImage: CGImage) async throws -> [RecognizedTextObservation] {
        observations
    }
}

private struct SampleScoresheetValues {
    static let standard = SampleScoresheetValues.make()

    let values: [ScoresheetFieldID: ScoresheetFieldValue]

    static func make() -> SampleScoresheetValues {
        SampleScoresheetValues(
            values: [
                .stuntDifficulty: .score(3.5),
                .stuntExecution: .score(3.8),
                .stuntDriverDegree: .score(0.4),
                .stuntDriverMaxPart: .score(0.3),
                .pyramidDifficulty: .score(3.2),
                .pyramidExecution: .score(3.7),
                .tossDifficulty: .score(1.5),
                .tossExecution: .score(1.6),
                .buildingCreativity: .score(1.92),
                .buildingShowmanship: .score(1.84),
                .standingDifficulty: .score(2.5),
                .standingExecution: .score(3.7),
                .standingDrivers: .score(0.5),
                .runningDifficulty: .score(2.5),
                .runningExecution: .score(3.6),
                .runningDrivers: .score(0.2),
                .runningDriverMaxPart: .score(0.3),
                .jumpsDifficulty: .score(1.5),
                .jumpsExecution: .score(1.7),
                .tumblingCreativity: .score(1.9),
                .tumblingShowmanship: .score(1.81),
                .danceDifficulty: .score(0.9),
                .danceExecution: .score(0.8),
                .formations: .score(1.7),
                .overallCreativity: .score(1.88),
                .overallShowmanship: .score(1.82),
                .athleteFalls: .deduction(0),
                .majorAthleteFalls: .deduction(0),
                .buildingBobbles: .deduction(2),
                .buildingFalls: .deduction(0),
                .majorBuildingFalls: .deduction(1),
                .boundaryViolations: .deduction(1),
                .timeLimitViolations: .deduction(0),
            ]
        )
    }
}

private enum StubObservationFactory {
    static func makeObservations(
        values: [ScoresheetFieldID: ScoresheetFieldValue],
        confidence: Double
    ) -> [RecognizedTextObservation] {
        ScoresheetImportService.fieldDefinitions.flatMap { definition in
            var fieldObservations: [RecognizedTextObservation] = [
                RecognizedTextObservation(
                    text: definition.aliases.first ?? definition.fieldID.title,
                    confidence: confidence,
                    boundingBox: definition.labelRegion
                )
            ]

            if let value = values[definition.fieldID] {
                fieldObservations.append(
                    RecognizedTextObservation(
                        text: value.displayString,
                        confidence: confidence,
                        boundingBox: definition.valueRegion
                    )
                )
            }

            return fieldObservations
        }
    }
}

private enum FixtureDocumentFactory {
    static func cleanImageData(values: [ScoresheetFieldID: ScoresheetFieldValue]) throws -> Data {
        guard let jpegData = makeImage(values: values).jpegData(compressionQuality: 0.95) else {
            throw ScoresheetImportError.previewGenerationFailed
        }
        return jpegData
    }

    static func lowLightImageData(values: [ScoresheetFieldID: ScoresheetFieldValue]) throws -> Data {
        let image = makeImage(values: values, backgroundColor: .darkGray, textColor: .white)
        guard let jpegData = image.jpegData(compressionQuality: 0.75) else {
            throw ScoresheetImportError.previewGenerationFailed
        }
        return jpegData
    }

    static func singlePagePDF(values: [ScoresheetFieldID: ScoresheetFieldValue]) throws -> URL {
        let image = makeImage(values: values)
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString + ".pdf"
        )

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: ScoresheetImportService.previewCanvasSize)
        )
        try renderer.writePDF(to: temporaryURL) { context in
            context.beginPage()
            image.draw(
                in: CGRect(origin: .zero, size: ScoresheetImportService.previewCanvasSize)
            )
        }

        return temporaryURL
    }

    private static func makeImage(
        values: [ScoresheetFieldID: ScoresheetFieldValue],
        backgroundColor: UIColor = .white,
        textColor: UIColor = .black
    ) -> UIImage {
        let size = ScoresheetImportService.previewCanvasSize
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 34),
                .foregroundColor: textColor,
            ]
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: textColor,
            ]
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .semibold),
                .foregroundColor: textColor,
            ]

            NSString(string: "BUILDING").draw(
                at: CGPoint(x: 90, y: 70),
                withAttributes: sectionAttributes
            )
            NSString(string: "TUMBLING").draw(
                at: CGPoint(x: 670, y: 70),
                withAttributes: sectionAttributes
            )
            NSString(string: "OVERALL").draw(
                at: CGPoint(x: 1260, y: 70),
                withAttributes: sectionAttributes
            )
            NSString(string: "DEDUCTIONS").draw(
                at: CGPoint(x: 90, y: 1660),
                withAttributes: sectionAttributes
            )

            for definition in ScoresheetImportService.fieldDefinitions {
                let labelRect = definition.labelRect(in: size)
                let valueRect = definition.valueRect(in: size)

                NSString(string: definition.aliases.first ?? definition.fieldID.title).draw(
                    in: labelRect,
                    withAttributes: rowAttributes
                )

                if let value = values[definition.fieldID] {
                    NSString(string: value.displayString).draw(
                        in: valueRect,
                        withAttributes: valueAttributes
                    )
                }
            }
        }
    }
}

private func region(for fieldID: ScoresheetFieldID) -> ScoresheetFieldDefinition {
    guard let definition = ScoresheetImportService.fieldDefinitions.first(where: { $0.fieldID == fieldID }) else {
        fatalError("Missing field definition for \(fieldID.rawValue)")
    }
    return definition
}
