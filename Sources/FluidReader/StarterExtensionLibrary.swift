import Foundation

struct StarterExtensionTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let fileName: String
    let systemImage: String
    let keywords: [String]
    let scriptContents: String
}

enum StarterExtensionCatalog {
    static let templates: [StarterExtensionTemplate] = [
        StarterExtensionTemplate(
            id: "system-uptime",
            title: "System Uptime",
            subtitle: "Install a script that prints host, time, and uptime in one run",
            fileName: "system-uptime.sh",
            systemImage: "clock.arrow.circlepath",
            keywords: ["starter", "install", "extension", "uptime", "load", "diagnostics", "system"],
            scriptContents: """
            #!/bin/sh
            # @title System Uptime
            # @subtitle Snapshot hostname, uptime, and load averages
            # @keywords system, uptime, load, diagnostics
            # @icon clock.arrow.circlepath
            set -eu
            echo "# System Uptime"
            echo
            echo "Host: $(scutil --get ComputerName 2>/dev/null || hostname)"
            echo "Time: $(date)"
            echo
            uptime
            """
        ),
        StarterExtensionTemplate(
            id: "disk-space",
            title: "Disk Space",
            subtitle: "Install a script that prints local disk usage in a launcher-friendly format",
            fileName: "disk-space.sh",
            systemImage: "internaldrive",
            keywords: ["starter", "install", "extension", "disk", "space", "storage", "drive"],
            scriptContents: """
            #!/bin/sh
            # @title Disk Space
            # @subtitle Local disk usage snapshot
            # @keywords disk, space, storage, drive
            # @icon internaldrive
            set -eu
            echo "# Disk Space"
            echo
            df -h | awk 'NR == 1 || /^\\/dev\\// { print }'
            """
        ),
        StarterExtensionTemplate(
            id: "network-quick-look",
            title: "Network Quick Look",
            subtitle: "Install a script that prints active local IP addresses and Wi-Fi name",
            fileName: "network-quick-look.sh",
            systemImage: "network",
            keywords: ["starter", "install", "extension", "network", "wifi", "ip", "diagnostics"],
            scriptContents: """
            #!/bin/sh
            # @title Network Quick Look
            # @subtitle Local IP addresses and Wi-Fi snapshot
            # @keywords network, wifi, ip, diagnostics
            # @icon network
            set -eu
            echo "# Network Quick Look"
            echo
            for iface in en0 en1; do
              ip="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
              if [ -n "$ip" ]; then
                echo "$iface: $ip"
              fi
            done
            wifi="$(networksetup -getairportnetwork en0 2>/dev/null || true)"
            if [ -n "$wifi" ]; then
              echo
              echo "$wifi"
            fi
            """
        ),
        StarterExtensionTemplate(
            id: "recent-downloads",
            title: "Recent Downloads",
            subtitle: "Install a script that lists the newest files in Downloads",
            fileName: "recent-downloads.sh",
            systemImage: "arrow.down.circle",
            keywords: ["starter", "install", "extension", "downloads", "recent", "files", "finder"],
            scriptContents: """
            #!/bin/sh
            # @title Recent Downloads
            # @subtitle Latest files in Downloads
            # @keywords downloads, recent, files, finder
            # @icon arrow.down.circle
            set -eu
            downloads="${HOME}/Downloads"
            if [ ! -d "$downloads" ]; then
              echo "Downloads folder not found."
              exit 0
            fi
            echo "# Recent Downloads"
            echo
            ls -lt "$downloads" | head -n 11
            """
        )
    ]

    static func installedScript(
        for template: StarterExtensionTemplate,
        in scriptCommands: [ScriptCommandItem]
    ) -> ScriptCommandItem? {
        scriptCommands.first {
            $0.url.lastPathComponent.localizedCaseInsensitiveCompare(template.fileName) == .orderedSame
        }
    }
}

enum StarterExtensionInstallResult: Equatable {
    case installed(URL)
    case alreadyInstalled(URL)
}

enum StarterExtensionInstaller {
    static func install(
        _ template: StarterExtensionTemplate,
        directoryURL: URL,
        fileManager: FileManager = .default
    ) throws -> StarterExtensionInstallResult {
        let pack = LocalExtensionPack(template: template)
        let result = try pack.install(
            into: directoryURL,
            fileManager: fileManager,
            mode: .keepExisting
        )

        switch result {
        case .installed(let url):
            return .installed(url)
        case .alreadyInstalled(let url), .replaced(let url):
            return .alreadyInstalled(url)
        }
    }
}
