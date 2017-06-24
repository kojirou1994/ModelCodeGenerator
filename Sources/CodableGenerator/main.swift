import Foundation

guard CommandLine.arguments.count > 2 else {
    print("No input!")
    exit(1)
}

for i in 2..<CommandLine.arguments.count {
    let input = URL.init(fileURLWithPath: CommandLine.arguments[i])
    let jsonData = try Data.init(contentsOf: input)
    
    let json = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
    
    var code = StructComponents(name: "TestJSON")
    code.parse(json: json)
    try code.code.write(to: input.deletingPathExtension().appendingPathExtension("swift"), atomically: true, encoding: .utf8)
}

