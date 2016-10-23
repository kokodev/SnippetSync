//
//  Syncer.swift
//  SnippetSync
//
//  Created by Manuel Rieß on 20.10.16.
//  Copyright © 2016 kokodev.de. All rights reserved.
//

import Foundation

class Syncer {

    private var sourcePath = Globals.defaultSourcePath
    private var targetPath = Globals.defaultTargetPath
    private var fileExtension = Globals.defaultFileExtension
    private var createTarget = false
    private var initializeSource = false
    private var initializeTarget = false
    private var force = false

    fileprivate var xcodeEventHandler: FileEventHandler?
    fileprivate var backupEventHandler: FileEventHandler?

    fileprivate var fileManager = FileManager.default
    fileprivate var xcodePaths = [String]()
    fileprivate var backupPaths = [String]()
    fileprivate let lockQueue = DispatchQueue(label: "de.kokodev.LockQueue")

    private var running = false
    var isRunning: Bool {
        get {
            return running
        }
    }

    init(options: Options? = nil) {
        if let path = options?.outputPath {
            targetPath = NSString(string: path).expandingTildeInPath
        }
        if let path = options?.listenerPath {
            sourcePath = NSString(string: path).expandingTildeInPath
        }
        if let ext = options?.fileExtension {
            fileExtension = ext
        }
        if let create = options?.createTarget {
            createTarget = create
        }
        if let initTarget = options?.initializeTarget {
            initializeTarget = initTarget
        }
        if let initSource = options?.initializeSource {
            initializeSource = initSource
        }
        if let f = options?.force {
            force = f
        }
    }

    func start() {
        checkSourceDirectory()
        checkTargetDirectory()

        if initializeTarget {
            initializeTargetDirectory()
        }
        if initializeSource {
            initializeSourceDirectory()
        }

        xcodeEventHandler = FileEventHandler(path: sourcePath, criteria: fileExtension)
        xcodeEventHandler?.delegate = self

        backupEventHandler = FileEventHandler(path: targetPath, criteria: fileExtension)
        backupEventHandler?.delegate = self

        print("Listening at '\(sourcePath)' for files containing '\(fileExtension)'")
        print("Syncing snippets to '\(targetPath)'")

        running = true
        xcodeEventHandler?.registerEventStream()
        backupEventHandler?.registerEventStream()
    }

    func stop() {
        running = false
        xcodeEventHandler?.deregisterEventStream()
        backupEventHandler?.deregisterEventStream()
    }

    private func checkSourceDirectory() {
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: sourcePath, isDirectory: &isDir)
        if !exists || (isDir.boolValue == false) {
            print("Source directory '\(sourcePath)' does not exist.")
            exit(-1)
        }
    }

    private func checkTargetDirectory() {
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: targetPath, isDirectory: &isDir)
        if !exists || (isDir.boolValue == false) {
            if createTarget {
                print("Creating target directory at \(targetPath)")
                do {
                    try fileManager.createDirectory(atPath: targetPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Failed to create target directory at '\(targetPath)' with error: \(error)")
                    exit(-1)
                }
            } else {
                print("Output directory does not exist. Use option '-c' to create target directory.")
                exit(-1)
            }
        }
    }

    private func initializeTargetDirectory() {
        print("initializing target directory")
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: sourcePath)
            for file in filePaths {
                guard file.contains(fileExtension) else { continue }

                if initializeSource {
                    backupPaths.append(file)
                }

                let (source, target) = pathsForFile(file)

                let targetExists = fileManager.fileExists(atPath: target)
                if targetExists && !force {
                    print("file at '\(target)' already exists. Ignoring... use option '-f' to force override target files.")
                    continue
                } else {
                    do {
                        print("target '\(target)' exists. will override because force option '-f' is enabled.")
                        try fileManager.removeItem(atPath: target)
                    } catch {
                        print("failed to remove file '\(target)' to force initialize target.")
                    }
                }

                do {
                    print("copying '\(file)' to '\(target)'")
                    try fileManager.copyItem(atPath: source, toPath: target)
                } catch {
                    print("failed to copy file '\(source)' to target directory at '\(target)'")
                    exit(-1)
                }
            }
        } catch {
            print("failed to get contents of source directory")
            exit(-1)
        }
    }

    private func initializeSourceDirectory() {
        print("initializing source directory")
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: targetPath)
            for file in filePaths {
                guard file.contains(fileExtension) else { continue }

                print(file)

                if let index = backupPaths.index(of: file) {
                    backupPaths.remove(at: index)
                    return
                }

                let (target, source) = pathsForFile(file)

                let targetExists = fileManager.fileExists(atPath: target)
                if targetExists && !force {
                    print("file at '\(target)' already exists. Ignoring... use option '-f' to force override target files.")
                    continue
                } else if targetExists && force {
                    do {
                        print("source '\(target)' exists. will override because force option '-f' is enabled.")
                        try fileManager.removeItem(atPath: target)
                    } catch {
                        print("failed to remove file '\(target)' to force initialize source.")
                    }
                }

                do {
                    print("copying '\(file)' to '\(target)'")
                    try fileManager.copyItem(atPath: source, toPath: target)
                } catch {
                    print("failed to copy file '\(source)' to source directory at '\(target)'")
                    exit(-1)
                }
            }
        } catch {
            print("failed to get contents of target directory")
            exit(-1)
        }
    }

    fileprivate func pathsForFile(_ file: String) -> (String, String) {
        return (sourcePathForFile(file), targetPathForFile(file))
    }

    fileprivate func sourcePathForFile(_ file: String) -> String {
        return sourcePath + "/" + file
    }

    fileprivate func targetPathForFile(_ file: String) -> String {
        return targetPath + "/" + file
    }
}

extension Syncer: FileEventHandlerDelegate {

    func eventHandler(_ handler: FileEventHandler, didReceiveEventAtPath path: String, eventType type: FileEventHandler.EventType) {

        let nsPath = NSString(string: path)
        let file = nsPath.lastPathComponent as String

        let isXcodeHandler = (handler === self.xcodeEventHandler)

        let (source, target): (String, String)
        if isXcodeHandler {
            if let index = xcodePaths.index(of: file) {
                xcodePaths.remove(at: index)
                return
            }

            print("sync xcode -> target...")

            backupPaths.append(file)
            (source, target) = pathsForFile(file)
        } else {
            if let index = backupPaths.index(of: file) {
                backupPaths.remove(at: index)
                return
            }

            print("sync target -> xcode...")

            xcodePaths.append(file)
            (target, source) = pathsForFile(file)
        }

        lockQueue.sync {
            do {
                switch type {
                case .created:
                    print("file created: '\(file)'")
                    if !fileManager.fileExists(atPath: target) {
                        try fileManager.copyItem(atPath: source, toPath: target)
                    } else {
                        print("file exists at target. skipping...")
                    }

                case .removed:
                    print("file removed: '\(file)'")
                    if fileManager.fileExists(atPath: target) {
                        try fileManager.removeItem(atPath: target)
                    }

                case .modified:
                    print("file modified: '\(file)'")
                    if fileManager.fileExists(atPath: target) {
                        try fileManager.removeItem(atPath: target)
                    }
                    try fileManager.copyItem(atPath: source, toPath: target)

                case .renamed:
                    print("file renamed: '\(file)'")
                    if fileManager.fileExists(atPath: target) {
                        try fileManager.removeItem(atPath: target)
                    }
                    // When a file gets moved to the trash from within Finder, it got "renamed"
                    // Therefore we have to check whether it still exists at the source.
                    if fileManager.fileExists(atPath: source) {
                        try fileManager.copyItem(atPath: source, toPath: target)
                    }

                case .unknown:
                    print("received unknown event for file at path '\(path)'")
                }
            } catch {
                print("failed to handle sync event for file '\(path)': \(error)")
            }

            print("done")
        }
    }

}
