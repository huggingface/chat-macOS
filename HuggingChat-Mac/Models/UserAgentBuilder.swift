//
//  UserAgentBuilder.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

//https://github.com/WURFL/User-Agent-Native-apps/blob/master/swift/UABuilder.swift

import Foundation
import AppKit

final class UserAgentBuilder {
    
    static let userAgent: String = userAgentString()

    //eg. Darwin/16.3.0
    static func DarwinVersion() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        return "Darwin/\(dv)"
    }

    //eg. CFNetwork/808.3
    static func CFNetworkVersion() -> String {
        let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary!
        let version = dictionary?["CFBundleShortVersionString"] as! String
        return "CFNetwork/\(version)"
    }

    //eg.  MacBookPro18,3
    static func deviceVersion() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    //eg. arm64
    static func deviceName() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    static let appVersion: String = {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        return "\(version)"
    }()
    
    static let buildNumber: String = {
        let dictionary = Bundle.main.infoDictionary!
        let build = dictionary["CFBundleVersion"] as! String
        return "\(build)"
    }()
    
    static let device: String = {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }()
    
    static let osVersion: String = {
        let currentDevice = ProcessInfo.processInfo
        return "macOS \(currentDevice.operatingSystemVersion.majorVersion).\(currentDevice.operatingSystemVersion.minorVersion)"
    }()

    //eg. MyApp/1
    static func appNameAndVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        let name = dictionary["CFBundleName"] as! String
        return "\(name)/\(version)-(\(build))"
    }

    static func userAgentString() -> String {
        return "\(appNameAndVersion()) \(deviceName()) \(deviceVersion()) \(CFNetworkVersion()) \(DarwinVersion())"
    }
}
