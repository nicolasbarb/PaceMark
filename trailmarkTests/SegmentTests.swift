import Foundation
import Testing
@testable import trailmark

@MainActor
struct SegmentTests {

    // MARK: - Test Helpers

    private static func makeTrackPoints(elevations: [Double], spacing: Double = 100) -> [TrackPoint] {
        elevations.enumerated().map { index, elev in
            TrackPoint(
                id: Int64(index + 1),
                trailId: 1,
                index: index,
                latitude: 45.0 + Double(index) * 0.001,
                longitude: 5.0,
                elevation: elev,
                distance: Double(index) * spacing
            )
        }
    }

    // MARK: - SegmentType

    @Test
    func segmentType_milestoneTypeMapping() {
        #expect(SegmentType.climbing.milestoneType == .montee)
        #expect(SegmentType.descending.milestoneType == .descente)
        #expect(SegmentType.flat.milestoneType == .plat)
    }

    // MARK: - SegmentStats

    @Test
    func computeStats_climbing() {
        let trackPoints = Self.makeTrackPoints(elevations: [100, 120, 150, 180, 200])
        let segment = Segment(
            trailId: 1,
            type: SegmentType.climbing.rawValue,
            startIndex: 0,
            endIndex: 4,
            startDistance: 0,
            endDistance: 400
        )

        let stats = Segment.computeStats(segment: segment, trackPoints: trackPoints)

        #expect(stats.distance == 400)
        #expect(stats.elevationGain == 100)
        #expect(stats.elevationLoss == 0)
        #expect(stats.averageSlope == 0.25)
    }

    @Test
    func computeStats_undulating() {
        let trackPoints = Self.makeTrackPoints(elevations: [100, 150, 130, 170, 160])
        let segment = Segment(
            trailId: 1,
            type: SegmentType.climbing.rawValue,
            startIndex: 0,
            endIndex: 4,
            startDistance: 0,
            endDistance: 400
        )

        let stats = Segment.computeStats(segment: segment, trackPoints: trackPoints)

        #expect(stats.elevationGain == 90)
        #expect(stats.elevationLoss == 30)
        #expect(stats.averageSlope == 0.15)
    }

    // MARK: - findSegment

    @Test
    func findSegment_containingPoint() {
        let segments = [
            Segment(id: 1, trailId: 1, type: "climbing", startIndex: 10, endIndex: 30, startDistance: 1000, endDistance: 3000),
            Segment(id: 2, trailId: 1, type: "descending", startIndex: 50, endIndex: 70, startDistance: 5000, endDistance: 7000),
        ]

        let found = Segment.findSegment(containing: 20, in: segments)
        #expect(found?.id == 1)

        let notFound = Segment.findSegment(containing: 40, in: segments)
        #expect(notFound == nil)

        let atBoundary = Segment.findSegment(containing: 10, in: segments)
        #expect(atBoundary?.id == 1)
    }

    // MARK: - Overlap Validation

    @Test
    func overlaps_detectsOverlap() {
        let existing = Segment(id: 1, trailId: 1, type: "climbing", startIndex: 10, endIndex: 30, startDistance: 1000, endDistance: 3000)
        let overlapping = Segment(trailId: 1, type: "descending", startIndex: 20, endIndex: 40, startDistance: 2000, endDistance: 4000)
        let notOverlapping = Segment(trailId: 1, type: "flat", startIndex: 35, endIndex: 50, startDistance: 3500, endDistance: 5000)

        #expect(Segment.overlaps(overlapping, with: [existing]))
        #expect(!Segment.overlaps(notOverlapping, with: [existing]))
    }
}