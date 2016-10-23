//
//  main.swift
//  SnippetSync
//
//  Created by Manuel Rieß on 20.10.16.
//  Copyright © 2016 kokodev.de. All rights reserved.
//

import Foundation

let options = Options(arguments: CommandLine.arguments)

let syncer = Syncer(options: options)
syncer.start()

while (syncer.isRunning && RunLoop.current.run(mode: .defaultRunLoopMode, before: NSDate.distantFuture)) {}

print("exit")
