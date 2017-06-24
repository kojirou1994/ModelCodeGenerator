#### Usage
```shell
git clone https://github.com/kojirou1994/CodableGenerator.git
cd CodableGenerator
swift build
.build/debug/CodableGenerator input1.json input2.json
```

#### Requirement
Xcode9 / Swift4

#### Example
Example.json:
```json
{
    "integer": 555555,
    "float": 100.5,
    "string": "兰州烧饼",
    "long_path": 3,
    "bool": false,
    "null": null,
    "dic": {
        "sub_integer": 10,
        "sub_string": "haha"
    },
    "int_array": [
        100,
        1,
        2,
        3
    ],
    "json_array": [
        {
            "id": 555555,
            "name": "兰州烧饼",
            "add": "北京市海定区中关村"
        },
        {
            "id": 666666,
            "name": "兰州拉面",
            "add": "北京市海定区中关村"
        },
        {
            "id": 888888,
            "name": "肯德基",
            "add": "北京市海定区中关村"
        }
    ],
}
```
run `build/debug/CodableGenerator Example.json`

It will generate Example.swift in the working dir.
```swift
struct Example: Codable {

    var string: String

    var null: NSNull

    var integer: Int

    struct Dic: Codable {
    
        var subString: String
    
        var subInteger: Int
    
        private enum CodingKeys: String, CodingKey {
            case subString = "sub_string"
            case subInteger = "sub_integer"
        }
    
    }

    var dic: Dic

    var intArray: [Int]

    var float: Double

    var longPath: Int

    var bool: Bool

    struct JsonArray: Codable {
    
        var id: Int
    
        var name: String
    
        var add: String
    
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case add
        }
    
    }

    var jsonArray: [JsonArray]

    private enum CodingKeys: String, CodingKey {
        case string
        case null
        case integer
        case dic
        case intArray = "int_array"
        case float
        case longPath = "long_path"
        case bool
        case jsonArray = "json_array"
    }

}
```

