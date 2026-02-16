@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

final class ADASAttributesTests: XCTestCase {
    // MARK: - Test Fixtures

    let testEdgeIdentifier: RoadGraph.Edge.Identifier = 12345

    // MARK: - SpeedLimitInfo Tests

    func testSpeedLimitInfoInitialization() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let nativeSpeedLimit = SpeedLimitInfo(
            value: 60,
            unit: .kilometresPerHour,
            type: .explicit,
            restriction: nativeRestriction
        )

        let speedLimitInfo = RoadGraph.Edge.SpeedLimitInfo(nativeSpeedLimit)

        XCTAssertEqual(speedLimitInfo.speedLimit.value, 60)
        XCTAssertEqual(speedLimitInfo.speedLimit.unit, .kilometersPerHour)
        XCTAssertEqual(speedLimitInfo.kind, .explicit)
        XCTAssertNotNil(speedLimitInfo.restriction)
    }

    func testSpeedLimitInfoWithMilesPerHour() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let nativeSpeedLimit = SpeedLimitInfo(
            value: 55,
            unit: .milesPerHour,
            type: .implicit,
            restriction: nativeRestriction
        )

        let speedLimitInfo = RoadGraph.Edge.SpeedLimitInfo(nativeSpeedLimit)

        XCTAssertEqual(speedLimitInfo.speedLimit.value, 55)
        XCTAssertEqual(speedLimitInfo.speedLimit.unit, .milesPerHour)
        XCTAssertEqual(speedLimitInfo.kind, .implicit)
    }

    // MARK: - SpeedLimitInfo.Kind Tests

    func testSpeedLimitKindImplicit() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let nativeSpeedLimit = SpeedLimitInfo(
            value: 50,
            unit: .kilometresPerHour,
            type: .implicit,
            restriction: nativeRestriction
        )

        let speedLimitInfo = RoadGraph.Edge.SpeedLimitInfo(nativeSpeedLimit)
        XCTAssertEqual(speedLimitInfo.kind, .implicit)
    }

    func testSpeedLimitKindExplicit() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let nativeSpeedLimit = SpeedLimitInfo(
            value: 50,
            unit: .kilometresPerHour,
            type: .explicit,
            restriction: nativeRestriction
        )

        let speedLimitInfo = RoadGraph.Edge.SpeedLimitInfo(nativeSpeedLimit)
        XCTAssertEqual(speedLimitInfo.kind, .explicit)
    }

    func testSpeedLimitKindUnknown() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let nativeSpeedLimit = SpeedLimitInfo(
            value: 50,
            unit: .kilometresPerHour,
            type: .unknown,
            restriction: nativeRestriction
        )

        let speedLimitInfo = RoadGraph.Edge.SpeedLimitInfo(nativeSpeedLimit)
        XCTAssertEqual(speedLimitInfo.kind, .unknown)
    }

    func testSpeedLimitKindProlonged() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let nativeSpeedLimit = SpeedLimitInfo(
            value: 50,
            unit: .kilometresPerHour,
            type: .prolonged,
            restriction: nativeRestriction
        )

        let speedLimitInfo = RoadGraph.Edge.SpeedLimitInfo(nativeSpeedLimit)
        XCTAssertEqual(speedLimitInfo.kind, .prolonged)
    }

    // MARK: - SpeedLimitInfo.Restriction Tests

    func testSpeedLimitRestrictionEmpty() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let restriction = RoadGraph.Edge.SpeedLimitInfo.Restriction(nativeRestriction)

        XCTAssertTrue(restriction.weather.isEmpty)
        XCTAssertEqual(restriction.timeCondition, "")
        XCTAssertTrue(restriction.vehicleTypes.isEmpty)
        XCTAssertTrue(restriction.lanes.isEmpty)
    }

    func testSpeedLimitRestrictionWithWeather() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [NSNumber(value: 0), NSNumber(value: 1)], // rain, snow
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let restriction = RoadGraph.Edge.SpeedLimitInfo.Restriction(nativeRestriction)

        XCTAssertEqual(restriction.weather.count, 2)
        XCTAssertEqual(restriction.weather[0], .rain)
        XCTAssertEqual(restriction.weather[1], .snow)
    }

    func testSpeedLimitRestrictionWithTimeCondition() {
        let timeCondition = "Mo-Fr 06:00-20:00"
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: timeCondition,
            vehicleTypes: [],
            lanes: []
        )

        let restriction = RoadGraph.Edge.SpeedLimitInfo.Restriction(nativeRestriction)

        XCTAssertEqual(restriction.timeCondition, timeCondition)
    }

    func testSpeedLimitRestrictionWithVehicleTypes() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [NSNumber(value: 0), NSNumber(value: 1)], // car, truck
            lanes: []
        )

        let restriction = RoadGraph.Edge.SpeedLimitInfo.Restriction(nativeRestriction)

        XCTAssertEqual(restriction.vehicleTypes.count, 2)
        XCTAssertEqual(restriction.vehicleTypes[0], .car)
        XCTAssertEqual(restriction.vehicleTypes[1], .truck)
    }

    func testSpeedLimitRestrictionWithLanes() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: [NSNumber(value: 1), NSNumber(value: 2), NSNumber(value: 3)]
        )

        let restriction = RoadGraph.Edge.SpeedLimitInfo.Restriction(nativeRestriction)

        XCTAssertEqual(restriction.lanes, [1, 2, 3])
    }

    func testSpeedLimitRestrictionWithAllConditions() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [NSNumber(value: 3)], // wetRoad
            dateTimeCondition: "Mo-Su 00:00-24:00",
            vehicleTypes: [NSNumber(value: 2)], // bus
            lanes: [NSNumber(value: 2)]
        )

        let restriction = RoadGraph.Edge.SpeedLimitInfo.Restriction(nativeRestriction)

        XCTAssertEqual(restriction.weather.count, 1)
        XCTAssertEqual(restriction.weather[0], .wetRoad)
        XCTAssertEqual(restriction.timeCondition, "Mo-Su 00:00-24:00")
        XCTAssertEqual(restriction.vehicleTypes.count, 1)
        XCTAssertEqual(restriction.vehicleTypes[0], .bus)
        XCTAssertEqual(restriction.lanes, [2])
    }

    // MARK: - Weather Tests

    func testWeatherTypes() {
        XCTAssertEqual(RoadGraph.Edge.Weather(0), .rain)
        XCTAssertEqual(RoadGraph.Edge.Weather(1), .snow)
        XCTAssertEqual(RoadGraph.Edge.Weather(2), .fog)
        XCTAssertEqual(RoadGraph.Edge.Weather(3), .wetRoad)
    }

    // MARK: - VehicleType Tests

    func testVehicleTypes() {
        XCTAssertEqual(RoadGraph.Edge.VehicleType(0), .car)
        XCTAssertEqual(RoadGraph.Edge.VehicleType(1), .truck)
        XCTAssertEqual(RoadGraph.Edge.VehicleType(2), .bus)
        XCTAssertEqual(RoadGraph.Edge.VehicleType(3), .trailer)
        XCTAssertEqual(RoadGraph.Edge.VehicleType(4), .motorcycle)
    }

    // MARK: - ValueOnEdge Tests

    func testValueOnEdgeInitialization() {
        let nativeValue = ValueOnEdge(
            shapeIndex: 3.5,
            percentAlong: 0.35,
            value: 5.2
        )

        let valueOnEdge = RoadGraph.Edge.ValueOnEdge<Double>(
            nativeValue,
            edgeIdentifier: testEdgeIdentifier
        )

        XCTAssertEqual(valueOnEdge.edgeShapeIndex, 3.5)
        XCTAssertEqual(valueOnEdge.value, 5.2)
        XCTAssertEqual(valueOnEdge.position.edgeIdentifier, testEdgeIdentifier)
        XCTAssertEqual(valueOnEdge.position.fractionFromStart, 0.35)
    }

    func testValueOnEdgeWithZeroIndex() {
        let nativeValue = ValueOnEdge(
            shapeIndex: 0.0,
            percentAlong: 0.0,
            value: 10.5
        )

        let valueOnEdge = RoadGraph.Edge.ValueOnEdge<Double>(
            nativeValue,
            edgeIdentifier: testEdgeIdentifier
        )

        XCTAssertEqual(valueOnEdge.edgeShapeIndex, 0.0)
        XCTAssertEqual(valueOnEdge.value, 10.5)
        XCTAssertEqual(valueOnEdge.position.fractionFromStart, 0.0)
    }

    func testValueOnEdgeAtEndOfEdge() {
        let nativeValue = ValueOnEdge(
            shapeIndex: 10.0,
            percentAlong: 1.0,
            value: -3.2
        )

        let valueOnEdge = RoadGraph.Edge.ValueOnEdge<Double>(
            nativeValue,
            edgeIdentifier: testEdgeIdentifier
        )

        XCTAssertEqual(valueOnEdge.edgeShapeIndex, 10.0)
        XCTAssertEqual(valueOnEdge.value, -3.2)
        XCTAssertEqual(valueOnEdge.position.fractionFromStart, 1.0)
    }

    // MARK: - FormOfWay Tests

    func testFormOfWayTypes() {
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(0), .unknown)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(1), .freeway)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(2), .multipleCarriageway)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(3), .singleCarriageway)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(4), .roundaboutCircle)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(5), .trafficSquare)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(6), .slipRoad)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(7), .reserved)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(8), .parallelRoad)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(9), .rampOnFreeway)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(10), .ramp)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(11), .serviceRoad)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(12), .carParkEntrance)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(13), .serviceEntrance)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(14), .pedestrianZone)
        XCTAssertEqual(RoadGraph.Edge.FormOfWay(15), .NA)
    }

    // MARK: - ETC2RoadType Tests

    func testETC2RoadTypeUnknown() {
        let etc2Type = RoadGraph.Edge.ETC2RoadType(.unknown)
        XCTAssertEqual(etc2Type, .unknown)
    }

    func testETC2RoadTypeHighway() {
        let etc2Type = RoadGraph.Edge.ETC2RoadType(.highway)
        XCTAssertEqual(etc2Type, .highway)
    }

    func testETC2RoadTypeCityHighway() {
        let etc2Type = RoadGraph.Edge.ETC2RoadType(.cityHighway)
        XCTAssertEqual(etc2Type, .cityHighway)
    }

    func testETC2RoadTypeNormalRoad() {
        let etc2Type = RoadGraph.Edge.ETC2RoadType(.normalRoad)
        XCTAssertEqual(etc2Type, .normalRoad)
    }

    func testETC2RoadTypeOther() {
        let etc2Type = RoadGraph.Edge.ETC2RoadType(.other)
        XCTAssertEqual(etc2Type, .other)
    }

    // MARK: - RoadItem Tests

    func testRoadItemInitialization() {
        let nativeRoadItem = RoadItem(
            type: .speedLimitSign,
            location: NSNumber(value: 0), // right
            lanes: [],
            value: NSNumber(value: 50)
        )

        let roadItem = RoadGraph.Edge.RoadItem(nativeRoadItem)

        XCTAssertEqual(roadItem.kind, .speedLimitSign)
        XCTAssertNotNil(roadItem.location)
        XCTAssertEqual(roadItem.location, .right)
        XCTAssertTrue(roadItem.lanes.isEmpty)
        XCTAssertEqual(roadItem.value, 50)
    }

    func testRoadItemWithoutLocation() {
        let nativeRoadItem = RoadItem(
            type: .trafficLight,
            location: nil,
            lanes: [],
            value: nil
        )

        let roadItem = RoadGraph.Edge.RoadItem(nativeRoadItem)

        XCTAssertEqual(roadItem.kind, .trafficLight)
        XCTAssertNil(roadItem.location)
        XCTAssertTrue(roadItem.lanes.isEmpty)
        XCTAssertNil(roadItem.value)
    }

    func testRoadItemWithLanes() {
        let nativeRoadItem = RoadItem(
            type: .roadCamSpeedCurrentSpeed,
            location: NSNumber(value: 4), // aboveLane
            lanes: [NSNumber(value: 1), NSNumber(value: 2)],
            value: NSNumber(value: 80)
        )

        let roadItem = RoadGraph.Edge.RoadItem(nativeRoadItem)

        XCTAssertEqual(roadItem.kind, .roadCamSpeedCurrentSpeed)
        XCTAssertEqual(roadItem.location, .aboveLane)
        XCTAssertEqual(roadItem.lanes, [1, 2])
        XCTAssertEqual(roadItem.value, 80)
    }

    func testRoadItemLocationTypes() {
        XCTAssertEqual(RoadGraph.Edge.RoadItem.Location(0), .right)
        XCTAssertEqual(RoadGraph.Edge.RoadItem.Location(1), .left)
        XCTAssertEqual(RoadGraph.Edge.RoadItem.Location(2), .above)
        XCTAssertEqual(RoadGraph.Edge.RoadItem.Location(3), .onSurface)
        XCTAssertEqual(RoadGraph.Edge.RoadItem.Location(4), .aboveLane)
    }

    // MARK: - ValueOnEdge<RoadItem> Tests

    func testValueOnEdgeRoadItemInitialization() {
        let nativeRoadItem = RoadItem(
            type: .speedBump,
            location: NSNumber(value: 3), // onSurface
            lanes: [],
            value: nil
        )

        let nativeRoadItemOnEdge = RoadItemOnEdge(
            shapeIndex: 5.0,
            percentAlong: 0.5,
            roadItem: nativeRoadItem
        )

        let valueOnEdge = RoadGraph.Edge.ValueOnEdge<RoadGraph.Edge.RoadItem>(
            nativeRoadItemOnEdge,
            edgeIdentifier: testEdgeIdentifier
        )

        XCTAssertEqual(valueOnEdge.edgeShapeIndex, 5.0)
        XCTAssertEqual(valueOnEdge.position.edgeIdentifier, testEdgeIdentifier)
        XCTAssertEqual(valueOnEdge.position.fractionFromStart, 0.5)
        XCTAssertEqual(valueOnEdge.value.kind, .speedBump)
        XCTAssertEqual(valueOnEdge.value.location, .onSurface)
    }

    // MARK: - ADASAttributes Tests

    func testADASAttributesInitializationEmpty() {
        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [],
            slopes: [],
            elevations: [],
            curvatures: [],
            isDividedRoad: nil,
            isBuiltUpArea: nil,
            formOfWay: nil,
            etc2: .unknown,
            roadItems: []
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        XCTAssertTrue(adasAttrs.speedLimit.isEmpty)
        XCTAssertTrue(adasAttrs.slopes.isEmpty)
        XCTAssertTrue(adasAttrs.elevations.isEmpty)
        XCTAssertTrue(adasAttrs.curvatures.isEmpty)
        XCTAssertNil(adasAttrs.isDividedRoad)
        XCTAssertNil(adasAttrs.isBuiltUpArea)
        XCTAssertNil(adasAttrs.formOfWay)
        XCTAssertEqual(adasAttrs.etc2, .unknown)
        XCTAssertTrue(adasAttrs.roadItems.isEmpty)
    }

    func testADASAttributesInitializationWithSpeedLimits() {
        let restriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let speedLimit1 = SpeedLimitInfo(
            value: 60,
            unit: .kilometresPerHour,
            type: .explicit,
            restriction: restriction
        )

        let speedLimit2 = SpeedLimitInfo(
            value: 80,
            unit: .kilometresPerHour,
            type: .implicit,
            restriction: restriction
        )

        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [speedLimit1, speedLimit2],
            slopes: [],
            elevations: [],
            curvatures: [],
            isDividedRoad: nil,
            isBuiltUpArea: nil,
            formOfWay: nil,
            etc2: .unknown,
            roadItems: []
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        XCTAssertEqual(adasAttrs.speedLimit.count, 2)
        XCTAssertEqual(adasAttrs.speedLimit[0].speedLimit.value, 60)
        XCTAssertEqual(adasAttrs.speedLimit[0].kind, .explicit)
        XCTAssertEqual(adasAttrs.speedLimit[1].speedLimit.value, 80)
        XCTAssertEqual(adasAttrs.speedLimit[1].kind, .implicit)
    }

    func testADASAttributesInitializationWithSlopes() {
        let slope1 = ValueOnEdge(shapeIndex: 0.0, percentAlong: 0.0, value: 3.5)
        let slope2 = ValueOnEdge(shapeIndex: 5.0, percentAlong: 0.5, value: -2.8)

        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [],
            slopes: [slope1, slope2],
            elevations: [],
            curvatures: [],
            isDividedRoad: nil,
            isBuiltUpArea: nil,
            formOfWay: nil,
            etc2: .unknown,
            roadItems: []
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        XCTAssertEqual(adasAttrs.slopes.count, 2)
        XCTAssertEqual(adasAttrs.slopes[0].value, 3.5)
        XCTAssertEqual(adasAttrs.slopes[0].edgeShapeIndex, 0.0)
        XCTAssertEqual(adasAttrs.slopes[1].value, -2.8)
        XCTAssertEqual(adasAttrs.slopes[1].edgeShapeIndex, 5.0)
    }

    func testADASAttributesInitializationWithElevations() {
        let elevation1 = ValueOnEdge(shapeIndex: 0.0, percentAlong: 0.0, value: 100.5)
        let elevation2 = ValueOnEdge(shapeIndex: 10.0, percentAlong: 1.0, value: 150.3)

        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [],
            slopes: [],
            elevations: [elevation1, elevation2],
            curvatures: [],
            isDividedRoad: nil,
            isBuiltUpArea: nil,
            formOfWay: nil,
            etc2: .unknown,
            roadItems: []
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        XCTAssertEqual(adasAttrs.elevations.count, 2)
        XCTAssertEqual(adasAttrs.elevations[0].value, 100.5)
        XCTAssertEqual(adasAttrs.elevations[1].value, 150.3)
    }

    func testADASAttributesInitializationWithCurvatures() {
        let curvature1 = ValueOnEdge(shapeIndex: 2.5, percentAlong: 0.25, value: 0.01)
        let curvature2 = ValueOnEdge(shapeIndex: 7.5, percentAlong: 0.75, value: 0.05)

        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [],
            slopes: [],
            elevations: [],
            curvatures: [curvature1, curvature2],
            isDividedRoad: nil,
            isBuiltUpArea: nil,
            formOfWay: nil,
            etc2: .unknown,
            roadItems: []
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        XCTAssertEqual(adasAttrs.curvatures.count, 2)
        XCTAssertEqual(adasAttrs.curvatures[0].value, 0.01)
        XCTAssertEqual(adasAttrs.curvatures[1].value, 0.05)
    }

    func testADASAttributesInitializationWithBooleanFlags() {
        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [],
            slopes: [],
            elevations: [],
            curvatures: [],
            isDividedRoad: NSNumber(value: true),
            isBuiltUpArea: NSNumber(value: false),
            formOfWay: nil,
            etc2: .unknown,
            roadItems: []
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        XCTAssertEqual(adasAttrs.isDividedRoad, true)
        XCTAssertEqual(adasAttrs.isBuiltUpArea, false)
    }

    func testADASAttributesInitializationWithFormOfWay() {
        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [],
            slopes: [],
            elevations: [],
            curvatures: [],
            isDividedRoad: nil,
            isBuiltUpArea: nil,
            formOfWay: NSNumber(value: 1), // freeway
            etc2: .unknown,
            roadItems: []
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        XCTAssertNotNil(adasAttrs.formOfWay)
        XCTAssertEqual(adasAttrs.formOfWay, .freeway)
    }

    func testADASAttributesInitializationWithETC2() {
        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [],
            slopes: [],
            elevations: [],
            curvatures: [],
            isDividedRoad: nil,
            isBuiltUpArea: nil,
            formOfWay: nil,
            etc2: .highway,
            roadItems: []
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        XCTAssertEqual(adasAttrs.etc2, .highway)
    }

    func testADASAttributesInitializationWithRoadItems() {
        let roadItem1 = RoadItem(
            type: .stopSign,
            location: NSNumber(value: 0),
            lanes: [],
            value: nil
        )

        let roadItem2 = RoadItem(
            type: .speedLimitSign,
            location: NSNumber(value: 1),
            lanes: [],
            value: NSNumber(value: 50)
        )

        let roadItemOnEdge1 = RoadItemOnEdge(
            shapeIndex: 2.0,
            percentAlong: 0.2,
            roadItem: roadItem1
        )

        let roadItemOnEdge2 = RoadItemOnEdge(
            shapeIndex: 8.0,
            percentAlong: 0.8,
            roadItem: roadItem2
        )

        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [],
            slopes: [],
            elevations: [],
            curvatures: [],
            isDividedRoad: nil,
            isBuiltUpArea: nil,
            formOfWay: nil,
            etc2: .unknown,
            roadItems: [roadItemOnEdge1, roadItemOnEdge2]
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        XCTAssertEqual(adasAttrs.roadItems.count, 2)
        XCTAssertEqual(adasAttrs.roadItems[0].value.kind, .stopSign)
        XCTAssertEqual(adasAttrs.roadItems[0].edgeShapeIndex, 2.0)
        XCTAssertEqual(adasAttrs.roadItems[1].value.kind, .speedLimitSign)
        XCTAssertEqual(adasAttrs.roadItems[1].value.value, 50)
        XCTAssertEqual(adasAttrs.roadItems[1].edgeShapeIndex, 8.0)
    }

    func testADASAttributesInitializationComplete() {
        // Create a complete ADAS attributes object with all fields populated
        let restriction = SpeedLimitRestriction(
            weather: [NSNumber(value: 0)],
            dateTimeCondition: "Mo-Fr 06:00-20:00",
            vehicleTypes: [NSNumber(value: 0)],
            lanes: [NSNumber(value: 1)]
        )

        let speedLimit = SpeedLimitInfo(
            value: 100,
            unit: .kilometresPerHour,
            type: .explicit,
            restriction: restriction
        )

        let slope = ValueOnEdge(shapeIndex: 1.0, percentAlong: 0.1, value: 4.5)
        let elevation = ValueOnEdge(shapeIndex: 2.0, percentAlong: 0.2, value: 200.0)
        let curvature = ValueOnEdge(shapeIndex: 3.0, percentAlong: 0.3, value: 0.02)

        let roadItem = RoadItem(
            type: .trafficLight,
            location: NSNumber(value: 2),
            lanes: [],
            value: nil
        )

        let roadItemOnEdge = RoadItemOnEdge(
            shapeIndex: 4.0,
            percentAlong: 0.4,
            roadItem: roadItem
        )

        let nativeAttrs = EdgeAdasAttributes(
            speedLimit: [speedLimit],
            slopes: [slope],
            elevations: [elevation],
            curvatures: [curvature],
            isDividedRoad: NSNumber(value: true),
            isBuiltUpArea: NSNumber(value: true),
            formOfWay: NSNumber(value: 1), // freeway
            etc2: .highway,
            roadItems: [roadItemOnEdge]
        )

        let adasAttrs = RoadGraph.Edge.ADASAttributes(nativeAttrs, edgeIdentifier: testEdgeIdentifier)

        // Verify all fields are correctly initialized
        XCTAssertEqual(adasAttrs.speedLimit.count, 1)
        XCTAssertEqual(adasAttrs.speedLimit[0].speedLimit.value, 100)
        XCTAssertEqual(adasAttrs.speedLimit[0].restriction.weather.count, 1)

        XCTAssertEqual(adasAttrs.slopes.count, 1)
        XCTAssertEqual(adasAttrs.slopes[0].value, 4.5)

        XCTAssertEqual(adasAttrs.elevations.count, 1)
        XCTAssertEqual(adasAttrs.elevations[0].value, 200.0)

        XCTAssertEqual(adasAttrs.curvatures.count, 1)
        XCTAssertEqual(adasAttrs.curvatures[0].value, 0.02)

        XCTAssertEqual(adasAttrs.isDividedRoad, true)
        XCTAssertEqual(adasAttrs.isBuiltUpArea, true)
        XCTAssertEqual(adasAttrs.formOfWay, .freeway)
        XCTAssertEqual(adasAttrs.etc2, .highway)

        XCTAssertEqual(adasAttrs.roadItems.count, 1)
        XCTAssertEqual(adasAttrs.roadItems[0].value.kind, .trafficLight)
    }

    // MARK: - Edge Cases

    func testSpeedLimitInfoWithZeroValue() {
        let nativeRestriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let nativeSpeedLimit = SpeedLimitInfo(
            value: 0,
            unit: .kilometresPerHour,
            type: .explicit,
            restriction: nativeRestriction
        )

        let speedLimitInfo = RoadGraph.Edge.SpeedLimitInfo(nativeSpeedLimit)

        XCTAssertEqual(speedLimitInfo.speedLimit.value, 0)
    }

    func testValueOnEdgeWithNegativeValue() {
        let nativeValue = ValueOnEdge(
            shapeIndex: 5.0,
            percentAlong: 0.5,
            value: -10.0
        )

        let valueOnEdge = RoadGraph.Edge.ValueOnEdge<Double>(
            nativeValue,
            edgeIdentifier: testEdgeIdentifier
        )

        XCTAssertEqual(valueOnEdge.value, -10.0)
    }

    func testADASAttributesHashable() {
        let restriction = SpeedLimitRestriction(
            weather: [],
            dateTimeCondition: "",
            vehicleTypes: [],
            lanes: []
        )

        let speedLimit = SpeedLimitInfo(
            value: 50,
            unit: .kilometresPerHour,
            type: .explicit,
            restriction: restriction
        )

        let nativeAttrs1 = EdgeAdasAttributes(
            speedLimit: [speedLimit],
            slopes: [],
            elevations: [],
            curvatures: [],
            isDividedRoad: NSNumber(value: true),
            isBuiltUpArea: nil,
            formOfWay: nil,
            etc2: .unknown,
            roadItems: []
        )

        let nativeAttrs2 = EdgeAdasAttributes(
            speedLimit: [speedLimit],
            slopes: [],
            elevations: [],
            curvatures: [],
            isDividedRoad: NSNumber(value: true),
            isBuiltUpArea: nil,
            formOfWay: nil,
            etc2: .unknown,
            roadItems: []
        )

        let adasAttrs1 = RoadGraph.Edge.ADASAttributes(nativeAttrs1, edgeIdentifier: testEdgeIdentifier)
        let adasAttrs2 = RoadGraph.Edge.ADASAttributes(nativeAttrs2, edgeIdentifier: testEdgeIdentifier)

        // Test that ADASAttributes conforms to Hashable
        let set: Set = [adasAttrs1, adasAttrs2]
        XCTAssertGreaterThanOrEqual(set.count, 1)
    }
}
