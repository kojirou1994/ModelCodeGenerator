import Foundation
import ModelCodeGenerator
import ArgumentParser

@main
struct ModelCodeGeneratorCli: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(
      subcommands: [
        JSONFile.self,
        JSONSchema.self,
      ]
    )
  }
}
