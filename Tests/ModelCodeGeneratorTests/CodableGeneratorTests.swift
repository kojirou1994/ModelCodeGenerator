import XCTest
@testable import ModelCodeGenerator

final class ModelCodeGeneratorTests: XCTestCase {
  func testExample() throws {
    let gen = ModelCodeGenerator(options: .init(sortedProperty: true,
                                              variableNameStrategy: .convertFromSnakeCase,
                                              rootName: "Model", nestedObject: true, variable: true,
                                              indentation: .spaces(width: 2), accessControl: .internal,
                                              alwaysCodingKeys: true, conformingProtocols: ["Codable"]))
    let stru = try gen.parseStruct(name: "Root", value: [
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
    print(stru)
    print(try gen.generateCode(from: stru))
  }
}
