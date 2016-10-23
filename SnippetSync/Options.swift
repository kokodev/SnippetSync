//
//  Options.swift
//  SnippetSync
//
//  Created by Manuel Rieß on 23.10.16.
//  Copyright © 2016 kokodev.de. All rights reserved.
//

import Foundation

struct Options {
    enum Switches: String {
        case createTargetShort = "-c"
        case createTargetLong = "--createTarget"

        case forceShort = "-f"
        case forceLong = "--force"

        case fileExtensionShort = "-e"
        case fileExtensionLong = "--extension"

        case helpShort = "-h"
        case helpLong = "--help"
        case helpMark = "-?"

        case copyFromSourceShort = "-s"
        case copyFromSourceLong = "--copy-from-source"

        case initializeTargetShort = "-i"
        case initializeTargetLong = "--initializeTarget"

        case listenDirShort = "-l"
        case listenDirLong = "--listenDir"

        case outputDirShort = "-o"
        case outputDirLong = "--outputDir"

        case versionShort = "-v"
        case versionLong = "--version"
    }

    var createTarget: Bool = false
    var fileExtension: String?
    var force: Bool = false
    var initializeSource: Bool = false
    var initializeTarget: Bool = false
    var listenerPath: String?
    var outputPath: String?

    init(arguments: [String]) {
        var skip = false
        var index = 0
        for argument in CommandLine.arguments {
            guard index > 0, !skip else {
                index += 1
                skip = false
                continue
            }

            if let argumentSwitch = Switches.init(rawValue: argument) {
                switch argumentSwitch {
                case .createTargetShort,
                     .createTargetLong:
                    createTarget = true

                case .copyFromSourceShort,
                     .copyFromSourceLong:
                    initializeSource = true

                case .fileExtensionShort,
                     .fileExtensionLong:
                    if index < CommandLine.arguments.count - 1 {
                        fileExtension = CommandLine.arguments[index + 1]
                        skip = true
                    } else {
                        print("Missing extension for argument '-e'")
                        exit(-1)
                    }

                case .forceShort,
                     .forceLong:
                    force = true

                case .helpShort,
                     .helpLong,
                     .helpMark:
                    printHelp()
                    if index == CommandLine.arguments.count - 1 {
                        exit(0)
                    }

                case .initializeTargetShort,
                     .initializeTargetLong:
                    initializeTarget = true

                case .listenDirShort,
                     .listenDirLong:
                    if index < CommandLine.arguments.count - 1 {
                        listenerPath = CommandLine.arguments[index + 1]
                        skip = true
                    } else {
                        print("Missing path for argument '-l'")
                        exit(-1)
                    }

                case .outputDirShort,
                     .outputDirLong:
                    if index < CommandLine.arguments.count - 1 {
                        outputPath = CommandLine.arguments[index + 1]
                        skip = true
                    } else {
                        print("Missing path for argument '-o'")
                        exit(-1)
                    }

                    case .versionShort,
                         .versionLong:
                    print("SnippetSync version \(Globals.version)")
                    if index == CommandLine.arguments.count - 1 {
                        exit(0)
                    }
                }
            } else {
                print("Unknown argument: '\(argument)'")
                printHelp()
                exit(-1)
            }
            index += 1
        }
    }

    func printHelp() {
        print("usage:\n" +
                "-?, -h, --help\t\t\t\t# Show this help\n" +
                "-v, --version\t\t\t\t# Show SnippetSync version\n" +
                "-e, --extension <fileextension>\t\t# A string to match filenames to listen for. Default: .codesnippet\n" +
                "-l, --listenDir <path>\t\t\t# The source snippet directory. Default: Xcode snippet folder\n" +
                "-o, --outputDir <path>\t\t\t# The folder to sync the snippets to. Default: Desktop\n" +
                "-c, --createTarget\t\t\t# If <outputDir> does not exist, create it\n" +
                "-i, --initializeTarget\t\t\t# Initialize the target directory with existing Xcode snippets\n" +
                "-s, --copy-from-source\t\t\t# Initialize source directory with existing files from the output folder\n" +
                "-f, --force\t\t\t\t# When initializing source/output directories, override files if they exist\n")
    }

}
