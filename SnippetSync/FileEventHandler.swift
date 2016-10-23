//
//  FileEventHandler.swift
//  SnippetSync
//
//  Created by Manuel Rieß on 23.10.16.
//  Copyright © 2016 kokodev.de. All rights reserved.
//

import Foundation

protocol FileEventHandlerDelegate {
    func eventHandler(_ handler: FileEventHandler, didReceiveEventAtPath path: String, eventType type: FileEventHandler.EventType)
}

class FileEventHandler {

    enum EventType {
        case unknown
        case created
        case removed
        case modified
        case renamed
    }

    private struct Event {
        var path: String
        var flags: FSEventStreamEventFlags
    }

    var delegate: FileEventHandlerDelegate?

    private var eventPath: String
    private var criteria: String?
    private var eventStream: FSEventStreamRef?

    init(path: String, criteria: String? = nil) {
        self.eventPath = path
        self.criteria = criteria
    }

    func registerEventStream() {
        let latency = 0.5
        var context = FSEventStreamContext()
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        if let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            [eventPath] as CFArray,
            UInt64(kFSEventStreamEventIdSinceNow),
            latency,
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents))
        {
            eventStream = stream
            if let runloop = CFRunLoopGetCurrent() {
                FSEventStreamScheduleWithRunLoop(stream, runloop, CFRunLoopMode.defaultMode.rawValue)
                FSEventStreamStart(stream)
            } else {
                print("failed to get current runloop")
            }
        }
    }

    func deregisterEventStream() {
        if let stream = eventStream {
            if let runloop = CFRunLoopGetCurrent() {
                FSEventStreamUnscheduleFromRunLoop(stream, runloop, CFRunLoopMode.defaultMode.rawValue)
            } else {
                print("failed to get current runloop")
            }
        }
    }

    private let callback: FSEventStreamCallback = {
        (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in

        if let info = clientCallBackInfo {
            guard numEvents > 0,
                let eventFlags = eventFlags
                else {
                    return
            }

            let	eventPathsArray = unsafeBitCast(eventPaths, to: NSArray.self)
            var	events = [Event]()
            events.reserveCapacity(numEvents)

            for i in 0..<Int(numEvents) {
                let	path = eventPathsArray[i] as! String
                let	flags = eventFlags[i]

                let	ev = Event(path: path, flags: flags)
                events.append(ev)
            }

            let handler = unsafeBitCast(info, to: FileEventHandler.self)
            handler.handleEvents(events)
        }
    }

    private func handleEvents(_ events: [Event])
    {
        guard let delegate = delegate else { return }

        for event in events {
            if let criteria = criteria {
                guard event.path.contains(criteria) else { continue }
            }

            let eventType: EventType
            if (event.flags & UInt32(kFSEventStreamEventFlagItemCreated) != 0) {
                eventType = .created
            } else if (event.flags & UInt32(kFSEventStreamEventFlagItemRemoved) != 0) {
                eventType = .removed
            } else if (event.flags & UInt32(kFSEventStreamEventFlagItemModified) != 0) {
                eventType = .modified
            } else if (event.flags & UInt32(kFSEventStreamEventFlagItemRenamed) != 0) {
                eventType = .renamed
            } else {
                print("unknown event type in event: \(event)")
                continue
            }

            delegate.eventHandler(self, didReceiveEventAtPath: event.path, eventType: eventType)
        }
    }

}
