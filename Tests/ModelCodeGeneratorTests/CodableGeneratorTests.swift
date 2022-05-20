import XCTest
@testable import ModelCodeGenerator

final class ModelCodeGeneratorTests: XCTestCase {
  func testExample() throws {
    let parser = JSONModelParser(options: .init(detectUUID: true))
    let info = try parser.parseStruct(value: [
      "name": "Bob",
      "age": 10,
      "numbers": [
        1, 2, 3
      ],
      "nested": [
        "id": 1,
        "string": "A",
        "anotherNested": [
          "id": 1,
          "string": "A",
          "anotherNested": [
            "id": 1,
            "string": "A"
          ]
        ]
      ]
    ])
    print(info)

    let writer = StructCodeWriter(options: .init(rootName: "Model", sortedProperty: true, nestedObject: true, variable: true, indentation: .spaces(width: 2), accessControl: .internal, alwaysCodingKeys: false, conformingProtocols: ["Codable"], variableNameStrategy: .camelFromSnakeCase, objectNameStrategy: .camelFromSnakeCase, dropObjectPluralSuffix: true))
    print(writer.generateCode(from: info))
  }
}
