import Foundation

guard CommandLine.arguments.count > 1 else {
    print("No input!")
    exit(1)
}

for i in 1..<CommandLine.arguments.count {
    let input = URL.init(fileURLWithPath: CommandLine.arguments[i])
    let inputFilename = input.lastPathComponent.components(separatedBy: ".")[0]
    
    let content = try Data.init(contentsOf: input)
    let json = try JSONSerialization.jsonObject(with: content, options: .allowFragments)
    
    var code = StructComponents(name: inputFilename)
    code.parse(json: json)
    try code.structCode.write(to: input.deletingLastPathComponent().appendingPathComponent(inputFilename).appendingPathExtension("swift"), atomically: true, encoding: .utf8)
}
