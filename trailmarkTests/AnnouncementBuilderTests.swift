import Foundation
import Testing
@testable import trailmark

struct AnnouncementBuilderTests {

    // MARK: - Montée

    @Test
    func montee_generatesCorrectMessage() throws {
        let stats = SegmentStats(
            distance: 1800,
            elevationGain: 215,
            elevationLoss: 0,
            averageSlope: 0.12
        )

        let result = AnnouncementBuilder.build(
            type: .montee,
            name: nil,
            segmentStats: stats
        )

        let message = try #require(result)
        #expect(message.contains("Montée"))
        #expect(message.contains("1 virgule 8 kilomètres"))
        #expect(message.contains("12 pourcent"))
        #expect(message.contains("215 mètres de dénivelé positif"))
    }

    @Test
    func montee_withName_includesName() throws {
        let stats = SegmentStats(
            distance: 2000,
            elevationGain: 300,
            elevationLoss: 0,
            averageSlope: 0.15
        )

        let result = AnnouncementBuilder.build(
            type: .montee,
            name: "Col de la Croix",
            segmentStats: stats
        )

        let message = try #require(result)
        #expect(message.contains("Col de la Croix"))
    }

    // MARK: - Descente

    @Test
    func descente_generatesCorrectMessage() throws {
        let stats = SegmentStats(
            distance: 2500,
            elevationGain: 0,
            elevationLoss: 350,
            averageSlope: -0.14
        )

        let result = AnnouncementBuilder.build(
            type: .descente,
            name: nil,
            segmentStats: stats
        )

        let message = try #require(result)
        #expect(message.contains("Descente"))
        #expect(message.contains("2 virgule 5 kilomètres"))
        #expect(message.contains("14 pourcent"))
        #expect(message.contains("350 mètres de dénivelé négatif"))
    }

    // MARK: - Distance formatting

    @Test
    func shortDistance_formattedInMeters() throws {
        let stats = SegmentStats(
            distance: 800,
            elevationGain: 80,
            elevationLoss: 0,
            averageSlope: 0.10
        )

        let result = AnnouncementBuilder.build(
            type: .montee,
            name: nil,
            segmentStats: stats
        )

        let message = try #require(result)
        #expect(message.contains("800 mètres"))
        #expect(!message.contains("kilomètres"))
    }

    @Test
    func wholeKilometer_noDecimal() throws {
        let stats = SegmentStats(
            distance: 3000,
            elevationGain: 300,
            elevationLoss: 0,
            averageSlope: 0.10
        )

        let result = AnnouncementBuilder.build(
            type: .montee,
            name: nil,
            segmentStats: stats
        )

        let message = try #require(result)
        #expect(message.contains("3 kilomètres"))
        #expect(!message.contains("virgule"))
    }

    // MARK: - Non-climb/descent types return nil

    @Test
    func nonClimbDescentType_returnsNil() {
        let stats = SegmentStats(
            distance: 2000,
            elevationGain: 10,
            elevationLoss: 5,
            averageSlope: 0.005
        )

        let result = AnnouncementBuilder.build(
            type: .plat,
            name: nil,
            segmentStats: stats
        )

        #expect(result == nil)
    }

    @Test
    func ravito_returnsNil() {
        let stats = SegmentStats(
            distance: 2000,
            elevationGain: 200,
            elevationLoss: 0,
            averageSlope: 0.10
        )

        let result = AnnouncementBuilder.build(
            type: .ravito,
            name: nil,
            segmentStats: stats
        )

        #expect(result == nil)
    }

    // MARK: - Nil stats

    @Test
    func nilStats_returnsNil() {
        let result = AnnouncementBuilder.build(
            type: .montee,
            name: nil,
            segmentStats: nil
        )

        #expect(result == nil)
    }
}
