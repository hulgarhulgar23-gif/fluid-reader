import XCTest
@testable import FluidReader

final class CommandPaletteActionTests: XCTestCase {
    func testSearchMatchesTitleSubtitleAndKeywords() {
        let actions = [
            CommandPaletteAction(
                id: "summarize",
                title: "Summarize",
                subtitle: "Ask the LLM for a short summary",
                systemImage: "text.badge.checkmark",
                keywords: ["ai"],
                run: {}
            ),
            CommandPaletteAction(
                id: "mark-screenshot",
                title: "Mark Screenshot",
                subtitle: "Draw a line and ask about that part",
                systemImage: "pencil.and.scribble",
                keywords: ["image", "screen"],
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "ai").map(\.id), ["summarize"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "screen line").map(\.id), ["mark-screenshot"])
    }

    func testSearchMatchesAliasKeywords() {
        let actions = [
            CommandPaletteAction(
                id: "settings",
                title: "Settings",
                subtitle: "Change app settings",
                systemImage: "gearshape",
                keywords: ["preferences", "prefs", "config"],
                run: {}
            ),
            CommandPaletteAction(
                id: "screen-recording-settings",
                title: "Screen Recording Settings",
                subtitle: "Open macOS permission settings",
                systemImage: "lock.shield",
                keywords: ["permissions", "setitngs", "screen recording", "allow", "grant"],
                run: {}
            ),
            CommandPaletteAction(
                id: "accessibility-settings",
                title: "Accessibility Settings",
                subtitle: "Open macOS permission settings",
                systemImage: "accessibility",
                keywords: ["permissions", "accessiblity", "a11y", "allow", "grant", "trust"],
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Type a question",
                systemImage: "sparkles",
                keywords: ["chat", "gpt", "assistant"],
                run: {}
            ),
            CommandPaletteAction(
                id: "open-app",
                title: "Open App",
                subtitle: "Launch an installed app",
                systemImage: "app.badge",
                keywords: ["launcher", "raycast", "spotlight"],
                run: {}
            ),
            CommandPaletteAction(
                id: "clipboard-text-stats",
                title: "Clipboard Text Stats",
                subtitle: "Word count",
                systemImage: "number",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-strong-password",
                title: "Copy Strong Password",
                subtitle: "Generate password",
                systemImage: "key",
                run: {}
            ),
            CommandPaletteAction(
                id: "clean-url-clipboard",
                title: "Clean URL Clipboard",
                subtitle: "Remove tracking",
                systemImage: "link.badge.minus",
                keywords: ["utm", "strip"],
                run: {}
            ),
            CommandPaletteAction(
                id: "base64-encode-clipboard",
                title: "Base64 Encode Clipboard",
                subtitle: "Encode b64",
                systemImage: "chevron.left.forwardslash.chevron.right",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-time-zone",
                title: "Copy Time Zone",
                subtitle: "Zone and offset",
                systemImage: "globe",
                keywords: ["timezone"],
                run: {}
            ),
            CommandPaletteAction(
                id: "extract-domains-clipboard",
                title: "Extract Domains Clipboard",
                subtitle: "Find domains",
                systemImage: "network",
                keywords: ["host", "hosts"],
                run: {}
            ),
            CommandPaletteAction(
                id: "pretty-json-clipboard",
                title: "Pretty JSON Clipboard",
                subtitle: "Format JSON",
                systemImage: "curlybraces",
                keywords: ["beautify", "prettify"],
                run: {}
            ),
            CommandPaletteAction(
                id: "minify-json-clipboard",
                title: "Minify JSON Clipboard",
                subtitle: "Compact JSON",
                systemImage: "curlybraces",
                run: {}
            ),
            CommandPaletteAction(
                id: "strip-ansi-clipboard",
                title: "Remove Terminal Colors Clipboard",
                subtitle: "Strip ANSI codes",
                systemImage: "terminal",
                run: {}
            ),
            CommandPaletteAction(
                id: "slugify-clipboard",
                title: "Slugify Clipboard",
                subtitle: "URL-friendly text",
                systemImage: "textformat",
                keywords: ["kebab-case"],
                run: {}
            ),
            CommandPaletteAction(
                id: "trim-lines-clipboard",
                title: "Trim Lines Clipboard",
                subtitle: "Trim lines",
                systemImage: "text.alignleft",
                keywords: ["blank-lines"],
                run: {}
            ),
            CommandPaletteAction(
                id: "unique-lines-clipboard",
                title: "Unique Lines Clipboard",
                subtitle: "Dedupe lines",
                systemImage: "list.bullet.rectangle",
                keywords: ["duplicate-lines"],
                run: {}
            ),
            CommandPaletteAction(
                id: "markdown-table-clipboard",
                title: "Markdown Table Clipboard",
                subtitle: "Make CSV table",
                systemImage: "tablecells",
                run: {}
            ),
            CommandPaletteAction(
                id: "window-left-half",
                title: "Window Left Half",
                subtitle: "Move front window to the left half",
                systemImage: "rectangle.lefthalf.filled",
                keywords: ["split", "tile", "snap"],
                run: {}
            ),
            CommandPaletteAction(
                id: "edit-snippet",
                title: "Edit Snippet: Daily Standup",
                subtitle: "Rename and edit snippet",
                systemImage: "square.and.pencil",
                keywords: ["rename", "title", "edit-text", "snippet"],
                run: {}
            ),
            CommandPaletteAction(
                id: "edit-quick-link",
                title: "Edit Link: Docs",
                subtitle: "Rename and edit URL",
                systemImage: "square.and.pencil",
                keywords: ["rename", "title", "edit-url", "url"],
                run: {}
            ),
            CommandPaletteAction(
                id: "window-center-third",
                title: "Window Center Third",
                subtitle: "Move front window to the center third",
                systemImage: "rectangle.split.3x1",
                keywords: ["middle", "third", "tile"],
                run: {}
            ),
            CommandPaletteAction(
                id: "window-right-two-thirds",
                title: "Window Right Two Thirds",
                subtitle: "Move front window to the right two thirds",
                systemImage: "rectangle.split.3x1",
                keywords: ["two-thirds", "2/3", "wide", "tile"],
                run: {}
            ),
            CommandPaletteAction(
                id: "window-top-left-quarter",
                title: "Window Top Left Quarter",
                subtitle: "Move front window to the top-left quarter",
                systemImage: "rectangle.split.2x2",
                keywords: ["quarter", "corner", "top-left"],
                run: {}
            ),
            CommandPaletteAction(
                id: "window-cycle-layout",
                title: "Window Cycle Layout",
                subtitle: "Move front window to the next layout preset",
                systemImage: "arrow.triangle.2.circlepath.rectangle",
                keywords: ["cycle", "rotate", "next-layout", "layout-loop"],
                run: {}
            ),
            CommandPaletteAction(
                id: "window-previous-layout",
                title: "Window Previous Layout",
                subtitle: "Move front window to the previous layout preset",
                systemImage: "arrow.triangle.2.circlepath.rectangle",
                keywords: ["reverse", "back", "previous-layout"],
                run: {}
            ),
            CommandPaletteAction(
                id: "window-cycle-profile-focus",
                title: "Cycle Profile: Focus",
                subtitle: "Cycle half-center-maximize set",
                systemImage: "viewfinder",
                keywords: ["profile", "focus"],
                run: {}
            ),
            CommandPaletteAction(
                id: "window-undo-last-move",
                title: "Window Undo Last Move",
                subtitle: "Restore the front window to its previous frame",
                systemImage: "arrow.uturn.backward",
                keywords: ["undo", "restore", "revert", "last-position"],
                run: {}
            ),
            CommandPaletteAction(
                id: "window-next-display",
                title: "Window Next Display",
                subtitle: "Move front window to the next display",
                systemImage: "display.2",
                keywords: ["monitor", "screen", "next"],
                run: {}
            ),
            CommandPaletteAction(
                id: "window-previous-display",
                title: "Window Previous Display",
                subtitle: "Move front window to the previous display",
                systemImage: "display.2",
                keywords: ["monitor", "screen", "previous"],
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-founder-command-presets",
                title: "Copy Fame Loop",
                subtitle: "Copy weekly KPI + fame command stack",
                systemImage: "chart.line.uptrend.xyaxis",
                keywords: ["founder", "growth", "fame", "kpi", "weekly"],
                run: {}
            ),
            CommandPaletteAction(
                id: "paste-founder-command-presets",
                title: "Paste Fame Loop",
                systemImage: "arrow.turn.down.right",
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "prefs").map(\.id), ["settings"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "config").map(\.id), ["settings"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "setitngs permission").map(\.id).first, "screen-recording-settings")
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "accessiblity").map(\.id).first, "accessibility-settings")
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "trust permission").map(\.id).first, "accessibility-settings")
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "grant screen").map(\.id).first, "screen-recording-settings")
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "assistant").map(\.id), ["ask-anything"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "raycast").map(\.id), ["open-app"])
        let founderWeeklyResults = CommandPaletteAction.filter(actions, query: "founder weekly").map(\.id)
        XCTAssertEqual(founderWeeklyResults.first, "copy-founder-command-presets")
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "fame weekly").map(\.id).first, "copy-founder-command-presets")
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "founder paste").map(\.id).first, "paste-founder-command-presets")
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "word count").map(\.id), ["clipboard-text-stats"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "generate password").map(\.id), [
            "copy-strong-password"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "tracking url").map(\.id), ["clean-url-clipboard"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "b64 encode").map(\.id), [
            "base64-encode-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "timezone").map(\.id), ["copy-time-zone"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "host").map(\.id), [
            "extract-domains-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "beautify json").map(\.id), [
            "pretty-json-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "prettify json").map(\.id), [
            "pretty-json-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "compact json").map(\.id), [
            "minify-json-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "remove color").map(\.id), [
            "strip-ansi-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "ansi code").map(\.id), [
            "strip-ansi-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "kebab case").map(\.id), [
            "slugify-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "blank lines").map(\.id), [
            "trim-lines-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "duplicate lines").map(\.id), [
            "unique-lines-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "dedupe lines").map(\.id), [
            "unique-lines-clipboard"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "split left").map(\.id), [
            "window-left-half"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "rename snippet").map(\.id), [
            "edit-snippet"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "edit url").map(\.id), [
            "edit-quick-link"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "tile left").map(\.id), [
            "window-left-half"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "snap left").map(\.id), [
            "window-left-half"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "middle third").map(\.id), [
            "window-center-third"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "next monitor").map(\.id), [
            "window-next-display"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "wide right").map(\.id), [
            "window-right-two-thirds"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "2/3 right").map(\.id), [
            "window-right-two-thirds"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "top left quarter").map(\.id), [
            "window-top-left-quarter"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "top left corner").map(\.id), [
            "window-top-left-quarter"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "cycle layout").map(\.id), [
            "window-cycle-layout"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "rotate window").map(\.id), [
            "window-cycle-layout"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "reverse layout").map(\.id), [
            "window-previous-layout"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "back layout").map(\.id), [
            "window-previous-layout"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "cycle profile focus").map(\.id), [
            "window-cycle-profile-focus"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "restore window").map(\.id), [
            "window-undo-last-move"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "previous screen").map(\.id), [
            "window-previous-display"
        ])
    }

    func testSearchMatchesPromptAliases() {
        let actions = PromptTemplate.builtIn.map { template in
            CommandPaletteAction(
                id: "prompt-\(template.id)",
                title: template.title,
                subtitle: "Ask about current content",
                systemImage: template.systemImage,
                keywords: template.keywords,
                run: {}
            )
        }

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "tldr").map(\.id), ["prompt-summarize"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "eli5").map(\.id), ["prompt-simple"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "meeting minutes").map(\.id), ["prompt-notes"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "next steps").map(\.id), ["prompt-actions"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "fix bug").map(\.id), ["prompt-code-help"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "launch announcement").map(\.id), ["prompt-launch-post"])
    }

    func testBlankSearchReturnsAllActions() {
        let actions = [
            CommandPaletteAction(id: "read", title: "Read", subtitle: "Speak text", systemImage: "speaker", run: {}),
            CommandPaletteAction(id: "stop", title: "Stop", subtitle: "Stop speech", systemImage: "stop", run: {})
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "  ").map(\.id), ["read", "stop"])
    }

    func testSearchMatchesAcronymsAndPartialTyping() {
        let actions = [
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Use selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "screen-recording-settings",
                title: "Screen Recording Settings",
                subtitle: "Open macOS permission settings",
                systemImage: "lock.shield",
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "rst").map(\.id), ["read-selected"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "scr rec").map(\.id), [
            "screen-recording-settings"
        ])
    }

    func testSearchSplitsPastedCommandNames() {
        let actions = [
            CommandPaletteAction(
                id: "screen-recording-settings",
                title: "Screen Recording Settings",
                subtitle: "Open macOS permission settings",
                systemImage: "lock.shield",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-clipboard",
                title: "Copy Clipboard Text",
                subtitle: "Copy clipboard text",
                systemImage: "doc.on.doc",
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "screen-recording").map(\.id), [
            "screen-recording-settings"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "copy_clipboard").map(\.id), [
            "copy-clipboard"
        ])
    }

    func testSearchMatchesCompactedCommandWords() {
        let actions = [
            CommandPaletteAction(
                id: "utc-offset",
                title: "Copy UTC Offset",
                subtitle: "Copy local UTC offset",
                systemImage: "globe",
                run: {}
            ),
            CommandPaletteAction(
                id: "local-iso",
                title: "Copy Local ISO Date",
                subtitle: "Copy ISO date with offset",
                systemImage: "calendar",
                run: {}
            ),
            CommandPaletteAction(
                id: "markdown-table",
                title: "Markdown Table Clipboard",
                subtitle: "Make a markdown table",
                systemImage: "tablecells",
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "utcoffset").map(\.id), ["utc-offset"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "localiso").map(\.id), ["local-iso"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "markdowntable").map(\.id), [
            "markdown-table"
        ])
    }

    func testSearchMatchesActionIDs() {
        let actions = [
            CommandPaletteAction(
                id: "open-clipboard-url",
                title: "Open Copied Link",
                subtitle: "Open a copied link in the browser",
                systemImage: "link",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-local-iso-date",
                title: "Copy Local ISO Date",
                subtitle: "Copy ISO date with local offset",
                systemImage: "calendar",
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "clipboard-url").map(\.id), [
            "open-clipboard-url"
        ])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "copylocalisodate").map(\.id), [
            "copy-local-iso-date"
        ])
    }

    func testSearchAllowsSmallTyposInLongWords() {
        let actions = [
            CommandPaletteAction(
                id: "copy-clipboard",
                title: "Copy Clipboard Text",
                subtitle: "Copy clipboard text",
                systemImage: "doc.on.doc",
                run: {}
            ),
            CommandPaletteAction(
                id: "mark-screenshot",
                title: "Mark Screenshot",
                subtitle: "Draw a line on a screenshot",
                systemImage: "pencil.and.scribble",
                run: {}
            ),
            CommandPaletteAction(
                id: "settings",
                title: "Screen Recording Settings",
                subtitle: "Open macOS permission settings",
                systemImage: "lock.shield",
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "clipbord").map(\.id), ["copy-clipboard"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "screnshot").map(\.id), ["mark-screenshot"])
        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "seting").map(\.id), ["settings"])
    }

    func testSearchDoesNotFuzzyMatchShortWords() {
        let actions = [
            CommandPaletteAction(id: "read", title: "Read", subtitle: "Speak text", systemImage: "speaker", run: {})
        ]

        XCTAssertTrue(CommandPaletteAction.filter(actions, query: "reed").isEmpty)
    }

    func testSearchRanksStrongTitleMatchesBeforeKeywordMatches() {
        let actions = [
            CommandPaletteAction(
                id: "copy",
                title: "Copy Answer",
                subtitle: "Copy answer",
                systemImage: "doc.on.clipboard",
                keywords: ["summary"],
                run: {}
            ),
            CommandPaletteAction(
                id: "summary",
                title: "Summary",
                subtitle: "Ask for a short summary",
                systemImage: "text.badge.checkmark",
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "sum").map(\.id), ["summary", "copy"])
    }

    func testFilterMovesReadyActionsAheadOfDisabledActions() {
        let actions = [
            CommandPaletteAction(
                id: "copy",
                title: "Copy",
                subtitle: "Copy text",
                systemImage: "doc.on.doc",
                isEnabled: false,
                run: {}
            ),
            CommandPaletteAction(
                id: "read",
                title: "Read Selected Text",
                subtitle: "Use selected text",
                systemImage: "text.cursor",
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "").map(\.id), ["read", "copy"])
    }

    func testDisabledReasonDefaultsAndCanBeSet() {
        let defaultAction = CommandPaletteAction(
            id: "copy",
            title: "Copy",
            subtitle: "Copy text",
            systemImage: "doc.on.doc",
            isEnabled: false,
            run: {}
        )
        let customAction = CommandPaletteAction(
            id: "answer",
            title: "Copy Answer",
            subtitle: "Copy answer",
            systemImage: "doc.on.clipboard",
            isEnabled: false,
            disabledReason: "Needs answer",
            run: {}
        )

        XCTAssertEqual(defaultAction.disabledReason, "Not ready")
        XCTAssertEqual(customAction.disabledReason, "Needs answer")
    }

    func testDedicatedShortcutBadgeTitleSupportsLaunchRecoveryCard() {
        XCTAssertEqual(
            CommandPaletteAction.dedicatedShortcutBadgeTitle(
                for: "run-fame-launch-recovery-next"
            ),
            "⌥⌘R"
        )
        XCTAssertEqual(
            CommandPaletteAction.dedicatedShortcutBadgeTitle(
                for: "run-fame-auto-bundle-status"
            ),
            "⌥⌘O"
        )
        XCTAssertEqual(
            CommandPaletteAction.dedicatedShortcutBadgeTitle(
                for: "run-fame-launch-rescue-burst-auto-status"
            ),
            "⌥⌘L"
        )
        XCTAssertNil(
            CommandPaletteAction.dedicatedShortcutBadgeTitle(
                for: "run-fame-launch-alert"
            )
        )
    }

    func testDedicatedShortcutActionIDsStayDistinctAndStable() {
        XCTAssertEqual(
            CommandPaletteAction.launchRecoveryNextActionID,
            "run-fame-launch-recovery-next"
        )
        XCTAssertEqual(
            CommandPaletteAction.autoOpsBundleStatusActionID,
            "run-fame-auto-bundle-status"
        )
        XCTAssertEqual(
            CommandPaletteAction.launchRescueAutoStatusActionID,
            "run-fame-launch-rescue-burst-auto-status"
        )
        XCTAssertEqual(
            Set([
                CommandPaletteAction.launchRecoveryNextActionID,
                CommandPaletteAction.autoOpsBundleStatusActionID,
                CommandPaletteAction.launchRescueAutoStatusActionID
            ]).count,
            3
        )
    }

    func testSearchMatchesDisabledReason() {
        let actions = [
            CommandPaletteAction(
                id: "paste-answer",
                title: "Paste Answer",
                subtitle: "Paste answer into the front app",
                systemImage: "arrow.right.doc.on.clipboard",
                isEnabled: false,
                disabledReason: "Needs Accessibility",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-answer",
                title: "Copy Answer",
                subtitle: "Copy answer",
                systemImage: "doc.on.clipboard",
                run: {}
            )
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "needs accessibility").map(\.id), [
            "paste-answer"
        ])
    }

    func testUsageRanksOftenRunActions() {
        let actions = [
            CommandPaletteAction(id: "read", title: "Read", subtitle: "Speak text", systemImage: "speaker", run: {}),
            CommandPaletteAction(id: "copy", title: "Copy", subtitle: "Copy text", systemImage: "doc.on.doc", run: {}),
            CommandPaletteAction(id: "save", title: "Save", subtitle: "Save text", systemImage: "square.and.arrow.down", run: {})
        ]
        let records = [
            "read": CommandUsageRecord(useCount: 1, lastUsedAt: Date(timeIntervalSince1970: 300)),
            "copy": CommandUsageRecord(useCount: 2, lastUsedAt: Date(timeIntervalSince1970: 100)),
            "save": CommandUsageRecord(useCount: 1, lastUsedAt: Date(timeIntervalSince1970: 200))
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "", usageRecords: records).map(\.id), [
            "copy",
            "read",
            "save"
        ])
    }

    func testFavoritesRankBeforeUsageWhenSearchIsBlank() {
        let actions = [
            CommandPaletteAction(id: "read", title: "Read", subtitle: "Speak text", systemImage: "speaker", run: {}),
            CommandPaletteAction(id: "copy", title: "Copy", subtitle: "Copy text", systemImage: "doc.on.doc", run: {}),
            CommandPaletteAction(id: "save", title: "Save", subtitle: "Save text", systemImage: "square.and.arrow.down", run: {})
        ]
        let records = [
            "read": CommandUsageRecord(useCount: 50, lastUsedAt: Date(timeIntervalSince1970: 300))
        ]

        XCTAssertEqual(
            CommandPaletteAction.filter(
                actions,
                query: "",
                usageRecords: records,
                favoriteActionIDs: ["save"]
            ).map(\.id),
            ["save", "read", "copy"]
        )
    }

    func testFavoritesDoNotOverrideBetterSearchMatches() {
        let actions = [
            CommandPaletteAction(id: "read", title: "Read Text", subtitle: "Speak text", systemImage: "speaker", run: {}),
            CommandPaletteAction(
                id: "copy",
                title: "Copy Answer",
                subtitle: "Read the answer later",
                systemImage: "doc.on.doc",
                run: {}
            )
        ]

        XCTAssertEqual(
            CommandPaletteAction.filter(
                actions,
                query: "read",
                favoriteActionIDs: ["copy"]
            ).map(\.id),
            ["read", "copy"]
        )
    }

    func testTemporaryCommandsCannotBePinnedByFavorites() {
        let actions = [
            CommandPaletteAction(id: "read", title: "Read", subtitle: "Speak text", systemImage: "speaker", run: {}),
            CommandPaletteAction(
                id: "recent-1",
                title: "Recent: Text",
                subtitle: "Saved item",
                systemImage: "clock",
                canFavorite: false,
                run: {}
            )
        ]

        XCTAssertEqual(
            CommandPaletteAction.filter(actions, query: "", favoriteActionIDs: ["recent-1"]).map(\.id),
            ["read", "recent-1"]
        )
    }

    func testSearchQualityRanksBeforeUsageWhenQueryIsPresent() {
        let actions = [
            CommandPaletteAction(
                id: "copy",
                title: "Copy Answer",
                subtitle: "Copy answer",
                systemImage: "doc.on.clipboard",
                keywords: ["summary"],
                run: {}
            ),
            CommandPaletteAction(
                id: "summary",
                title: "Summary",
                subtitle: "Ask for a short summary",
                systemImage: "text.badge.checkmark",
                run: {}
            )
        ]
        let records = [
            "copy": CommandUsageRecord(useCount: 50, lastUsedAt: Date(timeIntervalSince1970: 300)),
            "summary": CommandUsageRecord(useCount: 1, lastUsedAt: Date(timeIntervalSince1970: 100))
        ]

        XCTAssertEqual(CommandPaletteAction.filter(actions, query: "sum", usageRecords: records).map(\.id), [
            "summary",
            "copy"
        ])
    }

    func testInlineAskActionUsesTypedQuestion() {
        var askedPrompt = ""
        let action = CommandPaletteInlineAsk.makeAction(query: "  What does this mean?  ") { prompt in
            askedPrompt = prompt
        }

        XCTAssertEqual(action?.id, "inline-ask")
        XCTAssertEqual(action?.title, "Ask: What does this mean?")
        XCTAssertEqual(action?.isEnabled, true)
        XCTAssertEqual(action?.canFavorite, false)

        action?.run()
        XCTAssertEqual(askedPrompt, "What does this mean?")
    }

    func testInlineAskActionSkipsVeryShortText() {
        XCTAssertNil(CommandPaletteInlineAsk.makeAction(query: "  a  ", run: { _ in }))
    }

    func testInlineAskActionDoesNotBeatStrongCommandMatch() throws {
        let readAction = CommandPaletteAction(
            id: "read",
            title: "Read Selected Text",
            subtitle: "Use selected text",
            systemImage: "text.cursor",
            run: {}
        )
        let askAction = try XCTUnwrap(CommandPaletteInlineAsk.makeAction(query: "read", run: { _ in }))

        XCTAssertEqual(CommandPaletteAction.filter([readAction, askAction], query: "read").map(\.id), [
            "read",
            "inline-ask"
        ])
    }

    func testActionResolvedGroupClassifiesCommonCommands() {
        let ask = CommandPaletteAction(
            id: "ask-anything",
            title: "Ask Anything",
            subtitle: "Type a one-off question",
            systemImage: "sparkles",
            run: {}
        )
        let textUtility = CommandPaletteAction(
            id: "base64-encode-clipboard",
            title: "Base64 Encode Clipboard",
            subtitle: "Encode clipboard text",
            systemImage: "chevron.left.forwardslash.chevron.right",
            run: {}
        )
        let saved = CommandPaletteAction(
            id: "save-selected-snippet",
            title: "Save Selected as Snippet",
            subtitle: "Store selected text",
            systemImage: "bookmark",
            run: {}
        )
        let open = CommandPaletteAction(
            id: "open-selected-url",
            title: "Open Selected URL",
            subtitle: "Open in the browser",
            systemImage: "link",
            run: {}
        )
        let settings = CommandPaletteAction(
            id: "screen-recording-settings",
            title: "Screen Recording Settings",
            subtitle: "Open macOS settings",
            systemImage: "lock.shield",
            run: {}
        )
        let support = CommandPaletteAction(
            id: "copy-issue-bundle",
            title: "Copy Issue Bundle",
            subtitle: "Copy safe bug details",
            systemImage: "ladybug",
            run: {}
        )
        let window = CommandPaletteAction(
            id: "window-left-half",
            title: "Window Left Half",
            subtitle: "Move the front window",
            systemImage: "rectangle.lefthalf.filled",
            run: {}
        )

        XCTAssertEqual(ask.resolvedGroup, .ask)
        XCTAssertEqual(textUtility.resolvedGroup, .text)
        XCTAssertEqual(saved.resolvedGroup, .saved)
        XCTAssertEqual(open.resolvedGroup, .open)
        XCTAssertEqual(settings.resolvedGroup, .settings)
        XCTAssertEqual(support.resolvedGroup, .support)
        XCTAssertEqual(window.resolvedGroup, .window)
    }

    func testActionGroupCanBeOverridden() {
        let action = CommandPaletteAction(
            id: "open-selected-url",
            title: "Open Selected URL",
            subtitle: "Open in the browser",
            systemImage: "link",
            group: .core,
            run: {}
        )

        XCTAssertEqual(action.resolvedGroup, .core)
    }

    func testFilterCanLimitResultsToSelectedGroup() {
        let actions = [
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask about text",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-answer",
                title: "Copy Answer",
                subtitle: "Copy result",
                systemImage: "doc.on.doc",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-selected-url",
                title: "Open Selected URL",
                subtitle: "Open in browser",
                systemImage: "link",
                run: {}
            )
        ]

        XCTAssertEqual(
            CommandPaletteAction.filter(actions, query: "", requiredGroup: .ask).map(\.id),
            ["ask-anything"]
        )
        XCTAssertEqual(
            CommandPaletteAction.filter(actions, query: "", requiredGroup: .open).map(\.id),
            ["open-selected-url"]
        )
    }

    func testFilterCanLimitResultsToSourceKinds() {
        let actions = [
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask about text",
                systemImage: "sparkles",
                sourceKind: .ask,
                run: {}
            ),
            CommandPaletteAction(
                id: "script-command",
                title: "Run Build Script",
                subtitle: "Run local script",
                systemImage: "terminal",
                sourceKind: .script,
                run: {}
            ),
            CommandPaletteAction(
                id: "quick-link",
                title: "Open Link",
                subtitle: "Open saved link",
                systemImage: "link",
                sourceKind: .link,
                run: {}
            ),
            CommandPaletteAction(
                id: "open-app",
                title: "Open App: Safari",
                subtitle: "Launch installed app",
                systemImage: "app.badge",
                sourceKind: .app,
                run: {}
            )
        ]

        XCTAssertEqual(
            CommandPaletteAction.filter(
                actions,
                query: "",
                requiredSourceKinds: [.script]
            ).map(\.id),
            ["script-command"]
        )
        XCTAssertEqual(
            CommandPaletteAction.filter(
                actions,
                query: "",
                requiredSourceKinds: [.link, .app]
            ).map(\.id),
            ["quick-link", "open-app"]
        )
    }

    func testFilterCanBoostPlatformActionsForSingleTermSearch() {
        let actions = [
            CommandPaletteAction(
                id: "prompt-notes",
                title: "Notes",
                subtitle: "Turn text into notes",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-notes-workspace",
                title: "Open Notes Workspace",
                subtitle: "Browse, edit, and pin saved notes",
                systemImage: "note.text",
                run: {}
            ),
            CommandPaletteAction(
                id: "import-extension-pack",
                title: "Import Extension Pack",
                subtitle: "Install a local script-extension pack",
                systemImage: "square.and.arrow.down.on.square",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-extensions-workspace",
                title: "Open Extensions Workspace",
                subtitle: "Browse AI commands and script commands",
                systemImage: "puzzlepiece.extension",
                run: {}
            )
        ]

        XCTAssertEqual(
            CommandPaletteAction.filter(
                actions,
                query: "notes",
                priorityActionIDs: Set(["open-notes-workspace"])
            ).first?.id,
            "open-notes-workspace"
        )

        XCTAssertEqual(
            CommandPaletteAction.filter(
                actions,
                query: "extension pack",
                priorityActionIDs: Set(["open-extensions-workspace"])
            ).first?.id,
            "import-extension-pack"
        )
    }

    func testScopedQueryParsingRecognizesGroupPrefixes() {
        let askScope = CommandPaletteGroup.parseScopedQuery("ask: rewrite this")
        let textScope = CommandPaletteGroup.parseScopedQuery("text/base64 encode")

        XCTAssertEqual(askScope.group, .ask)
        XCTAssertNil(askScope.sourceKinds)
        XCTAssertEqual(askScope.searchQuery, "rewrite this")
        XCTAssertEqual(askScope.hasScope, true)

        XCTAssertEqual(textScope.group, .text)
        XCTAssertNil(textScope.sourceKinds)
        XCTAssertEqual(textScope.searchQuery, "base64 encode")
        XCTAssertEqual(textScope.hasScope, true)
    }

    func testScopedQueryParsingSupportsAliases() {
        let quickAskScope = CommandPaletteGroup.parseScopedQuery("q: summarize")
        let questionAskScope = CommandPaletteGroup.parseScopedQuery("question: explain this")
        let copyScope = CommandPaletteGroup.parseScopedQuery("copy: quote")
        let calcScope = CommandPaletteGroup.parseScopedQuery("calc: 2 + 2")
        let pasteScope = CommandPaletteGroup.parseScopedQuery("paste: answer")
        let fileScope = CommandPaletteGroup.parseScopedQuery("file: downloads")
        let siteScope = CommandPaletteGroup.parseScopedQuery("site: openai")
        let docsScope = CommandPaletteGroup.parseScopedQuery("docs: ~/Desktop")
        let prefsScope = CommandPaletteGroup.parseScopedQuery("prefs: permission")
        let checklistScope = CommandPaletteGroup.parseScopedQuery("checklist: screen")
        let onboardingScope = CommandPaletteGroup.parseScopedQuery("onboarding: setup")
        let bugScope = CommandPaletteGroup.parseScopedQuery("bug: screenshot")
        let shareScope = CommandPaletteGroup.parseScopedQuery("share: recap")
        let socialScope = CommandPaletteGroup.parseScopedQuery("social: post")
        let postScope = CommandPaletteGroup.parseScopedQuery("post: x")
        let fameScope = CommandPaletteGroup.parseScopedQuery("fame: board")
        let viralScope = CommandPaletteGroup.parseScopedQuery("viral: hooks")
        let blockedScope = CommandPaletteGroup.parseScopedQuery("blocked: permission")
        let errorScope = CommandPaletteGroup.parseScopedQuery("error: stuck")
        let permScope = CommandPaletteGroup.parseScopedQuery("perm: accessibility")
        let grantScope = CommandPaletteGroup.parseScopedQuery("grant: screen")
        let fixScope = CommandPaletteGroup.parseScopedQuery("fix: paste")
        let repairScope = CommandPaletteGroup.parseScopedQuery("repair: pick")
        let snipScope = CommandPaletteGroup.parseScopedQuery("snip: pinned")
        let favScope = CommandPaletteGroup.parseScopedQuery("fav: pinned")
        let noteScope = CommandPaletteGroup.parseScopedQuery("note: meeting")
        let clipScope = CommandPaletteGroup.parseScopedQuery("clip: history")
        let tileScope = CommandPaletteGroup.parseScopedQuery("tile: left")
        let appScope = CommandPaletteGroup.parseScopedQuery("app: safari")
        let linkScope = CommandPaletteGroup.parseScopedQuery("link: docs")
        let scriptScope = CommandPaletteGroup.parseScopedQuery("script: build")

        XCTAssertEqual(quickAskScope.group, .ask)
        XCTAssertNil(quickAskScope.sourceKinds)
        XCTAssertEqual(quickAskScope.searchQuery, "summarize")
        XCTAssertEqual(quickAskScope.hasScope, true)

        XCTAssertEqual(questionAskScope.group, .ask)
        XCTAssertNil(questionAskScope.sourceKinds)
        XCTAssertEqual(questionAskScope.searchQuery, "explain this")
        XCTAssertEqual(questionAskScope.hasScope, true)

        XCTAssertEqual(copyScope.group, .text)
        XCTAssertNil(copyScope.sourceKinds)
        XCTAssertEqual(copyScope.searchQuery, "quote")
        XCTAssertEqual(copyScope.hasScope, true)

        XCTAssertEqual(calcScope.group, .text)
        XCTAssertNil(calcScope.sourceKinds)
        XCTAssertEqual(calcScope.searchQuery, "2 + 2")
        XCTAssertEqual(calcScope.hasScope, true)

        XCTAssertEqual(pasteScope.group, .text)
        XCTAssertNil(pasteScope.sourceKinds)
        XCTAssertEqual(pasteScope.searchQuery, "answer")
        XCTAssertEqual(pasteScope.hasScope, true)

        XCTAssertEqual(fileScope.group, .open)
        XCTAssertEqual(fileScope.sourceKinds, [.file, .path])
        XCTAssertEqual(fileScope.searchQuery, "downloads")
        XCTAssertEqual(fileScope.hasScope, true)

        XCTAssertEqual(siteScope.group, .open)
        XCTAssertEqual(siteScope.sourceKinds, [.web, .link])
        XCTAssertEqual(siteScope.searchQuery, "openai")
        XCTAssertEqual(siteScope.hasScope, true)

        XCTAssertEqual(docsScope.group, .open)
        XCTAssertEqual(docsScope.sourceKinds, [.file, .folder, .path])
        XCTAssertEqual(docsScope.searchQuery, "~/Desktop")
        XCTAssertEqual(docsScope.hasScope, true)

        XCTAssertEqual(prefsScope.group, .settings)
        XCTAssertNil(prefsScope.sourceKinds)
        XCTAssertEqual(prefsScope.searchQuery, "permission")
        XCTAssertEqual(prefsScope.hasScope, true)

        XCTAssertEqual(checklistScope.group, .settings)
        XCTAssertNil(checklistScope.sourceKinds)
        XCTAssertEqual(checklistScope.searchQuery, "screen")
        XCTAssertEqual(checklistScope.hasScope, true)

        XCTAssertEqual(onboardingScope.group, .settings)
        XCTAssertNil(onboardingScope.sourceKinds)
        XCTAssertEqual(onboardingScope.searchQuery, "setup")
        XCTAssertEqual(onboardingScope.hasScope, true)

        XCTAssertEqual(bugScope.group, .support)
        XCTAssertNil(bugScope.sourceKinds)
        XCTAssertEqual(bugScope.searchQuery, "screenshot")
        XCTAssertEqual(bugScope.hasScope, true)

        XCTAssertEqual(shareScope.group, .support)
        XCTAssertNil(shareScope.sourceKinds)
        XCTAssertEqual(shareScope.searchQuery, "recap")
        XCTAssertEqual(shareScope.hasScope, true)

        XCTAssertEqual(socialScope.group, .support)
        XCTAssertNil(socialScope.sourceKinds)
        XCTAssertEqual(socialScope.searchQuery, "post")
        XCTAssertEqual(socialScope.hasScope, true)

        XCTAssertEqual(postScope.group, .support)
        XCTAssertNil(postScope.sourceKinds)
        XCTAssertEqual(postScope.searchQuery, "x")
        XCTAssertEqual(postScope.hasScope, true)

        XCTAssertEqual(fameScope.group, .support)
        XCTAssertNil(fameScope.sourceKinds)
        XCTAssertEqual(fameScope.searchQuery, "board")
        XCTAssertEqual(fameScope.hasScope, true)

        XCTAssertEqual(viralScope.group, .support)
        XCTAssertNil(viralScope.sourceKinds)
        XCTAssertEqual(viralScope.searchQuery, "hooks")
        XCTAssertEqual(viralScope.hasScope, true)

        XCTAssertEqual(blockedScope.group, .support)
        XCTAssertNil(blockedScope.sourceKinds)
        XCTAssertEqual(blockedScope.searchQuery, "permission")
        XCTAssertEqual(blockedScope.hasScope, true)

        XCTAssertEqual(errorScope.group, .support)
        XCTAssertNil(errorScope.sourceKinds)
        XCTAssertEqual(errorScope.searchQuery, "stuck")
        XCTAssertEqual(errorScope.hasScope, true)

        XCTAssertEqual(permScope.group, .settings)
        XCTAssertNil(permScope.sourceKinds)
        XCTAssertEqual(permScope.searchQuery, "accessibility")
        XCTAssertEqual(permScope.hasScope, true)

        XCTAssertEqual(grantScope.group, .settings)
        XCTAssertNil(grantScope.sourceKinds)
        XCTAssertEqual(grantScope.searchQuery, "screen")
        XCTAssertEqual(grantScope.hasScope, true)

        XCTAssertEqual(fixScope.group, .support)
        XCTAssertNil(fixScope.sourceKinds)
        XCTAssertEqual(fixScope.searchQuery, "paste")
        XCTAssertEqual(fixScope.hasScope, true)

        XCTAssertEqual(repairScope.group, .support)
        XCTAssertNil(repairScope.sourceKinds)
        XCTAssertEqual(repairScope.searchQuery, "pick")
        XCTAssertEqual(repairScope.hasScope, true)

        XCTAssertEqual(snipScope.group, .saved)
        XCTAssertEqual(snipScope.sourceKinds, [.snippet])
        XCTAssertEqual(snipScope.searchQuery, "pinned")
        XCTAssertEqual(snipScope.hasScope, true)

        XCTAssertEqual(favScope.group, .saved)
        XCTAssertNil(favScope.sourceKinds)
        XCTAssertEqual(favScope.searchQuery, "pinned")
        XCTAssertEqual(favScope.hasScope, true)

        XCTAssertEqual(noteScope.group, .saved)
        XCTAssertEqual(noteScope.sourceKinds, [.snippet])
        XCTAssertEqual(noteScope.searchQuery, "meeting")
        XCTAssertEqual(noteScope.hasScope, true)

        XCTAssertEqual(clipScope.group, .saved)
        XCTAssertEqual(clipScope.sourceKinds, [.clipboard])
        XCTAssertEqual(clipScope.searchQuery, "history")
        XCTAssertEqual(clipScope.hasScope, true)

        XCTAssertEqual(tileScope.group, .window)
        XCTAssertNil(tileScope.sourceKinds)
        XCTAssertEqual(tileScope.searchQuery, "left")
        XCTAssertEqual(tileScope.hasScope, true)

        XCTAssertEqual(appScope.group, .open)
        XCTAssertEqual(appScope.sourceKinds, [.app])
        XCTAssertEqual(appScope.searchQuery, "safari")
        XCTAssertEqual(appScope.hasScope, true)

        XCTAssertEqual(linkScope.group, .saved)
        XCTAssertEqual(linkScope.sourceKinds, [.link])
        XCTAssertEqual(linkScope.searchQuery, "docs")
        XCTAssertEqual(linkScope.hasScope, true)

        XCTAssertNil(scriptScope.group)
        XCTAssertEqual(scriptScope.sourceKinds, [.script])
        XCTAssertEqual(scriptScope.searchQuery, "build")
        XCTAssertEqual(scriptScope.hasScope, true)
    }

    func testScopedQueryParsingSkipsRegularTimeAndURLInputs() {
        let timeQuery = CommandPaletteGroup.parseScopedQuery("09:00 UTC to local")
        let urlQuery = CommandPaletteGroup.parseScopedQuery("https://example.com/docs")

        XCTAssertNil(timeQuery.group)
        XCTAssertEqual(timeQuery.searchQuery, "09:00 UTC to local")
        XCTAssertEqual(timeQuery.hasScope, false)

        XCTAssertNil(urlQuery.group)
        XCTAssertEqual(urlQuery.searchQuery, "https://example.com/docs")
        XCTAssertEqual(urlQuery.hasScope, false)
    }

    func testGroupShortcutDigitsAreStable() {
        XCTAssertEqual(CommandPaletteGroup.core.shortcutDigit, 1)
        XCTAssertEqual(CommandPaletteGroup.ask.shortcutDigit, 2)
        XCTAssertEqual(CommandPaletteGroup.text.shortcutDigit, 3)
        XCTAssertEqual(CommandPaletteGroup.saved.shortcutDigit, 4)
        XCTAssertEqual(CommandPaletteGroup.open.shortcutDigit, 5)
        XCTAssertEqual(CommandPaletteGroup.window.shortcutDigit, 6)
        XCTAssertEqual(CommandPaletteGroup.settings.shortcutDigit, 7)
        XCTAssertEqual(CommandPaletteGroup.support.shortcutDigit, 8)
    }

    func testGroupLookupByShortcutDigit() {
        XCTAssertEqual(CommandPaletteGroup.group(forShortcutDigit: 1), .core)
        XCTAssertEqual(CommandPaletteGroup.group(forShortcutDigit: 2), .ask)
        XCTAssertEqual(CommandPaletteGroup.group(forShortcutDigit: 7), .settings)
        XCTAssertEqual(CommandPaletteGroup.group(forShortcutDigit: 8), .support)
        XCTAssertNil(CommandPaletteGroup.group(forShortcutDigit: 0))
        XCTAssertNil(CommandPaletteGroup.group(forShortcutDigit: 9))
    }

    func testTopPicksPrioritizeErrorRecoveryActions() {
        let actions = [
            CommandPaletteAction(
                id: "copy-troubleshooting-guide",
                title: "Copy Troubleshooting Guide",
                subtitle: "Troubleshoot",
                systemImage: "wrench",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-issue-bundle",
                title: "Copy Issue Bundle",
                subtitle: "Issue details",
                systemImage: "doc.text",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-error-message",
                title: "Copy Error Message",
                subtitle: "Copy error",
                systemImage: "exclamationmark.triangle",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read",
                systemImage: "text.cursor",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: true,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 3).map(\.id),
            ["copy-troubleshooting-guide", "copy-issue-bundle", "copy-error-message"]
        )
    }

    func testTopPicksSkipDisabledPreferredActions() {
        let actions = [
            CommandPaletteAction(
                id: "paste-answer",
                title: "Paste Answer",
                subtitle: "Paste answer",
                systemImage: "arrow.turn.down.right",
                isEnabled: false,
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-answer",
                title: "Copy Answer",
                subtitle: "Copy answer",
                systemImage: "doc.on.doc",
                run: {}
            ),
            CommandPaletteAction(
                id: "save-answer",
                title: "Save Answer",
                subtitle: "Save answer",
                systemImage: "square.and.arrow.down",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: true,
            hasImage: false,
            hasError: false,
            llmEnabled: true
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 2).map(\.id),
            ["copy-answer", "save-answer"]
        )
    }

    func testTopPicksCanPrioritizePromotedActionsAheadOfDefaultOrdering() {
        let actions = [
            CommandPaletteAction(
                id: "copy-troubleshooting-guide",
                title: "Copy Troubleshooting Guide",
                subtitle: "Troubleshoot",
                systemImage: "wrench",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-cadence-autopilot-loop",
                title: "Run Fame Cadence Autopilot Loop",
                subtitle: "Autopilot",
                systemImage: "bolt.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-issue-bundle",
                title: "Copy Issue Bundle",
                subtitle: "Issue details",
                systemImage: "doc.text",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: true,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(
                from: actions,
                context: context,
                promotedActionIDs: ["run-fame-cadence-autopilot-loop"],
                limit: 3
            ).map(\.id),
            ["run-fame-cadence-autopilot-loop", "copy-troubleshooting-guide", "copy-issue-bundle"]
        )
    }

    func testTopPicksPromotedActionsSkipMissingOrDisabledEntries() {
        let actions = [
            CommandPaletteAction(
                id: "copy-answer",
                title: "Copy Answer",
                subtitle: "Copy answer",
                systemImage: "doc.on.doc",
                run: {}
            ),
            CommandPaletteAction(
                id: "save-answer",
                title: "Save Answer",
                subtitle: "Save answer",
                systemImage: "square.and.arrow.down",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-cadence-autopilot-loop",
                title: "Run Fame Cadence Autopilot Loop",
                subtitle: "Autopilot",
                systemImage: "bolt.fill",
                isEnabled: false,
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: true,
            hasImage: false,
            hasError: false,
            llmEnabled: true
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(
                from: actions,
                context: context,
                promotedActionIDs: [
                    "run-fame-cadence-autopilot-loop",
                    "non-existent-action-id"
                ],
                limit: 2
            ).map(\.id),
            ["copy-answer", "save-answer"]
        )
    }

    func testTopPicksPriorityPromotedActionsCanRankAheadOfIdleFavorites() {
        let actions = [
            CommandPaletteAction(
                id: "copy-next-move-best-channel-launch-pack",
                title: "Copy Best Channel Launch Pack",
                subtitle: "Copy one-tap launch pack",
                systemImage: "star.bubble",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "settings",
                title: "Settings",
                subtitle: "Open settings",
                systemImage: "gearshape",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(
                from: actions,
                context: context,
                favoriteActionIDs: ["settings"],
                priorityPromotedActionIDs: ["copy-next-move-best-channel-launch-pack"],
                limit: 2
            ).map(\.id),
            ["copy-next-move-best-channel-launch-pack", "settings"]
        )
    }

    func testTopPicksHallOfFamePriorityPromotionCanRankRescueActionAheadOfIdleFavorites() {
        let actions = [
            CommandPaletteAction(
                id: "run-fame-next-move-copy-drafts",
                title: "Run Fame Next Move + Copy Drafts",
                subtitle: "Rescue next move",
                systemImage: "bolt.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-cadence-autopilot-loop",
                title: "Run Fame Cadence Autopilot Loop",
                subtitle: "Autopilot",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "settings",
                title: "Settings",
                subtitle: "Open settings",
                systemImage: "gearshape",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )
        let cue = CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue(
            tone: .defense,
            trend: .falling,
            title: "Hall of Fame Defense · Cooling",
            subtitle: "Week pace slipped. 2 more rescues to set record 8.",
            buttonTitle: "Stabilize Pace",
            systemImage: "thermometer.low",
            helpText: "stub"
        )
        let rescuePlan = CommandPaletteTopPicks.RecommendationPairRescuePlan(
            recommendedActionID: "run-fame-next-move-copy-drafts",
            opportunities: 8,
            conversions: 6,
            opensSinceLastConversion: 9,
            conversionRatePercent: 75
        )
        let priorityPromotedActionIDs = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFamePriorityPromotedActionIDs(
                cue: cue,
                rescuePlan: rescuePlan,
                enabledActionIDs: Set(actions.map(\.id))
            )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(
                from: actions,
                context: context,
                favoriteActionIDs: ["settings"],
                priorityPromotedActionIDs: priorityPromotedActionIDs,
                limit: 2
            ).map(\.id),
            ["run-fame-next-move-copy-drafts", "run-fame-cadence-autopilot-loop"]
        )
    }

    func testTopPicksTextContextIncludesLaunchPostWhenLLMEnabled() {
        let actions = [
            CommandPaletteAction(
                id: "prompt-summarize",
                title: "Summary",
                subtitle: "Ask for summary",
                systemImage: "text.badge.checkmark",
                run: {}
            ),
            CommandPaletteAction(
                id: "prompt-actions",
                title: "Action Items",
                subtitle: "Ask for action items",
                systemImage: "checklist",
                run: {}
            ),
            CommandPaletteAction(
                id: "prompt-launch-post",
                title: "Launch Post",
                subtitle: "Draft a launch post",
                systemImage: "megaphone.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-last-text",
                title: "Copy Last Text",
                subtitle: "Copy text",
                systemImage: "doc.on.doc",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: true,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: true
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 4).map(\.id),
            ["prompt-summarize", "prompt-actions", "prompt-launch-post", "ask-anything"]
        )
    }

    func testTopPicksFallbackToEnabledRankingOrder() {
        let actions = [
            CommandPaletteAction(
                id: "custom-1",
                title: "Custom One",
                subtitle: "First",
                systemImage: "1.square",
                run: {}
            ),
            CommandPaletteAction(
                id: "custom-2",
                title: "Custom Two",
                subtitle: "Second",
                systemImage: "2.square",
                run: {}
            ),
            CommandPaletteAction(
                id: "custom-3",
                title: "Custom Three",
                subtitle: "Third",
                systemImage: "3.square",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 2).map(\.id),
            ["custom-1", "custom-2"]
        )
    }

    func testTopPicksIdleStateIncludesShareCardWhenAvailable() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-win-card",
                title: "Copy Win Card",
                subtitle: "Copy visual share card",
                systemImage: "photo",
                run: {}
            ),
            CommandPaletteAction(
                id: "show-reader",
                title: "Show Reader",
                subtitle: "Open reader window",
                systemImage: "macwindow",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 4).map(\.id),
            ["pick-and-read", "read-selected", "ask-anything", "copy-win-card"]
        )
    }

    func testTopPicksIdleStatePrefersFamePackWhenAvailable() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-sprint",
                title: "Run Fame Sprint",
                subtitle: "Generate and copy today's sprint plan",
                systemImage: "bolt.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-fame-pack",
                title: "Copy Fame Pack",
                subtitle: "Copy complete fame execution pack",
                systemImage: "shippingbox",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-win-card",
                title: "Copy Win Card",
                subtitle: "Copy visual share card",
                systemImage: "photo",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 4).map(\.id),
            ["pick-and-read", "read-selected", "ask-anything", "run-fame-sprint"]
        )
    }

    func testTopPicksIdleStateCanSurfaceFounderPresetsAndSavePack() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-fame-pack",
                title: "Copy Fame Pack",
                subtitle: "Copy complete fame execution pack",
                systemImage: "shippingbox",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-founder-command-presets",
                title: "Copy Founder Presets",
                subtitle: "Copy weekly KPI + fame command stack",
                systemImage: "chart.line.uptrend.xyaxis",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-win-card",
                title: "Copy Win Card",
                subtitle: "Copy visual share card",
                systemImage: "photo",
                run: {}
            ),
            CommandPaletteAction(
                id: "save-fame-pack",
                title: "Save Fame Pack",
                subtitle: "Save complete fame execution pack",
                systemImage: "square.and.arrow.down.on.square",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 7).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "copy-fame-pack",
                "copy-founder-command-presets",
                "copy-win-card",
                "save-fame-pack"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceRunSprintSnapshot() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-sprint",
                title: "Run Fame Sprint",
                subtitle: "Generate and copy today's sprint plan",
                systemImage: "bolt.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-sprint-snapshot",
                title: "Run Fame Sprint + Save Snapshot",
                subtitle: "Generate today's plan and save snapshot files",
                systemImage: "internaldrive",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-fame-pack",
                title: "Copy Fame Pack",
                subtitle: "Copy complete fame execution pack",
                systemImage: "shippingbox",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            ["pick-and-read", "read-selected", "ask-anything", "run-fame-sprint", "run-fame-sprint-snapshot"]
        )
    }

    func testTopPicksIdleStateCanIncludeOpenSnapshotFolder() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-sprint",
                title: "Run Fame Sprint",
                subtitle: "Generate and copy today's sprint plan",
                systemImage: "bolt.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-sprint-snapshot",
                title: "Run Fame Sprint + Save Snapshot",
                subtitle: "Generate today's plan and save snapshot files",
                systemImage: "internaldrive",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-morning-brief",
                title: "Run Morning Fame Brief",
                subtitle: "Generate and save launch-ready morning brief",
                systemImage: "sun.max.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-weekly-rollup",
                title: "Run Weekly Fame Rollup",
                subtitle: "Generate weekly summary + best experiments",
                systemImage: "chart.line.text.clipboard",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-24h-queue",
                title: "Run Daily Fame Mission",
                subtitle: "Generate next 3h mission",
                systemImage: "list.bullet.clipboard",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-command-center",
                title: "Run Fame Command Center",
                subtitle: "Generate and save a 72h fame operator brief",
                systemImage: "gauge.open.with.lines.needle.33percent",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-daily-checkpoint",
                title: "Run Daily Fame Checkpoint",
                subtitle: "Generate and save KPI delta checkpoint",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-daily-scorecard",
                title: "Run Daily Fame Scorecard",
                subtitle: "Generate and save risk + delta scorecard",
                systemImage: "chart.xyaxis.line",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-operator-dashboard",
                title: "Run Fame Operator Dashboard",
                subtitle: "Generate and save unified pulse + scorecard ops view",
                systemImage: "gauge.open.with.lines.needle.33percent",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-pulse-nudge",
                title: "Run Fame Pulse Nudge",
                subtitle: "Generate streak + must-ship alert",
                systemImage: "bolt.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-fame-snapshot-folder",
                title: "Open Fame Snapshot Folder",
                subtitle: "Reveal saved sprint snapshots",
                systemImage: "folder",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 14).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-sprint",
                "run-fame-sprint-snapshot",
                "run-fame-morning-brief",
                "run-fame-weekly-rollup",
                "run-fame-24h-queue",
                "run-fame-command-center",
                "run-fame-daily-checkpoint",
                "run-fame-daily-scorecard",
                "run-fame-operator-dashboard",
                "run-fame-pulse-nudge",
                "open-fame-snapshot-folder"
            ]
        )
    }

    func testTopPicksIdleStateCanIncludeMiddayAndEveningBriefs() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-morning-brief",
                title: "Run Morning Fame Brief",
                subtitle: "Generate and save launch-ready morning brief",
                systemImage: "sun.max.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-midday-brief",
                title: "Run Midday Fame Brief",
                subtitle: "Generate and save adaptive midday operator brief",
                systemImage: "sun.max.circle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-evening-brief",
                title: "Run Evening Fame Brief",
                subtitle: "Generate and save closeout + tomorrow launch brief",
                systemImage: "moon.stars.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-morning-brief",
                title: "Open Latest Morning Brief",
                subtitle: "Reveal latest saved morning launch brief",
                systemImage: "sun.max",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-midday-brief",
                title: "Open Latest Midday Brief",
                subtitle: "Reveal latest saved midday operator brief",
                systemImage: "sun.max.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-evening-brief",
                title: "Open Latest Evening Brief",
                subtitle: "Reveal latest saved evening closeout brief",
                systemImage: "moon.stars",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 9).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-morning-brief",
                "run-fame-midday-brief",
                "run-fame-evening-brief",
                "open-latest-morning-brief",
                "open-latest-midday-brief",
                "open-latest-evening-brief"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceEscalationNudgeActions() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-daily-scorecard",
                title: "Run Daily Fame Scorecard",
                subtitle: "Generate and save risk + delta scorecard",
                systemImage: "chart.xyaxis.line",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-escalation-nudge",
                title: "Run Fame Escalation Nudge",
                subtitle: "Generate and save recovery nudge for risk transitions",
                systemImage: "exclamationmark.triangle.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-escalation-nudge",
                title: "Open Latest Escalation Nudge",
                subtitle: "Reveal latest saved risk-escalation recovery nudge",
                systemImage: "exclamationmark.triangle.badge.clock",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 6).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-daily-scorecard",
                "run-fame-escalation-nudge",
                "open-latest-escalation-nudge"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceRecoveryChecklistActions() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-recovery-sprint",
                title: "Run Fame Recovery Sprint",
                subtitle: "Generate and save a 6h must-ship recovery plan",
                systemImage: "flame.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-recovery-checklist",
                title: "Run 2h Recovery Checklist",
                subtitle: "Generate and save the next 2h recovery execution checklist",
                systemImage: "checklist.checked",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-recovery-sprint",
                title: "Open Latest Recovery Sprint",
                subtitle: "Reveal latest saved must-ship recovery plan",
                systemImage: "clock.arrow.circlepath",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-recovery-checklist",
                title: "Open Latest Recovery Checklist",
                subtitle: "Reveal latest saved 2h recovery execution checklist",
                systemImage: "checklist.checked",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 7).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-recovery-sprint",
                "run-fame-recovery-checklist",
                "open-latest-recovery-sprint",
                "open-latest-recovery-checklist"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceRecoveryProofPackActions() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-recovery-checklist",
                title: "Run 2h Recovery Checklist",
                subtitle: "Generate and save the next 2h recovery execution checklist",
                systemImage: "checklist.checked",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-recovery-proof-pack",
                title: "Run Recovery Proof Pack",
                subtitle: "Generate and save post/reply/checkpoint recovery snippets",
                systemImage: "text.badge.checkmark",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-recovery-checklist",
                title: "Open Latest Recovery Checklist",
                subtitle: "Reveal latest saved 2h recovery execution checklist",
                systemImage: "checklist.checked",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-recovery-proof-pack",
                title: "Open Latest Recovery Proof Pack",
                subtitle: "Reveal latest saved recovery post/reply proof pack",
                systemImage: "text.badge.checkmark",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 7).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-recovery-checklist",
                "run-fame-recovery-proof-pack",
                "open-latest-recovery-checklist",
                "open-latest-recovery-proof-pack"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceLatestOpsArtifactOpeners() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-command-center",
                title: "Open Latest Command Center",
                subtitle: "Reveal latest saved 72h fame operator brief",
                systemImage: "gauge.open.with.lines.needle.33percent",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-next-move-handoff",
                title: "Open Latest Next Move Handoff",
                subtitle: "Reveal latest saved founder next-move handoff",
                systemImage: "paperplane",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-next-move-draft-pack",
                title: "Open Latest Next Move Draft Pack",
                subtitle: "Reveal latest saved founder next-move draft pack",
                systemImage: "doc.text",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-drafts",
                title: "Copy Next-Move Draft Pack",
                subtitle: "X + LinkedIn + checklist",
                systemImage: "doc.on.doc",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-launch-now-sequence",
                title: "Copy Launch Now Sequence",
                subtitle: "Cadence step + next two channel drafts",
                systemImage: "bolt.horizontal.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-execution-kit",
                title: "Copy Cadence Execution Kit",
                subtitle: "Copy post + open queue + reply ladder",
                systemImage: "rocket",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-post-queue",
                title: "Copy Post Cadence + Queue",
                subtitle: "Copy cadence draft + open 30m posting checklist",
                systemImage: "paperplane.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-reply-ladder",
                title: "Copy Next-Move Reply Ladder",
                subtitle: "Copy 5 ready replies for the first 30m",
                systemImage: "text.bubble",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-post",
                title: "Copy Post Cadence Now",
                subtitle: "Copy first cadence draft only",
                systemImage: "paperplane.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-step",
                title: "Copy First Cadence Step",
                subtitle: "Copy recommended 0-15m post block",
                systemImage: "bolt.badge.a",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-daily-checkpoint",
                title: "Open Latest Daily Checkpoint",
                subtitle: "Reveal latest saved KPI delta checkpoint",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-risk-timeline",
                title: "Open Latest Risk Timeline",
                subtitle: "Reveal latest saved pulse-risk transition timeline",
                systemImage: "waveform.path.ecg",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-pulse-nudge",
                title: "Open Latest Pulse Nudge",
                subtitle: "Reveal latest saved streak + must-ship alert",
                systemImage: "bolt.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-daily-scorecard",
                title: "Open Latest Daily Scorecard",
                subtitle: "Reveal latest saved risk + delta scorecard",
                systemImage: "chart.xyaxis.line",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 12).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "open-latest-command-center",
                "open-latest-next-move-handoff",
                "copy-next-move-launch-now-sequence",
                "copy-next-move-cadence-execution-kit",
                "copy-next-move-cadence-post-queue",
                "copy-next-move-reply-ladder",
                "copy-next-move-cadence-post",
                "copy-next-move-drafts",
                "open-latest-daily-checkpoint"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizePulseAlertCard() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-pulse-alert",
                title: "Fame Pulse Alert: MUST SHIP",
                subtitle: "Risk Critical · MUST SHIP in next 2h",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-sprint",
                title: "Run Fame Sprint",
                subtitle: "Generate and copy today's sprint plan",
                systemImage: "bolt.circle",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            ["pick-and-read", "read-selected", "ask-anything", "run-fame-pulse-alert", "run-fame-sprint"]
        )
    }

    func testTopPicksIdleStateCanPrioritizeRecoverySprint() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-recovery-sprint",
                title: "Run Fame Recovery Sprint",
                subtitle: "Generate and save a 6h must-ship recovery plan",
                systemImage: "flame.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-sprint",
                title: "Run Fame Sprint",
                subtitle: "Generate and copy today's sprint plan",
                systemImage: "bolt.circle",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            ["pick-and-read", "read-selected", "ask-anything", "run-fame-recovery-sprint", "run-fame-sprint"]
        )
    }

    func testTopPicksIdleStateCanSurfaceRiskTimelineAndLatestRecoveryOpen() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-recovery-sprint",
                title: "Run Fame Recovery Sprint",
                subtitle: "Generate and save a 6h must-ship recovery plan",
                systemImage: "flame.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-risk-timeline",
                title: "Run Fame Risk Timeline",
                subtitle: "Generate and save pulse-risk transition timeline",
                systemImage: "waveform.path.ecg",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-recovery-sprint",
                title: "Open Latest Recovery Sprint",
                subtitle: "Reveal latest saved must-ship recovery plan",
                systemImage: "clock.arrow.circlepath",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-daily-scorecard",
                title: "Open Latest Daily Scorecard",
                subtitle: "Reveal latest saved risk + delta scorecard",
                systemImage: "chart.xyaxis.line",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-operator-dashboard",
                title: "Open Latest Operator Dashboard",
                subtitle: "Reveal latest saved unified fame ops dashboard",
                systemImage: "chart.bar.doc.horizontal",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-morning-brief",
                title: "Open Latest Morning Brief",
                subtitle: "Reveal latest saved morning launch brief",
                systemImage: "sun.max",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 9).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-recovery-sprint",
                "run-fame-risk-timeline",
                "open-latest-recovery-sprint",
                "open-latest-daily-scorecard",
                "open-latest-operator-dashboard",
                "open-latest-morning-brief"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceRunOpsBundle() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-command-center",
                title: "Run Fame Command Center",
                subtitle: "Generate and save a 72h fame operator brief",
                systemImage: "gauge.open.with.lines.needle.33percent",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-ops-bundle",
                title: "Run Fame Ops Bundle",
                subtitle: "Generate and save command center + checkpoint + timeline + pulse nudge",
                systemImage: "shippingbox.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-daily-checkpoint",
                title: "Run Daily Fame Checkpoint",
                subtitle: "Generate and save KPI delta checkpoint",
                systemImage: "calendar.badge.clock",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 6).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-command-center",
                "run-fame-ops-bundle",
                "run-fame-daily-checkpoint"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceAutoBundleStatusAction() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-command-center",
                title: "Run Fame Command Center",
                subtitle: "Generate and save a 72h fame operator brief",
                systemImage: "gauge.open.with.lines.needle.33percent",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-auto-bundle-status",
                title: "Fame Auto Bundle: Run Now",
                subtitle: "Auto bundle is ready on escalation. Run once now.",
                systemImage: "shippingbox.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-ops-bundle",
                title: "Run Fame Ops Bundle",
                subtitle: "Generate and save command center + checkpoint + timeline + pulse nudge",
                systemImage: "shippingbox.circle",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 6).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-command-center",
                "run-fame-auto-bundle-status",
                "run-fame-ops-bundle"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceLaunchRescueAutoStatusAction() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-rescue-burst",
                title: "Run Launch Rescue Burst",
                subtitle: "Generate launch countdown + next-move handoff + recovery checklist",
                systemImage: "bolt.shield",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-rescue-burst-auto-status",
                title: "Launch Rescue Auto: Run Now",
                subtitle: "Launch rescue auto-burst is ready on launch escalation. Run once now.",
                systemImage: "bolt.shield",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-operator-dashboard",
                title: "Run Fame Operator Dashboard",
                subtitle: "Generate operator dashboard",
                systemImage: "gauge.open.with.lines.needle.33percent",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 6).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-rescue-burst",
                "run-fame-launch-rescue-burst-auto-status",
                "run-fame-operator-dashboard"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceLaunchControlBriefAction() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-rescue-burst",
                title: "Run Launch Rescue Burst",
                subtitle: "Generate launch countdown + next-move handoff + recovery checklist",
                systemImage: "bolt.shield",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-fame-launch-control-brief",
                title: "Copy Launch Control Brief",
                subtitle: "Copy live launch alert + rescue + threshold status brief",
                systemImage: "list.bullet.rectangle.portrait",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-operator-dashboard",
                title: "Run Fame Operator Dashboard",
                subtitle: "Generate operator dashboard",
                systemImage: "gauge.open.with.lines.needle.33percent",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 6).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-rescue-burst",
                "copy-fame-launch-control-brief",
                "run-fame-operator-dashboard"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceRunLaunchControlBriefAction() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-rescue-burst",
                title: "Run Launch Rescue Burst",
                subtitle: "Generate launch countdown + next-move handoff + recovery checklist",
                systemImage: "bolt.shield",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-control-brief",
                title: "Run Launch Control Brief",
                subtitle: "Refresh launch countdown + save + copy launch control brief",
                systemImage: "list.bullet.rectangle.portrait",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-fame-launch-control-brief",
                title: "Copy Launch Control Brief",
                subtitle: "Copy live launch alert + rescue + threshold status brief",
                systemImage: "list.bullet.rectangle.portrait",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 6).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-rescue-burst",
                "run-fame-launch-control-brief",
                "copy-fame-launch-control-brief"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceOpenLatestLaunchControlBriefAction() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-launch-rescue-burst",
                title: "Open Latest Launch Rescue Burst",
                subtitle: "Open latest launch rescue burst",
                systemImage: "bolt.shield",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-launch-control-brief",
                title: "Open Latest Launch Control Brief",
                subtitle: "Open latest launch control brief",
                systemImage: "list.bullet.rectangle.portrait",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "open-latest-launch-rescue-burst",
                "open-latest-launch-control-brief"
            ]
        )
    }

    func testTopPicksIdleStateCanShowFameBoardAfterShareCard() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-win-card",
                title: "Copy Win Card",
                subtitle: "Copy visual share card",
                systemImage: "photo",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-experiment-board",
                title: "Copy Fame Board",
                subtitle: "Copy weekly fame board",
                systemImage: "chart.bar.doc.horizontal",
                run: {}
            ),
            CommandPaletteAction(
                id: "setup-checklist",
                title: "Setup Checklist",
                subtitle: "Open setup guide",
                systemImage: "checklist",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            ["pick-and-read", "read-selected", "ask-anything", "copy-win-card", "copy-experiment-board"]
        )
    }

    func testTopPicksIdleStateCanPrioritizeFameNextMove() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-cadence-execution-kit",
                title: "Run Next Move + Cadence Execution Kit",
                subtitle: "Execute Recovery Sprint, then copy cadence post + open queue + reply ladder",
                systemImage: "rocket.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-copy-drafts",
                title: "Run Next Move + Copy Draft Pack",
                subtitle: "Execute Recovery Sprint, then copy ranked drafts + follow-ups + hook variants + cadence",
                systemImage: "paperplane.circle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-pulse-alert",
                title: "Fame Pulse Alert",
                subtitle: "Risk is high",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-command-center",
                title: "Run Fame Command Center",
                subtitle: "Generate and save a 72h fame operator brief",
                systemImage: "gauge.open.with.lines.needle.33percent",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 9).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-next-move",
                "run-fame-next-move-cadence-execution-kit",
                "run-fame-next-move-copy-drafts",
                "run-fame-pulse-alert",
                "run-fame-command-center"
            ]
        )
    }

    func testTopPicksIdleStateSurfacesCadenceAutopilotBeforeExecutionHelpers() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-cadence-autopilot-loop",
                title: "Run Cadence Autopilot Loop (x4)",
                subtitle: "Next Recovery Sprint · push to x5 in 1 run",
                systemImage: "bolt.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-cadence-execution-kit",
                title: "Run Next Move + Cadence Execution Kit",
                subtitle: "Execute Recovery Sprint, then copy cadence post + open queue + reply ladder",
                systemImage: "rocket.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-copy-drafts",
                title: "Run Next Move + Copy Draft Pack",
                subtitle: "Execute Recovery Sprint, then copy ranked drafts + follow-ups + hook variants + cadence",
                systemImage: "paperplane.circle.fill",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 7).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-next-move",
                "run-fame-cadence-autopilot-loop",
                "run-fame-next-move-cadence-execution-kit",
                "run-fame-next-move-copy-drafts"
            ]
        )
    }

    func testTopPicksIdleStateSurfacesCelebrationDemoAfterMomentumBrief() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-cadence-autopilot-loop",
                title: "Run Cadence Autopilot Loop (x4)",
                subtitle: "Next Recovery Sprint · push to x5 in 1 run",
                systemImage: "bolt.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-cadence-execution-kit",
                title: "Run Next Move + Cadence Execution Kit",
                subtitle: "Execute Recovery Sprint, then copy cadence post + open queue + reply ladder",
                systemImage: "rocket.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-cadence-momentum-brief",
                title: "Run Cadence Momentum Brief",
                subtitle: "Streak x4 · Next Recovery Sprint · save + copy brief",
                systemImage: "bolt.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-fame-cadence-share-line",
                title: "Copy Cadence Share Line",
                subtitle: "Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Next Recovery Sprint · copy share line",
                systemImage: "quote.bubble",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-fame-cadence-share-pack",
                title: "Copy Cadence Share Pack",
                subtitle: "Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Next Recovery Sprint · short + standard + hype",
                systemImage: "text.justify",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-cadence-celebration-demo",
                title: "Run Cadence Celebration Demo",
                subtitle: "Streak x4 · current Balanced · preview Calm/Balanced/Epic before x5",
                systemImage: "sparkles",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 10).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-next-move",
                "run-fame-cadence-autopilot-loop",
                "run-fame-next-move-cadence-execution-kit",
                "run-fame-cadence-momentum-brief",
                "copy-fame-cadence-share-line",
                "copy-fame-cadence-share-pack",
                "run-fame-cadence-celebration-demo"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeOnboardingNudgeInFirstWeek() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-onboarding-nudge",
                title: "Fame Onboarding Day 3: Momentum",
                subtitle: "Day 3/7 · Push the streak to the next milestone before the day closes. · Start with Run Cadence Autopilot Loop",
                systemImage: "sparkles.rectangle.stack",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-onboarding-nudge",
                "run-fame-next-move"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeOnboardingScorecardBeforeNudge() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-onboarding-scorecard",
                title: "Run First-Week Fame Scorecard (Day 3/7)",
                subtitle: "Day 3/7 · Progress 2/7 (5 left) · Next Run Cadence Autopilot Loop",
                systemImage: "chart.bar.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-onboarding-nudge",
                title: "Fame Onboarding Day 3: Momentum",
                subtitle: "Day 3/7 · Progress 2/7 (5 left) · Push the streak to the next milestone before the day closes. · Start with Run Cadence Autopilot Loop",
                systemImage: "sparkles.rectangle.stack",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 6).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-onboarding-scorecard",
                "run-fame-onboarding-nudge",
                "run-fame-next-move"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeOnboardingDailyBriefAndOpenLatestArtifacts() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-onboarding-fill-gap",
                title: "Fill Onboarding Gap: Daily Brief",
                subtitle: "Missing 2/3: daily brief, scorecard · Day 3/7 · updated 2h ago · Next Run First-Week Daily Brief",
                systemImage: "sparkles.square.filled.on.square",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-onboarding-daily-brief",
                title: "Run First-Week Daily Brief (Day 3/7)",
                subtitle: "Day 3/7 · Progress 2/7 (5 left) · Save nudge + scorecard + daily brief · Next Run Cadence Autopilot Loop",
                systemImage: "square.stack.3d.up.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-onboarding-scorecard",
                title: "Run First-Week Fame Scorecard (Day 3/7)",
                subtitle: "Day 3/7 · Progress 2/7 (5 left) · Next Run Cadence Autopilot Loop",
                systemImage: "chart.bar.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-onboarding-nudge",
                title: "Fame Onboarding Day 3: Momentum",
                subtitle: "Day 3/7 · Progress 2/7 (5 left) · Push the streak to the next milestone before the day closes. · Start with Run Cadence Autopilot Loop",
                systemImage: "sparkles.rectangle.stack",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-onboarding-suite",
                title: "Open First-Week Onboarding Hub",
                subtitle: "Open latest daily brief + scorecard + nudge",
                systemImage: "square.stack.3d.up.badge.a",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-onboarding-daily-brief",
                title: "Open Latest First-Week Daily Brief",
                subtitle: "Open latest first-week daily brief",
                systemImage: "square.stack.3d.up.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-onboarding-scorecard",
                title: "Open Latest First-Week Fame Scorecard",
                subtitle: "Open latest first-week onboarding scorecard",
                systemImage: "chart.bar.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-onboarding-nudge",
                title: "Open Latest Fame Onboarding Nudge",
                subtitle: "Open latest first-week onboarding nudge",
                systemImage: "sparkles.rectangle.stack",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 8).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-onboarding-fill-gap",
                "run-fame-onboarding-daily-brief",
                "run-fame-onboarding-scorecard",
                "run-fame-onboarding-nudge",
                "open-latest-onboarding-suite"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeChannelDraftCopiesWhenPulseAlertIsActive() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-copy-drafts",
                title: "Run Next Move + Copy Draft Pack",
                subtitle: "Execute and save ranked drafts",
                systemImage: "paperplane.circle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-pulse-alert",
                title: "Fame Pulse Alert: MUST SHIP",
                subtitle: "Risk Critical · MUST SHIP in next 2h",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-launch-now-sequence",
                title: "Copy Launch Now Sequence",
                subtitle: "Cadence step + next two channel drafts",
                systemImage: "bolt.horizontal.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-execution-kit",
                title: "Copy Cadence Execution Kit",
                subtitle: "Copy post + open queue + reply ladder",
                systemImage: "rocket",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-post-queue",
                title: "Copy Post Cadence + Queue",
                subtitle: "Copy cadence draft + open 30m posting checklist",
                systemImage: "paperplane.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-reply-ladder",
                title: "Copy Next-Move Reply Ladder",
                subtitle: "Copy 5 ready replies for the first 30m",
                systemImage: "text.bubble",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-post",
                title: "Copy Post Cadence Now",
                subtitle: "Copy first cadence draft only",
                systemImage: "paperplane.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-step",
                title: "Copy First Cadence Step",
                subtitle: "Copy recommended 0-15m post block",
                systemImage: "bolt.badge.a",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-x-draft",
                title: "Copy Next-Move X Draft",
                subtitle: "Copy latest X draft from handoff",
                systemImage: "x.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-bluesky-draft",
                title: "Copy Next-Move Bluesky Draft",
                subtitle: "Copy latest Bluesky draft from handoff",
                systemImage: "cloud",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-linkedin-draft",
                title: "Copy Next-Move LinkedIn Draft",
                subtitle: "Copy latest LinkedIn draft from handoff",
                systemImage: "briefcase",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-drafts",
                title: "Copy Next-Move Draft Pack",
                subtitle: "Copy full channel draft pack",
                systemImage: "doc.on.doc",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-sprint",
                title: "Run Fame Sprint",
                subtitle: "Generate and copy today's sprint plan",
                systemImage: "bolt.circle",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 16).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-next-move",
                "run-fame-next-move-copy-drafts",
                "run-fame-pulse-alert",
                "copy-next-move-launch-now-sequence",
                "copy-next-move-cadence-execution-kit",
                "copy-next-move-cadence-post-queue",
                "copy-next-move-reply-ladder",
                "copy-next-move-cadence-post",
                "copy-next-move-cadence-step",
                "copy-next-move-x-draft",
                "copy-next-move-bluesky-draft",
                "copy-next-move-linkedin-draft",
                "copy-next-move-drafts"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeBestChannelDraftWhenPulseAlertIsActive() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-copy-drafts",
                title: "Run Next Move + Copy Draft Pack",
                subtitle: "Execute and save ranked drafts",
                systemImage: "paperplane.circle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-pulse-alert",
                title: "Fame Pulse Alert: MUST SHIP",
                subtitle: "Risk Critical · MUST SHIP in next 2h",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-step",
                title: "Copy First Cadence Step",
                subtitle: "Copy recommended 0-15m post block",
                systemImage: "bolt.badge.a",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-best-channel-draft",
                title: "Copy Best Channel Draft",
                subtitle: "Copy first cadence channel draft from handoff",
                systemImage: "star.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-x-draft",
                title: "Copy Next-Move X Draft",
                subtitle: "Copy latest X draft from handoff",
                systemImage: "x.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-bluesky-draft",
                title: "Copy Next-Move Bluesky Draft",
                subtitle: "Copy latest Bluesky draft from handoff",
                systemImage: "cloud",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-linkedin-draft",
                title: "Copy Next-Move LinkedIn Draft",
                subtitle: "Copy latest LinkedIn draft from handoff",
                systemImage: "briefcase",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 11).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-next-move",
                "run-fame-next-move-copy-drafts",
                "run-fame-pulse-alert",
                "copy-next-move-cadence-step",
                "copy-next-move-best-channel-draft",
                "copy-next-move-x-draft",
                "copy-next-move-bluesky-draft",
                "copy-next-move-linkedin-draft"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeBestChannelLaunchPackWhenPulseAlertIsActive() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-copy-drafts",
                title: "Run Next Move + Copy Draft Pack",
                subtitle: "Execute and save ranked drafts",
                systemImage: "paperplane.circle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-pulse-alert",
                title: "Fame Pulse Alert: MUST SHIP",
                subtitle: "Risk Critical · MUST SHIP in next 2h",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-best-channel-launch-pack",
                title: "Copy Best Channel Launch Pack",
                subtitle: "Best channel now: X · copy post + launch pack",
                systemImage: "star.bubble",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-best-channel-draft",
                title: "Copy Best Channel Draft",
                subtitle: "Best channel now: X · copy first cadence draft",
                systemImage: "star.circle",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 8).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-next-move",
                "run-fame-next-move-copy-drafts",
                "run-fame-pulse-alert",
                "copy-next-move-best-channel-launch-pack",
                "copy-next-move-best-channel-draft"
            ]
        )
    }

    func testTopPicksIdleStatePromotesCadenceAutopilotAfterPulseAlert() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-cadence-autopilot-loop",
                title: "Run Cadence Recovery Loop",
                subtitle: "Best x6 saved · restart with Recovery Sprint + execution kit",
                systemImage: "arrow.counterclockwise.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-copy-drafts",
                title: "Run Next Move + Copy Draft Pack",
                subtitle: "Execute and save ranked drafts",
                systemImage: "paperplane.circle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-pulse-alert",
                title: "Fame Pulse Alert: MUST SHIP",
                subtitle: "Risk Critical · MUST SHIP in next 2h",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-execution-kit",
                title: "Copy Cadence Execution Kit",
                subtitle: "Copy post + open queue + reply ladder",
                systemImage: "rocket",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-post",
                title: "Copy Post Cadence Now",
                subtitle: "Copy first cadence draft only",
                systemImage: "paperplane.badge.clock",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 9).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-next-move",
                "run-fame-next-move-copy-drafts",
                "run-fame-pulse-alert",
                "run-fame-cadence-autopilot-loop",
                "copy-next-move-cadence-execution-kit",
                "copy-next-move-cadence-post"
            ]
        )
    }

    func testTopPicksIdleStateKeepsPulseAlertOrderingStableWithExecutionKitAndReplyLadder() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Run best command now",
                systemImage: "calendar.badge.clock",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-cadence-execution-kit",
                title: "Run Next Move + Cadence Execution Kit",
                subtitle: "Execute and immediately open queue + reply ladder",
                systemImage: "rocket.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-copy-drafts",
                title: "Run Next Move + Copy Draft Pack",
                subtitle: "Execute and save ranked drafts",
                systemImage: "paperplane.circle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-pulse-alert",
                title: "Fame Pulse Alert: MUST SHIP",
                subtitle: "Risk Critical · MUST SHIP in next 2h",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-cadence-execution-kit",
                title: "Copy Cadence Execution Kit",
                subtitle: "Copy post + open queue + reply ladder",
                systemImage: "rocket",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-reply-ladder",
                title: "Copy Next-Move Reply Ladder",
                subtitle: "Copy 5 ready replies for the first 30m",
                systemImage: "text.bubble",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 9).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-next-move",
                "run-fame-next-move-cadence-execution-kit",
                "run-fame-next-move-copy-drafts",
                "run-fame-pulse-alert",
                "copy-next-move-cadence-execution-kit",
                "copy-next-move-reply-ladder"
            ]
        )
    }

    func testTopPicksIdleStatePrefersFavorites() {
        let actions = [
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "settings",
                title: "Settings",
                subtitle: "Open settings",
                systemImage: "gearshape",
                run: {}
            ),
            CommandPaletteAction(
                id: "show-reader",
                title: "Show Reader",
                subtitle: "Open reader",
                systemImage: "macwindow",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )
        let usage = [
            "read-selected": CommandUsageRecord(useCount: 100, lastUsedAt: Date(timeIntervalSince1970: 200)),
            "settings": CommandUsageRecord(useCount: 1, lastUsedAt: Date(timeIntervalSince1970: 100))
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(
                from: actions,
                context: context,
                usageRecords: usage,
                favoriteActionIDs: ["settings"],
                limit: 2
            ).map(\.id),
            ["settings", "read-selected"]
        )
    }

    func testTopPicksSummaryTextMatchesContext() {
        XCTAssertEqual(
            CommandPaletteTopPicks.summaryText(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: true,
                    llmEnabled: false
                )
            ),
            "Looks like there is an error right now"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.summaryText(
                for: CommandPaletteTopPickContext(
                    hasText: true,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: true
                )
            ),
            "You have text ready for reading or ask flows"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.summaryText(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false
                )
            ),
            "Start with capture, read, ask, or share"
        )
    }

    func testTopPicksSummaryTextHighlightsFreshOnboardingRecovery() {
        XCTAssertEqual(
            CommandPaletteTopPicks.summaryText(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
                    onboardingRecoveryRemainingArtifacts: 1
                )
            ),
            "Onboarding recovery live (1 artifact left) · Next Run First-Week Fame Scorecard"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.summaryText(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: nil,
                    onboardingRecoveryRemainingArtifacts: 0
                )
            ),
            "Onboarding gap just closed — lock in momentum"
        )
    }

    func testTopPicksStatusShortcutBadgeTitleReflectsAvailableDedicatedShortcuts() {
        XCTAssertEqual(
            CommandPaletteTopPicks.statusShortcutBadgeTitle(
                hasAutoOpsShortcut: true,
                hasLaunchRescueShortcut: true
            ),
            "Status ⌥⌘O · ⌥⌘L"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.statusShortcutBadgeTitle(
                hasAutoOpsShortcut: true,
                hasLaunchRescueShortcut: false
            ),
            "Status ⌥⌘O"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.statusShortcutBadgeTitle(
                hasAutoOpsShortcut: false,
                hasLaunchRescueShortcut: true
            ),
            "Status ⌥⌘L"
        )
        XCTAssertNil(
            CommandPaletteTopPicks.statusShortcutBadgeTitle(
                hasAutoOpsShortcut: false,
                hasLaunchRescueShortcut: false
            )
        )
    }

    func testTopPicksStatusShortcutBadgeHelpTextReflectsAvailableDedicatedShortcuts() {
        XCTAssertEqual(
            CommandPaletteTopPicks.statusShortcutBadgeHelpText(
                hasAutoOpsShortcut: true,
                hasLaunchRescueShortcut: true
            ),
            "Reader status shortcuts: ⌥⌘O runs Auto Bundle status. ⌥⌘L runs Launch Rescue Auto status."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.statusShortcutBadgeHelpText(
                hasAutoOpsShortcut: true,
                hasLaunchRescueShortcut: false
            ),
            "Reader status shortcut: ⌥⌘O runs Auto Bundle status."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.statusShortcutBadgeHelpText(
                hasAutoOpsShortcut: false,
                hasLaunchRescueShortcut: true
            ),
            "Reader status shortcut: ⌥⌘L runs Launch Rescue Auto status."
        )
        XCTAssertNil(
            CommandPaletteTopPicks.statusShortcutBadgeHelpText(
                hasAutoOpsShortcut: false,
                hasLaunchRescueShortcut: false
            )
        )
    }

    func testTopPicksOnboardingRecoveryHelpTextUsesFollowupTitleAndFallbacks() {
        XCTAssertEqual(
            CommandPaletteTopPicks.onboardingRecoveryHelpText(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
                    onboardingRecoveryRemainingArtifacts: 2
                ),
                followupTitle: "Run First-Week Fame Scorecard"
            ),
            "Onboarding recovery is active. 2 artifacts left. Next focus: Run First-Week Fame Scorecard."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.onboardingRecoveryHelpText(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: nil,
                    onboardingRecoveryRemainingArtifacts: 2
                ),
                followupTitle: nil
            ),
            "Onboarding recovery is active. 2 artifacts left. Pick the top recovery command to close the gap."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.onboardingRecoveryHelpText(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: "run-fame-onboarding-nudge",
                    onboardingRecoveryRemainingArtifacts: 0
                ),
                followupTitle: nil
            ),
            "Onboarding gap closed. Keep momentum with Run Fame Onboarding Nudge."
        )
    }

    func testTopPicksOnboardingRecoveryBadgeHelpersMapActiveAndClosedStates() {
        XCTAssertEqual(
            CommandPaletteTopPicks.onboardingRecoveryBadgeTitle(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
                    onboardingRecoveryRemainingArtifacts: 2
                )
            ),
            "Recovery · 2 artifacts left"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.onboardingRecoveryBadgeSystemImage(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
                    onboardingRecoveryRemainingArtifacts: 2
                )
            ),
            "checkmark.seal"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.onboardingRecoveryBadgeTitle(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: nil,
                    onboardingRecoveryRemainingArtifacts: 0
                )
            ),
            "Recovery · Gap closed"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.onboardingRecoveryBadgeSystemImage(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: nil,
                    onboardingRecoveryRemainingArtifacts: 0
                )
            ),
            "checkmark.seal.fill"
        )
        XCTAssertNil(
            CommandPaletteTopPicks.onboardingRecoveryBadgeTitle(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false
                )
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.onboardingRecoveryBadgeSystemImage(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false
                )
            )
        )
    }

    func testTopPicksOnboardingRecoveryQuickRunActionIDPrefersFollowupWhenEnabled() {
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false,
            hasFreshOnboardingRecovery: true,
            onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
            onboardingRecoveryRemainingArtifacts: 2
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.onboardingRecoveryQuickRunActionID(
                for: context,
                enabledActionIDs: [
                    "run-fame-onboarding-fill-gap",
                    "run-fame-onboarding-scorecard",
                    "run-fame-onboarding-daily-brief"
                ]
            ),
            "run-fame-onboarding-scorecard"
        )
    }

    func testTopPicksOnboardingRecoveryQuickRunActionIDFallsBackWhenFollowupUnavailable() {
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false,
            hasFreshOnboardingRecovery: true,
            onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
            onboardingRecoveryRemainingArtifacts: 2
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.onboardingRecoveryQuickRunActionID(
                for: context,
                enabledActionIDs: [
                    "run-fame-onboarding-daily-brief",
                    "run-fame-onboarding-nudge"
                ]
            ),
            "run-fame-onboarding-daily-brief"
        )
    }

    func testTopPicksOnboardingRecoveryQuickRunActionIDReturnsNilWhenStaleOrUnavailable() {
        XCTAssertNil(
            CommandPaletteTopPicks.onboardingRecoveryQuickRunActionID(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: false,
                    onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
                    onboardingRecoveryRemainingArtifacts: 1
                ),
                enabledActionIDs: ["run-fame-onboarding-scorecard"]
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.onboardingRecoveryQuickRunActionID(
                for: CommandPaletteTopPickContext(
                    hasText: false,
                    hasAnswer: false,
                    hasImage: false,
                    hasError: false,
                    llmEnabled: false,
                    hasFreshOnboardingRecovery: true,
                    onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
                    onboardingRecoveryRemainingArtifacts: 1
                ),
                enabledActionIDs: []
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyReadinessTracksDirectRerouteAndStandby() {
        let directReadiness = CommandPaletteTopPicks.launchRecoveryHotKeyReadiness(
            for: CommandPaletteTopPickContext(
                hasText: false,
                hasAnswer: false,
                hasImage: false,
                hasError: false,
                llmEnabled: false,
                hasFreshOnboardingRecovery: true,
                onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
                onboardingRecoveryRemainingArtifacts: 1
            ),
            enabledActionIDs: ["run-fame-onboarding-scorecard"]
        )
        XCTAssertEqual(
            directReadiness,
            .direct(actionID: "run-fame-onboarding-scorecard")
        )

        let rerouteReadiness = CommandPaletteTopPicks.launchRecoveryHotKeyReadiness(
            for: CommandPaletteTopPickContext(
                hasText: false,
                hasAnswer: false,
                hasImage: false,
                hasError: false,
                llmEnabled: false,
                hasFreshOnboardingRecovery: false,
                onboardingRecoveryFollowupActionID: nil,
                onboardingRecoveryRemainingArtifacts: nil
            ),
            enabledActionIDs: ["run-fame-cadence-autopilot-loop"]
        )
        XCTAssertEqual(
            rerouteReadiness,
            .reroute(actionID: "run-fame-cadence-autopilot-loop")
        )

        let standbyReadiness = CommandPaletteTopPicks.launchRecoveryHotKeyReadiness(
            for: CommandPaletteTopPickContext(
                hasText: false,
                hasAnswer: false,
                hasImage: false,
                hasError: false,
                llmEnabled: false,
                hasFreshOnboardingRecovery: false,
                onboardingRecoveryFollowupActionID: nil,
                onboardingRecoveryRemainingArtifacts: nil
            ),
            enabledActionIDs: []
        )
        XCTAssertEqual(standbyReadiness, .unavailable)
    }

    func testTopPicksLaunchRecoveryHotKeyBadgeHelpersMapReadinessStates() {
        let directReadiness = CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness
            .direct(actionID: "run-fame-onboarding-scorecard")
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeTitle(for: directReadiness),
            "⌥⇧L Direct"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeSystemImage(for: directReadiness),
            "checkmark.seal.fill"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeHelpText(for: directReadiness),
            "Global launch recovery hotkey is primed to run Run First-Week Fame Scorecard directly."
        )

        let rerouteReadiness = CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness
            .reroute(actionID: "run-fame-cadence-autopilot-loop")
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeTitle(for: rerouteReadiness),
            "⌥⇧L Reroute"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeSystemImage(for: rerouteReadiness),
            "arrow.triangle.branch"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeHelpText(for: rerouteReadiness),
            "Global launch recovery hotkey will auto-reroute to Run Fame Cadence Autopilot Loop until a fresh recovery pulse appears."
        )

        let standbyReadiness = CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness.unavailable
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeTitle(for: standbyReadiness),
            "⌥⇧L Standby"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeSystemImage(for: standbyReadiness),
            "clock"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeHelpText(for: standbyReadiness),
            "Global launch recovery hotkey is on standby until a recovery action becomes eligible."
        )
    }

    func testTopPicksLaunchRecoveryHotKeyLegendRiskStickyPromotionBadgeHelpersMarkAutoMode() {
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyLegendRiskStickyPromotionBadgeTitle(
                opensRemaining: 2,
                holdUntilRecovered: false
            ),
            "Legend Hold 2"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyLegendRiskStickyPromotionBadgeTitle(
                opensRemaining: 2,
                holdUntilRecovered: true
            ),
            "Legend Hold Auto 2"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyLegendRiskStickyPromotionBadgeHelpText(
                actionTitle: "Run Fame Cadence Autopilot Loop",
                opensRemaining: 2,
                holdUntilRecovered: false
            ),
            "Legend Risk Alert pinned Run Fame Cadence Autopilot Loop to the front of Top Picks for 2 more opens, including this open."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyLegendRiskStickyPromotionBadgeHelpText(
                actionTitle: "Run Fame Cadence Autopilot Loop",
                opensRemaining: 1,
                holdUntilRecovered: true
            ),
            "Legend Risk Alert pinned Run Fame Cadence Autopilot Loop to the front of Top Picks for 1 more open, including this open. Auto hold is active and keeps extending while the legend decay forecast remains active."
        )
    }

    func testTopPicksRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadgeHelpersMarkAutoMode() {
        XCTAssertEqual(
            CommandPaletteTopPicks
                .recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadgeTitle(
                    opensRemaining: 2,
                    holdUntilRecovered: false
                ),
            "Hall-of-Fame Hold 2"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks
                .recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadgeTitle(
                    opensRemaining: 2,
                    holdUntilRecovered: true
                ),
            "Hall-of-Fame Hold Auto 2"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks
                .recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadgeHelpText(
                    actionTitle: "Copy Next-Move Drafts",
                    opensRemaining: 2,
                    holdUntilRecovered: false
                ),
            "Hall-of-Fame Legend Risk pinned Copy Next-Move Drafts to the front of Top Picks for 2 more opens, including this open."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks
                .recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadgeHelpText(
                    actionTitle: "Copy Next-Move Drafts",
                    opensRemaining: 1,
                    holdUntilRecovered: true
                ),
            "Hall-of-Fame Legend Risk pinned Copy Next-Move Drafts to the front of Top Picks for 1 more open, including this open. Auto hold is active and keeps extending while Hall-of-Fame legend risk remains active."
        )
    }

    func testTopPicksLaunchRecoveryHotKeyPromptHelpersOnlySurfaceDirectState() {
        let directReadiness = CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness
            .direct(actionID: "run-fame-onboarding-scorecard")
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyPromptTitle(for: directReadiness),
            "Press ⌥⇧L now"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyPromptSystemImage(for: directReadiness),
            "keyboard"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyPromptHelpText(for: directReadiness),
            "Launch recovery route is direct. Press Option + Shift + L now to run Run First-Week Fame Scorecard."
        )

        let rerouteReadiness = CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness
            .reroute(actionID: "run-fame-cadence-autopilot-loop")
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyPromptTitle(for: rerouteReadiness)
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyPromptSystemImage(for: rerouteReadiness)
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyPromptHelpText(for: rerouteReadiness)
        )

        let standbyReadiness = CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness.unavailable
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyPromptTitle(for: standbyReadiness)
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyPromptSystemImage(for: standbyReadiness)
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyPromptHelpText(for: standbyReadiness)
        )
    }

    func testTopPicksLaunchRecoveryHotKeyTrendHelpersSummarizeRecentReadiness() {
        let trend = CommandPaletteTopPicks.launchRecoveryHotKeyTrend(
            for: [.direct, .reroute, .direct, .standby, .direct, .reroute, .direct],
            limit: 6
        )
        XCTAssertEqual(
            trend,
            CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
                directCount: 3,
                rerouteCount: 2,
                standbyCount: 1
            )
        )

        guard let trend else {
            XCTFail("Expected launch recovery trend.")
            return
        }

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendDominantState(for: trend),
            .direct
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeTitle(for: trend),
            "Trend D3·R2·S1"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeSystemImage(for: trend),
            "chart.line.uptrend.xyaxis"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeHelpText(for: trend),
            "Launch recovery confidence over last 6 palette opens: Direct 3, Reroute 2, Standby 1. Direct route is leading."
        )
    }

    func testTopPicksLaunchRecoveryHotKeyTrendHelpersMapRerouteAndStandbyDominance() {
        let rerouteTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
            directCount: 1,
            rerouteCount: 3,
            standbyCount: 1
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendDominantState(for: rerouteTrend),
            .reroute
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeSystemImage(for: rerouteTrend),
            "arrow.triangle.branch"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeHelpText(for: rerouteTrend),
            "Launch recovery confidence over last 5 palette opens: Direct 1, Reroute 3, Standby 1. Reroute is carrying recovery while fresh pulses rebuild."
        )

        let standbyTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
            directCount: 1,
            rerouteCount: 1,
            standbyCount: 4
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendDominantState(for: standbyTrend),
            .standby
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeSystemImage(for: standbyTrend),
            "clock.badge.exclamationmark"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeHelpText(for: standbyTrend),
            "Launch recovery confidence over last 6 palette opens: Direct 1, Reroute 1, Standby 4. Recovery mostly stays on standby; queue onboarding recovery steps to restore one-click flow."
        )
    }

    func testTopPicksLaunchRecoveryHotKeyWinMeterTracksWinsToneAndMultiplier() {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyWinMeter(
                readinessHistory: [],
                directStreak: 0,
                bestDirectStreak: 0,
                sampleLimit: 8
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyWinMeter(
                readinessHistory: [.direct, .direct, .reroute, .direct, .direct, .standby, .direct, .direct],
                directStreak: 6,
                bestDirectStreak: 9,
                sampleLimit: 8
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeter(
                tone: .surge,
                wins: 6,
                sampleCount: 8,
                multiplier: 3,
                title: "Recovery Wins 6/8 · x3",
                subtitle: "Direct route is winning 6/8 opens. Keep streak pressure high.",
                systemImage: "trophy.fill",
                helpText: "Launch recovery win meter tracks direct-route wins over the last 8 opens: 6 direct wins, current streak x6, best x9, multiplier x3."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyWinMeter(
                readinessHistory: [.direct, .reroute, .standby, .direct, .reroute, .standby, .direct, .direct],
                directStreak: 2,
                bestDirectStreak: 5,
                sampleLimit: 8
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeter(
                tone: .steady,
                wins: 4,
                sampleCount: 8,
                multiplier: 2,
                title: "Recovery Wins 4/8 · x2",
                subtitle: "Recovery is stabilizing at 4/8 direct wins. Stack the next win.",
                systemImage: "chart.line.uptrend.xyaxis",
                helpText: "Launch recovery win meter tracks direct-route wins over the last 8 opens: 4 direct wins, current streak x2, best x5, multiplier x2."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyWinMeter(
                readinessHistory: [.standby, .reroute, .standby, .direct, .reroute, .standby, .direct, .reroute],
                directStreak: 1,
                bestDirectStreak: 3,
                sampleLimit: 8
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeter(
                tone: .rebuild,
                wins: 2,
                sampleCount: 8,
                multiplier: 1,
                title: "Recovery Wins 2/8 · x1",
                subtitle: "Recovery is rebuilding (2/8 direct wins). Run the next recovery step now.",
                systemImage: "arrow.triangle.2.circlepath",
                helpText: "Launch recovery win meter tracks direct-route wins over the last 8 opens: 2 direct wins, current streak x1, best x3, multiplier x1."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyWinDeltaTracksClimbingSteadyAndSlipping() {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyWinDelta(
                readinessHistory: [.direct, .reroute, .standby],
                sampleWindow: 4
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyWinDelta(
                readinessHistory: [.standby, .reroute, .direct, .standby, .direct, .direct, .reroute, .direct],
                sampleWindow: 4
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .climbing,
                currentWins: 3,
                previousWins: 1,
                sampleCount: 4,
                deltaWins: 2,
                title: "Fame Momentum Delta +2 wins",
                subtitle: "Direct wins climbed to 3/4 from 1/4. Keep compounding.",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Fame momentum delta compares direct wins across two 4-open windows: current 3, previous 1, Δ+2."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyWinDelta(
                readinessHistory: [.direct, .reroute, .standby, .direct, .reroute, .direct, .standby, .direct],
                sampleWindow: 4
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .steady,
                currentWins: 2,
                previousWins: 2,
                sampleCount: 4,
                deltaWins: 0,
                title: "Fame Momentum Delta 0 wins",
                subtitle: "Direct wins are flat at 2/4 vs 2/4. Push one extra direct win.",
                systemImage: "equal.circle.fill",
                helpText: "Fame momentum delta compares direct wins across two 4-open windows: current 2, previous 2, Δ0."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyWinDelta(
                readinessHistory: [.direct, .direct, .reroute, .direct, .reroute, .standby, .standby, .reroute],
                sampleWindow: 4
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .slipping,
                currentWins: 0,
                previousWins: 3,
                sampleCount: 4,
                deltaWins: -3,
                title: "Fame Momentum Delta -3 wins",
                subtitle: "Direct wins slipped to 0/4 from 3/4. Re-anchor recovery now.",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Fame momentum delta compares direct wins across two 4-open windows: current 0, previous 3, Δ-3."
            )
        )
    }

    func testTopPicksFameMomentumPanelPrefersTrustFixWhenConfidenceNeedsAttention() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .critical, points: 24),
            winDelta: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .slipping,
                currentWins: 1,
                previousWins: 3,
                sampleCount: 4,
                deltaWins: -2,
                title: "Fame Momentum Delta -2 wins",
                subtitle: "Direct wins slipped.",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Win delta slipped."
            ),
            rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 5,
                opensSinceLastConversion: 7,
                conversionRatePercent: 63
            ),
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop",
                "run-fame-next-move-copy-drafts"
            ]
        )

        XCTAssertEqual(panel?.tone, .alert)
        XCTAssertEqual(panel?.actionID, "run-trust-fix")
        XCTAssertEqual(panel?.actionPrompt, "Run Trust Fix")
        XCTAssertEqual(panel?.systemImage, "exclamationmark.shield.fill")
        XCTAssertTrue(panel?.subtitle.contains("Δwins -2") ?? false)
    }

    func testTopPicksFameMomentumPanelPrefersRescueActionWhenConfidenceIsStable() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .steady, points: 68),
            winDelta: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .climbing,
                currentWins: 3,
                previousWins: 2,
                sampleCount: 4,
                deltaWins: 1,
                title: "Fame Momentum Delta +1 wins",
                subtitle: "Direct wins climbed.",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Win delta climbed."
            ),
            rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 4,
                conversionRatePercent: 75
            ),
            hallOfFameCue: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue(
                tone: .defense,
                trend: .falling,
                title: "Hall of Fame Defense · Cooling",
                subtitle: "Week pace slipped.",
                buttonTitle: "Stabilize Pace",
                systemImage: "thermometer.low",
                helpText: "Defense cue is active."
            ),
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop",
                "run-fame-next-move-copy-drafts"
            ]
        )

        XCTAssertEqual(panel?.tone, .watch)
        XCTAssertEqual(panel?.actionID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(panel?.actionPrompt, "Run Rescue Now")
        XCTAssertTrue(panel?.subtitle.contains("Rescue 75%") ?? false)
    }

    func testTopPicksFameMomentumPanelCanAdaptToObservedTrustStepImpact() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .critical, points: 26),
            winDelta: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .slipping,
                currentWins: 1,
                previousWins: 3,
                sampleCount: 4,
                deltaWins: -2,
                title: "Fame Momentum Delta -2 wins",
                subtitle: "Direct wins slipped.",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Win delta slipped."
            ),
            rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 10,
                conversions: 6,
                opensSinceLastConversion: 5,
                conversionRatePercent: 60
            ),
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [
                "run-trust-fix": -4,
                "run-fame-cadence-autopilot-loop": 6
            ],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop",
                "run-fame-next-move-copy-drafts"
            ]
        )

        XCTAssertEqual(panel?.tone, .alert)
        XCTAssertEqual(panel?.actionID, "run-fame-cadence-autopilot-loop")
        XCTAssertEqual(panel?.actionPrompt, "Run Trust Step")
    }

    func testTopPicksFameMomentumPanelCanShiftFromRescueWhenRescueImpactCools() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .steady, points: 66),
            winDelta: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .steady,
                currentWins: 2,
                previousWins: 2,
                sampleCount: 4,
                deltaWins: 0,
                title: "Fame Momentum Delta 0 wins",
                subtitle: "Direct wins are flat.",
                systemImage: "equal.circle.fill",
                helpText: "Win delta is flat."
            ),
            rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 10,
                conversions: 6,
                opensSinceLastConversion: 8,
                conversionRatePercent: 60
            ),
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [
                "run-fame-next-move-copy-drafts": -8,
                "run-fame-cadence-autopilot-loop": 5
            ],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop",
                "run-fame-next-move-copy-drafts"
            ]
        )

        XCTAssertEqual(panel?.tone, .steady)
        XCTAssertEqual(panel?.actionID, "run-fame-cadence-autopilot-loop")
        XCTAssertEqual(panel?.actionPrompt, "Run Trust Step")
    }

    func testTopPicksFameMomentumPanelReasonChipsCanExplainTrustPriorityAndObservedLift() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .critical, points: 26),
            winDelta: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .slipping,
                currentWins: 1,
                previousWins: 3,
                sampleCount: 4,
                deltaWins: -2,
                title: "Fame Momentum Delta -2 wins",
                subtitle: "Direct wins slipped.",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Win delta slipped."
            ),
            rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 10,
                conversions: 6,
                opensSinceLastConversion: 5,
                conversionRatePercent: 60
            ),
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [
                "run-trust-fix": -4,
                "run-fame-cadence-autopilot-loop": 6
            ],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop",
                "run-fame-next-move-copy-drafts"
            ]
        )

        let reasonTitles = panel?.reasonChips.map(\.title) ?? []
        XCTAssertEqual(panel?.actionID, "run-fame-cadence-autopilot-loop")
        XCTAssertTrue(reasonTitles.contains("Trust Priority"))
        XCTAssertTrue(reasonTitles.contains("Observed +6"))
        XCTAssertTrue(reasonTitles.contains("Δwins -2"))
    }

    func testTopPicksFameMomentumPanelReasonChipsCanExplainRescueConfidenceBias() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .steady, points: 68),
            winDelta: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .climbing,
                currentWins: 3,
                previousWins: 2,
                sampleCount: 4,
                deltaWins: 1,
                title: "Fame Momentum Delta +1 wins",
                subtitle: "Direct wins climbed.",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Win delta climbed."
            ),
            rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 7,
                opensSinceLastConversion: 1,
                conversionRatePercent: 88
            ),
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [:],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop",
                "run-fame-next-move-copy-drafts"
            ]
        )

        let reasonTitles = panel?.reasonChips.map(\.title) ?? []
        XCTAssertEqual(panel?.actionID, "run-fame-next-move-copy-drafts")
        XCTAssertTrue(reasonTitles.contains("Rescue Conf +7"))
        XCTAssertTrue(reasonTitles.contains("Δwins +1"))
    }

    func testTopPicksFameMomentumPanelCanDemoteStaleObservedLeaderWithRecencyPenalty() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 42),
            winDelta: nil,
            rescuePlan: nil,
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [
                "run-fame-cadence-autopilot-loop": 6
            ],
            actionRecency: [
                "run-trust-fix": .recentlyValidated(opensAgo: 0),
                "run-fame-cadence-autopilot-loop": .stale(opensAgo: 8)
            ],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop"
            ]
        )

        XCTAssertEqual(
            panel?.actionID,
            "run-trust-fix",
            "Stale signals should not overpower fresher trust routes even when observed impact is higher."
        )
        XCTAssertEqual(panel?.secondaryActionID, "run-fame-cadence-autopilot-loop")
    }

    func testTopPicksFameMomentumPanelCanStabilizeVolatileRhythmByFavoringFreshRoute() {
        let baselinePanel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 42),
            winDelta: nil,
            rescuePlan: nil,
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [
                "run-fame-cadence-autopilot-loop": 8
            ],
            actionRecency: [
                "run-trust-fix": .recentlyValidated(opensAgo: 0),
                "run-fame-cadence-autopilot-loop": .stale(opensAgo: 8)
            ],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop"
            ]
        )

        let volatilePanel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 42),
            winDelta: nil,
            routeFlipRhythmTone: .volatile,
            rescuePlan: nil,
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [
                "run-fame-cadence-autopilot-loop": 8
            ],
            actionRecency: [
                "run-trust-fix": .recentlyValidated(opensAgo: 0),
                "run-fame-cadence-autopilot-loop": .stale(opensAgo: 8)
            ],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop"
            ]
        )

        XCTAssertEqual(baselinePanel?.actionID, "run-fame-cadence-autopilot-loop")
        XCTAssertEqual(volatilePanel?.actionID, "run-trust-fix")
        XCTAssertTrue(
            volatilePanel?.reasonChips.map(\.title).contains("Rhythm Vol +24") == true,
            "Volatile rhythm should show its adaptive bias in reason chips for explainability."
        )
    }

    func testTopPicksFameMomentumPanelReasonChipsCanExplainSignalStaleness() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .critical, points: 28),
            winDelta: nil,
            rescuePlan: nil,
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: nil,
            actionScores: [
                "run-trust-fix": 2
            ],
            actionRecency: [
                "run-trust-fix": .stale(opensAgo: 7)
            ],
            enabledActionIDs: [
                "run-trust-fix"
            ]
        )

        let reasonTitles = panel?.reasonChips.map(\.title) ?? []
        XCTAssertTrue(
            reasonTitles.contains("Signal Stale"),
            "Reason chips should explain when ranking confidence is discounted due to stale learning signals."
        )
    }

    func testTopPicksFameMomentumPanelCanCarryInterventionTrustTrendStrip() {
        let trend = CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend(
            samples: [28, 41, 52, 64],
            currentPoints: 64,
            deltaPoints: 18,
            direction: .rising,
            title: "Intervention Trust Rising",
            subtitle: "Trust 64/100 · Δ+18",
            systemImage: "chart.line.uptrend.xyaxis",
            helpText: "Trust trend is climbing."
        )
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .steady, points: 68),
            winDelta: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .steady,
                currentWins: 2,
                previousWins: 2,
                sampleCount: 4,
                deltaWins: 0,
                title: "Fame Momentum Delta 0 wins",
                subtitle: "Direct wins are flat.",
                systemImage: "equal.circle.fill",
                helpText: "Win delta is flat."
            ),
            interventionTrustTrend: trend,
            rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 4,
                conversionRatePercent: 75
            ),
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [:],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop",
                "run-fame-next-move-copy-drafts"
            ]
        )

        XCTAssertEqual(panel?.interventionTrustTrend, trend)
        XCTAssertEqual(panel?.interventionTrustTrend?.samples, [28, 41, 52, 64])
        XCTAssertEqual(panel?.interventionTrustTrend?.direction, .rising)
    }

    func testTopPicksFameMomentumPanelTrustTrendCelebrationOnlyForFallingToRising() {
        XCTAssertTrue(
            CommandPaletteTopPicks.shouldCelebrateFameMomentumPanelTrustTrendTransition(
                previousDirection: .falling,
                nextDirection: .rising
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldCelebrateFameMomentumPanelTrustTrendTransition(
                previousDirection: nil,
                nextDirection: .rising
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldCelebrateFameMomentumPanelTrustTrendTransition(
                previousDirection: .falling,
                nextDirection: .steady
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldCelebrateFameMomentumPanelTrustTrendTransition(
                previousDirection: .steady,
                nextDirection: .rising
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldCelebrateFameMomentumPanelTrustTrendTransition(
                previousDirection: .rising,
                nextDirection: .rising
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldCelebrateFameMomentumPanelTrustTrendTransition(
                previousDirection: .rising,
                nextDirection: .falling
            )
        )
    }

    func testTopPicksFameMomentumPanelCanSurfaceBackupActionWhenRankIsClose() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 42),
            winDelta: nil,
            rescuePlan: nil,
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [
                "run-trust-fix": -4,
                "run-fame-cadence-autopilot-loop": 1
            ],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop"
            ]
        )

        XCTAssertEqual(panel?.actionID, "run-trust-fix")
        XCTAssertEqual(panel?.actionPrompt, "Run Trust Fix")
        XCTAssertEqual(panel?.secondaryActionID, "run-fame-cadence-autopilot-loop")
        XCTAssertEqual(panel?.secondaryActionPrompt, "Run Trust Step")
        XCTAssertEqual(panel?.selectionConfidence?.tier, .split)
        XCTAssertEqual(panel?.selectionConfidence?.gapPoints, 10)
        XCTAssertEqual(panel?.selectionConfidence?.confidencePercent, 8)
        XCTAssertTrue(
            panel?.reasonChips.map(\.title).contains("Backup Trust Step") == true,
            "Close ranking should expose a backup action chip so users can recover quickly if the primary is blocked."
        )
    }

    func testTopPicksFameMomentumPanelSelectionConfidenceCanLockWhenOnlySingleActionIsEligible() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 45),
            winDelta: nil,
            rescuePlan: nil,
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [:],
            enabledActionIDs: [
                "run-trust-fix"
            ]
        )

        XCTAssertEqual(panel?.actionID, "run-trust-fix")
        XCTAssertNil(panel?.secondaryActionID)
        XCTAssertEqual(panel?.selectionConfidence?.tier, .locked)
        XCTAssertEqual(panel?.selectionConfidence?.confidencePercent, 100)
        XCTAssertEqual(panel?.selectionConfidence?.subtitle, "Only one eligible route")
    }

    func testTopPicksFameMomentumPanelSelectionConfidenceCanLeanWhenGapIsModerate() {
        let panel = CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 45),
            winDelta: nil,
            rescuePlan: nil,
            hallOfFameCue: nil,
            trustGuardActionID: "run-trust-fix",
            trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
            actionScores: [
                "run-fame-cadence-autopilot-loop": 2
            ],
            enabledActionIDs: [
                "run-trust-fix",
                "run-fame-cadence-autopilot-loop"
            ]
        )

        XCTAssertEqual(panel?.selectionConfidence?.tier, .leaning)
        XCTAssertEqual(panel?.selectionConfidence?.gapPoints, 64)
        XCTAssertEqual(panel?.selectionConfidence?.confidencePercent, 53)
        XCTAssertEqual(panel?.secondaryActionID, "run-fame-cadence-autopilot-loop")
    }

    func testTopPicksFameMomentumPanelActionEmphasisCanPromoteBackupForTightSplit() {
        let tightSplit = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 11,
            gapPoints: 14,
            title: "Selection Split",
            subtitle: "Gap 14 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Tight split."
        )
        let wideSplit = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 32,
            gapPoints: 38,
            title: "Selection Split",
            subtitle: "Gap 38 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Wider split."
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelActionEmphasis(
                selectionConfidence: tightSplit,
                hasSecondaryAction: true
            ),
            .splitDecision
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelActionEmphasis(
                selectionConfidence: tightSplit,
                hasSecondaryAction: false
            ),
            .primaryDominant
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelActionEmphasis(
                selectionConfidence: wideSplit,
                hasSecondaryAction: true
            ),
            .primaryDominant
        )
    }

    func testTopPicksFameMomentumPanelActionEmphasisCanWidenSplitDuringVolatileRhythm() {
        let moderateSplit = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 22,
            gapPoints: 24,
            title: "Selection Split",
            subtitle: "Gap 24 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Moderate split."
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelActionEmphasis(
                selectionConfidence: moderateSplit,
                hasSecondaryAction: true
            ),
            .primaryDominant
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelActionEmphasis(
                selectionConfidence: moderateSplit,
                hasSecondaryAction: true,
                routeFlipRhythmTone: .volatile
            ),
            .splitDecision
        )
    }

    func testTopPicksFameMomentumPanelResolvedActionPromptsCanKeepOriginalPromptsWhenPrimaryDominates() {
        let resolved = CommandPaletteTopPicks.fameMomentumPanelResolvedActionPrompts(
            primaryPrompt: "Run Trust Fix",
            secondaryPrompt: "Run Trust Step",
            selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
                tier: .leaning,
                confidencePercent: 54,
                gapPoints: 65,
                title: "Selection Leaning",
                subtitle: "Gap 65 · backup live",
                systemImage: "slider.horizontal.2.square",
                helpText: "Leaning signal."
            ),
            actionEmphasis: .primaryDominant,
            hasSecondaryAction: true
        )

        XCTAssertEqual(resolved.primary, "Run Trust Fix")
        XCTAssertEqual(resolved.secondary, "Run Trust Step")
    }

    func testTopPicksFameMomentumPanelResolvedActionPromptsCanPromoteBestAndAlternateForSplitDecision() {
        let resolvedHighSplit = CommandPaletteTopPicks.fameMomentumPanelResolvedActionPrompts(
            primaryPrompt: "Run Trust Fix",
            secondaryPrompt: "Run Trust Step",
            selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
                tier: .split,
                confidencePercent: 23,
                gapPoints: 28,
                title: "Selection Split",
                subtitle: "Gap 28 · backup live",
                systemImage: "arrow.triangle.branch",
                helpText: "Split signal."
            ),
            actionEmphasis: .splitDecision,
            hasSecondaryAction: true
        )
        XCTAssertEqual(resolvedHighSplit.primary, "Best Bet")
        XCTAssertEqual(resolvedHighSplit.secondary, "Strong Alternate")

        let resolvedTightSplit = CommandPaletteTopPicks.fameMomentumPanelResolvedActionPrompts(
            primaryPrompt: "Run Trust Fix",
            secondaryPrompt: "Run Trust Step",
            selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
                tier: .split,
                confidencePercent: 9,
                gapPoints: 10,
                title: "Selection Split",
                subtitle: "Gap 10 · backup live",
                systemImage: "arrow.triangle.branch",
                helpText: "Tight split signal."
            ),
            actionEmphasis: .splitDecision,
            hasSecondaryAction: true
        )
        XCTAssertEqual(resolvedTightSplit.primary, "Best Bet")
        XCTAssertEqual(resolvedTightSplit.secondary, "Alternate Bet")
    }

    func testTopPicksFameMomentumPanelActionLabelExplanationCanExplainSplitAndDominantStates() {
        let splitConfidence = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 9,
            gapPoints: 10,
            title: "Selection Split",
            subtitle: "Gap 10 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Tight split signal."
        )
        let dominantConfidence = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .leaning,
            confidencePercent: 54,
            gapPoints: 64,
            title: "Selection Leaning",
            subtitle: "Gap 64 · backup live",
            systemImage: "slider.horizontal.2.square",
            helpText: "Leaning signal."
        )

        let splitExplanation = CommandPaletteTopPicks.fameMomentumPanelActionLabelExplanation(
            selectionConfidence: splitConfidence,
            actionEmphasis: .splitDecision,
            hasSecondaryAction: true
        )
        XCTAssertEqual(
            splitExplanation,
            "Decision confidence is ultra-tight at 9% (gap 10), so labels switch to Best Bet and Alternate Bet."
        )

        let dominantExplanation = CommandPaletteTopPicks.fameMomentumPanelActionLabelExplanation(
            selectionConfidence: dominantConfidence,
            actionEmphasis: .primaryDominant,
            hasSecondaryAction: true
        )
        XCTAssertEqual(
            dominantExplanation,
            "Primary route leads by 64 points (54% confidence), so original run/backup labels stay in place."
        )

        let singleRouteExplanation = CommandPaletteTopPicks.fameMomentumPanelActionLabelExplanation(
            selectionConfidence: dominantConfidence,
            actionEmphasis: .primaryDominant,
            hasSecondaryAction: false
        )
        XCTAssertEqual(
            singleRouteExplanation,
            "Only one eligible action is available right now, so adaptive split labels stay off."
        )
    }

    func testTopPicksFameMomentumPanelActionLabelExplanationCanExplainVolatileSplitWidening() {
        let splitConfidence = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 22,
            gapPoints: 24,
            title: "Selection Split",
            subtitle: "Gap 24 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Moderate split."
        )

        let explanation = CommandPaletteTopPicks.fameMomentumPanelActionLabelExplanation(
            selectionConfidence: splitConfidence,
            actionEmphasis: .splitDecision,
            hasSecondaryAction: true,
            routeFlipRhythmTone: .volatile
        )
        XCTAssertEqual(
            explanation,
            "Route rhythm is volatile and decision confidence remains split (22% · gap 24), so labels stay in split mode to keep the backup route explicit."
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationCueReturnsNilWithoutVolatilePulseContext() {
        let splitConfidence = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 22,
            gapPoints: 24,
            title: "Selection Split",
            subtitle: "Gap 24 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Moderate split."
        )

        XCTAssertNil(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationCue(
                rhythmTone: .volatile,
                stabilizationPulse: nil,
                selectionConfidence: splitConfidence,
                hasSecondaryAction: true
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationCue(
                rhythmTone: .watch,
                stabilizationPulse: CommandPaletteSession.FameMomentumPanelRouteStabilizationPulse(
                    title: "Route Stabilizer x2",
                    subtitle: "sample",
                    systemImage: "shield",
                    helpText: "sample",
                    volatileStreak: 2,
                    flipCount: 3,
                    openSpan: 3
                ),
                selectionConfidence: splitConfidence,
                hasSecondaryAction: true
            )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationCueCanDualTrackWhenSplitAndBackupLive() {
        let splitConfidence = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 22,
            gapPoints: 24,
            title: "Selection Split",
            subtitle: "Gap 24 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Moderate split."
        )
        let cue = CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationCue(
            rhythmTone: .volatile,
            stabilizationPulse: CommandPaletteSession.FameMomentumPanelRouteStabilizationPulse(
                title: "Route Stabilizer x2",
                subtitle: "sample",
                systemImage: "shield",
                helpText: "sample",
                volatileStreak: 2,
                flipCount: 3,
                openSpan: 3
            ),
            selectionConfidence: splitConfidence,
            hasSecondaryAction: true
        )

        XCTAssertEqual(cue?.focus, .dualTrack)
        XCTAssertEqual(cue?.buttonTitle, "Stabilize Now")
        XCTAssertEqual(cue?.secondaryButtonTitle, "Run Alternate")
        XCTAssertEqual(cue?.title, "Route Stabilizer Active")
    }

    func testTopPicksFameMomentumPanelRouteStabilizationCueCanLockPrimaryWhenBackupIsNotLive() {
        let leaningConfidence = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .leaning,
            confidencePercent: 54,
            gapPoints: 64,
            title: "Selection Leaning",
            subtitle: "Gap 64 · backup live",
            systemImage: "slider.horizontal.2.square",
            helpText: "Leaning signal."
        )
        let cue = CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationCue(
            rhythmTone: .volatile,
            stabilizationPulse: CommandPaletteSession.FameMomentumPanelRouteStabilizationPulse(
                title: "Route Stabilizer x3",
                subtitle: "sample",
                systemImage: "shield",
                helpText: "sample",
                volatileStreak: 3,
                flipCount: 3,
                openSpan: 3
            ),
            selectionConfidence: leaningConfidence,
            hasSecondaryAction: false
        )

        XCTAssertEqual(cue?.focus, .primaryLock)
        XCTAssertEqual(cue?.buttonTitle, "Stabilize Now")
        XCTAssertNil(cue?.secondaryButtonTitle)
        XCTAssertEqual(cue?.title, "Route Stabilizer Lock")
    }

    func testTopPicksFameMomentumPanelRouteStabilizationCueCanEscalateResetWhenSettledHitRateFalls() {
        let splitConfidence = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 22,
            gapPoints: 24,
            title: "Selection Split",
            subtitle: "Gap 24 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Moderate split."
        )
        let cue = CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationCue(
            rhythmTone: .volatile,
            stabilizationPulse: CommandPaletteSession.FameMomentumPanelRouteStabilizationPulse(
                title: "Route Stabilizer x4",
                subtitle: "sample",
                systemImage: "shield",
                helpText: "sample",
                volatileStreak: 4,
                flipCount: 5,
                openSpan: 4
            ),
            selectionConfidence: splitConfidence,
            hasSecondaryAction: true,
            stabilizationScoreboard: makeFameMomentumRouteStabilizationScoreboard(
                runs: 6,
                successes: 2,
                pendingRuns: 1
            )
        )

        XCTAssertEqual(cue?.focus, .primaryReset)
        XCTAssertEqual(cue?.title, "Route Stabilizer Reset")
        XCTAssertEqual(cue?.buttonTitle, "Re-anchor Route")
        XCTAssertNil(cue?.secondaryButtonTitle)
        XCTAssertTrue(cue?.subtitle.contains("Hit rate 40%") == true)
        XCTAssertTrue(cue?.subtitle.contains("5 settled runs") == true)
    }

    func testTopPicksFameMomentumPanelRouteStabilizationCueCanPromoteCompoundingWhenHitRateIsStrong() {
        let splitConfidence = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 22,
            gapPoints: 24,
            title: "Selection Split",
            subtitle: "Gap 24 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Moderate split."
        )
        let cue = CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationCue(
            rhythmTone: .volatile,
            stabilizationPulse: CommandPaletteSession.FameMomentumPanelRouteStabilizationPulse(
                title: "Route Stabilizer x4",
                subtitle: "sample",
                systemImage: "shield",
                helpText: "sample",
                volatileStreak: 4,
                flipCount: 5,
                openSpan: 4
            ),
            selectionConfidence: splitConfidence,
            hasSecondaryAction: true,
            stabilizationScoreboard: makeFameMomentumRouteStabilizationScoreboard(
                runs: 6,
                successes: 5,
                pendingRuns: 1
            )
        )

        XCTAssertEqual(cue?.focus, .dualTrack)
        XCTAssertEqual(cue?.title, "Route Stabilizer Compounding")
        XCTAssertEqual(cue?.buttonTitle, "Keep Stabilizing")
        XCTAssertEqual(cue?.secondaryButtonTitle, "Run Alternate")
        XCTAssertTrue(cue?.subtitle.contains("Hit rate 100%") == true)
        XCTAssertTrue(cue?.subtitle.contains("5 settled runs") == true)
    }

    func testTopPicksFameMomentumPanelRouteStabilizationCueKeepsDefaultModeWhenSettledRunsAreInsufficient() {
        let splitConfidence = CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: .split,
            confidencePercent: 22,
            gapPoints: 24,
            title: "Selection Split",
            subtitle: "Gap 24 · backup live",
            systemImage: "arrow.triangle.branch",
            helpText: "Moderate split."
        )
        let cue = CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationCue(
            rhythmTone: .volatile,
            stabilizationPulse: CommandPaletteSession.FameMomentumPanelRouteStabilizationPulse(
                title: "Route Stabilizer x2",
                subtitle: "sample",
                systemImage: "shield",
                helpText: "sample",
                volatileStreak: 2,
                flipCount: 3,
                openSpan: 3
            ),
            selectionConfidence: splitConfidence,
            hasSecondaryAction: true,
            stabilizationScoreboard: makeFameMomentumRouteStabilizationScoreboard(
                runs: 4,
                successes: 1,
                pendingRuns: 2
            )
        )

        XCTAssertEqual(cue?.focus, .dualTrack)
        XCTAssertEqual(cue?.title, "Route Stabilizer Active")
        XCTAssertEqual(cue?.buttonTitle, "Stabilize Now")
        XCTAssertEqual(cue?.secondaryButtonTitle, "Run Alternate")
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeReturnsNilWithoutExposure() {
        XCTAssertNil(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
                shownCount: 0,
                runCount: 0,
                blockedCount: 0
            )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeCanFormatStrongWatchAndBlockedTones() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
                shownCount: 3,
                runCount: 2,
                blockedCount: 0
            ),
            CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
                tone: .strong,
                title: "Recovery CTA 67%",
                systemImage: "checkmark.shield.fill",
                helpText: "Recovery suggestion CTA shown x3; launched x2 (67%)."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
                shownCount: 5,
                runCount: 2,
                blockedCount: 1
            ),
            CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
                tone: .watch,
                title: "Recovery CTA 40% · 1 blocked",
                systemImage: "exclamationmark.shield.fill",
                helpText: "Recovery suggestion CTA shown x5; launched x2 (40%). Blocked x1 (20%) when suggested actions were unavailable."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
                shownCount: 5,
                runCount: 1,
                blockedCount: 2
            ),
            CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
                tone: .blocked,
                title: "Recovery CTA Blocked x2",
                systemImage: "xmark.shield.fill",
                helpText: "Recovery suggestion CTA shown x5; launched x1 (20%). Blocked x2 (40%) when suggested actions were unavailable."
            )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeReturnsNilWithoutExposure() {
        XCTAssertNil(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 0,
                    blockedCount: 0,
                    recoveryRunCount: 0,
                    unblockRunCount: 0
                )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeCanFormatStableWatchAndAlertStates() throws {
        let stableBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 12,
                    blockedCount: 1,
                    recoveryRunCount: 3,
                    unblockRunCount: 3
                )
        )
        XCTAssertEqual(stableBadge.tone, .steady)
        XCTAssertEqual(stableBadge.confidencePercent, 83)
        XCTAssertEqual(stableBadge.title, "Pressure Stable 83%")
        XCTAssertEqual(stableBadge.systemImage, "checkmark.shield.fill")
        XCTAssertTrue(stableBadge.helpText.contains("Pressure model is Balanced at 83% confidence.") == true)
        XCTAssertTrue(stableBadge.helpText.contains("Blocked x1/12 cues (8%).") == true)
        XCTAssertTrue(stableBadge.helpText.contains("Unblock coverage is 3/6 runs (50%).") == true)
        XCTAssertTrue(stableBadge.helpText.contains("Pressure gates require ≥3 blocked cues and ≥34% blocked rate.") == true)
        XCTAssertTrue(stableBadge.helpText.contains("Coverage is balanced between recovery and unblock runs.") == true)

        let watchBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 6,
                    blockedCount: 2,
                    recoveryRunCount: 3,
                    unblockRunCount: 1
                )
        )
        XCTAssertEqual(watchBadge.tone, .watch)
        XCTAssertEqual(watchBadge.confidencePercent, 35)
        XCTAssertEqual(watchBadge.title, "Pressure Mixed 35%")
        XCTAssertEqual(watchBadge.systemImage, "exclamationmark.shield.fill")
        XCTAssertTrue(watchBadge.helpText.contains("Pressure model is Balanced at 35% confidence.") == true)
        XCTAssertTrue(watchBadge.helpText.contains("Unblock coverage is 1/4 runs (25%).") == true)
        XCTAssertTrue(watchBadge.helpText.contains("Coverage is skewed toward recovery runs.") == true)

        let alertBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 8,
                    blockedCount: 4,
                    recoveryRunCount: 6,
                    unblockRunCount: 0
                )
        )
        XCTAssertEqual(alertBadge.tone, .alert)
        XCTAssertEqual(alertBadge.confidencePercent, 85)
        XCTAssertEqual(alertBadge.title, "Pressure High 85%")
        XCTAssertEqual(alertBadge.systemImage, "xmark.shield.fill")
        XCTAssertTrue(alertBadge.helpText.contains("Pressure model is Aggressive at 85% confidence.") == true)
        XCTAssertTrue(alertBadge.helpText.contains("Pressure gates require ≥1 blocked cues and ≥23% blocked rate.") == true)
        XCTAssertTrue(alertBadge.helpText.contains("Unblock coverage is 0/6 runs (0%).") == true)
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeHandlesTelemetryExtremes() throws {
        let lowSampleBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 1,
                    blockedCount: 0,
                    recoveryRunCount: 0,
                    unblockRunCount: 0
                )
        )
        XCTAssertEqual(lowSampleBadge.tone, .watch)
        XCTAssertEqual(lowSampleBadge.confidencePercent, 59)
        XCTAssertEqual(lowSampleBadge.title, "Pressure Mixed 59%")
        XCTAssertTrue(lowSampleBadge.helpText.contains("Unblock coverage is 0/1 runs (0%).") == true)

        let noRunCoverageBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 10,
                    blockedCount: 3,
                    recoveryRunCount: 0,
                    unblockRunCount: 0
                )
        )
        XCTAssertEqual(noRunCoverageBadge.tone, .watch)
        XCTAssertTrue(noRunCoverageBadge.title.hasPrefix("Pressure Mixed ") == true)
        XCTAssertTrue(noRunCoverageBadge.helpText.contains("Unblock coverage is 0/1 runs (0%).") == true)

        let saturatedBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 120,
                    blockedCount: 120,
                    recoveryRunCount: 120,
                    unblockRunCount: 0
                )
        )
        XCTAssertEqual(saturatedBadge.tone, .alert)
        XCTAssertEqual(saturatedBadge.confidencePercent, 99)
        XCTAssertEqual(saturatedBadge.title, "Pressure High 99%")
        XCTAssertTrue(saturatedBadge.helpText.contains("Pressure model is Aggressive at 99% confidence.") == true)
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeCanAnnotateTrendFromHistory() throws {
        let badge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 6,
                    blockedCount: 2,
                    recoveryRunCount: 3,
                    unblockRunCount: 1,
                    pressureConfidenceHistory: [50, 48]
                )
        )
        XCTAssertEqual(badge.tone, .watch)
        XCTAssertEqual(badge.confidencePercent, 35)
        XCTAssertTrue(
            badge.helpText.contains(
                "Pressure trend is cooling (-14pts vs recent baseline) across 3 checks."
            ) == true
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeCanAnnotateCalibrationProfile() throws {
        let calibratedBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2,
                    pressureCalibration: CommandPaletteTopPicks
                        .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                            biasPoints: 2,
                            sampleCount: 14
                        )
                )
        )
        XCTAssertEqual(calibratedBadge.tone, .alert)
        XCTAssertTrue(calibratedBadge.title.contains("Cal +2/14") == true)
        XCTAssertTrue(
            calibratedBadge.helpText.contains(
                "Calibration profile is Aggressive +2 from 14 samples."
            ) == true
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrendClassifiesRisingCoolingAndSteady() throws {
        let risingTrend = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend(
                    history: [41, 44, 53]
                )
        )
        XCTAssertEqual(risingTrend.direction, .rising)
        XCTAssertEqual(risingTrend.deltaPoints, 10)
        XCTAssertEqual(risingTrend.sampleCount, 3)
        XCTAssertEqual(risingTrend.subtitle, "Pressure trend rising (+10pts)")

        let coolingTrend = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend(
                    history: [69, 67, 58]
                )
        )
        XCTAssertEqual(coolingTrend.direction, .cooling)
        XCTAssertEqual(coolingTrend.deltaPoints, -10)
        XCTAssertEqual(coolingTrend.subtitle, "Pressure trend cooling (-10pts)")

        let steadyTrend = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend(
                    history: [56, 55, 57]
                )
        )
        XCTAssertEqual(steadyTrend.direction, .steady)
        XCTAssertEqual(steadyTrend.deltaPoints, 1)
        XCTAssertEqual(steadyTrend.subtitle, "Pressure trend steady (+1pts)")
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeActionHelpTextKeepsBaseCopyWithoutDiagnosticsCue() {
        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeActionHelpText(
                    baseHelpText: "Recovery suggestion CTA shown x5; launched x2 (40%).",
                    diagnosticsCue: nil,
                    actionTitle: "Run Fame Recovery Sprint"
                ),
            "Recovery suggestion CTA shown x5; launched x2 (40%)."
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeActionHelpTextAddsFocusCopyWhenDiagnosticsCueIsVisible() {
        let diagnosticsCue = CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
            tone: .watch,
            title: "Recovery Route Watch",
            subtitle: "Run rate 40% across 5 cues.",
            systemImage: "exclamationmark.shield.fill",
            buttonTitle: "Run Recovery Now",
            helpText: "sample"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeActionHelpText(
                    baseHelpText: "Recovery suggestion CTA shown x5; launched x2 (40%).",
                    diagnosticsCue: diagnosticsCue,
                    actionTitle: "Run Fame Recovery Sprint"
                ),
            "Recovery suggestion CTA shown x5; launched x2 (40%). Click to focus recovery diagnostics and highlight Run Fame Recovery Sprint."
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueReturnsNilWithoutExposureOrWhenStrong() {
        XCTAssertNil(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 0,
                runCount: 0,
                blockedCount: 0
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 10,
                runCount: 7,
                blockedCount: 0
            )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueFormatsWatchAndBlocked() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 5,
                runCount: 2,
                blockedCount: 1,
                actionTitle: "Run Fame Recovery Sprint"
            ),
            CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                tone: .watch,
                title: "Recovery Route Watch",
                subtitle: "Run rate 40% across 5 cues · 1 blocked.",
                systemImage: "exclamationmark.shield.fill",
                buttonTitle: "Run Recovery Now",
                helpText: "Recovery suggestion engagement is mixed at 40% across 5 cues. Run Fame Recovery Sprint to keep route stabilization momentum compounding."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 5,
                runCount: 1,
                blockedCount: 2,
                actionTitle: "Run Fame Launch Recovery Next"
            ),
            CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                tone: .blocked,
                title: "Recovery Route Blockers",
                subtitle: "Blocked x2/5 recovery cues · run rate 20%.",
                systemImage: "xmark.shield.fill",
                buttonTitle: "Run Recovery Now",
                helpText: "Recovery suggestions are blocking too often (40% blocked, 20% run rate). Run Fame Launch Recovery Next to reopen a clean stabilization lane."
            )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueCanEscalateCopyWhenNoRunnableActionIsAvailable() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 5,
                runCount: 2,
                blockedCount: 1,
                actionTitle: nil,
                hasRunnableAction: false
            ),
            CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                tone: .watch,
                title: "Recovery Route Watch",
                subtitle: "Run rate 40% across 5 cues · 1 blocked.",
                systemImage: "exclamationmark.shield.fill",
                buttonTitle: "Review Blockers",
                helpText: "Recovery suggestion engagement is mixed at 40% across 5 cues. No runnable recovery command is currently available, so review blockers to keep route stabilization momentum compounding."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 5,
                runCount: 1,
                blockedCount: 2,
                actionTitle: "Run Fame Launch Recovery Next",
                hasRunnableAction: false
            ),
            CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                tone: .blocked,
                title: "Recovery Route Blockers",
                subtitle: "Blocked x2/5 recovery cues · run rate 20%.",
                systemImage: "xmark.shield.fill",
                buttonTitle: "Resolve Blockers",
                helpText: "Recovery suggestions are blocking too often (40% blocked, 20% run rate). No runnable recovery command is currently available, so resolve blockers to reopen a clean stabilization lane."
            )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueUsesUnblockButtonTitleForNonRecoveryAction() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 5,
                runCount: 2,
                blockedCount: 1,
                actionTitle: "Run Fame Launch Control Health",
                hasRunnableAction: true
            ),
            CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                tone: .watch,
                title: "Recovery Route Watch",
                subtitle: "Run rate 40% across 5 cues · 1 blocked.",
                systemImage: "exclamationmark.shield.fill",
                buttonTitle: "Run Unblock Plan",
                helpText: "Recovery suggestion engagement is mixed at 40% across 5 cues. Run Fame Launch Control Health to keep route stabilization momentum compounding."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 5,
                runCount: 1,
                blockedCount: 2,
                actionTitle: "Run Fame Launch Control Health",
                hasRunnableAction: true
            ),
            CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                tone: .blocked,
                title: "Recovery Route Blockers",
                subtitle: "Blocked x2/5 recovery cues · run rate 20%.",
                systemImage: "xmark.shield.fill",
                buttonTitle: "Run Unblock Plan",
                helpText: "Recovery suggestions are blocking too often (40% blocked, 20% run rate). Run Fame Launch Control Health to reopen a clean stabilization lane."
            )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueAddsPressureWatchGuidance() throws {
        let pressureBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 6,
                    blockedCount: 1,
                    recoveryRunCount: 4,
                    unblockRunCount: 1
                )
        )
        XCTAssertEqual(pressureBadge.tone, .watch)

        let diagnosticsCue = try XCTUnwrap(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 6,
                runCount: 3,
                blockedCount: 1,
                pressureConfidenceBadge: pressureBadge,
                actionTitle: "Run Fame Recovery Sprint",
                hasRunnableAction: true
            )
        )
        XCTAssertEqual(diagnosticsCue.tone, .watch)
        XCTAssertEqual(diagnosticsCue.title, "Recovery Route Watch")
        XCTAssertTrue(diagnosticsCue.subtitle.contains("Pressure Mixed") == true)
        XCTAssertTrue(
            diagnosticsCue.helpText.contains("suggests blocker pressure is rising, so keep unblock coverage active.") == true
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueSurfacesCalibrationCueInSubtitle() throws {
        let pressureBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2,
                    pressureCalibration: CommandPaletteTopPicks
                        .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                            biasPoints: 2,
                            sampleCount: 14
                        )
                )
        )
        XCTAssertEqual(pressureBadge.tone, .alert)
        XCTAssertTrue(pressureBadge.title.contains("Cal +2/14") == true)

        let diagnosticsCue = try XCTUnwrap(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 12,
                runCount: 4,
                blockedCount: 4,
                pressureConfidenceBadge: pressureBadge,
                actionTitle: "Run Fame Launch Control Health",
                hasRunnableAction: true
            )
        )
        XCTAssertTrue(diagnosticsCue.subtitle.contains("Cal +2/14") == true)
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueCanEscalateToPressureAlert() throws {
        let pressureBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 8,
                    blockedCount: 2,
                    recoveryRunCount: 6,
                    unblockRunCount: 0
                )
        )
        XCTAssertEqual(pressureBadge.tone, .alert)

        let diagnosticsCue = try XCTUnwrap(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 8,
                runCount: 3,
                blockedCount: 2,
                pressureConfidenceBadge: pressureBadge,
                actionTitle: "Run Fame Launch Recovery Next",
                hasRunnableAction: true
            )
        )
        XCTAssertEqual(diagnosticsCue.tone, .blocked)
        XCTAssertEqual(diagnosticsCue.title, "Recovery Route Pressure Alert")
        XCTAssertTrue(diagnosticsCue.subtitle.contains("Pressure High") == true)
        XCTAssertTrue(
            diagnosticsCue.helpText.contains("signals critical blocker pressure, so prioritize unblock coverage now.") == true
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueCanEscalateToPressureSpikeFromRisingTrend() throws {
        let pressureBadge = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                    shownCount: 6,
                    blockedCount: 2,
                    recoveryRunCount: 3,
                    unblockRunCount: 1
                )
        )
        XCTAssertEqual(pressureBadge.tone, .watch)

        let pressureTrend = try XCTUnwrap(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend(
                    history: [22, 27, 35]
                )
        )
        XCTAssertEqual(pressureTrend.direction, .rising)

        let diagnosticsCue = try XCTUnwrap(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 5,
                runCount: 2,
                blockedCount: 1,
                pressureConfidenceBadge: pressureBadge,
                pressureConfidenceTrend: pressureTrend,
                actionTitle: "Run Fame Launch Recovery Next",
                hasRunnableAction: true
            )
        )
        XCTAssertEqual(diagnosticsCue.tone, .blocked)
        XCTAssertEqual(diagnosticsCue.title, "Recovery Route Pressure Spike")
        XCTAssertTrue(diagnosticsCue.subtitle.contains("Pressure trend rising") == true)
        XCTAssertTrue(
            diagnosticsCue.helpText.contains("Pressure trend is rising (+10pts vs recent baseline)") == true
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionButtonTitleAdaptsToActionRoute() {
        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionButtonTitle(
                    defaultTitle: "Run Full Recovery",
                    actionID: CommandPaletteAction.launchRecoveryNextActionID,
                    actionTitle: "Run Fame Launch Control Health"
                ),
            "Run Full Recovery"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionButtonTitle(
                    defaultTitle: "Run Full Recovery",
                    actionID: "run-fame-launch-control-health",
                    actionTitle: "Run Fame Launch Recovery Next"
                ),
            "Run Unblock Plan"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionButtonTitle(
                    defaultTitle: "   ",
                    actionID: nil,
                    actionTitle: "Run Fame Recovery Sprint"
                ),
            "Run Recovery Loop"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueClassifiesActionRouteUsingActionIDBeforeTitle() {
        let recoveryCue = CommandPaletteTopPicks
            .fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 5,
                runCount: 2,
                blockedCount: 1,
                actionID: CommandPaletteAction.launchRecoveryNextActionID,
                actionTitle: "Run Fame Launch Control Health",
                hasRunnableAction: true
            )
        XCTAssertEqual(recoveryCue?.buttonTitle, "Run Recovery Now")

        let unblockCue = CommandPaletteTopPicks
            .fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                shownCount: 5,
                runCount: 2,
                blockedCount: 1,
                actionID: "run-fame-launch-control-health",
                actionTitle: "Run Fame Launch Recovery Next",
                hasRunnableAction: true
            )
        XCTAssertEqual(unblockCue?.buttonTitle, "Run Unblock Plan")
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsActionHelpTextFormatsEnabledAndDisabledStates() {
        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsActionHelpText(
                    tone: .watch,
                    actionTitle: "Run Fame Recovery Sprint",
                    isEnabled: true,
                    disabledReason: ""
                ),
            "Run Fame Recovery Sprint to improve recovery cue throughput."
        )

        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsActionHelpText(
                    tone: .blocked,
                    actionTitle: "Run Fame Recovery Sprint",
                    isEnabled: false,
                    disabledReason: "Action is cooling down"
                ),
            "Recovery command is unavailable: Action is cooling down. Clear blockers to reopen a clean stabilization lane."
        )

        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsActionHelpText(
                    tone: .watch,
                    actionTitle: "Run Fame Recovery Sprint",
                    isEnabled: false,
                    disabledReason: "   "
                ),
            "Recovery command is unavailable: this command is currently unavailable. Resolve blockers, then rerun recovery."
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressureAdaptsForLowSampleRecoveryBias() {
        XCTAssertTrue(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 3,
                    blockedCount: 2,
                    recoveryRunCount: 4,
                    unblockRunCount: 0
                ),
            "Small samples should still flag blocker pressure when recovery bias is high and unblock coverage is absent."
        )

        XCTAssertFalse(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 3,
                    blockedCount: 1,
                    recoveryRunCount: 2,
                    unblockRunCount: 2
                ),
            "Balanced unblock coverage should suppress blocker-pressure escalation."
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressureRequiresMeaningfulRateAtScale() {
        XCTAssertFalse(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 18,
                    blockedCount: 3,
                    recoveryRunCount: 8,
                    unblockRunCount: 0
                ),
            "Large telemetry windows should resist escalation on low blocked rates."
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressureScalesSensitivityByTelemetryMaturity() {
        XCTAssertFalse(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 20,
                    blockedCount: 4,
                    recoveryRunCount: 10,
                    unblockRunCount: 0
                ),
            "At mature telemetry volumes, very low blocked rates should keep pressure relaxed."
        )

        XCTAssertTrue(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 20,
                    blockedCount: 7,
                    recoveryRunCount: 10,
                    unblockRunCount: 0
                ),
            "When blocked pressure rises at scale, the model should reactivate unblock pressure handling."
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressureCanUseCalibrationBias() {
        XCTAssertFalse(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2
                )
        )
        XCTAssertTrue(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2,
                    pressureCalibration: CommandPaletteTopPicks
                        .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                            biasPoints: 1,
                            sampleCount: 12
                        )
                )
        )

        XCTAssertTrue(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 8,
                    blockedCount: 2,
                    recoveryRunCount: 6,
                    unblockRunCount: 0
                )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 8,
                    blockedCount: 2,
                    recoveryRunCount: 6,
                    unblockRunCount: 0,
                    pressureCalibration: CommandPaletteTopPicks
                        .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                            biasPoints: -3,
                            sampleCount: 20
                        )
                )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressureIgnoresCalibrationBiasWithoutSamples() {
        XCTAssertFalse(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2
                )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2,
                    pressureCalibration: CommandPaletteTopPicks
                        .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                            biasPoints: 3,
                            sampleCount: 0
                        )
                )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressureWeightsCalibrationBySampleMaturity() {
        XCTAssertFalse(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2,
                    pressureCalibration: CommandPaletteTopPicks
                        .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                            biasPoints: 3,
                            sampleCount: 1
                        )
                )
        )
        XCTAssertTrue(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2,
                    pressureCalibration: CommandPaletteTopPicks
                        .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                            biasPoints: 3,
                            sampleCount: 12
                        )
                )
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionAdaptiveTriggerThresholdDropsOneStepUnderBlockedPressure() {
        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionAdaptiveTriggerThreshold(
                    defaultThreshold: 3,
                    shownCount: 6,
                    blockedCount: 3,
                    recoveryRunCount: 4,
                    unblockRunCount: 0
                ),
            2
        )
        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionAdaptiveTriggerThreshold(
                    defaultThreshold: 2,
                    shownCount: 6,
                    blockedCount: 3,
                    recoveryRunCount: 4,
                    unblockRunCount: 0
                ),
            1
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoverySuggestionAdaptiveTriggerThresholdCanUseCalibrationBias() {
        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionAdaptiveTriggerThreshold(
                    defaultThreshold: 3,
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2
                ),
            3
        )
        XCTAssertEqual(
            CommandPaletteTopPicks
                .fameMomentumPanelRouteStabilizationRecoverySuggestionAdaptiveTriggerThreshold(
                    defaultThreshold: 3,
                    shownCount: 12,
                    blockedCount: 4,
                    recoveryRunCount: 5,
                    unblockRunCount: 2,
                    pressureCalibration: CommandPaletteTopPicks
                        .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                            biasPoints: 2,
                            sampleCount: 14
                        )
                ),
            2
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDPrefersHighestPriorityEnabledAction() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-recovery-checklist",
                secondaryActionID: "run-fame-recovery-sprint",
                enabledActionIDs: [
                    "run-fame-launch-recovery-next",
                    "run-fame-recovery-checklist",
                    "run-fame-recovery-sprint"
                ]
            ),
            "run-fame-launch-recovery-next"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDCanFallbackToEnabledUnblockActionWhenRecoveryRoutesAreUnavailable() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-recovery-sprint",
                secondaryActionID: "run-fame-recovery-checklist",
                enabledActionIDs: ["run-fame-launch-control-health"]
            ),
            "run-fame-launch-control-health"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDKeepsRecoveryPriorityAheadOfUnblockFallbacks() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-recovery-sprint",
                secondaryActionID: nil,
                enabledActionIDs: [
                    "run-fame-recovery-sprint",
                    "run-fame-launch-control-health"
                ]
            ),
            "run-fame-recovery-sprint"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDPrioritizesUnblockRouteUnderSustainedBlockedPressure() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-launch-recovery-next",
                secondaryActionID: "run-fame-recovery-sprint",
                enabledActionIDs: [
                    "run-fame-launch-recovery-next",
                    "run-fame-launch-control-health"
                ],
                recoverySuggestionShownCount: 6,
                recoverySuggestionBlockedCount: 3,
                recoverySuggestionRecoveryRunCount: 4,
                recoverySuggestionUnblockRunCount: 0
            ),
            "run-fame-launch-control-health"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDCanUsePressureCalibrationToPreferUnblockRoute() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-launch-recovery-next",
                secondaryActionID: "run-fame-recovery-sprint",
                enabledActionIDs: [
                    "run-fame-launch-recovery-next",
                    "run-fame-launch-control-health"
                ],
                recoverySuggestionShownCount: 12,
                recoverySuggestionBlockedCount: 4,
                recoverySuggestionRecoveryRunCount: 5,
                recoverySuggestionUnblockRunCount: 2
            ),
            "run-fame-launch-recovery-next"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-launch-recovery-next",
                secondaryActionID: "run-fame-recovery-sprint",
                enabledActionIDs: [
                    "run-fame-launch-recovery-next",
                    "run-fame-launch-control-health"
                ],
                recoverySuggestionShownCount: 12,
                recoverySuggestionBlockedCount: 4,
                recoverySuggestionRecoveryRunCount: 5,
                recoverySuggestionUnblockRunCount: 2,
                pressureCalibration: CommandPaletteTopPicks
                    .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                        biasPoints: 2,
                        sampleCount: 14
                    )
            ),
            "run-fame-launch-control-health"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDKeepsRecoveryPriorityWhenUnblockCoverageIsHealthy() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-launch-recovery-next",
                secondaryActionID: "run-fame-recovery-sprint",
                enabledActionIDs: [
                    "run-fame-launch-recovery-next",
                    "run-fame-launch-control-health"
                ],
                recoverySuggestionShownCount: 6,
                recoverySuggestionBlockedCount: 3,
                recoverySuggestionRecoveryRunCount: 3,
                recoverySuggestionUnblockRunCount: 3
            ),
            "run-fame-launch-recovery-next"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDCanPreferAvailableUnblockRouteUnderBlockedPressure() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-next-move-copy-drafts",
                secondaryActionID: nil,
                enabledActionIDs: ["read-selected"],
                availableActionIDs: [
                    "run-fame-launch-control-brief",
                    "run-fame-recovery-sprint"
                ],
                recoverySuggestionShownCount: 5,
                recoverySuggestionBlockedCount: 2,
                recoverySuggestionRecoveryRunCount: 3,
                recoverySuggestionUnblockRunCount: 0
            ),
            "run-fame-launch-control-brief"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDFallsBackToDirectEnabledActionWhenPriorityUnavailable() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-next-move-copy-drafts",
                secondaryActionID: nil,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDCanFallbackToAvailablePriorityActionWhenEnabledSetHasNoCandidate() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-next-move-copy-drafts",
                secondaryActionID: nil,
                enabledActionIDs: ["read-selected"],
                availableActionIDs: [
                    "run-fame-recovery-checklist",
                    "run-fame-recovery-sprint",
                    "run-fame-next-move-copy-drafts"
                ]
            ),
            "run-fame-recovery-sprint"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDCanFallbackToAvailableDirectActionWhenPriorityUnavailable() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-next-move-copy-drafts",
                secondaryActionID: nil,
                enabledActionIDs: ["read-selected"],
                availableActionIDs: ["run-fame-next-move-copy-drafts"]
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDPrefersEnabledCandidateOverUnavailablePriorityAction() {
        XCTAssertEqual(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-next-move-copy-drafts",
                secondaryActionID: nil,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"],
                availableActionIDs: [
                    "run-fame-launch-recovery-next",
                    "run-fame-next-move-copy-drafts"
                ]
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testTopPicksFameMomentumPanelRouteStabilizationRecoveryActionIDReturnsNilWhenNoCandidateIsEnabled() {
        XCTAssertNil(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-recovery-checklist",
                secondaryActionID: "run-fame-next-move-copy-drafts",
                enabledActionIDs: []
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationRecoveryActionID(
                primaryActionID: "run-fame-recovery-checklist",
                secondaryActionID: nil,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            )
        )
    }

    func testTopPicksFameMomentumPanelReturnsNilWithoutSignalsOrAttention() {
        XCTAssertNil(
            CommandPaletteTopPicks.fameMomentumPanel(
                confidenceScore: makeLaunchRecoveryConfidenceScore(tier: .prime, points: 92),
                winDelta: nil,
                rescuePlan: nil,
                hallOfFameCue: nil,
                trustGuardActionID: "run-trust-fix",
                trustMomentumPlanActionID: "run-fame-cadence-autopilot-loop",
                enabledActionIDs: [
                    "run-trust-fix",
                    "run-fame-cadence-autopilot-loop"
                ]
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyMomentumCapturesRisingFallingAndSteady() {
        let risingMomentum = CommandPaletteTopPicks.launchRecoveryHotKeyMomentum(
            for: [.standby, .reroute, .reroute, .direct, .reroute, .direct, .direct, .direct],
            window: 4
        )
        XCTAssertEqual(
            risingMomentum,
            CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum(
                direction: .rising,
                deltaPoints: 33,
                previousScore: 56,
                recentScore: 89,
                windowSize: 4,
                title: "Momentum +33",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Launch recovery momentum compares last 4 opens (89/100) vs prior 4 opens (56/100), Δ+33."
            )
        )

        let fallingMomentum = CommandPaletteTopPicks.launchRecoveryHotKeyMomentum(
            for: [.direct, .direct, .reroute, .direct, .reroute, .standby, .standby, .reroute],
            window: 4
        )
        XCTAssertEqual(
            fallingMomentum,
            CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum(
                direction: .falling,
                deltaPoints: -54,
                previousScore: 89,
                recentScore: 35,
                windowSize: 4,
                title: "Momentum -54",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Launch recovery momentum compares last 4 opens (35/100) vs prior 4 opens (89/100), Δ-54."
            )
        )

        let steadyMomentum = CommandPaletteTopPicks.launchRecoveryHotKeyMomentum(
            for: [.direct, .reroute, .direct, .reroute, .direct, .direct, .reroute, .reroute],
            window: 4
        )
        XCTAssertEqual(
            steadyMomentum,
            CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum(
                direction: .steady,
                deltaPoints: 0,
                previousScore: 78,
                recentScore: 78,
                windowSize: 4,
                title: "Momentum Stable",
                systemImage: "equal.circle.fill",
                helpText: "Launch recovery momentum compares last 4 opens (78/100) vs prior 4 opens (78/100), Δ0."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyMomentumRequiresTwoWindows() {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentum(
                for: [.direct, .reroute, .standby, .direct, .reroute, .direct, .standby],
                window: 4
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyConfidenceScoreUsesTrendAndStreakSignals() {
        let trend = CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
            directCount: 3,
            rerouteCount: 2,
            standbyCount: 1
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceScore(
                readiness: .direct(actionID: "run-fame-onboarding-scorecard"),
                trend: trend,
                directStreak: 2,
                bestDirectStreak: 4
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore(
                points: 79,
                tier: .steady,
                title: "Confidence 79 · Steady",
                subtitle: "Direct routing is stable. Keep stacking direct opens (streak x2, best x4).",
                systemImage: "chart.line.uptrend.xyaxis",
                helpText: "Launch recovery confidence score 79/100 (Steady). Trend D3·R2·S1. Direct streak x2, best x4."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyConfidenceScoreMapsLowAndPrimeTiers() {
        let watchScore = CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceScore(
            readiness: .reroute(actionID: "run-fame-cadence-autopilot-loop"),
            trend: CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
                directCount: 1,
                rerouteCount: 4,
                standbyCount: 1
            ),
            directStreak: 0,
            bestDirectStreak: 2
        )
        XCTAssertEqual(watchScore.tier, .watch)
        XCTAssertEqual(watchScore.points, 36)
        XCTAssertEqual(
            watchScore.subtitle,
            "Reroute pressure is rising. Run a coach step to restore direct confidence."
        )
        XCTAssertTrue(
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceScoreNeedsAttention(watchScore)
        )

        let criticalScore = CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceScore(
            readiness: .unavailable,
            trend: nil,
            directStreak: 0,
            bestDirectStreak: 0
        )
        XCTAssertEqual(criticalScore.tier, .critical)
        XCTAssertEqual(criticalScore.points, 8)
        XCTAssertTrue(
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceScoreNeedsAttention(criticalScore)
        )

        let primeScore = CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceScore(
            readiness: .direct(actionID: "run-fame-onboarding-scorecard"),
            trend: CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
                directCount: 5,
                rerouteCount: 1,
                standbyCount: 0
            ),
            directStreak: 4,
            bestDirectStreak: 6
        )
        XCTAssertEqual(primeScore.tier, .prime)
        XCTAssertEqual(primeScore.points, 94)
        XCTAssertFalse(
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceScoreNeedsAttention(primeScore)
        )
    }

    func testTopPicksLaunchRecoveryHotKeyConfidencePulseFormatsTierTransitions() {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidencePulse(
                previousTier: .steady,
                nextTier: .steady,
                points: 70
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidencePulse(
                previousTier: .watch,
                nextTier: .prime,
                points: 84
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidencePulse(
                title: "Confidence Prime",
                subtitle: "Recovery confidence reached Prime (84). Keep direct streak alive.",
                systemImage: "checkmark.seal.fill",
                helpText: "Launch recovery confidence climbed from Watch to Prime at 84/100. Keep stacking direct opens to preserve prime routing."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidencePulse(
                previousTier: .prime,
                nextTier: .watch,
                points: 44
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidencePulse(
                title: "Confidence Drop",
                subtitle: "Recovery confidence slipped to Watch (44).",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Launch recovery confidence dropped from Prime to Watch at 44/100."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidencePulse(
                previousTier: .steady,
                nextTier: .critical,
                points: 19
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidencePulse(
                title: "Confidence Drop",
                subtitle: "Recovery confidence fell to Critical (19). Run coach now.",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Launch recovery confidence dropped from Steady to Critical at 19/100. Run a coach step to restore direct routing."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyMomentumPulseEmitsForSurgeSlipAndBreakouts() {
        let steadyMomentum = makeLaunchRecoveryMomentumSnapshot(
            direction: .steady,
            deltaPoints: 0,
            previousScore: 78,
            recentScore: 78
        )
        let risingMomentum = makeLaunchRecoveryMomentumSnapshot(
            direction: .rising,
            deltaPoints: 16,
            previousScore: 70,
            recentScore: 86
        )
        let risingBreakoutMomentum = makeLaunchRecoveryMomentumSnapshot(
            direction: .rising,
            deltaPoints: 28,
            previousScore: 66,
            recentScore: 94
        )
        let fallingMomentum = makeLaunchRecoveryMomentumSnapshot(
            direction: .falling,
            deltaPoints: -14,
            previousScore: 64,
            recentScore: 50
        )
        let fallingAlertMomentum = makeLaunchRecoveryMomentumSnapshot(
            direction: .falling,
            deltaPoints: -29,
            previousScore: 60,
            recentScore: 31
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
                previousMomentum: nil,
                nextMomentum: steadyMomentum
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
                previousMomentum: steadyMomentum,
                nextMomentum: risingMomentum
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse(
                tone: .rising,
                title: "Recovery Momentum Surge",
                subtitle: "Launch recovery pace accelerated to 86/100 (Δ+16).",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Launch recovery momentum turned upward across 4-open windows (70 → 86, Δ+16)."
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
                previousMomentum: risingMomentum,
                nextMomentum: makeLaunchRecoveryMomentumSnapshot(
                    direction: .rising,
                    deltaPoints: 22,
                    previousScore: 71,
                    recentScore: 93
                )
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
                previousMomentum: risingMomentum,
                nextMomentum: risingBreakoutMomentum
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse(
                tone: .rising,
                title: "Recovery Momentum Breakout",
                subtitle: "Launch recovery hit breakout pace at 94/100 (Δ+28).",
                systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                helpText: "Launch recovery momentum expanded to breakout pace across 4-open windows (66 → 94, Δ+28). Keep direct runs compounding."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
                previousMomentum: steadyMomentum,
                nextMomentum: fallingMomentum
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse(
                tone: .falling,
                title: "Recovery Momentum Slip",
                subtitle: "Launch recovery pace slipped to 50/100 (Δ-14).",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Launch recovery momentum turned downward across 4-open windows (64 → 50, Δ-14)."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
                previousMomentum: fallingMomentum,
                nextMomentum: fallingAlertMomentum
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse(
                tone: .falling,
                title: "Recovery Momentum Alert",
                subtitle: "Launch recovery dropped to 31/100 (Δ-29). Run coach now.",
                systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
                helpText: "Launch recovery momentum has sharply deteriorated across 4-open windows (60 → 31, Δ-29). Run a coach step now."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyMomentumRescuePrioritizesBestAction() {
        let risingPulse = CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse(
            tone: .rising,
            title: "Recovery Momentum Surge",
            subtitle: "Launch recovery pace accelerated to 88/100 (Δ+17).",
            systemImage: "arrow.up.right.circle.fill",
            helpText: "Launch recovery momentum turned upward across 4-open windows (71 → 88, Δ+17)."
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumRescue(
                pulse: risingPulse,
                coachCue: nil,
                readiness: .direct(actionID: "run-fame-onboarding-scorecard"),
                enabledActionIDs: ["run-fame-onboarding-scorecard"]
            )
        )

        let fallingPulse = CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse(
            tone: .falling,
            title: "Recovery Momentum Slip",
            subtitle: "Launch recovery pace slipped to 48/100 (Δ-15).",
            systemImage: "arrow.down.right.circle.fill",
            helpText: "Launch recovery momentum turned downward across 4-open windows (63 → 48, Δ-15)."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumRescue(
                pulse: fallingPulse,
                coachCue: CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue(
                    title: "Coach",
                    subtitle: "Run fill gap",
                    systemImage: "arrow.triangle.2.circlepath",
                    actionID: "run-fame-onboarding-fill-gap"
                ),
                readiness: .reroute(actionID: "run-fame-cadence-autopilot-loop"),
                enabledActionIDs: ["run-fame-onboarding-fill-gap", "run-fame-cadence-autopilot-loop"]
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumRescue(
                severity: .watch,
                title: "Momentum Rescue Ready",
                subtitle: "Launch recovery pace slipped to 48/100 (Δ-15). Fill Onboarding Gap now.",
                systemImage: "cross.case",
                helpText: "Launch recovery momentum turned downward across 4-open windows (63 → 48, Δ-15). Run Fill Onboarding Gap now to recover launch-routing momentum.",
                actionID: "run-fame-onboarding-fill-gap"
            )
        )

        let alertPulse = CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse(
            tone: .falling,
            title: "Recovery Momentum Alert",
            subtitle: "Launch recovery dropped to 31/100 (Δ-29). Run coach now.",
            systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
            helpText: "Launch recovery momentum has sharply deteriorated across 4-open windows (60 → 31, Δ-29). Run a coach step now."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumRescue(
                pulse: alertPulse,
                coachCue: nil,
                readiness: .unavailable,
                enabledActionIDs: [CommandPaletteAction.launchRecoveryNextActionID]
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumRescue(
                severity: .alert,
                title: "Momentum Rescue Alert",
                subtitle: "Launch recovery dropped to 31/100 (Δ-29). Run coach now. Launch Recovery Next now.",
                systemImage: "cross.case.fill",
                helpText: "Launch recovery momentum has sharply deteriorated across 4-open windows (60 → 31, Δ-29). Run a coach step now. Run Launch Recovery Next now to recover launch-routing momentum.",
                actionID: CommandPaletteAction.launchRecoveryNextActionID
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLeaguePulseFormatsPromotionsOnly() {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeaguePulse(
                fromTier: .elite,
                toTier: .elite,
                runsThisWeek: 6,
                currentStreak: 3
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeaguePulse(
                fromTier: .legend,
                toTier: .rising,
                runsThisWeek: 6,
                currentStreak: 3
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeaguePulse(
                fromTier: .rising,
                toTier: .elite,
                runsThisWeek: 7,
                currentStreak: 4
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeaguePulse(
                fromTier: .rising,
                toTier: .elite,
                title: "Auto League Elite Unlocked",
                subtitle: "Promoted from Rising • Week 7 • Streak x4d",
                systemImage: "sparkles",
                helpText: "Auto Trust Surge promoted from Rising to Elite. Weekly auto-run volume is 7 with a streak of x4d."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeaguePulse(
                fromTier: .elite,
                toTier: .legend,
                runsThisWeek: 10,
                currentStreak: 5
            )?.systemImage,
            "crown.fill"
        )
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulseFormatsPromotionsOnly() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse(
                fromTier: .elite,
                toTier: .elite,
                currentWeekRuns: 6,
                currentStreak: 4
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse(
                fromTier: .legend,
                toTier: .rising,
                currentWeekRuns: 6,
                currentStreak: 4
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse(
                fromTier: .rising,
                toTier: .elite,
                currentWeekRuns: 6,
                currentStreak: 4
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse(
                fromTier: .rising,
                toTier: .elite,
                title: "Defense League Elite Unlocked",
                subtitle: "Promoted from Rising • Week 6 • Streak x4d",
                systemImage: "sparkles",
                helpText: "Hall-of-Fame auto-defense league promoted from Rising to Elite. Weekly auto-defense volume is 6 with a streak of x4d."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse(
                fromTier: .elite,
                toTier: .legend,
                currentWeekRuns: 8,
                currentStreak: 7
            )?.systemImage,
            "crown.fill"
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseEmitsOnRiskEscalationAndWindowReady() {
        let alertForecast = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            tone: .alert,
            riskLabel: "High",
            nextDefenseMinutes: 0,
            nextDefenseLabel: "now",
            title: "Legend Decay Forecast",
            subtitle: "Risk High · est. tier slip ~14d · Next defense now",
            systemImage: "hourglass.badge.exclamationmark",
            helpText: "Auto Trust Surge is armed and ready.",
            actionID: "run-fame-cadence-autopilot-loop"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                previousForecast: nil,
                nextForecast: alertForecast
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                tone: .alert,
                title: "Legend Risk Alert",
                subtitle: "Risk High · est. tier slip ~14d · Next defense now",
                systemImage: "hourglass.badge.exclamationmark",
                helpText: "Legend decay risk escalated to High. Auto Trust Surge is armed and ready."
            )
        )

        let watchDelayed = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            tone: .watch,
            riskLabel: "Watch",
            nextDefenseMinutes: 12,
            nextDefenseLabel: "in 12m (~11:32)",
            title: "Legend Stability Forecast",
            subtitle: "Risk Watch · 3w steady · Legend at 24 · Next defense in 12m (~11:32)",
            systemImage: "clock.arrow.circlepath",
            helpText: "Auto Trust Surge is cooling down.",
            actionID: nil
        )
        let watchReady = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            tone: .watch,
            riskLabel: "Watch",
            nextDefenseMinutes: 0,
            nextDefenseLabel: "now",
            title: "Legend Stability Forecast",
            subtitle: "Risk Watch · 3w steady · Legend at 24 · Next defense now",
            systemImage: "clock.arrow.circlepath",
            helpText: "Auto Trust Surge is armed and ready.",
            actionID: nil
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                previousForecast: watchDelayed,
                nextForecast: watchReady
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                tone: .ready,
                title: "Legend Defense Window Open",
                subtitle: "Next defense is now · Risk Watch",
                systemImage: "shield.checkerboard",
                helpText: "Legend defense timing just shifted to now. Auto Trust Surge is armed and ready."
            )
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                previousForecast: watchDelayed,
                nextForecast: watchDelayed
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyLegendRiskStickyReleasePulseFormatsRecoveredUnpin() {
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyLegendRiskStickyReleasePulse(
                actionID: "run-fame-cadence-autopilot-loop"
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyLegendRiskStickyReleasePulse(
                title: "Legend Hold Released",
                subtitle: "Run Fame Cadence Autopilot Loop unpinned after recovery.",
                systemImage: "pin.slash.fill",
                helpText: "Legend decay forecast recovered, so Run Fame Cadence Autopilot Loop was unpinned from sticky Top Picks promotion."
            )
        )
    }

    func testTopPicksRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseFormatsRecoveredUnpin() {
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
                actionID: "run-fame-next-move-copy-drafts"
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
                title: "Hall-of-Fame Hold Released",
                subtitle: "Copy Next-Move Drafts unpinned after Hall-of-Fame recovery.",
                systemImage: "pin.slash.fill",
                helpText: "Hall-of-Fame legend risk recovered, so Copy Next-Move Drafts was unpinned from sticky Top Picks promotion."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionsPrioritizeCoachAndRecoveryNext() {
        let interventions = CommandPaletteTopPicks.launchRecoveryHotKeyInterventions(
            score: makeLaunchRecoveryConfidenceScore(tier: .critical, points: 22),
            readiness: .reroute(actionID: "run-fame-onboarding-daily-brief"),
            trend: CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
                directCount: 0,
                rerouteCount: 2,
                standbyCount: 4
            ),
            coachCue: CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue(
                title: "Coach: Restore ⌥⇧L Direct",
                subtitle: "Reroute leads 4/6 opens. Run Fill Onboarding Gap to restore direct launch recovery.",
                systemImage: "arrow.triangle.2.circlepath",
                actionID: "run-fame-onboarding-fill-gap"
            ),
            enabledActionIDs: [
                "run-fame-onboarding-fill-gap",
                "run-fame-onboarding-daily-brief",
                "run-fame-launch-recovery-next"
            ],
            limit: 3
        )

        XCTAssertEqual(
            interventions.map(\.actionID),
            [
                "run-fame-onboarding-fill-gap",
                "run-fame-onboarding-daily-brief",
                "run-fame-launch-recovery-next"
            ]
        )
        XCTAssertEqual(interventions.first?.title, "Coach Step")
        XCTAssertEqual(interventions.last?.title, "Recovery Next")
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionsProvideTierTunedFallbacks() {
        let watchInterventions = CommandPaletteTopPicks.launchRecoveryHotKeyInterventions(
            score: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 47),
            readiness: .unavailable,
            trend: nil,
            coachCue: nil,
            enabledActionIDs: [
                "run-fame-launch-recovery-next",
                "run-fame-onboarding-scorecard",
                "run-fame-onboarding-daily-brief"
            ],
            limit: 3
        )
        XCTAssertEqual(
            watchInterventions.map(\.actionID),
            [
                "run-fame-launch-recovery-next",
                "run-fame-onboarding-scorecard",
                "run-fame-onboarding-daily-brief"
            ]
        )
        XCTAssertEqual(watchInterventions.first?.title, "Recovery Next")

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventions(
                score: makeLaunchRecoveryConfidenceScore(tier: .steady, points: 71),
                readiness: .direct(actionID: "run-fame-onboarding-scorecard"),
                trend: nil,
                coachCue: nil,
                enabledActionIDs: [
                    "run-fame-launch-recovery-next",
                    "run-fame-onboarding-scorecard"
                ],
                limit: 3
            ),
            []
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionsCanUseObservedImpactToReorder() {
        let interventions = CommandPaletteTopPicks.launchRecoveryHotKeyInterventions(
            score: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 45),
            readiness: .unavailable,
            trend: nil,
            coachCue: nil,
            enabledActionIDs: [
                "run-fame-launch-recovery-next",
                "run-fame-onboarding-scorecard",
                "run-fame-onboarding-daily-brief"
            ],
            interventionScores: [
                "run-fame-onboarding-daily-brief": 5,
                "run-fame-onboarding-scorecard": 2,
                "run-fame-launch-recovery-next": -1
            ],
            limit: 3
        )

        XCTAssertEqual(
            interventions.map(\.actionID),
            [
                "run-fame-onboarding-daily-brief",
                "run-fame-onboarding-scorecard",
                "run-fame-launch-recovery-next"
            ]
        )
        XCTAssertEqual(interventions.first?.impactScore, 5)
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionsCanSurfaceRecencyMetadata() {
        let interventions = CommandPaletteTopPicks.launchRecoveryHotKeyInterventions(
            score: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 45),
            readiness: .unavailable,
            trend: nil,
            coachCue: nil,
            enabledActionIDs: [
                "run-fame-launch-recovery-next",
                "run-fame-onboarding-scorecard",
                "run-fame-onboarding-daily-brief"
            ],
            interventionScores: [
                "run-fame-onboarding-daily-brief": 5,
                "run-fame-onboarding-scorecard": 2
            ],
            interventionRecency: [
                "run-fame-onboarding-daily-brief": .stale(opensAgo: 4),
                "run-fame-onboarding-scorecard": .recentlyValidated(opensAgo: 1)
            ],
            limit: 3
        )

        XCTAssertEqual(
            interventions.map(\.actionID),
            [
                "run-fame-onboarding-daily-brief",
                "run-fame-onboarding-scorecard",
                "run-fame-launch-recovery-next"
            ]
        )
        XCTAssertEqual(interventions.first?.recency, .stale(opensAgo: 4))
        XCTAssertEqual(interventions.dropFirst().first?.recency, .recentlyValidated(opensAgo: 1))
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustPointsPreferRecentStrongSignals() {
        let recentStrong = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPoints(
            interventionScores: [
                "run-fame-onboarding-daily-brief": 6,
                "run-fame-onboarding-scorecard": 4
            ],
            interventionRecency: [
                "run-fame-onboarding-daily-brief": .recentlyValidated(opensAgo: 0),
                "run-fame-onboarding-scorecard": .recentlyValidated(opensAgo: 1)
            ]
        )
        let staleWeak = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPoints(
            interventionScores: [
                "run-fame-onboarding-daily-brief": 1,
                "run-fame-onboarding-scorecard": -1
            ],
            interventionRecency: [
                "run-fame-onboarding-daily-brief": .stale(opensAgo: 5),
                "run-fame-onboarding-scorecard": .stale(opensAgo: 6)
            ]
        )

        XCTAssertGreaterThan(recentStrong, staleWeak)
        XCTAssertGreaterThanOrEqual(recentStrong, 70)
        XCTAssertLessThanOrEqual(staleWeak, 45)
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPoints(
                interventionScores: [:],
                interventionRecency: [:]
            ),
            24
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustTrendCapturesDirection() {
        let rising = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustTrend(
            for: [31, 36, 44, 57, 66, 72],
            limit: 8
        )
        XCTAssertEqual(rising?.direction, .rising)
        XCTAssertEqual(rising?.title, "Intervention Trust Rising")
        XCTAssertEqual(rising?.currentPoints, 72)
        XCTAssertEqual(rising?.samples.count, 6)

        let falling = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustTrend(
            for: [74, 70, 62, 55, 47],
            limit: 8
        )
        XCTAssertEqual(falling?.direction, .falling)
        XCTAssertEqual(falling?.title, "Intervention Trust Sliding")

        let steady = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustTrend(
            for: [52, 53, 51, 52, 54],
            limit: 8
        )
        XCTAssertEqual(steady?.direction, .steady)
        XCTAssertEqual(steady?.title, "Intervention Trust Stable")
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustMomentumRequiresConsecutiveRebounds() throws {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentum(for: [24])
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentum(
                for: [24, 37]
            ),
            "Single rebound should not show momentum badge."
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentum(
                for: [24, 37, 31]
            ),
            "Momentum should reset when rebound sequence breaks."
        )

        let streakTwo = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentum(
                for: [24, 37, 50]
            )
        )
        XCTAssertEqual(streakTwo.streak, 2)
        XCTAssertEqual(streakTwo.title, "Trust Momentum x2")
        XCTAssertEqual(streakTwo.subtitle, "Rebound +26 · Trust 50/100")
        XCTAssertEqual(streakTwo.systemImage, "arrow.up.right.circle.fill")

        let streakThree = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentum(
                for: [24, 37, 50, 64]
            )
        )
        XCTAssertEqual(streakThree.streak, 3)
        XCTAssertEqual(streakThree.systemImage, "flame.fill")

        let streakFive = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentum(
                for: [10, 25, 40, 55, 70, 85]
            )
        )
        XCTAssertEqual(streakFive.streak, 5)
        XCTAssertEqual(streakFive.systemImage, "trophy.fill")

        XCTAssertNotNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentum(
                for: [20, 27, 34],
                reboundDeltaThreshold: 7,
                minimumStreak: 2
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustMomentumPulseUsesMilestoneThresholds() throws {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPulse(
                for: [24, 37, 50]
            ),
            "Streak x2 should not emit a milestone pulse."
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPulse(
                for: [24, 37, 50, 64, 78]
            ),
            "Only milestone streaks should emit momentum pulses."
        )

        let milestoneThree = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPulse(
                for: [24, 37, 50, 64]
            )
        )
        XCTAssertEqual(milestoneThree.streak, 3)
        XCTAssertEqual(milestoneThree.milestone, 3)
        XCTAssertEqual(milestoneThree.title, "Trust Momentum Milestone x3")
        XCTAssertEqual(
            milestoneThree.subtitle,
            "Milestone x3 unlocked · Rebound +40 · Trust 64/100"
        )
        XCTAssertEqual(milestoneThree.systemImage, "flame.fill")

        let milestoneFive = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPulse(
                for: [10, 25, 40, 55, 70, 85]
            )
        )
        XCTAssertEqual(milestoneFive.streak, 5)
        XCTAssertEqual(milestoneFive.milestone, 5)
        XCTAssertEqual(milestoneFive.title, "Trust Momentum Milestone x5")
        XCTAssertEqual(
            milestoneFive.subtitle,
            "Milestone x5 unlocked · Rebound +75 · Trust 85/100"
        )
        XCTAssertEqual(milestoneFive.systemImage, "trophy.fill")

        let milestoneTen = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPulse(
                for: [20, 27, 34, 41, 48, 55, 62, 69, 76, 83, 90],
                reboundDeltaThreshold: 7
            )
        )
        XCTAssertEqual(milestoneTen.streak, 10)
        XCTAssertEqual(milestoneTen.milestone, 10)
        XCTAssertEqual(milestoneTen.title, "Trust Momentum Milestone x10")
        XCTAssertEqual(
            milestoneTen.subtitle,
            "Milestone x10 unlocked · Rebound +70 · Trust 90/100"
        )
        XCTAssertEqual(milestoneTen.systemImage, "trophy.fill")
        XCTAssertEqual(
            milestoneTen.helpText,
            "Trust Momentum Milestone x10. Intervention trust has rebounded for 10 consecutive opens (+70 points) and now sits at 90/100. Keep the current recovery ordering active while momentum holds."
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustMomentumPlanFormatsActionAndNextMilestone() throws {
        let momentum = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentum(
                for: [24, 37, 50, 64]
            )
        )
        let plan = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPlan(
                momentum: momentum,
                interventions: [
                    CommandPaletteTopPicks.LaunchRecoveryHotKeyIntervention(
                        actionID: "run-fame-onboarding-daily-brief",
                        title: "Daily Brief",
                        subtitle: "Queue today’s next recovery move.",
                        systemImage: "calendar.badge.clock",
                        helpText: "Run daily brief",
                        impactScore: 4
                    )
                ],
                coachCue: nil,
                enabledActionIDs: [
                    "run-fame-onboarding-daily-brief"
                ]
            )
        )

        XCTAssertEqual(plan.streak, 3)
        XCTAssertEqual(plan.nextMilestone, 5)
        XCTAssertEqual(plan.remainingOpens, 2)
        XCTAssertEqual(plan.title, "Trust Surge x3")
        XCTAssertEqual(
            plan.subtitle,
            "Next milestone x5 in 2 opens · Run First-Week Daily Brief."
        )
        XCTAssertEqual(plan.systemImage, "flame.fill")
        XCTAssertEqual(plan.actionID, "run-fame-onboarding-daily-brief")
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustMomentumPlanPrefersInterventionThenCoachThenRecoveryNext() throws {
        let momentum = CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustMomentum(
            streak: 5,
            title: "Trust Momentum x5",
            subtitle: "Rebound +75 · Trust 85/100",
            systemImage: "trophy.fill",
            helpText: "Momentum"
        )
        let coachCue = CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue(
            title: "Coach",
            subtitle: "Run scorecard",
            systemImage: "sparkles",
            actionID: "run-fame-onboarding-scorecard"
        )

        let interventionPlan = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPlan(
                momentum: momentum,
                interventions: [
                    CommandPaletteTopPicks.LaunchRecoveryHotKeyIntervention(
                        actionID: "run-fame-onboarding-daily-brief",
                        title: "Daily Brief",
                        subtitle: "Queue today’s next recovery move.",
                        systemImage: "calendar.badge.clock",
                        helpText: "Run daily brief",
                        impactScore: 2
                    )
                ],
                coachCue: coachCue,
                enabledActionIDs: [
                    "run-fame-onboarding-daily-brief",
                    "run-fame-onboarding-scorecard",
                    CommandPaletteAction.launchRecoveryNextActionID
                ]
            )
        )
        XCTAssertEqual(interventionPlan.actionID, "run-fame-onboarding-daily-brief")

        let coachFallbackPlan = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPlan(
                momentum: momentum,
                interventions: [],
                coachCue: coachCue,
                enabledActionIDs: [
                    "run-fame-onboarding-scorecard",
                    CommandPaletteAction.launchRecoveryNextActionID
                ]
            )
        )
        XCTAssertEqual(coachFallbackPlan.actionID, "run-fame-onboarding-scorecard")

        let recoveryNextFallbackPlan = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPlan(
                momentum: momentum,
                interventions: [],
                coachCue: coachCue,
                enabledActionIDs: [
                    CommandPaletteAction.launchRecoveryNextActionID
                ]
            )
        )
        XCTAssertEqual(recoveryNextFallbackPlan.actionID, CommandPaletteAction.launchRecoveryNextActionID)
        XCTAssertEqual(
            recoveryNextFallbackPlan.subtitle,
            "Next milestone x10 in 5 opens · Run Launch Recovery Next."
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustMomentumPlanRespectsMinimumStreak() throws {
        let momentum = CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustMomentum(
            streak: 2,
            title: "Trust Momentum x2",
            subtitle: "Rebound +26 · Trust 50/100",
            systemImage: "arrow.up.right.circle.fill",
            helpText: "Momentum"
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPlan(
                momentum: momentum,
                interventions: [],
                coachCue: nil,
                enabledActionIDs: []
            )
        )

        let lowThresholdPlan = try XCTUnwrap(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPlan(
                momentum: momentum,
                interventions: [],
                coachCue: nil,
                enabledActionIDs: [],
                minimumStreak: 2
            )
        )
        XCTAssertEqual(lowThresholdPlan.nextMilestone, 3)
        XCTAssertEqual(lowThresholdPlan.remainingOpens, 1)
        XCTAssertEqual(
            lowThresholdPlan.subtitle,
            "Next milestone x3 in 1 open · Keep ordering active."
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustPulseEmitsForSharpDropOrRise() {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPulse(
                previousPoints: 64,
                nextPoints: 58
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPulse(
                previousPoints: 41,
                nextPoints: 45
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPulse(
                previousPoints: 46,
                nextPoints: 61
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustPulse(
                tone: .rising,
                title: "Intervention Trust Rising",
                subtitle: "Trust improved to 61/100 (Δ+15). Keep validating.",
                systemImage: "chart.line.uptrend.xyaxis",
                helpText: "Intervention trust improved from 46/100 to 61/100 (Δ+15). Continue validating intervention ordering to preserve recovery momentum."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPulse(
                previousPoints: 52,
                nextPoints: 77
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustPulse(
                tone: .rising,
                title: "Intervention Trust Recovered",
                subtitle: "Trust climbed to 77/100 (Δ+25). Keep this ordering.",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Intervention trust rebounded from 52/100 to 77/100 (Δ+25). Keep the current lead intervention ordering while confidence is rising."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPulse(
                previousPoints: 78,
                nextPoints: 62
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustPulse(
                tone: .falling,
                title: "Intervention Trust Dip",
                subtitle: "Trust slipped to 62/100 (Δ-16). Validate ordering.",
                systemImage: "chart.line.downtrend.xyaxis",
                helpText: "Intervention trust dropped from 78/100 to 62/100 (Δ-16). Validate top intervention ordering to keep launch recovery guidance reliable."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPulse(
                previousPoints: 68,
                nextPoints: 34
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustPulse(
                tone: .falling,
                title: "Intervention Trust Alert",
                subtitle: "Trust fell to 34/100 (Δ-34). Re-run coach now.",
                systemImage: "exclamationmark.triangle.fill",
                helpText: "Intervention trust dropped sharply from 68/100 to 34/100 (Δ-34). Re-run the lead coach intervention and verify ordering before the next launch recovery cycle."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustGuardTriggersWatchAndCriticalStates() {
        let risingTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend(
            samples: [41, 46, 53, 58],
            currentPoints: 58,
            deltaPoints: 12,
            direction: .rising,
            title: "Intervention Trust Rising",
            subtitle: "Trust 58/100 · Δ+12",
            systemImage: "chart.line.uptrend.xyaxis",
            helpText: "Rising"
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuard(for: risingTrend)
        )

        let mildFallingTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend(
            samples: [64, 61, 58, 55],
            currentPoints: 55,
            deltaPoints: -7,
            direction: .falling,
            title: "Intervention Trust Sliding",
            subtitle: "Trust 55/100 · Δ-7",
            systemImage: "chart.line.downtrend.xyaxis",
            helpText: "Falling"
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuard(for: mildFallingTrend)
        )

        let watchTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend(
            samples: [73, 68, 61, 54],
            currentPoints: 54,
            deltaPoints: -10,
            direction: .falling,
            title: "Intervention Trust Sliding",
            subtitle: "Trust 54/100 · Δ-10",
            systemImage: "chart.line.downtrend.xyaxis",
            helpText: "Falling"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuard(for: watchTrend),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustGuard(
                severity: .watch,
                title: "Trust Guard Watch",
                subtitle: "Trust is sliding to 54/100 (Δ-10). Validate ordering.",
                systemImage: "shield.lefthalf.filled",
                helpText: "Intervention trust is trending down at 54/100 (Δ-10). Run a trust-fix step to refresh intervention ordering confidence."
            )
        )

        let criticalTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend(
            samples: [68, 57, 46, 34],
            currentPoints: 34,
            deltaPoints: -22,
            direction: .falling,
            title: "Intervention Trust Sliding",
            subtitle: "Trust 34/100 · Δ-22",
            systemImage: "chart.line.downtrend.xyaxis",
            helpText: "Falling"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuard(
                for: criticalTrend
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustGuard(
                severity: .critical,
                title: "Trust Guard Critical",
                subtitle: "Trust dropped to 34/100 (Δ-22). Run a trust fix now.",
                systemImage: "exclamationmark.triangle.fill",
                helpText: "Intervention trust is sliding critically at 34/100 (Δ-22). Run a coach or recovery-next action to revalidate intervention ordering before the next launch cycle."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionTrustGuardActionIDPrefersCoachThenRecoveryThenFallback() {
        let coachCue = CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue(
            title: "Coach",
            subtitle: "Recover",
            systemImage: "arrow.triangle.2.circlepath",
            actionID: "run-fame-onboarding-fill-gap"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuardActionID(
                coachCue: coachCue,
                enabledActionIDs: [
                    "run-fame-onboarding-fill-gap",
                    "run-fame-launch-recovery-next"
                ]
            ),
            "run-fame-onboarding-fill-gap"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuardActionID(
                coachCue: nil,
                enabledActionIDs: [
                    "run-fame-launch-recovery-next",
                    "run-fame-onboarding-scorecard"
                ]
            ),
            "run-fame-launch-recovery-next"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuardActionID(
                coachCue: nil,
                enabledActionIDs: [
                    "run-fame-onboarding-daily-brief",
                    "run-fame-onboarding-fill-gap"
                ]
            ),
            "run-fame-onboarding-daily-brief"
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuardActionID(
                coachCue: nil,
                enabledActionIDs: []
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyInterventionButtonTitleIncludesImpactBadge() {
        let boostedIntervention = CommandPaletteTopPicks.LaunchRecoveryHotKeyIntervention(
            actionID: "run-fame-launch-recovery-next",
            title: "Recovery Next",
            subtitle: "Run now",
            systemImage: "command",
            helpText: "Run now",
            impactScore: 4
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionButtonTitle(boostedIntervention),
            "Recovery Next +4"
        )

        let neutralIntervention = CommandPaletteTopPicks.LaunchRecoveryHotKeyIntervention(
            actionID: "run-fame-launch-recovery-next",
            title: "Recovery Next",
            subtitle: "Run now",
            systemImage: "command",
            helpText: "Run now",
            impactScore: 0
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionButtonTitle(neutralIntervention),
            "Recovery Next"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionImpactBadgeTitle(-2),
            "-2"
        )
        XCTAssertNil(CommandPaletteTopPicks.launchRecoveryHotKeyInterventionImpactBadgeTitle(0))
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionImpactTone(3),
            .positive
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionImpactTone(-2),
            .negative
        )
        XCTAssertNil(CommandPaletteTopPicks.launchRecoveryHotKeyInterventionImpactTone(0))

        let staleIntervention = CommandPaletteTopPicks.LaunchRecoveryHotKeyIntervention(
            actionID: "run-fame-launch-recovery-next",
            title: "Recovery Next",
            subtitle: "Run now",
            systemImage: "command",
            helpText: "Run now",
            impactScore: -2,
            recency: .stale(opensAgo: 4)
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionButtonTitle(staleIntervention),
            "Recovery Next -2 (Stale)"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionRecencyBadgeTitle(
                .recentlyValidated(opensAgo: 0)
            ),
            "Recent"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionRecencyBadgeTitle(
                .stale(opensAgo: 3)
            ),
            "Stale"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionRecencyTone(
                .recentlyValidated(opensAgo: 1)
            ),
            .recent
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionRecencyTone(
                .stale(opensAgo: 2)
            ),
            .stale
        )
        XCTAssertNil(CommandPaletteTopPicks.launchRecoveryHotKeyInterventionRecencyTone(nil))
    }

    func testTopPicksLaunchRecoveryHotKeyCoachCueCanRecommendRerouteRecoveryStep() {
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false,
            hasFreshOnboardingRecovery: false,
            onboardingRecoveryFollowupActionID: nil,
            onboardingRecoveryRemainingArtifacts: nil
        )
        let trend = CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
            directCount: 1,
            rerouteCount: 4,
            standbyCount: 1
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyCoachCue(
                readiness: .reroute(actionID: "run-fame-cadence-autopilot-loop"),
                trend: trend,
                context: context,
                enabledActionIDs: [
                    "run-fame-cadence-autopilot-loop",
                    "run-fame-onboarding-fill-gap"
                ]
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue(
                title: "Coach: Restore ⌥⇧L Direct",
                subtitle: "Reroute leads 4/6 opens. Run Fill Onboarding Gap to restore direct launch recovery.",
                systemImage: "arrow.triangle.2.circlepath",
                actionID: "run-fame-onboarding-fill-gap"
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyCoachCueCanRecommendStandbyRecoveryStep() {
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false,
            hasFreshOnboardingRecovery: false,
            onboardingRecoveryFollowupActionID: nil,
            onboardingRecoveryRemainingArtifacts: nil
        )
        let trend = CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
            directCount: 1,
            rerouteCount: 1,
            standbyCount: 4
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyCoachCue(
                readiness: .unavailable,
                trend: trend,
                context: context,
                enabledActionIDs: ["run-fame-onboarding-scorecard"]
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue(
                title: "Coach: Wake Recovery Route",
                subtitle: "Standby leads 4/6 opens. Run Run First-Week Fame Scorecard to re-arm launch recovery.",
                systemImage: "bolt.badge.clock",
                actionID: "run-fame-onboarding-scorecard"
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyCoachCueStaysHiddenWhenNotNeeded() {
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false,
            hasFreshOnboardingRecovery: true,
            onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
            onboardingRecoveryRemainingArtifacts: 1
        )
        let trend = CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
            directCount: 4,
            rerouteCount: 1,
            standbyCount: 0
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyCoachCue(
                readiness: .direct(actionID: "run-fame-onboarding-scorecard"),
                trend: trend,
                context: context,
                enabledActionIDs: ["run-fame-onboarding-scorecard"]
            )
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyCoachCue(
                readiness: .reroute(actionID: "run-fame-cadence-autopilot-loop"),
                trend: CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
                    directCount: 1,
                    rerouteCount: 1,
                    standbyCount: 0
                ),
                context: context,
                enabledActionIDs: ["run-fame-onboarding-scorecard"]
            )
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyCoachCue(
                readiness: .reroute(actionID: "run-fame-cadence-autopilot-loop"),
                trend: CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
                    directCount: 0,
                    rerouteCount: 3,
                    standbyCount: 1
                ),
                context: context,
                enabledActionIDs: ["run-fame-cadence-autopilot-loop"]
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyDecayPulseFormatsCoachEscalation() {
        let cue = CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue(
            title: "Coach: Restore ⌥⇧L Direct",
            subtitle: "Reroute leads 4/6 opens. Run Fill Onboarding Gap to restore direct launch recovery.",
            systemImage: "arrow.triangle.2.circlepath",
            actionID: "run-fame-onboarding-fill-gap"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyDecayPulse(
                coachCue: cue,
                streakCount: 3
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyDecayPulse(
                title: "Recovery Drift x3",
                subtitle: "Coach has repeated 3 opens. Run Fill Onboarding Gap now.",
                systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
                helpText: "Launch recovery confidence has drifted for 3 consecutive palette opens. Run Fill Onboarding Gap to restore direct hotkey routing."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyRestorePulseFormatsRecoveredRoutes() {
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyRestorePulse(previousState: .reroute),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyRestorePulse(
                title: "Direct Restored",
                subtitle: "Reroute cleared. ⌥⇧L is running direct again.",
                systemImage: "checkmark.arrow.trianglehead.counterclockwise",
                helpText: "Launch recovery reroute fallback has cleared. Global ⌥⇧L now runs the primary recovery route directly."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyRestorePulse(previousState: .standby),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyRestorePulse(
                title: "Direct Restored",
                subtitle: "Standby cleared. ⌥⇧L route is live again.",
                systemImage: "checkmark.arrow.trianglehead.counterclockwise",
                helpText: "Launch recovery standby has cleared. Global ⌥⇧L now runs the primary recovery route directly."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoCoachStatusTracksEnablementAndCooldown() {
        let now = Date(timeIntervalSince1970: 1_200)

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoCoachStatus(
                isEnabled: false,
                lastRunAt: now.addingTimeInterval(-60),
                now: now,
                cooldownMinutes: 10
            ),
            .disabled
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoCoachStatus(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10
            ),
            .ready
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoCoachStatus(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-180),
                now: now,
                cooldownMinutes: 10
            ),
            .coolingDown(minutesRemaining: 7)
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoCoachStatus(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-120),
                now: now,
                cooldownMinutes: 0
            ),
            .ready
        )
        XCTAssertTrue(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyCoach(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyCoach(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-30),
                now: now,
                cooldownMinutes: 10
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoRescueStatusTracksEnablementAndCooldown() {
        let now = Date(timeIntervalSince1970: 1_200)
        let alertRescue = CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumRescue(
            severity: .alert,
            title: "Momentum Rescue Alert",
            subtitle: "Recovery momentum dropped sharply.",
            systemImage: "cross.case.fill",
            helpText: "Run rescue now.",
            actionID: "run-fame-onboarding-fill-gap"
        )
        let watchRescue = CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumRescue(
            severity: .watch,
            title: "Momentum Rescue Ready",
            subtitle: "Recovery momentum slipped.",
            systemImage: "cross.case",
            helpText: "Queue rescue.",
            actionID: "run-fame-onboarding-fill-gap"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueStatus(
                isEnabled: false,
                lastRunAt: now.addingTimeInterval(-60),
                now: now,
                cooldownMinutes: 10
            ),
            .disabled
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueStatus(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10
            ),
            .ready
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueStatus(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-180),
                now: now,
                cooldownMinutes: 10
            ),
            .coolingDown(minutesRemaining: 7)
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueStatus(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-120),
                now: now,
                cooldownMinutes: 0
            ),
            .ready
        )
        XCTAssertTrue(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyAutoRescue(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                rescue: alertRescue,
                hasRunnableAction: true
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyAutoRescue(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                rescue: watchRescue,
                hasRunnableAction: true
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyAutoRescue(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                rescue: alertRescue,
                hasRunnableAction: false
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyAutoRescue(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-30),
                now: now,
                cooldownMinutes: 10,
                rescue: alertRescue,
                hasRunnableAction: true
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyAutoRescue(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                rescue: nil,
                hasRunnableAction: true
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoRescueBadgeCopyReflectsState() {
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueBadge(
                status: .disabled
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueBadge(
                tone: .disabled,
                title: "Auto Rescue Off",
                systemImage: "power",
                helpText: "Launch recovery auto rescue guard is off. Enable it to auto-run one rescue step when Momentum Alert appears."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueBadge(
                status: .ready
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueBadge(
                tone: .ready,
                title: "Auto Rescue Ready",
                systemImage: "bolt.badge.automatic",
                helpText: "Launch recovery auto rescue guard is armed and will auto-run one rescue step when Momentum Alert appears."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueBadge(
                status: .coolingDown(minutesRemaining: 6)
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueBadge(
                tone: .coolingDown,
                title: "Auto Rescue Cooldown 6m",
                systemImage: "clock.badge.checkmark",
                helpText: "Launch recovery auto rescue guard is cooling down for about 6 more minutes."
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseStatusTracksEnablementAndCooldown() {
        let now = Date(timeIntervalSince1970: 1_500)
        let cue = CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue(
            tone: .defense,
            trend: .falling,
            title: "Hall of Fame Defense · Cooling",
            subtitle: "Week pace slipped.",
            buttonTitle: "Stabilize Pace",
            systemImage: "thermometer.low",
            helpText: "Keep rescue momentum alive."
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseStatus(
                isEnabled: false,
                lastRunAt: now.addingTimeInterval(-60),
                now: now,
                cooldownMinutes: 10
            ),
            .disabled
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseStatus(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10
            ),
            .ready
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseStatus(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-180),
                now: now,
                cooldownMinutes: 10
            ),
            .coolingDown(minutesRemaining: 7)
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseStatus(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-120),
                now: now,
                cooldownMinutes: 0
            ),
            .ready
        )
        XCTAssertTrue(
            CommandPaletteTopPicks.shouldAutoRunRecommendationMomentumRescueHallOfFameAutoDefense(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                cue: cue,
                hasRunnableAction: true
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunRecommendationMomentumRescueHallOfFameAutoDefense(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                cue: nil,
                hasRunnableAction: true
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunRecommendationMomentumRescueHallOfFameAutoDefense(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                cue: cue,
                hasRunnableAction: false
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunRecommendationMomentumRescueHallOfFameAutoDefense(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-30),
                now: now,
                cooldownMinutes: 10,
                cue: cue,
                hasRunnableAction: true
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseBadgeCopyReflectsState() {
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseBadge(
                status: .disabled
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseBadge(
                tone: .disabled,
                title: "Auto Defense Off",
                systemImage: "power",
                helpText: "Hall-of-Fame auto-defense is off. Enable it to auto-run the active rescue lane when Hall-of-Fame defense/chase cues appear."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseBadge(
                status: .ready
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseBadge(
                tone: .ready,
                title: "Auto Defense Ready",
                systemImage: "shield.lefthalf.filled",
                helpText: "Hall-of-Fame auto-defense is armed and will auto-run the active rescue lane when Hall-of-Fame defense/chase cues appear."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseBadge(
                status: .coolingDown(minutesRemaining: 8)
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseBadge(
                tone: .coolingDown,
                title: "Auto Defense Cooldown 8m",
                systemImage: "clock.badge.checkmark",
                helpText: "Hall-of-Fame auto-defense is cooling down for about 8 more minutes."
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadgeUsesCompactRelativeTime() {
        let now = Date(timeIntervalSince1970: 2_700)

        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                lastRunAt: nil,
                now: now
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                lastRunAt: now.addingTimeInterval(-25),
                now: now
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                title: "Auto defended <1m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Hall-of-Fame auto-defense ran less than a minute ago."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                lastRunAt: now.addingTimeInterval(-60),
                now: now
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                title: "Auto defended 1m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Hall-of-Fame auto-defense ran about 1 minute ago."
            )
        )

        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                lastRunAt: now.addingTimeInterval(-1_800),
                now: now,
                maxAgeMinutes: 20
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseRunHelpersResetAcrossBoundaries() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 9_000_000)
        let todayStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(
            now: now,
            calendar: calendar
        )
        let yesterdayStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(
            now: now.addingTimeInterval(-86_400),
            calendar: calendar
        )
        let twoDaysAgoStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(
            now: now.addingTimeInterval(-172_800),
            calendar: calendar
        )
        let weekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
            now: now,
            calendar: calendar
        )
        let lastWeekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
            now: now.addingTimeInterval(-691_200),
            calendar: calendar
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRunsToday(
                dayStamp: todayStamp,
                storedCount: 2,
                now: now,
                calendar: calendar
            ),
            2
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRunsToday(
                dayStamp: yesterdayStamp,
                storedCount: 9,
                now: now,
                calendar: calendar
            ),
            0
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRunsThisWeek(
                weekStamp: weekStamp,
                storedCount: 4,
                now: now,
                calendar: calendar
            ),
            4
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRunsThisWeek(
                weekStamp: lastWeekStamp,
                storedCount: 12,
                now: now,
                calendar: calendar
            ),
            0
        )

        let sameDayRecorded =
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRecordedRun(
                dayStamp: todayStamp,
                storedCount: 2,
                now: now,
                calendar: calendar
            )
        XCTAssertEqual(sameDayRecorded.dayStamp, todayStamp)
        XCTAssertEqual(sameDayRecorded.runsToday, 3)

        let rolloverRecorded =
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRecordedRun(
                dayStamp: yesterdayStamp,
                storedCount: 9,
                now: now,
                calendar: calendar
            )
        XCTAssertEqual(rolloverRecorded.dayStamp, todayStamp)
        XCTAssertEqual(rolloverRecorded.runsToday, 1)

        let sameWeekRecorded =
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRecordedWeeklyRun(
                weekStamp: weekStamp,
                storedCount: 4,
                bestWeekCount: 6,
                now: now,
                calendar: calendar
            )
        XCTAssertEqual(sameWeekRecorded.weekStamp, weekStamp)
        XCTAssertEqual(sameWeekRecorded.runsThisWeek, 5)
        XCTAssertEqual(sameWeekRecorded.bestWeekCount, 6)

        let rolloverWeekRecorded =
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRecordedWeeklyRun(
                weekStamp: lastWeekStamp,
                storedCount: 12,
                bestWeekCount: 12,
                now: now,
                calendar: calendar
            )
        XCTAssertEqual(rolloverWeekRecorded.weekStamp, weekStamp)
        XCTAssertEqual(rolloverWeekRecorded.runsThisWeek, 1)
        XCTAssertEqual(rolloverWeekRecorded.bestWeekCount, 12)

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseUpdatedStreak(
                previousDayStamp: nil,
                currentStreak: 0,
                bestStreak: 0,
                now: now,
                calendar: calendar
            ).streak,
            1
        )
        let sameDayStreak = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseUpdatedStreak(
                previousDayStamp: todayStamp,
                currentStreak: 3,
                bestStreak: 5,
                now: now,
                calendar: calendar
            )
        XCTAssertEqual(sameDayStreak.streak, 3)
        XCTAssertEqual(sameDayStreak.bestStreak, 5)

        let consecutiveDayStreak = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseUpdatedStreak(
                previousDayStamp: yesterdayStamp,
                currentStreak: 3,
                bestStreak: 3,
                now: now,
                calendar: calendar
            )
        XCTAssertEqual(consecutiveDayStreak.streak, 4)
        XCTAssertEqual(consecutiveDayStreak.bestStreak, 4)

        let resetStreak = CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseUpdatedStreak(
            previousDayStamp: twoDaysAgoStamp,
            currentStreak: 7,
            bestStreak: 9,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(resetStreak.streak, 1)
        XCTAssertEqual(resetStreak.bestStreak, 9)
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseBadgesAndScorecardReflectProgress() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseStreakBadge(
                currentStreak: 0,
                bestStreak: 4
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseStreakBadge(
                currentStreak: 2,
                bestStreak: 5
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseStreakBadge(
                title: "Defense Streak x2d",
                systemImage: "shield.fill",
                helpText: "Hall-of-Fame auto-defense streak: x2 day(s) with at least one auto run. Best x5."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseStreakBadge(
                currentStreak: 7,
                bestStreak: 6
            )?.systemImage,
            "flame.fill"
        )

        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge(
                currentWeekRuns: 0,
                bestWeekRuns: 4
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge(
                currentWeekRuns: 3,
                bestWeekRuns: 7
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge(
                title: "Defense Week 3",
                systemImage: "calendar",
                helpText: "Hall-of-Fame auto-defense this week: 3 runs. Best week: 7 runs."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge(
                currentWeekRuns: 8,
                bestWeekRuns: 7
            )?.systemImage,
            "sparkles"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                status: .disabled,
                runsToday: 2,
                currentWeekRuns: 3,
                bestWeekRuns: 7,
                currentStreak: 4,
                bestStreak: 6
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                tone: .disabled,
                title: "Hall-of-Fame Auto Defense Disabled",
                subtitle: "Enable auto-defense to protect weekly rescue pace. Today 2 · week 3/best 7 · streak x4d (best x6d).",
                systemImage: "power",
                helpText: "Hall-of-Fame auto-defense is currently disabled. Today 2 · week 3/best 7 · streak x4d (best x6d)."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                status: .ready,
                runsToday: 0,
                currentWeekRuns: 0,
                bestWeekRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                tone: .ready,
                title: "Hall-of-Fame Auto Defense Armed",
                subtitle: "Armed for the first Hall-of-Fame save this week. Today 0 · week 0/best 0 · streak x0d (best x0d).",
                systemImage: "shield.checkered",
                helpText: "Hall-of-Fame auto-defense is ready for the next defense/chase cue. Today 0 · week 0/best 0 · streak x0d (best x0d)."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                status: .coolingDown(minutesRemaining: 9),
                runsToday: 1,
                currentWeekRuns: 2,
                bestWeekRuns: 4,
                currentStreak: 2,
                bestStreak: 3
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                tone: .coolingDown,
                title: "Hall-of-Fame Auto Defense Cooldown",
                subtitle: "Cooling down for about 9m. Today 1 · week 2/best 4 · streak x2d (best x3d).",
                systemImage: "clock.badge.checkmark",
                helpText: "Hall-of-Fame auto-defense is cooling down for about 9 minutes. Today 1 · week 2/best 4 · streak x2d (best x3d)."
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadgeTracksTierProgression() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge(
                status: .disabled,
                currentWeekRuns: 0,
                bestWeekRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
                currentWeekRuns: 0,
                currentStreak: 0
            ),
            .starter
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
                currentWeekRuns: 2,
                currentStreak: 0
            ),
            .rising
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
                currentWeekRuns: 5,
                currentStreak: 0
            ),
            .elite
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
                currentWeekRuns: 0,
                currentStreak: 7
            ),
            .legend
        )

        let starterBadge = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge(
                status: .ready,
                currentWeekRuns: 0,
                bestWeekRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        XCTAssertEqual(starterBadge?.tier, .starter)
        XCTAssertEqual(starterBadge?.title, "Defense League Starter")
        XCTAssertEqual(starterBadge?.systemImage, "shield")
        XCTAssertTrue(starterBadge?.helpText.contains("Hall-of-Fame auto-defense is armed and ready.") == true)
        XCTAssertTrue(starterBadge?.helpText.contains("reach Rising") == true)

        let risingBadge = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge(
                status: .ready,
                currentWeekRuns: 3,
                bestWeekRuns: 6,
                currentStreak: 2,
                bestStreak: 4
            )
        XCTAssertEqual(risingBadge?.tier, .rising)
        XCTAssertEqual(risingBadge?.title, "Defense League Rising")
        XCTAssertEqual(risingBadge?.systemImage, "chart.line.uptrend.xyaxis")
        XCTAssertTrue(risingBadge?.helpText.contains("reach Elite") == true)

        let legendBadge = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge(
                status: .coolingDown(minutesRemaining: 4),
                currentWeekRuns: 8,
                bestWeekRuns: 9,
                currentStreak: 7,
                bestStreak: 8
            )
        XCTAssertEqual(legendBadge?.tier, .legend)
        XCTAssertEqual(legendBadge?.title, "Defense League Legend")
        XCTAssertEqual(legendBadge?.systemImage, "crown.fill")
        XCTAssertTrue(legendBadge?.helpText.contains("cooling down (4m remaining)") == true)
        XCTAssertTrue(legendBadge?.helpText.contains("protect the crown") == true)
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgressTracksRaceToNextTier() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                status: .disabled,
                currentWeekRuns: 0,
                bestWeekRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                status: .ready,
                currentWeekRuns: 1,
                bestWeekRuns: 2,
                currentStreak: 1,
                bestStreak: 2
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                tier: .starter,
                pointsToNextTier: 1,
                title: "1 step to Rising",
                subtitle: "League Starter • Week 1/2 • Streak x1d",
                systemImage: "flag.checkered.2.crossed",
                helpText: "Hall-of-Fame auto-defense is armed and ready. Need 1 more weekly auto-defense or 1 more streak day to reach Rising."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                status: .coolingDown(minutesRemaining: 5),
                currentWeekRuns: 3,
                bestWeekRuns: 6,
                currentStreak: 2,
                bestStreak: 4
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                tier: .rising,
                pointsToNextTier: 2,
                title: "2 steps to Elite",
                subtitle: "League Rising • Week 3/6 • Streak x2d",
                systemImage: "flag.checkered.2.crossed",
                helpText: "Hall-of-Fame auto-defense is cooling down (5m remaining). Need 2 more weekly auto-defenses or 2 more streak days to reach Elite."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                status: .ready,
                currentWeekRuns: 6,
                bestWeekRuns: 8,
                currentStreak: 4,
                bestStreak: 5
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                tier: .elite,
                pointsToNextTier: 2,
                title: "2 steps to Legend",
                subtitle: "League Elite • Week 6/8 • Streak x4d",
                systemImage: "flag.checkered.2.crossed",
                helpText: "Hall-of-Fame auto-defense is armed and ready. Need 2 more weekly auto-defenses or 3 more streak days to reach Legend."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                status: .ready,
                currentWeekRuns: 9,
                bestWeekRuns: 10,
                currentStreak: 7,
                bestStreak: 8
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                tier: .legend,
                pointsToNextTier: 0,
                title: "Defense League Legend Locked",
                subtitle: "League Legend • Week 9/10 • Streak x7d",
                systemImage: "crown.fill",
                helpText: "Hall-of-Fame auto-defense is armed and ready. Legend tier is active. Keep weekly auto-defense volume and streak pressure compounding."
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryRecordsWeeksAndTracksTrend() {
        let startingHistory = [
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 1,
                runsThisWeek: 2,
                bestWeekRuns: 2,
                currentStreak: 2,
                bestStreak: 2,
                leagueScore: 7,
                tier: .rising
            )
        ]

        let updatedHistory = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseRecordedLeagueHistory(
                history: startingHistory,
                weekStamp: "2000",
                runsToday: 2,
                runsThisWeek: 6,
                bestWeekRuns: 8,
                currentStreak: 4,
                bestStreak: 4
            )
        XCTAssertEqual(updatedHistory.count, 2)
        XCTAssertEqual(updatedHistory.first?.weekStamp, "2000")
        XCTAssertEqual(updatedHistory.first?.tier, .elite)
        XCTAssertEqual(updatedHistory.first?.leagueScore, 18)

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                history: updatedHistory
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                direction: .rising,
                sampleCount: 2,
                scoreDelta: 11,
                fromTier: .rising,
                toTier: .elite,
                title: "Defense League Heat +11",
                subtitle: "2w climb · Rising -> Elite",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Hall-of-Fame defense league momentum is rising over the last 2 weeks: score 7 -> 18 (Δ+11), tier Rising -> Elite."
            )
        )

        let dedupedCurrentWeekHistory = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseRecordedLeagueHistory(
                history: updatedHistory,
                weekStamp: "2000",
                runsToday: 3,
                runsThisWeek: 8,
                bestWeekRuns: 8,
                currentStreak: 7,
                bestStreak: 7
            )
        XCTAssertEqual(dedupedCurrentWeekHistory.count, 2)
        XCTAssertEqual(dedupedCurrentWeekHistory.first?.weekStamp, "2000")
        XCTAssertEqual(dedupedCurrentWeekHistory.first?.tier, .legend)
        XCTAssertEqual(dedupedCurrentWeekHistory.first?.leagueScore, 26)
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrendClassifiesSteadyAndFalling() {
        let steadyHistory = [
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 1,
                runsThisWeek: 3,
                bestWeekRuns: 3,
                currentStreak: 2,
                bestStreak: 2,
                leagueScore: 9,
                tier: .rising
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 1,
                runsThisWeek: 4,
                bestWeekRuns: 4,
                currentStreak: 2,
                bestStreak: 2,
                leagueScore: 11,
                tier: .rising
            )
        ]
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                history: steadyHistory
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                direction: .steady,
                sampleCount: 2,
                scoreDelta: 2,
                fromTier: .rising,
                toTier: .rising,
                title: "Defense League Holding",
                subtitle: "2w steady · Rising at 11",
                systemImage: "equal.circle.fill",
                helpText: "Hall-of-Fame defense league momentum is steady over the last 2 weeks: score 9 -> 11 (Δ+2) while holding Rising."
            )
        )

        let fallingHistory = [
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 3,
                runsThisWeek: 8,
                bestWeekRuns: 8,
                currentStreak: 7,
                bestStreak: 7,
                leagueScore: 26,
                tier: .legend
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 2,
                runsThisWeek: 5,
                bestWeekRuns: 8,
                currentStreak: 4,
                bestStreak: 7,
                leagueScore: 16,
                tier: .elite
            )
        ]
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                history: fallingHistory
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                direction: .falling,
                sampleCount: 2,
                scoreDelta: -10,
                fromTier: .legend,
                toTier: .elite,
                title: "Defense League Drift -10",
                subtitle: "2w slide · Legend -> Elite",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Hall-of-Fame defense league momentum is cooling over the last 2 weeks: score 26 -> 16 (Δ-10), tier Legend -> Elite."
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                history: [steadyHistory[0]]
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryLoadsFromDefaultsAndLimits()
        throws
    {
        let defaults = try makeDefaults()
        let history = [
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 1,
                runsThisWeek: 2,
                bestWeekRuns: 2,
                currentStreak: 2,
                bestStreak: 2,
                leagueScore: 7,
                tier: .rising
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "3000",
                runsToday: 3,
                runsThisWeek: 8,
                bestWeekRuns: 8,
                currentStreak: 7,
                bestStreak: 7,
                leagueScore: 26,
                tier: .legend
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 1,
                runsThisWeek: 4,
                bestWeekRuns: 5,
                currentStreak: 2,
                bestStreak: 3,
                leagueScore: 11,
                tier: .rising
            )
        ]
        let historyData = try JSONEncoder().encode(history)
        defaults.set(
            historyData,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey
        )

        let loadedHistory = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory(
                defaults: defaults,
                historyKey: AppDefaults
                    .fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey,
                limit: 2
            )
        XCTAssertEqual(loadedHistory.map(\.weekStamp), ["3000", "2000"])

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory(
                defaults: defaults,
                historyKey: AppDefaults
                    .fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey,
                limit: 0
            ),
            []
        )
    }

    func testRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistorySanitizesMalformedEntries() throws {
        let defaults = try makeDefaults()
        let history = [
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: " 3000 ",
                runsToday: -2,
                runsThisWeek: 6,
                bestWeekRuns: 1,
                currentStreak: 4,
                bestStreak: 2,
                leagueScore: -100,
                tier: .starter
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "oops",
                runsToday: 1,
                runsThisWeek: 1,
                bestWeekRuns: 1,
                currentStreak: 1,
                bestStreak: 1,
                leagueScore: 9,
                tier: .legend
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 1,
                runsThisWeek: 0,
                bestWeekRuns: 0,
                currentStreak: 1,
                bestStreak: 1,
                leagueScore: 999,
                tier: .legend
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                weekStamp: "2000 ",
                runsToday: 2,
                runsThisWeek: 3,
                bestWeekRuns: 4,
                currentStreak: 2,
                bestStreak: 3,
                leagueScore: 0,
                tier: .starter
            )
        ]
        let historyData = try JSONEncoder().encode(history)
        defaults.set(
            historyData,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey
        )

        let loadedHistory = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory(
                defaults: defaults,
                historyKey: AppDefaults
                    .fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey,
                limit: 10
            )

        XCTAssertEqual(loadedHistory.map(\.weekStamp), ["3000", "2000"])

        let latestWeek = try XCTUnwrap(loadedHistory.first)
        XCTAssertEqual(latestWeek.runsToday, 0)
        XCTAssertEqual(latestWeek.runsThisWeek, 6)
        XCTAssertEqual(latestWeek.bestWeekRuns, 6)
        XCTAssertEqual(latestWeek.currentStreak, 4)
        XCTAssertEqual(latestWeek.bestStreak, 4)
        XCTAssertEqual(latestWeek.leagueScore, 16)
        XCTAssertEqual(latestWeek.tier, .elite)

        let previousWeek = try XCTUnwrap(loadedHistory.last)
        XCTAssertEqual(previousWeek.runsToday, 2)
        XCTAssertEqual(previousWeek.runsThisWeek, 3)
        XCTAssertEqual(previousWeek.bestWeekRuns, 4)
        XCTAssertEqual(previousWeek.currentStreak, 2)
        XCTAssertEqual(previousWeek.bestStreak, 3)
        XCTAssertEqual(previousWeek.leagueScore, 10)
        XCTAssertEqual(previousWeek.tier, .rising)
    }

    func testTopPicksLaunchRecoveryHotKeyAutoRescueRecencyBadgeUsesCompactRelativeTime() {
        let now = Date(timeIntervalSince1970: 2_400)

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueRecencyBadge(
                lastRunAt: nil,
                now: now
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueRecencyBadge(
                lastRunAt: now.addingTimeInterval(-30),
                now: now
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueRecencyBadge(
                title: "Auto rescued <1m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Launch recovery auto rescue ran less than a minute ago."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueRecencyBadge(
                lastRunAt: now.addingTimeInterval(-60),
                now: now
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueRecencyBadge(
                title: "Auto rescued 1m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Launch recovery auto rescue ran about 1 minute ago."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueRecencyBadge(
                lastRunAt: now.addingTimeInterval(-300),
                now: now,
                maxAgeMinutes: 5
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueRecencyBadge(
                title: "Auto rescued 5m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Launch recovery auto rescue ran about 5 minutes ago."
            )
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueRecencyBadge(
                lastRunAt: now.addingTimeInterval(-301),
                now: now,
                maxAgeMinutes: 5
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeStatusTracksEnablementAndReadiness() {
        let now = Date(timeIntervalSince1970: 1_200)

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
                isEnabled: false,
                lastRunAt: now.addingTimeInterval(-60),
                now: now,
                cooldownMinutes: 10
            ),
            .disabled
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10
            ),
            .ready
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-180),
                now: now,
                cooldownMinutes: 10
            ),
            .coolingDown(minutesRemaining: 7)
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-120),
                now: now,
                cooldownMinutes: 0
            ),
            .ready
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-120),
                now: now,
                cooldownMinutes: 0,
                dailyCap: 3,
                runsToday: 3
            ),
            .capped(runsToday: 3, dailyCap: 3)
        )
        XCTAssertTrue(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyTrustSurge(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                remainingOpens: 1,
                confidenceNeedsAttention: false
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyTrustSurge(
                isEnabled: true,
                lastRunAt: now.addingTimeInterval(-30),
                now: now,
                cooldownMinutes: 10,
                remainingOpens: 1,
                confidenceNeedsAttention: false
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyTrustSurge(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                remainingOpens: 2,
                confidenceNeedsAttention: false
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyTrustSurge(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                remainingOpens: 1,
                confidenceNeedsAttention: true
            )
        )
        XCTAssertFalse(
            CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyTrustSurge(
                isEnabled: true,
                lastRunAt: nil,
                now: now,
                cooldownMinutes: 10,
                dailyCap: 3,
                runsToday: 3,
                remainingOpens: 1,
                confidenceNeedsAttention: false
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeBadgeCopyReflectsState() {
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeBadge(
                status: .disabled,
                remainingOpens: 1
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                tone: .disabled,
                title: "Auto Surge Off",
                systemImage: "power",
                helpText: "Auto Trust Surge is currently off. Enable it to auto-run the momentum step when Trust Surge is 1 open from the next milestone."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeBadge(
                status: .ready,
                remainingOpens: 1
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                tone: .ready,
                title: "Auto Surge Ready",
                systemImage: "bolt.badge.automatic",
                helpText: "Auto Trust Surge is armed and will auto-run when the next 1-open milestone setup appears."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeBadge(
                status: .ready,
                remainingOpens: 3
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                tone: .ready,
                title: "Auto Surge Armed",
                systemImage: "bolt.badge.automatic",
                helpText: "Auto Trust Surge is armed. The next auto-run unlocks when Trust Surge is 3 opens from its next milestone."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeBadge(
                status: .coolingDown(minutesRemaining: 6),
                remainingOpens: 1
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                tone: .coolingDown,
                title: "Auto Surge Cooldown 6m",
                systemImage: "clock.badge.checkmark",
                helpText: "Auto Trust Surge is cooling down for about 6 more minutes."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeBadge(
                status: .capped(runsToday: 3, dailyCap: 3),
                remainingOpens: 1
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                tone: .capped,
                title: "Auto Surge Cap 3/3",
                systemImage: "hand.raised.slash",
                helpText: "Auto Trust Surge hit today’s cap at 3/3 runs. It automatically re-arms after midnight."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeRecencyBadgeUsesCompactRelativeTime() {
        let now = Date(timeIntervalSince1970: 2_400)

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                lastRunAt: nil,
                now: now
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                lastRunAt: now.addingTimeInterval(-30),
                now: now
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                title: "Auto surged <1m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Auto Trust Surge ran less than a minute ago."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                lastRunAt: now.addingTimeInterval(-60),
                now: now
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                title: "Auto surged 1m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Auto Trust Surge ran about 1 minute ago."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                lastRunAt: now.addingTimeInterval(-300),
                now: now,
                maxAgeMinutes: 5
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                title: "Auto surged 5m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Auto Trust Surge ran about 5 minutes ago."
            )
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                lastRunAt: now.addingTimeInterval(-301),
                now: now,
                maxAgeMinutes: 5
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeInsightToneAndCopyBoundaries() {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeInsight(
                status: .disabled,
                runsToday: 0,
                currentWeekRuns: 0,
                bestWeekRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeInsight(
                status: .disabled,
                runsToday: 0,
                currentWeekRuns: 0,
                bestWeekRuns: 4,
                currentStreak: 0,
                bestStreak: 3
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .standby,
                title: "Auto Surge Engine Paused",
                subtitle: "Today 0 • Week 0/4 • Streak x0d",
                systemImage: "pause.circle",
                helpText: "Auto Trust Surge is disabled. Today: 0 auto runs. Week: 0 runs (best 4). Streak: x0 days (best x3). Re-enable Auto Trust Surge to keep the streak engine compounding."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeInsight(
                status: .ready,
                runsToday: 1,
                currentWeekRuns: 1,
                bestWeekRuns: 2,
                currentStreak: 1,
                bestStreak: 2
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .primed,
                title: "Auto Surge Engine Primed",
                subtitle: "Today 1 • Week 1/2 • Streak x1d",
                systemImage: "bolt.badge.automatic",
                helpText: "Auto Trust Surge is armed and waiting for the next 1-open milestone setup. Today: 1 auto runs. Week: 1 runs (best 2). Streak: x1 days (best x2)."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeInsight(
                status: .ready,
                runsToday: 2,
                currentWeekRuns: 2,
                bestWeekRuns: 5,
                currentStreak: 1,
                bestStreak: 1
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .climbing,
                title: "Auto Surge Engine Climbing",
                subtitle: "Today 2 • Week 2/5 • Streak x1d",
                systemImage: "chart.line.uptrend.xyaxis",
                helpText: "Auto Trust Surge is compounding with strong momentum. Today: 2 auto runs. Week: 2 runs (best 5). Streak: x1 days (best x1)."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeInsight(
                status: .ready,
                runsToday: 3,
                currentWeekRuns: 5,
                bestWeekRuns: 5,
                currentStreak: 2,
                bestStreak: 2
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .podium,
                title: "Auto Surge Engine Podium Pace",
                subtitle: "Today 3 • Week 5/5 • Streak x2d",
                systemImage: "trophy.fill",
                helpText: "Auto Trust Surge is running at a leaderboard pace. Today: 3 auto runs. Week: 5 runs (best 5). Streak: x2 days (best x2)."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeInsight(
                status: .coolingDown(minutesRemaining: 6),
                runsToday: 1,
                currentWeekRuns: 4,
                bestWeekRuns: 6,
                currentStreak: 2,
                bestStreak: 4
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .coolingDown,
                title: "Auto Surge Engine Cooling",
                subtitle: "Today 1 • Week 4/6 • Streak x2d",
                systemImage: "hourglass.bottomhalf.filled",
                helpText: "Auto Trust Surge is cooling down and re-arms in about 6 minutes. Today: 1 auto runs. Week: 4 runs (best 6). Streak: x2 days (best x4)."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeInsight(
                status: .capped(runsToday: 3, dailyCap: 3),
                runsToday: 3,
                currentWeekRuns: 6,
                bestWeekRuns: 7,
                currentStreak: 4,
                bestStreak: 5
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .capped,
                title: "Auto Surge Engine Capped",
                subtitle: "Today 3 • Week 6/7 • Streak x4d",
                systemImage: "flag.checkered",
                helpText: "Auto Trust Surge reached today’s cap at 3/3 runs. Today: 3 auto runs. Week: 6 runs (best 7). Streak: x4 days (best x5)."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLeagueBadgeMapsTierBoundaries() {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                status: .disabled,
                runsToday: 0,
                currentWeekRuns: 0,
                bestWeekRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                status: .ready,
                runsToday: 1,
                currentWeekRuns: 1,
                bestWeekRuns: 2,
                currentStreak: 1,
                bestStreak: 2
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                tier: .starter,
                title: "Auto League Starter",
                systemImage: "figure.run",
                helpText: "Auto Trust Surge is armed and ready. League tier uses today 1, week 1/2, and streak x1d (best x2)."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                status: .ready,
                runsToday: 1,
                currentWeekRuns: 3,
                bestWeekRuns: 4,
                currentStreak: 1,
                bestStreak: 2
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                tier: .rising,
                title: "Auto League Rising",
                systemImage: "chart.line.uptrend.xyaxis",
                helpText: "Auto Trust Surge is armed and ready. League tier uses today 1, week 3/4, and streak x1d (best x2)."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                status: .coolingDown(minutesRemaining: 4),
                runsToday: 2,
                currentWeekRuns: 6,
                bestWeekRuns: 8,
                currentStreak: 2,
                bestStreak: 3
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                tier: .elite,
                title: "Auto League Elite",
                systemImage: "bolt.fill",
                helpText: "Auto Trust Surge is cooling down (4m remaining). League tier uses today 2, week 6/8, and streak x2d (best x3)."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                status: .capped(runsToday: 3, dailyCap: 3),
                runsToday: 3,
                currentWeekRuns: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                tier: .legend,
                title: "Auto League Legend",
                systemImage: "crown.fill",
                helpText: "Auto Trust Surge reached today’s cap at 3/3 runs. League tier uses today 3, week 10/10, and streak x5d (best x5)."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLeagueProgressTracksRaceToNextTier() {
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                status: .disabled,
                runsToday: 0,
                currentWeekRuns: 0,
                bestWeekRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                status: .ready,
                runsToday: 1,
                currentWeekRuns: 1,
                bestWeekRuns: 2,
                currentStreak: 1,
                bestStreak: 2
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                tier: .starter,
                pointsToNextTier: 2,
                title: "2 points to Rising",
                subtitle: "League Starter • Score 4 • Week 1/2 • Streak x1d",
                systemImage: "flag.checkered.2.crossed",
                helpText: "Auto Trust Surge is armed and ready. Auto League score is 4. Need 2 more points to reach Rising. Score grows from daily auto runs, weekly volume, and streak compounding."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                status: .coolingDown(minutesRemaining: 5),
                runsToday: 1,
                currentWeekRuns: 4,
                bestWeekRuns: 6,
                currentStreak: 3,
                bestStreak: 5
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                tier: .rising,
                pointsToNextTier: 1,
                title: "1 point to Elite",
                subtitle: "League Rising • Score 11 • Week 4/6 • Streak x3d",
                systemImage: "flag.checkered.2.crossed",
                helpText: "Auto Trust Surge is cooling down (5m remaining). Auto League score is 11. Need 1 more point to reach Elite. Score grows from daily auto runs, weekly volume, and streak compounding."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                status: .capped(runsToday: 4, dailyCap: 4),
                runsToday: 4,
                currentWeekRuns: 6,
                bestWeekRuns: 8,
                currentStreak: 4,
                bestStreak: 5
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                tier: .elite,
                pointsToNextTier: 2,
                title: "2 points to Legend",
                subtitle: "League Elite • Score 18 • Week 6/8 • Streak x4d",
                systemImage: "flag.checkered.2.crossed",
                helpText: "Auto Trust Surge reached today’s cap at 4/4 runs. Auto League score is 18. Need 2 more points to reach Legend. Score grows from daily auto runs, weekly volume, and streak compounding."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                status: .ready,
                runsToday: 3,
                currentWeekRuns: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                tier: .legend,
                pointsToNextTier: 0,
                title: "Auto League Legend Locked",
                subtitle: "League Legend • Score 27 • Week 10/10 • Streak x5d",
                systemImage: "crown.fill",
                helpText: "Auto Trust Surge is armed and ready. Legend tier is active. Score 27 reflects sustained weekly runs and streak pressure."
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryRecordsWeeksAndTracksTransitions() {
        let startingHistory = [
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 1,
                runsThisWeek: 3,
                bestWeekRuns: 4,
                currentStreak: 2,
                bestStreak: 3,
                leagueScore: 8,
                tier: .rising
            )
        ]

        let updatedHistory = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedLeagueHistory(
            history: startingHistory,
            weekStamp: "2000",
            runsToday: 1,
            runsThisWeek: 6,
            bestWeekRuns: 8,
            currentStreak: 4,
            bestStreak: 4
        )
        XCTAssertEqual(updatedHistory.count, 2)
        XCTAssertEqual(updatedHistory.first?.weekStamp, "2000")
        XCTAssertEqual(updatedHistory.first?.tier, .elite)
        XCTAssertEqual(updatedHistory.first?.leagueScore, 17)

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTransition(
                history: updatedHistory
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTransition(
                fromTier: .rising,
                toTier: .elite,
                weekStamp: "2000"
            )
        )

        let dedupedCurrentWeekHistory = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeRecordedLeagueHistory(
                history: updatedHistory,
                weekStamp: "2000",
                runsToday: 3,
                runsThisWeek: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5
            )
        XCTAssertEqual(dedupedCurrentWeekHistory.count, 2)
        XCTAssertEqual(dedupedCurrentWeekHistory.first?.weekStamp, "2000")
        XCTAssertEqual(dedupedCurrentWeekHistory.first?.tier, .legend)
        XCTAssertEqual(dedupedCurrentWeekHistory.first?.leagueScore, 27)

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTransition(
                history: [
                    CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                        weekStamp: "1000",
                        runsToday: 1,
                        runsThisWeek: 3,
                        bestWeekRuns: 3,
                        currentStreak: 2,
                        bestStreak: 2,
                        leagueScore: 10,
                        tier: .rising
                    ),
                    CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                        weekStamp: "2000",
                        runsToday: 2,
                        runsThisWeek: 4,
                        bestWeekRuns: 6,
                        currentStreak: 3,
                        bestStreak: 4,
                        leagueScore: 12,
                        tier: .rising
                    )
                ]
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionTransitionHandlesWeekAndCurrentWeekPromotions() {
        let priorHistory = [
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 1,
                runsThisWeek: 3,
                bestWeekRuns: 4,
                currentStreak: 2,
                bestStreak: 3,
                leagueScore: 8,
                tier: .rising
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 1,
                runsThisWeek: 5,
                bestWeekRuns: 8,
                currentStreak: 3,
                bestStreak: 4,
                leagueScore: 13,
                tier: .rising
            )
        ]

        let sameWeekUpdated = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedLeagueHistory(
            history: priorHistory,
            weekStamp: "2000",
            runsToday: 2,
            runsThisWeek: 6,
            bestWeekRuns: 8,
            currentStreak: 4,
            bestStreak: 4
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionTransition(
                previousHistory: priorHistory,
                updatedHistory: sameWeekUpdated,
                weekStamp: "2000"
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTransition(
                fromTier: .rising,
                toTier: .elite,
                weekStamp: "2000"
            )
        )

        let nextWeekUpdated = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedLeagueHistory(
            history: priorHistory,
            weekStamp: "3000",
            runsToday: 2,
            runsThisWeek: 8,
            bestWeekRuns: 9,
            currentStreak: 5,
            bestStreak: 5
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionTransition(
                previousHistory: priorHistory,
                updatedHistory: nextWeekUpdated,
                weekStamp: "3000"
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTransition(
                fromTier: .rising,
                toTier: .legend,
                weekStamp: "3000"
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionTransition(
                previousHistory: sameWeekUpdated,
                updatedHistory: sameWeekUpdated,
                weekStamp: "2000"
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLeagueTrendClassifiesRisingSteadyAndFalling() {
        let risingHistory = [
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 1,
                runsThisWeek: 3,
                bestWeekRuns: 4,
                currentStreak: 2,
                bestStreak: 3,
                leagueScore: 8,
                tier: .rising
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 2,
                runsThisWeek: 5,
                bestWeekRuns: 6,
                currentStreak: 3,
                bestStreak: 3,
                leagueScore: 11,
                tier: .rising
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "3000",
                runsToday: 2,
                runsThisWeek: 6,
                bestWeekRuns: 8,
                currentStreak: 4,
                bestStreak: 4,
                leagueScore: 18,
                tier: .elite
            )
        ]
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                history: risingHistory
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                direction: .rising,
                sampleCount: 3,
                scoreDelta: 10,
                fromTier: .rising,
                toTier: .elite,
                title: "League Heat +10",
                subtitle: "3w climb · Rising -> Elite",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Auto League momentum is rising over the last 3 weeks: score 8 -> 18 (Δ+10), tier Rising -> Elite."
            )
        )

        let steadyHistory = [
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 1,
                runsThisWeek: 3,
                bestWeekRuns: 4,
                currentStreak: 2,
                bestStreak: 3,
                leagueScore: 8,
                tier: .rising
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 1,
                runsThisWeek: 4,
                bestWeekRuns: 5,
                currentStreak: 2,
                bestStreak: 3,
                leagueScore: 9,
                tier: .rising
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "3000",
                runsToday: 1,
                runsThisWeek: 4,
                bestWeekRuns: 5,
                currentStreak: 2,
                bestStreak: 3,
                leagueScore: 10,
                tier: .rising
            )
        ]
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                history: steadyHistory
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                direction: .steady,
                sampleCount: 3,
                scoreDelta: 2,
                fromTier: .rising,
                toTier: .rising,
                title: "League Holding",
                subtitle: "3w steady · Rising at 10",
                systemImage: "equal.circle.fill",
                helpText: "Auto League momentum is steady over the last 3 weeks: score 8 -> 10 (Δ+2) while holding Rising."
            )
        )

        let fallingHistory = [
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 3,
                runsThisWeek: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5,
                leagueScore: 27,
                tier: .legend
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 2,
                runsThisWeek: 6,
                bestWeekRuns: 10,
                currentStreak: 3,
                bestStreak: 5,
                leagueScore: 16,
                tier: .elite
            )
        ]
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                history: fallingHistory
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                direction: .falling,
                sampleCount: 2,
                scoreDelta: -11,
                fromTier: .legend,
                toTier: .elite,
                title: "League Drift -11",
                subtitle: "2w slide · Legend -> Elite",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Auto League momentum is cooling over the last 2 weeks: score 27 -> 16 (Δ-11), tier Legend -> Elite."
            )
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                history: [risingHistory[0]]
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLegendDefenseAlertsOnLegendDriftAndSuggestsAction() {
        let fallingTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
            direction: .falling,
            sampleCount: 4,
            scoreDelta: -8,
            fromTier: .legend,
            toTier: .legend,
            title: "League Drift -8",
            subtitle: "4w slide · Legend",
            systemImage: "arrow.down.right.circle.fill",
            helpText: "Auto League momentum is cooling."
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                status: .ready,
                trend: fallingTrend,
                runsToday: 0,
                currentWeekRuns: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5,
                enabledActionIDs: ["run-fame-cadence-autopilot-loop"]
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                tone: .alert,
                title: "Legend Defense Alert",
                subtitle: "Legend under pressure · League Drift -8 (Δ-8)",
                systemImage: "shield.slash.fill",
                helpText: "Auto Trust Surge is armed and ready. Legend defense flagged over 4 weeks (4w slide · Legend). Run Fame Cadence Autopilot Loop now to protect Legend with week 10/10 and streak x5d.",
                actionID: "run-fame-cadence-autopilot-loop"
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLegendDefenseChecksLegendTouchpoints() {
        let steadyTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
            direction: .steady,
            sampleCount: 3,
            scoreDelta: 0,
            fromTier: .legend,
            toTier: .legend,
            title: "League Holding",
            subtitle: "3w steady · Legend at 24",
            systemImage: "equal.circle.fill",
            helpText: "Auto League momentum is steady."
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                status: .ready,
                trend: steadyTrend,
                runsToday: 0,
                currentWeekRuns: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5,
                enabledActionIDs: ["run-fame-next-move-cadence-execution-kit"]
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                tone: .watch,
                title: "Legend Defense Check",
                subtitle: "Legend holding · Today 0 runs · Week 10/10",
                systemImage: "shield.lefthalf.filled",
                helpText: "Auto Trust Surge is armed and ready. Legend is holding but needs a defense touchpoint. Run Next-Move Cadence Execution Kit now to keep the tier stable while trend reads League Holding.",
                actionID: "run-fame-next-move-cadence-execution-kit"
            )
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                status: .ready,
                trend: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                    direction: .steady,
                    sampleCount: 3,
                    scoreDelta: 2,
                    fromTier: .legend,
                    toTier: .legend,
                    title: "League Holding",
                    subtitle: "3w steady · Legend at 26",
                    systemImage: "equal.circle.fill",
                    helpText: "Auto League momentum is steady."
                ),
                runsToday: 1,
                currentWeekRuns: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5,
                enabledActionIDs: ["run-fame-next-move-cadence-execution-kit"]
            ),
            "When Legend is already trending up and has today’s defense run, no extra card should appear."
        )

        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                status: .ready,
                trend: steadyTrend,
                runsToday: 1,
                currentWeekRuns: 5,
                bestWeekRuns: 6,
                currentStreak: 2,
                bestStreak: 3,
                enabledActionIDs: ["run-fame-next-move-cadence-execution-kit"]
            ),
            "Legend defense should stay hidden when the league is below Legend tier."
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastHiddenOutsideLegendRiskWindows() {
        let risingTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
            direction: .rising,
            sampleCount: 3,
            scoreDelta: 7,
            fromTier: .legend,
            toTier: .legend,
            title: "League Heat +7",
            subtitle: "3w climb · Legend",
            systemImage: "arrow.up.right.circle.fill",
            helpText: "Auto League momentum is rising."
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                status: .ready,
                trend: risingTrend,
                runsToday: 1,
                currentWeekRuns: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5,
                enabledActionIDs: ["run-fame-cadence-autopilot-loop"]
            ),
            "Forecast should stay hidden while Legend is rising."
        )

        let steadyTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
            direction: .steady,
            sampleCount: 3,
            scoreDelta: 1,
            fromTier: .legend,
            toTier: .legend,
            title: "League Holding",
            subtitle: "3w steady · Legend at 24",
            systemImage: "equal.circle.fill",
            helpText: "Auto League momentum is steady."
        )
        XCTAssertNil(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                status: .ready,
                trend: steadyTrend,
                runsToday: 1,
                currentWeekRuns: 5,
                bestWeekRuns: 6,
                currentStreak: 2,
                bestStreak: 3,
                enabledActionIDs: ["run-fame-next-move-cadence-execution-kit"]
            ),
            "Forecast should stay hidden below Legend tier."
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastWatchForSteadyLegend() {
        let steadyTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
            direction: .steady,
            sampleCount: 3,
            scoreDelta: 0,
            fromTier: .legend,
            toTier: .legend,
            title: "League Holding",
            subtitle: "3w steady · Legend at 24",
            systemImage: "equal.circle.fill",
            helpText: "Auto League momentum is steady."
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                status: .ready,
                trend: steadyTrend,
                runsToday: 0,
                currentWeekRuns: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5,
                enabledActionIDs: ["run-fame-next-move-cadence-execution-kit"]
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                tone: .watch,
                riskLabel: "Watch",
                nextDefenseMinutes: 0,
                nextDefenseLabel: "now",
                title: "Legend Stability Forecast",
                subtitle: "Risk Watch · 3w steady · Legend at 24 · Next defense now",
                systemImage: "clock.arrow.circlepath",
                helpText: "Auto Trust Surge is armed and ready. Auto League momentum is steady. Defense timing now. Run Next-Move Cadence Execution Kit now to reinforce Legend. Current week 10/10, streak x5d.",
                actionID: "run-fame-next-move-cadence-execution-kit"
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastAlertsOnFallingLegend() {
        let fallingTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
            direction: .falling,
            sampleCount: 4,
            scoreDelta: -8,
            fromTier: .legend,
            toTier: .legend,
            title: "League Drift -8",
            subtitle: "4w slide · Legend",
            systemImage: "arrow.down.right.circle.fill",
            helpText: "Auto League momentum is cooling."
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                status: .ready,
                trend: fallingTrend,
                runsToday: 0,
                currentWeekRuns: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5,
                enabledActionIDs: ["run-fame-cadence-autopilot-loop"]
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                tone: .alert,
                riskLabel: "High",
                nextDefenseMinutes: 0,
                nextDefenseLabel: "now",
                title: "Legend Decay Forecast",
                subtitle: "Risk High · est. tier slip ~14d · Next defense now",
                systemImage: "hourglass.badge.exclamationmark",
                helpText: "Auto Trust Surge is armed and ready. Auto League momentum is cooling. Defense timing now. Run Fame Cadence Autopilot Loop now to reinforce Legend. Current week 10/10, streak x5d.",
                actionID: "run-fame-cadence-autopilot-loop"
            )
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastAdaptsTimingByStatus() {
        let steadyTrend = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
            direction: .steady,
            sampleCount: 3,
            scoreDelta: 0,
            fromTier: .legend,
            toTier: .legend,
            title: "League Holding",
            subtitle: "3w steady · Legend at 24",
            systemImage: "equal.circle.fill",
            helpText: "Auto League momentum is steady."
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let readyForecast = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            status: .ready,
            trend: steadyTrend,
            runsToday: 0,
            currentWeekRuns: 10,
            bestWeekRuns: 10,
            currentStreak: 5,
            bestStreak: 5,
            enabledActionIDs: [],
            now: Date(timeIntervalSince1970: 0),
            calendar: calendar
        )
        XCTAssertEqual(readyForecast?.nextDefenseMinutes, 0)
        XCTAssertEqual(readyForecast?.nextDefenseLabel, "now")

        let coolingForecast = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            status: .coolingDown(minutesRemaining: 17),
            trend: steadyTrend,
            runsToday: 0,
            currentWeekRuns: 10,
            bestWeekRuns: 10,
            currentStreak: 5,
            bestStreak: 5,
            enabledActionIDs: [],
            now: Date(timeIntervalSince1970: 0),
            calendar: calendar
        )
        XCTAssertEqual(coolingForecast?.nextDefenseMinutes, 17)
        XCTAssertEqual(coolingForecast?.nextDefenseLabel, "in 17m (~00:17)")

        let cappedForecast = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            status: .capped(runsToday: 3, dailyCap: 3),
            trend: steadyTrend,
            runsToday: 3,
            currentWeekRuns: 10,
            bestWeekRuns: 10,
            currentStreak: 5,
            bestStreak: 5,
            enabledActionIDs: [],
            now: Date(timeIntervalSince1970: 85_200),
            calendar: calendar
        )
        XCTAssertEqual(cappedForecast?.nextDefenseMinutes, 20)
        XCTAssertEqual(cappedForecast?.nextDefenseLabel, "after reset in 20m (~00:00)")
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryLoadsFromDefaultsAndLimits() throws {
        let defaults = try makeDefaults()
        let history = [
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: 1,
                runsThisWeek: 2,
                bestWeekRuns: 2,
                currentStreak: 1,
                bestStreak: 1,
                leagueScore: 5,
                tier: .starter
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "3000",
                runsToday: 3,
                runsThisWeek: 10,
                bestWeekRuns: 10,
                currentStreak: 5,
                bestStreak: 5,
                leagueScore: 27,
                tier: .legend
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 1,
                runsThisWeek: 4,
                bestWeekRuns: 5,
                currentStreak: 2,
                bestStreak: 3,
                leagueScore: 9,
                tier: .rising
            )
        ]
        let historyData = try JSONEncoder().encode(history)
        defaults.set(
            historyData,
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey
        )

        let loadedHistory = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
            defaults: defaults,
            historyKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
            limit: 2
        )
        XCTAssertEqual(loadedHistory.map(\.weekStamp), ["3000", "2000"])

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
                defaults: defaults,
                historyKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
                limit: 0
            ),
            []
        )
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistorySanitizesMalformedEntries() throws {
        let defaults = try makeDefaults()
        let history = [
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "1000",
                runsToday: -1,
                runsThisWeek: 2,
                bestWeekRuns: 1,
                currentStreak: 0,
                bestStreak: -2,
                leagueScore: -10,
                tier: .legend
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "bad",
                runsToday: 1,
                runsThisWeek: 1,
                bestWeekRuns: 1,
                currentStreak: 1,
                bestStreak: 1,
                leagueScore: 9,
                tier: .legend
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: " 0 ",
                runsToday: 1,
                runsThisWeek: 1,
                bestWeekRuns: 1,
                currentStreak: 1,
                bestStreak: 1,
                leagueScore: 9,
                tier: .legend
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "2000 ",
                runsToday: 5,
                runsThisWeek: 10,
                bestWeekRuns: 3,
                currentStreak: 8,
                bestStreak: 1,
                leagueScore: 1,
                tier: .starter
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
                weekStamp: "2000",
                runsToday: 1,
                runsThisWeek: 4,
                bestWeekRuns: 4,
                currentStreak: 2,
                bestStreak: 2,
                leagueScore: 99,
                tier: .legend
            )
        ]
        let historyData = try JSONEncoder().encode(history)
        defaults.set(
            historyData,
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey
        )

        let loadedHistory = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
            defaults: defaults,
            historyKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
            limit: 10
        )

        XCTAssertEqual(loadedHistory.map(\.weekStamp), ["2000", "1000"])

        let latestWeek = try XCTUnwrap(loadedHistory.first)
        XCTAssertEqual(latestWeek.runsToday, 1)
        XCTAssertEqual(latestWeek.runsThisWeek, 4)
        XCTAssertEqual(latestWeek.bestWeekRuns, 4)
        XCTAssertEqual(latestWeek.currentStreak, 2)
        XCTAssertEqual(latestWeek.bestStreak, 2)
        XCTAssertEqual(latestWeek.leagueScore, 13)
        XCTAssertEqual(latestWeek.tier, .elite)

        let previousWeek = try XCTUnwrap(loadedHistory.last)
        XCTAssertEqual(previousWeek.runsToday, 0)
        XCTAssertEqual(previousWeek.runsThisWeek, 2)
        XCTAssertEqual(previousWeek.bestWeekRuns, 2)
        XCTAssertEqual(previousWeek.currentStreak, 0)
        XCTAssertEqual(previousWeek.bestStreak, 0)
        XCTAssertEqual(previousWeek.leagueScore, 4)
        XCTAssertEqual(previousWeek.tier, .starter)
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeDailyRunHelpersResetAcrossDayBoundary() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 9_000_000)
        let todayStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(
            now: now,
            calendar: calendar
        )
        let yesterdayStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(
            now: now.addingTimeInterval(-86_400),
            calendar: calendar
        )
        let twoDaysAgoStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(
            now: now.addingTimeInterval(-172_800),
            calendar: calendar
        )
        let weekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
            now: now,
            calendar: calendar
        )
        let lastWeekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
            now: now.addingTimeInterval(-691_200),
            calendar: calendar
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsToday(
                dayStamp: todayStamp,
                storedCount: 2,
                now: now,
                calendar: calendar
            ),
            2
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsToday(
                dayStamp: yesterdayStamp,
                storedCount: 9,
                now: now,
                calendar: calendar
            ),
            0
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsThisWeek(
                weekStamp: weekStamp,
                storedCount: 4,
                now: now,
                calendar: calendar
            ),
            4
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsThisWeek(
                weekStamp: lastWeekStamp,
                storedCount: 12,
                now: now,
                calendar: calendar
            ),
            0
        )

        let sameDayRecorded = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedRun(
            dayStamp: todayStamp,
            storedCount: 2,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(sameDayRecorded.dayStamp, todayStamp)
        XCTAssertEqual(sameDayRecorded.runsToday, 3)

        let rolloverRecorded = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedRun(
            dayStamp: yesterdayStamp,
            storedCount: 9,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(rolloverRecorded.dayStamp, todayStamp)
        XCTAssertEqual(rolloverRecorded.runsToday, 1)

        let sameWeekRecorded = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedWeeklyRun(
            weekStamp: weekStamp,
            storedCount: 4,
            bestWeekCount: 6,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(sameWeekRecorded.weekStamp, weekStamp)
        XCTAssertEqual(sameWeekRecorded.runsThisWeek, 5)
        XCTAssertEqual(sameWeekRecorded.bestWeekCount, 6)

        let rolloverWeekRecorded = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedWeeklyRun(
            weekStamp: lastWeekStamp,
            storedCount: 12,
            bestWeekCount: 12,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(rolloverWeekRecorded.weekStamp, weekStamp)
        XCTAssertEqual(rolloverWeekRecorded.runsThisWeek, 1)
        XCTAssertEqual(rolloverWeekRecorded.bestWeekCount, 12)

        XCTAssertEqual(
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeUpdatedStreak(
                previousDayStamp: nil,
                currentStreak: 0,
                bestStreak: 0,
                now: now,
                calendar: calendar
            ).streak,
            1
        )
        let sameDayStreak = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeUpdatedStreak(
            previousDayStamp: todayStamp,
            currentStreak: 3,
            bestStreak: 5,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(sameDayStreak.streak, 3)
        XCTAssertEqual(sameDayStreak.bestStreak, 5)

        let consecutiveDayStreak = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeUpdatedStreak(
            previousDayStamp: yesterdayStamp,
            currentStreak: 3,
            bestStreak: 3,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(consecutiveDayStreak.streak, 4)
        XCTAssertEqual(consecutiveDayStreak.bestStreak, 4)

        let resetStreak = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeUpdatedStreak(
            previousDayStamp: twoDaysAgoStamp,
            currentStreak: 7,
            bestStreak: 9,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(resetStreak.streak, 1)
        XCTAssertEqual(resetStreak.bestStreak, 9)
    }

    func testTopPicksLaunchRecoveryHotKeyAutoTrustSurgeRunHelpersSaturateAtIntMax() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 9_000_000)
        let todayStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(
            now: now,
            calendar: calendar
        )
        let weekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
            now: now,
            calendar: calendar
        )

        let sameDayRecorded = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedRun(
            dayStamp: todayStamp,
            storedCount: Int.max,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(sameDayRecorded.dayStamp, todayStamp)
        XCTAssertEqual(sameDayRecorded.runsToday, Int.max)

        let sameWeekRecorded = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedWeeklyRun(
            weekStamp: weekStamp,
            storedCount: Int.max,
            bestWeekCount: Int.max,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(sameWeekRecorded.weekStamp, weekStamp)
        XCTAssertEqual(sameWeekRecorded.runsThisWeek, Int.max)
        XCTAssertEqual(sameWeekRecorded.bestWeekCount, Int.max)
    }

    func testTopPicksIdleStatePrioritizesOnboardingRecoveryFollowupAction() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Capture screen",
                systemImage: "selection.pin.in.out",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-onboarding-fill-gap",
                title: "Fill Onboarding Gap",
                subtitle: "Recover missing onboarding artifacts",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-onboarding-scorecard",
                title: "Run First-Week Fame Scorecard",
                subtitle: "Capture first-week progress",
                systemImage: "chart.bar.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move-cadence-execution-kit",
                title: "Run Next Move + Cadence Execution Kit",
                subtitle: "Run next move and prep cadence follow-up",
                systemImage: "rocket.fill",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false,
            hasFreshOnboardingRecovery: true,
            onboardingRecoveryFollowupActionID: "run-fame-onboarding-scorecard",
            onboardingRecoveryRemainingArtifacts: 1
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 4).map(\.id),
            [
                "run-fame-onboarding-scorecard",
                "run-fame-onboarding-fill-gap",
                "run-fame-next-move-cadence-execution-kit",
                "pick-and-read"
            ]
        )
    }

    func testTopPicksOnboardingRecoverySnapshotUsesFreshWindowAndFollowupCommand() throws {
        let defaults = try makeDefaults()
        let now = Date(timeIntervalSince1970: 1_790_000_000)

        defaults.set(
            now.addingTimeInterval(-60).timeIntervalSince1970,
            forKey: AppDefaults.fameOnboardingGapRecoveryLastAtKey
        )
        defaults.set(
            "run-fame-onboarding-scorecard",
            forKey: AppDefaults.fameOnboardingGapRecoveryFollowupCommandIDKey
        )
        defaults.set(1, forKey: AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey)

        let freshSnapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot(
            now: now,
            defaults: defaults,
            freshnessWindowMinutes: 20
        )
        XCTAssertEqual(
            freshSnapshot,
            CommandPaletteTopPicks.OnboardingRecoverySnapshot(
                isFresh: true,
                followupActionID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 1
            )
        )

        let staleSnapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot(
            now: now.addingTimeInterval(25 * 60),
            defaults: defaults,
            freshnessWindowMinutes: 20
        )
        XCTAssertEqual(
            staleSnapshot,
            CommandPaletteTopPicks.OnboardingRecoverySnapshot(
                isFresh: false,
                followupActionID: nil,
                remainingArtifacts: nil
            )
        )
    }

    func testTopPicksAppearingActionIDsReturnsOnlyNewIDs() {
        XCTAssertEqual(
            CommandPaletteTopPicks.appearingActionIDs(
                previous: ["read-selected", "ask-anything"],
                current: ["ask-anything", "copy-answer", "save-answer"]
            ),
            ["copy-answer", "save-answer"]
        )
    }

    func testTopPicksAppearingActionIDsSkipsReorderedItems() {
        XCTAssertEqual(
            CommandPaletteTopPicks.appearingActionIDs(
                previous: ["read-selected", "ask-anything", "show-reader"],
                current: ["show-reader", "read-selected", "ask-anything"]
            ),
            []
        )
    }

    func testUsageStorePersistsRuns() throws {
        let defaults = try makeDefaults()
        let store = CommandUsageStore(defaults: defaults, key: "commandUsage")
        store.recordRun(actionID: "read", at: Date(timeIntervalSince1970: 100))
        store.recordRun(actionID: "read", at: Date(timeIntervalSince1970: 200))

        let reloadedStore = CommandUsageStore(defaults: defaults, key: "commandUsage")
        XCTAssertEqual(reloadedStore.records["read"]?.useCount, 2)
        XCTAssertEqual(reloadedStore.records["read"]?.lastUsedAt, Date(timeIntervalSince1970: 200))
    }

    func testUsageStoreClearsRuns() throws {
        let defaults = try makeDefaults()
        let store = CommandUsageStore(defaults: defaults, key: "commandUsage")
        store.recordRun(actionID: "read", at: Date(timeIntervalSince1970: 100))

        store.clearRecords()

        XCTAssertTrue(store.records.isEmpty)
        XCTAssertTrue(CommandUsageStore(defaults: defaults, key: "commandUsage").records.isEmpty)
    }

    func testUsageStorePersistsFavorites() throws {
        let defaults = try makeDefaults()
        let store = CommandUsageStore(
            defaults: defaults,
            key: "commandUsage",
            favoritesKey: "commandFavorites"
        )

        store.toggleFavorite(actionID: "read")

        let reloadedStore = CommandUsageStore(
            defaults: defaults,
            key: "commandUsage",
            favoritesKey: "commandFavorites"
        )
        XCTAssertEqual(reloadedStore.favoriteActionIDs, ["read"])
    }

    func testUsageStoreClearsFavorites() throws {
        let defaults = try makeDefaults()
        let store = CommandUsageStore(
            defaults: defaults,
            key: "commandUsage",
            favoritesKey: "commandFavorites"
        )
        store.toggleFavorite(actionID: "read")

        store.clearFavorites()

        XCTAssertTrue(store.favoriteActionIDs.isEmpty)
        XCTAssertTrue(
            CommandUsageStore(
                defaults: defaults,
                key: "commandUsage",
                favoritesKey: "commandFavorites"
            ).favoriteActionIDs.isEmpty
        )
    }

    func testUsageStoreLoadSanitizesPersistedRecordsAndFavorites() throws {
        let defaults = try makeDefaults()
        let records = [
            "read": CommandUsageRecord(useCount: 2, lastUsedAt: Date(timeIntervalSince1970: 100)),
            " bad id ": CommandUsageRecord(useCount: 8, lastUsedAt: Date(timeIntervalSince1970: 120)),
            "open": CommandUsageRecord(useCount: 0, lastUsedAt: Date(timeIntervalSince1970: 140))
        ]
        defaults.set(try JSONEncoder().encode(records), forKey: "commandUsage")
        defaults.set(["read", " read selected ", "", "   "], forKey: "commandFavorites")

        let store = CommandUsageStore(
            defaults: defaults,
            key: "commandUsage",
            favoritesKey: "commandFavorites"
        )

        XCTAssertEqual(Set(store.records.keys), ["read"])
        XCTAssertEqual(store.records["read"]?.useCount, 2)
        XCTAssertEqual(store.favoriteActionIDs, ["read"])
    }

    func testUsageStoreRejectsInvalidActionIDWhenRecordingOrFavoriting() throws {
        let defaults = try makeDefaults()
        let store = CommandUsageStore(
            defaults: defaults,
            key: "commandUsage",
            favoritesKey: "commandFavorites"
        )

        store.recordRun(actionID: "invalid id")
        store.toggleFavorite(actionID: "invalid id")

        XCTAssertTrue(store.records.isEmpty)
        XCTAssertTrue(store.favoriteActionIDs.isEmpty)
    }

    func testUsageStoreRecordRunSaturatesAtIntMax() throws {
        let defaults = try makeDefaults()
        let records = [
            "read": CommandUsageRecord(useCount: Int.max, lastUsedAt: Date(timeIntervalSince1970: 100))
        ]
        defaults.set(try JSONEncoder().encode(records), forKey: "commandUsage")

        let store = CommandUsageStore(defaults: defaults, key: "commandUsage")
        store.recordRun(actionID: "read", at: Date(timeIntervalSince1970: 200))

        XCTAssertEqual(store.records["read"]?.useCount, Int.max)
        XCTAssertEqual(store.records["read"]?.lastUsedAt, Date(timeIntervalSince1970: 200))
    }

    func testCommandPaletteSessionTracksOpens() {
        let session = CommandPaletteSession()

        XCTAssertEqual(session.openCount, 0)
        session.beginOpen()
        session.beginOpen()
        XCTAssertEqual(session.openCount, 2)
    }

    func testCommandPaletteSessionTracksTopPickStreaks() {
        let session = CommandPaletteSession()

        XCTAssertEqual(session.topPickRunStreak, 0)
        XCTAssertEqual(session.bestTopPickRunStreak, 0)
        XCTAssertEqual(session.lastTopPickMilestone, 0)
        XCTAssertEqual(session.topPickMilestoneEvent, 0)

        session.recordRun(wasTopPick: true)
        session.recordRun(wasTopPick: true)

        XCTAssertEqual(session.topPickRunStreak, 2)
        XCTAssertEqual(session.bestTopPickRunStreak, 2)
        XCTAssertEqual(session.lastTopPickMilestone, 0)
        XCTAssertEqual(session.topPickMilestoneEvent, 0)

        session.recordRun(wasTopPick: false)

        XCTAssertEqual(session.topPickRunStreak, 0)
        XCTAssertEqual(session.bestTopPickRunStreak, 2)

        session.recordRun(wasTopPick: true)
        session.recordRun(wasTopPick: true)
        session.recordRun(wasTopPick: true)

        XCTAssertEqual(session.topPickRunStreak, 3)
        XCTAssertEqual(session.bestTopPickRunStreak, 3)
        XCTAssertEqual(session.lastTopPickMilestone, 3)
        XCTAssertEqual(session.topPickMilestoneEvent, 1)
    }

    func testCommandPaletteSessionTracksBestChannelLaunchPackPressureConversions() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureOpportunity(tone: .alert))
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureConversion(tone: .alert))

        XCTAssertEqual(session.bestChannelLaunchPackPressureOpportunities, 1)
        XCTAssertEqual(session.bestChannelLaunchPackPressureConversions, 1)
        XCTAssertEqual(session.bestChannelLaunchPackPressureConversionStreak, 1)
        XCTAssertEqual(session.bestChannelLaunchPackPressureBestStreak, 1)
        XCTAssertEqual(session.bestChannelLaunchPackPressureLastTone, .alert)

        session.beginOpen()
        session.recordBestChannelLaunchPackPressureOpportunity(tone: .watch)

        XCTAssertEqual(session.bestChannelLaunchPackPressureOpportunities, 2)
        XCTAssertEqual(session.bestChannelLaunchPackPressureConversions, 1)
        XCTAssertEqual(session.bestChannelLaunchPackPressureConversionStreak, 1)

        session.beginOpen()

        XCTAssertEqual(session.bestChannelLaunchPackPressureConversionStreak, 0)
        XCTAssertEqual(session.bestChannelLaunchPackPressureBestStreak, 1)
    }

    func testCommandPaletteSessionBestChannelLaunchPackPressureTrackingDedupesPerOpen() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureOpportunity(tone: .watch))
        XCTAssertFalse(session.recordBestChannelLaunchPackPressureOpportunity(tone: .alert))
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureConversion(tone: .watch))
        XCTAssertFalse(session.recordBestChannelLaunchPackPressureConversion(tone: .alert))

        XCTAssertEqual(session.bestChannelLaunchPackPressureOpportunities, 1)
        XCTAssertEqual(session.bestChannelLaunchPackPressureConversions, 1)
        XCTAssertEqual(session.bestChannelLaunchPackPressureConversionStreak, 1)
        XCTAssertEqual(session.bestChannelLaunchPackPressureLastTone, .watch)
    }

    func testCommandPaletteSessionBestChannelLaunchPackPressureConversionRequiresOpportunity() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        XCTAssertFalse(session.recordBestChannelLaunchPackPressureConversion(tone: .alert))
        XCTAssertEqual(session.bestChannelLaunchPackPressureConversions, 0)
    }

    func testCommandPaletteSessionPersistsBestChannelLaunchPackPressureMetrics() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        session.recordBestChannelLaunchPackPressureOpportunity(tone: .alert)
        session.recordBestChannelLaunchPackPressureConversion(tone: .alert)
        session.beginOpen()
        session.recordBestChannelLaunchPackPressureOpportunity(tone: .watch)
        session.beginOpen()

        let reloaded = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(reloaded.bestChannelLaunchPackPressureOpportunities, 2)
        XCTAssertEqual(reloaded.bestChannelLaunchPackPressureConversions, 1)
        XCTAssertEqual(reloaded.bestChannelLaunchPackPressureConversionStreak, 0)
        XCTAssertEqual(reloaded.bestChannelLaunchPackPressureBestStreak, 1)
        XCTAssertEqual(reloaded.bestChannelLaunchPackPressureLastTone, .watch)
    }

    func testCommandPaletteSessionEmitsMilestonesAtExpectedThresholds() {
        let session = CommandPaletteSession()

        (0..<5).forEach { _ in
            session.recordRun(wasTopPick: true)
        }
        XCTAssertEqual(session.topPickRunStreak, 5)
        XCTAssertEqual(session.lastTopPickMilestone, 5)
        XCTAssertEqual(session.topPickMilestoneEvent, 2) // 3 and 5

        (0..<5).forEach { _ in
            session.recordRun(wasTopPick: true)
        }
        XCTAssertEqual(session.topPickRunStreak, 10)
        XCTAssertEqual(session.lastTopPickMilestone, 10)
        XCTAssertEqual(session.topPickMilestoneEvent, 3) // +10

        (0..<5).forEach { _ in
            session.recordRun(wasTopPick: true)
        }
        XCTAssertEqual(session.topPickRunStreak, 15)
        XCTAssertEqual(session.lastTopPickMilestone, 15)
        XCTAssertEqual(session.topPickMilestoneEvent, 4) // +15
    }

    func testCommandPaletteSessionRecommendationConversionsTrackOpenStreakAndBest() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        XCTAssertFalse(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertEqual(session.recommendationConversionOpportunities, 1)
        XCTAssertEqual(session.recommendationConversionCount, 1)
        XCTAssertEqual(session.recommendationConversionOpenStreak, 1)
        XCTAssertEqual(session.recommendationConversionBestOpenStreak, 1)

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertEqual(session.recommendationConversionOpportunities, 2)
        XCTAssertEqual(session.recommendationConversionCount, 2)
        XCTAssertEqual(session.recommendationConversionOpenStreak, 2)
        XCTAssertEqual(session.recommendationConversionBestOpenStreak, 2)

        session.beginOpen()
        XCTAssertEqual(session.recommendationConversionOpenStreak, 2)
        session.beginOpen()
        XCTAssertEqual(session.recommendationConversionOpenStreak, 0)

        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertEqual(session.recommendationConversionOpportunities, 3)
        XCTAssertEqual(session.recommendationConversionCount, 3)
        XCTAssertEqual(session.recommendationConversionOpenStreak, 1)
        XCTAssertEqual(session.recommendationConversionBestOpenStreak, 2)
        XCTAssertEqual(
            session.recommendationPairPerformance(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            CommandPaletteSession.RecommendationPairPerformance(
                opportunities: 2,
                conversions: 2
            )
        )
        XCTAssertEqual(
            session.recommendationPairPerformance(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            ),
            CommandPaletteSession.RecommendationPairPerformance(
                opportunities: 1,
                conversions: 1
            )
        )
    }

    func testCommandPaletteSessionRecommendationOpportunityTrackingDedupesPerOpen() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        XCTAssertFalse(session.recordRecommendationOpportunity())
        session.beginOpen()
        XCTAssertTrue(session.recordRecommendationOpportunity())
        XCTAssertTrue(
            session.recordRecommendationOpportunity(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertFalse(session.recordRecommendationOpportunity())
        XCTAssertFalse(
            session.recordRecommendationOpportunity(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertEqual(session.recommendationConversionOpportunities, 1)
        XCTAssertEqual(
            session.recommendationPairPerformance(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            CommandPaletteSession.RecommendationPairPerformance(
                opportunities: 1,
                conversions: 0
            )
        )

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertFalse(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertEqual(session.recommendationConversionOpportunities, 2)
        XCTAssertEqual(session.recommendationConversionCount, 1)
        XCTAssertEqual(
            session.recommendationPairPerformance(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            CommandPaletteSession.RecommendationPairPerformance(
                opportunities: 2,
                conversions: 1
            )
        )
    }

    func testCommandPaletteSessionPersistsRecommendationConversionMetrics() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        XCTAssertTrue(session.recordRecommendationOpportunity())
        XCTAssertTrue(
            session.recordRecommendationOpportunity(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )

        let reloaded = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(reloaded.recommendationConversionOpportunities, 3)
        XCTAssertEqual(reloaded.recommendationConversionCount, 2)
        XCTAssertEqual(reloaded.recommendationConversionBestOpenStreak, 2)
        XCTAssertEqual(reloaded.recommendationConversionOpenStreak, 0)
        XCTAssertEqual(
            reloaded.recommendationPairPerformance(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            CommandPaletteSession.RecommendationPairPerformance(
                opportunities: 2,
                conversions: 1
            )
        )
        XCTAssertEqual(
            reloaded.recommendationPairPerformance(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            ),
            CommandPaletteSession.RecommendationPairPerformance(
                opportunities: 1,
                conversions: 1
            )
        )
    }

    func testCommandPaletteSessionLoadSanitizesMalformedRecommendationPairMetrics() throws {
        let defaults = try makeDefaults()
        let opportunities: [String: Int] = [
            "run-fame-exceptional-loop->run-fame-next-move-copy-drafts": 4,
            " run-fame-exceptional-loop -> run-fame-cadence-autopilot-loop ": 3,
            "run fame->run-fame-next-move-copy-drafts": 8,
            "run-fame-next-move-copy-drafts->run-fame-next-move-copy-drafts": 5,
            "run-fame-exceptional-loop->run-fame-cadence-autopilot-loop->extra": 9
        ]
        let conversions: [String: Int] = [
            "run-fame-exceptional-loop->run-fame-next-move-copy-drafts": 9,
            "run-fame-exceptional-loop->run-fame-cadence-autopilot-loop": 1,
            "run fame->run-fame-cadence-autopilot-loop": 2
        ]
        let lastConversionOpenCounts: [String: Int] = [
            "run-fame-exceptional-loop->run-fame-next-move-copy-drafts": 7,
            "run-fame-exceptional-loop->run-fame-cadence-autopilot-loop": -2,
            "run-fame-exceptional-loop->run-fame-cadence-autopilot-loop->extra": 4
        ]
        defaults.set(
            try JSONEncoder().encode(opportunities),
            forKey: AppDefaults.fameRecommendationConversionPairOpportunitiesKey
        )
        defaults.set(
            try JSONEncoder().encode(conversions),
            forKey: AppDefaults.fameRecommendationConversionPairConversionsKey
        )
        defaults.set(
            try JSONEncoder().encode(lastConversionOpenCounts),
            forKey: AppDefaults.fameRecommendationConversionPairLastConversionOpenCountKey
        )

        let session = CommandPaletteSession(defaults: defaults)

        XCTAssertEqual(
            session.recommendationPairPerformance(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            CommandPaletteSession.RecommendationPairPerformance(
                opportunities: 4,
                conversions: 4
            )
        )
        XCTAssertEqual(
            session.recommendationPairPerformance(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            ),
            CommandPaletteSession.RecommendationPairPerformance(
                opportunities: 3,
                conversions: 1
            )
        )
        XCTAssertEqual(
            session.recommendationPairLastConversionOpenCount(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            7
        )
        XCTAssertNil(
            session.recommendationPairLastConversionOpenCount(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertNil(
            session.recommendationPairPerformance(
                sourceActionID: "run fame",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )
    }

    func testCommandPaletteSessionRecommendationPairCountersSaturateAtIntMax() throws {
        let defaults = try makeDefaults()
        let token = "run-fame-exceptional-loop->run-fame-next-move-copy-drafts"
        defaults.set(Int.max, forKey: AppDefaults.fameRecommendationConversionOpportunitiesKey)
        defaults.set(Int.max, forKey: AppDefaults.fameRecommendationConversionCountKey)
        defaults.set(
            try JSONEncoder().encode([token: Int.max]),
            forKey: AppDefaults.fameRecommendationConversionPairOpportunitiesKey
        )
        defaults.set(
            try JSONEncoder().encode([token: Int.max]),
            forKey: AppDefaults.fameRecommendationConversionPairConversionsKey
        )

        let session = CommandPaletteSession(defaults: defaults)
        session.beginOpen()

        XCTAssertTrue(session.recordRecommendationOpportunity())
        XCTAssertTrue(
            session.recordRecommendationOpportunity(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )

        XCTAssertEqual(session.recommendationConversionOpportunities, Int.max)
        XCTAssertEqual(session.recommendationConversionCount, Int.max)
        XCTAssertEqual(
            session.recommendationPairPerformance(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            CommandPaletteSession.RecommendationPairPerformance(
                opportunities: Int.max,
                conversions: Int.max
            )
        )
    }

    func testCommandPaletteSessionPersistsRecommendationPairLastConversionOpenCount() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertEqual(
            session.recommendationPairLastConversionOpenCount(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            1
        )
        XCTAssertEqual(
            session.recommendationPairOpensSinceLastConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            0
        )

        session.beginOpen()
        XCTAssertEqual(
            session.recommendationPairOpensSinceLastConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            1
        )
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertEqual(
            session.recommendationPairLastConversionOpenCount(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            ),
            2
        )

        let reloaded = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(
            reloaded.recommendationPairLastConversionOpenCount(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            ),
            1
        )
        XCTAssertEqual(
            reloaded.recommendationPairLastConversionOpenCount(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            ),
            2
        )
    }

    func testCommandPaletteSessionRecommendationConversionsIgnoreInvalidActionIDs() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        session.beginOpen()

        XCTAssertFalse(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-next-move-copy-drafts",
                recommendedActionID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertFalse(
            session.recordRecommendationConversion(
                sourceActionID: " ",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertEqual(session.recommendationConversionCount, 0)
        XCTAssertEqual(session.recommendationConversionOpenStreak, 0)
    }

    func testCommandPaletteSessionRecommendationPairAPIsRejectWhitespaceAndSeparatorIDs() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        session.beginOpen()

        XCTAssertFalse(
            session.recordRecommendationOpportunity(
                sourceActionID: "run fame",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertFalse(
            session.recordRecommendationOpportunity(
                sourceActionID: "run-fame-next-move-copy-drafts->bad",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertFalse(
            session.recordRecommendationConversion(
                sourceActionID: "run fame",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertFalse(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-next-move-copy-drafts",
                recommendedActionID: "run-fame-cadence-autopilot-loop->bad"
            )
        )
        XCTAssertNil(
            session.recommendationPairPerformance(
                sourceActionID: "run fame",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertNil(
            session.recommendationPairLastConversionOpenCount(
                sourceActionID: "run-fame-next-move-copy-drafts",
                recommendedActionID: "run-fame-cadence-autopilot-loop->bad"
            )
        )
        XCTAssertNil(
            session.recommendationPairOpensSinceLastConversion(
                sourceActionID: "run-fame-next-move-copy-drafts->bad",
                recommendedActionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertEqual(session.recommendationConversionOpportunities, 0)
        XCTAssertEqual(session.recommendationConversionCount, 0)
    }

    func testRecommendationConversionSignalLineFormatsLiveTelemetry() {
        XCTAssertNil(
            CommandPaletteAction.recommendationConversionSignalLine(
                opportunities: 0,
                conversionCount: 0,
                openStreak: 0,
                bestOpenStreak: 0
            )
        )

        XCTAssertEqual(
            CommandPaletteAction.recommendationConversionSignalLine(
                opportunities: 5,
                conversionCount: 3,
                openStreak: 2,
                bestOpenStreak: 5
            ),
            "Recommendation proof Medium · 3/5 (60%) · streak x2 · best x5"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationConversionSignalLine(
                opportunities: 1,
                conversionCount: 1,
                openStreak: -3,
                bestOpenStreak: -1
            ),
            "Recommendation proof Calibrating · 1/1 (100%) · streak x0 · best x0"
        )
    }

    func testRecommendationConversionConfidenceTitleUsesThresholds() {
        XCTAssertEqual(
            CommandPaletteAction.recommendationConversionConfidenceTitle(
                opportunities: 2,
                conversionCount: 2
            ),
            "Calibrating"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationConversionConfidenceTitle(
                opportunities: 10,
                conversionCount: 8
            ),
            "High"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationConversionConfidenceTitle(
                opportunities: 10,
                conversionCount: 5
            ),
            "Medium"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationConversionConfidenceTitle(
                opportunities: 10,
                conversionCount: 2
            ),
            "Low"
        )
    }

    func testRecommendationPairSignalLineFormatsPairTrust() {
        XCTAssertNil(
            CommandPaletteAction.recommendationPairSignalLine(
                opportunities: 0,
                conversionCount: 0
            )
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairSignalLine(
                opportunities: 5,
                conversionCount: 4
            ),
            "This recommendation High proof · 4/5 (80%)"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairSignalLine(
                opportunities: 2,
                conversionCount: 1
            ),
            "This recommendation Calibrating proof · 1/2 (50%)"
        )
    }

    func testRecommendationPairMomentumLineFormatsRecency() {
        XCTAssertNil(
            CommandPaletteAction.recommendationPairMomentumLine(
                opensSinceLastConversion: nil
            )
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumLine(
                opensSinceLastConversion: 0
            ),
            "Recommendation momentum Hot · converted this open"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumLine(
                opensSinceLastConversion: 1
            ),
            "Recommendation momentum Hot · last win 1 open ago"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumLine(
                opensSinceLastConversion: 3
            ),
            "Recommendation momentum Warm · last win 3 opens ago"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumLine(
                opensSinceLastConversion: 5
            ),
            "Recommendation momentum Cooling · last win 5 opens ago"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumLine(
                opensSinceLastConversion: 9
            ),
            "Recommendation momentum Cold · last win 9 opens ago"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumLine(
                opensSinceLastConversion: -4
            ),
            "Recommendation momentum Hot · converted this open"
        )
    }

    func testRecommendationPairMomentumBadgeFormatsRecency() {
        XCTAssertNil(
            CommandPaletteAction.recommendationPairMomentumBadge(
                opensSinceLastConversion: nil
            )
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumBadge(
                opensSinceLastConversion: 0
            ),
            CommandPaletteAction.RecommendationMomentumBadge(
                title: "Momentum Hot",
                tone: .hot,
                helpText: "Recent recommendation wins are compounding. Latest signal: converted this open."
            )
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumBadge(
                opensSinceLastConversion: 3
            ),
            CommandPaletteAction.RecommendationMomentumBadge(
                title: "Momentum Warm",
                tone: .warm,
                helpText: "Recommendation momentum is still active. Latest signal: last win 3 opens ago."
            )
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumBadge(
                opensSinceLastConversion: 5
            ),
            CommandPaletteAction.RecommendationMomentumBadge(
                title: "Momentum Cooling",
                tone: .cooling,
                helpText: "Recommendation momentum is cooling; refresh with a quick win. Latest signal: last win 5 opens ago."
            )
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumBadge(
                opensSinceLastConversion: 9
            ),
            CommandPaletteAction.RecommendationMomentumBadge(
                title: "Momentum Cold",
                tone: .cold,
                helpText: "Recommendation momentum is stale; force a fresh conversion. Latest signal: last win 9 opens ago."
            )
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumBadge(
                opensSinceLastConversion: -2
            ),
            CommandPaletteAction.RecommendationMomentumBadge(
                title: "Momentum Hot",
                tone: .hot,
                helpText: "Recent recommendation wins are compounding. Latest signal: converted this open."
            )
        )
    }

    func testRecommendationMomentumRescueSignalLineFormatsRunTierAndRestartCue() {
        XCTAssertNil(
            CommandPaletteAction.recommendationMomentumRescueSignalLine(
                currentStreak: 0,
                bestStreak: 0
            )
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationMomentumRescueSignalLine(
                currentStreak: 2,
                bestStreak: 5
            ),
            "Rescue lane Spark · run x2 · best x5 · next Breakout at x3"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationMomentumRescueSignalLine(
                currentStreak: 5,
                bestStreak: 1
            ),
            "Rescue lane Fame · run x5 · best x5 · next Legend at x8"
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationMomentumRescueSignalLine(
                currentStreak: 0,
                bestStreak: 4
            ),
            "Rescue lane cooling · best x4 (Breakout). Land one rescue to restart momentum."
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationMomentumRescueSignalLine(
                currentStreak: 9,
                bestStreak: 8
            ),
            "Rescue lane Legend · run x9 · best x9 · legend pace locked"
        )
    }

    func testRecommendationMomentumRescueLaneBadgeShowsActiveTierState() {
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLaneBadge(
                currentStreak: 2,
                bestStreak: 5
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueLaneBadge(
                tone: .active,
                title: "Rescue Lane Active",
                systemImage: "bolt.badge.clock",
                helpText: "Top Picks is biasing cold high-confidence recommendation pairs because rescue lane is active. Current x2 (Spark), best x5; next Breakout at x3."
            )
        )
    }

    func testRecommendationMomentumRescueLaneBadgeShowsCoolingBestState() {
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLaneBadge(
                currentStreak: 0,
                bestStreak: 4
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueLaneBadge(
                tone: .cooling,
                title: "Rescue Lane Cooling",
                systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                helpText: "Rescue lane promotions are paused until the next cold high-confidence recovery. Last best x4 (Breakout)."
            )
        )
    }

    func testRecommendationMomentumRescueLaneBadgeHiddenWithoutRescueHistory() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueLaneBadge(
                currentStreak: 0,
                bestStreak: 0
            )
        )
    }

    func testRecommendationMomentumRescueLaneDetailLineFormatsActiveCoolingAndIdleStates() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueLaneDetailLine(
                currentStreak: 0,
                bestStreak: 0
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLaneDetailLine(
                currentStreak: 2,
                bestStreak: 5
            ),
            "Rescue lane Spark active · run x2 · best x5 · next Breakout at x3. Top Picks is biasing cold high-confidence recoveries."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLaneDetailLine(
                currentStreak: 0,
                bestStreak: 4
            ),
            "Rescue lane cooling · best x4 (Breakout). Promotions resume after the next cold high-confidence recovery."
        )
    }

    func testRecommendationMomentumRescueLeaderboardBadgeFormatsActiveAndIdleStates() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardBadge(
                runsToday: 0,
                bestDayRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardBadge(
                runsToday: 3,
                bestDayRuns: 5,
                currentStreak: 2,
                bestStreak: 4
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardBadge(
                tone: .active,
                title: "Rescue Board 3 Today",
                systemImage: "chart.line.uptrend.xyaxis",
                helpText: "Rescue leaderboard is live with 3 today, best day 5, lane run x2, and best lane x4."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardBadge(
                runsToday: 5,
                bestDayRuns: 5,
                currentStreak: 1,
                bestStreak: 8
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardBadge(
                tone: .active,
                title: "Rescue Board 5 Today",
                systemImage: "trophy.fill",
                helpText: "Rescue leaderboard is live with 5 today, best day 5, lane run x1, and best lane x8."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardBadge(
                runsToday: 0,
                bestDayRuns: 4,
                currentStreak: 0,
                bestStreak: 6
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardBadge(
                tone: .idle,
                title: "Rescue Board Best 4",
                systemImage: "medal.fill",
                helpText: "Rescue leaderboard best day is 4. No rescue conversions landed yet today."
            )
        )
    }

    func testRecommendationMomentumRescueLeaderboardCardFormatsIdleTieAndCatchupStates() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardCard(
                runsToday: 0,
                bestDayRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardCard(
                runsToday: 0,
                bestDayRuns: 3,
                currentStreak: 0,
                bestStreak: 5
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardCard(
                title: "Rescue Leaderboard · Best Day 3",
                subtitle: "No rescue conversions landed today yet. Land one to restart the board.",
                systemImage: "medal.fill",
                helpText: "Best rescue day: 3. Lane cooling with best x5 (Fame). Land one rescue conversion to re-open today’s board."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardCard(
                runsToday: 4,
                bestDayRuns: 4,
                currentStreak: 2,
                bestStreak: 6
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardCard(
                title: "Rescue Leaderboard · Tied Best Day",
                subtitle: "Today is at 4, matching the all-time best rescue day.",
                systemImage: "trophy.fill",
                helpText: "Today matched the all-time rescue day at 4. Lane Spark active at x2 · best x6."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardCard(
                runsToday: 2,
                bestDayRuns: 5,
                currentStreak: 0,
                bestStreak: 0
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardCard(
                title: "Rescue Leaderboard · 2 Today",
                subtitle: "3 more rescues to tie best day 5.",
                systemImage: "chart.bar.fill",
                helpText: "Today is 2 with 3 more rescues needed to tie best day 5. Lane is waiting for the first rescue chain."
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameBadgeFormatsTrendStates() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameBadge(
                runsThisWeek: 0,
                bestWeekRuns: 0,
                previousWeekRuns: 0
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameBadge(
                runsThisWeek: 6,
                bestWeekRuns: 7,
                previousWeekRuns: 4
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameBadge(
                trend: .rising,
                title: "Hall of Fame 6 Wk",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Week trend rising (6 vs 4 last week). Best week 7."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameBadge(
                runsThisWeek: 0,
                bestWeekRuns: 5,
                previousWeekRuns: 6
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameBadge(
                trend: .falling,
                title: "Hall of Fame Best 5",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Week trend cooling (0 vs 6 last week). Best week 5."
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameCardFormatsIdleRecordAndCatchupStates() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameCard(
                runsThisWeek: 0,
                bestWeekRuns: 0,
                previousWeekRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameCard(
                runsThisWeek: 0,
                bestWeekRuns: 5,
                previousWeekRuns: 3,
                currentStreak: 0,
                bestStreak: 8
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameCard(
                trend: .falling,
                title: "Rescue Hall of Fame · Best Week 5",
                subtitle: "No rescue conversions landed this week yet. 6 rescues sets a new weekly record.",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Week trend cooling (0 vs 3 last week). Best week 5. Lane cooling with best x8 (Legend)."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameCard(
                runsThisWeek: 7,
                bestWeekRuns: 7,
                previousWeekRuns: 5,
                currentStreak: 2,
                bestStreak: 9
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameCard(
                trend: .rising,
                title: "Rescue Hall of Fame · Record Pace",
                subtitle: "One more rescue sets a new weekly record at 8.",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Week trend rising (7 vs 5 last week). Best week 7. Lane Spark active at x2 · best x9."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameCard(
                runsThisWeek: 3,
                bestWeekRuns: 8,
                previousWeekRuns: 6,
                currentStreak: 0,
                bestStreak: 0
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameCard(
                trend: .falling,
                title: "Rescue Hall of Fame · 3 This Week",
                subtitle: "6 more rescues to set weekly record 9.",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Week trend cooling (3 vs 6 last week). Best week 8. Lane is waiting for the next rescue chain."
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameDefenseCueFormatsDefenseChaseAndCoolingStates() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameDefenseCue(
                runsThisWeek: 0,
                bestWeekRuns: 0,
                previousWeekRuns: 0,
                currentStreak: 0,
                bestStreak: 0
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameDefenseCue(
                runsThisWeek: 7,
                bestWeekRuns: 7,
                previousWeekRuns: 6,
                currentStreak: 2,
                bestStreak: 9
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue(
                tone: .defense,
                trend: .rising,
                title: "Hall of Fame Defense · Tied Best",
                subtitle: "One more rescue sets a new weekly record at 8.",
                buttonTitle: "Take Record",
                systemImage: "shield.lefthalf.filled",
                helpText: "Week trend rising (7 vs 6 last week). Best week 7. Lane Spark active at x2 · best x9."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameDefenseCue(
                runsThisWeek: 6,
                bestWeekRuns: 7,
                previousWeekRuns: 8,
                currentStreak: 0,
                bestStreak: 8
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue(
                tone: .defense,
                trend: .falling,
                title: "Hall of Fame Chase · 2 Away",
                subtitle: "2 more rescues before pace cools further at 8.",
                buttonTitle: "Push Record",
                systemImage: "flag.checkered.2.crossed",
                helpText: "Week trend cooling (6 vs 8 last week). Best week 7. Lane cooling with best x8 (Legend)."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameDefenseCue(
                runsThisWeek: 3,
                bestWeekRuns: 8,
                previousWeekRuns: 6,
                currentStreak: 0,
                bestStreak: 0
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue(
                tone: .defense,
                trend: .falling,
                title: "Hall of Fame Defense · Cooling",
                subtitle: "Week pace slipped. 6 more rescues to set record 9.",
                buttonTitle: "Stabilize Pace",
                systemImage: "thermometer.low",
                helpText: "Week trend cooling (3 vs 6 last week). Best week 8. Lane is waiting for the next rescue chain."
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFamePriorityPromotedActionIDsBoostRescueActionForDefenseCue() {
        let cue = CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue(
            tone: .defense,
            trend: .rising,
            title: "Hall of Fame Defense · Tied Best",
            subtitle: "One more rescue sets a new weekly record at 8.",
            buttonTitle: "Take Record",
            systemImage: "shield.lefthalf.filled",
            helpText: "stub"
        )
        let rescuePlan = CommandPaletteTopPicks.RecommendationPairRescuePlan(
            recommendedActionID: "run-fame-next-move-copy-drafts",
            opportunities: 8,
            conversions: 6,
            opensSinceLastConversion: 10,
            conversionRatePercent: 75
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFamePriorityPromotedActionIDs(
                cue: cue,
                rescuePlan: rescuePlan,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ]
            ),
            [
                "run-fame-next-move-copy-drafts",
                "run-fame-cadence-autopilot-loop"
            ]
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFamePriorityPromotedActionIDs(
                cue: cue,
                rescuePlan: rescuePlan,
                enabledActionIDs: ["run-fame-cadence-autopilot-loop"]
            ),
            []
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFamePriorityPromotedActionIDs(
                cue: nil,
                rescuePlan: rescuePlan,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            ),
            []
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFamePriorityPromotedActionIDs(
                cue: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue(
                    tone: .chase,
                    trend: .steady,
                    title: "Hall of Fame Chase · 1 Away",
                    subtitle: "One more rescue to lock record 8.",
                    buttonTitle: "Take Record",
                    systemImage: "bolt.fill",
                    helpText: "stub"
                ),
                rescuePlan: rescuePlan,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ]
            ),
            ["run-fame-next-move-copy-drafts"]
        )
    }

    func testRecommendationMomentumRescueHallOfFameLegendRiskForecastHiddenOutsideLegendWindows() {
        let risingTrend = CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
            direction: .rising,
            sampleCount: 3,
            scoreDelta: 8,
            fromTier: .legend,
            toTier: .legend,
            title: "Defense League Heat +8",
            subtitle: "3w climb · Legend",
            systemImage: "arrow.up.right.circle.fill",
            helpText: "Hall-of-Fame defense league momentum is rising."
        )
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskForecast(
                status: .ready,
                trend: risingTrend,
                runsToday: 1,
                currentWeekRuns: 8,
                bestWeekRuns: 8,
                currentStreak: 7,
                bestStreak: 7,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            ),
            "Legend risk forecast should stay hidden while legend trend is rising."
        )

        let steadyTrend = CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
            direction: .steady,
            sampleCount: 3,
            scoreDelta: 0,
            fromTier: .legend,
            toTier: .legend,
            title: "Defense League Holding",
            subtitle: "3w steady · Legend at 24",
            systemImage: "equal.circle.fill",
            helpText: "Hall-of-Fame defense league momentum is steady."
        )
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskForecast(
                status: .ready,
                trend: steadyTrend,
                runsToday: 1,
                currentWeekRuns: 5,
                bestWeekRuns: 6,
                currentStreak: 2,
                bestStreak: 3,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            ),
            "Legend risk forecast should stay hidden below the legend league tier."
        )
    }

    func testRecommendationMomentumRescueHallOfFameLegendRiskForecastBuildsWatchAndAlertVariants() {
        let steadyTrend = CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
            direction: .steady,
            sampleCount: 3,
            scoreDelta: 0,
            fromTier: .legend,
            toTier: .legend,
            title: "Defense League Holding",
            subtitle: "3w steady · Legend at 24",
            systemImage: "equal.circle.fill",
            helpText: "Hall-of-Fame defense league momentum is steady."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskForecast(
                status: .ready,
                trend: steadyTrend,
                runsToday: 0,
                currentWeekRuns: 8,
                bestWeekRuns: 8,
                currentStreak: 7,
                bestStreak: 9,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecast(
                tone: .watch,
                riskLabel: "Watch",
                nextDefenseMinutes: 0,
                nextDefenseLabel: "now",
                title: "Hall-of-Fame Legend Stability",
                subtitle: "Risk Watch · 3w steady · Legend at 24 · Next defense now",
                systemImage: "clock.arrow.circlepath",
                helpText: "Hall-of-Fame auto-defense is armed and ready. Hall-of-Fame defense league momentum is steady. Defense timing now. Run the suggested rescue step now to protect Hall-of-Fame legend pace. Current week 8/8, streak x7d (best x9d).",
                actionID: "run-fame-next-move-copy-drafts"
            )
        )

        let fallingTrend = CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
            direction: .falling,
            sampleCount: 4,
            scoreDelta: -9,
            fromTier: .legend,
            toTier: .legend,
            title: "Defense League Drift -9",
            subtitle: "4w slide · Legend",
            systemImage: "arrow.down.right.circle.fill",
            helpText: "Hall-of-Fame defense league momentum is cooling."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskForecast(
                status: .ready,
                trend: fallingTrend,
                runsToday: 0,
                currentWeekRuns: 8,
                bestWeekRuns: 8,
                currentStreak: 7,
                bestStreak: 9,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecast(
                tone: .alert,
                riskLabel: "High",
                nextDefenseMinutes: 0,
                nextDefenseLabel: "now",
                title: "Hall-of-Fame Legend Risk",
                subtitle: "Risk High · Defense League Drift -9 (Δ-9) · Next defense now",
                systemImage: "exclamationmark.shield.fill",
                helpText: "Hall-of-Fame auto-defense is armed and ready. Hall-of-Fame defense league momentum is cooling. Defense timing now. Run the suggested rescue step now to protect Hall-of-Fame legend pace. Current week 8/8, streak x7d (best x9d).",
                actionID: "run-fame-next-move-copy-drafts"
            )
        )
    }

    func testRecommendationMomentumRescueHallOfFameLegendRiskForecastAdaptsTimingByAutoDefenseStatus() {
        let steadyTrend = CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
            direction: .steady,
            sampleCount: 3,
            scoreDelta: 0,
            fromTier: .legend,
            toTier: .legend,
            title: "Defense League Holding",
            subtitle: "3w steady · Legend at 24",
            systemImage: "equal.circle.fill",
            helpText: "Hall-of-Fame defense league momentum is steady."
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let readyForecast = CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskForecast(
            status: .ready,
            trend: steadyTrend,
            runsToday: 0,
            currentWeekRuns: 8,
            bestWeekRuns: 8,
            currentStreak: 7,
            bestStreak: 7,
            enabledActionIDs: [],
            now: Date(timeIntervalSince1970: 0),
            calendar: calendar
        )
        XCTAssertEqual(readyForecast?.nextDefenseMinutes, 0)
        XCTAssertEqual(readyForecast?.nextDefenseLabel, "now")

        let coolingForecast = CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskForecast(
            status: .coolingDown(minutesRemaining: 17),
            trend: steadyTrend,
            runsToday: 0,
            currentWeekRuns: 8,
            bestWeekRuns: 8,
            currentStreak: 7,
            bestStreak: 7,
            enabledActionIDs: [],
            now: Date(timeIntervalSince1970: 0),
            calendar: calendar
        )
        XCTAssertEqual(coolingForecast?.nextDefenseMinutes, 17)
        XCTAssertEqual(coolingForecast?.nextDefenseLabel, "in 17m (~00:17)")
    }

    func testRecommendationPairMomentumRescueCueRequiresColdHighTrustPair() {
        XCTAssertNil(
            CommandPaletteAction.recommendationPairMomentumRescueCue(
                opensSinceLastConversion: nil,
                opportunities: 8,
                conversionCount: 6
            )
        )
        XCTAssertNil(
            CommandPaletteAction.recommendationPairMomentumRescueCue(
                opensSinceLastConversion: 3,
                opportunities: 8,
                conversionCount: 6
            )
        )
        XCTAssertNil(
            CommandPaletteAction.recommendationPairMomentumRescueCue(
                opensSinceLastConversion: 9,
                opportunities: 8,
                conversionCount: 2
            )
        )
        XCTAssertEqual(
            CommandPaletteAction.recommendationPairMomentumRescueCue(
                opensSinceLastConversion: 9,
                opportunities: 8,
                conversionCount: 6
            ),
            CommandPaletteAction.RecommendationMomentumRescueCue(
                title: "Momentum Rescue Ready",
                systemImage: "bolt.badge.clock",
                helpText: "High-trust recommendation is cold (6/8). Latest signal: last win 9 opens ago. Run the recommended action now to restart momentum."
            )
        )
    }

    func testRecommendationMomentumTransitionCelebrationOnlyForTierUpgrades() {
        XCTAssertFalse(
            CommandPaletteAction.shouldCelebrateRecommendationMomentumTransition(
                previousTone: nil,
                nextTone: .cold
            )
        )
        XCTAssertTrue(
            CommandPaletteAction.shouldCelebrateRecommendationMomentumTransition(
                previousTone: .cold,
                nextTone: .cooling
            )
        )
        XCTAssertTrue(
            CommandPaletteAction.shouldCelebrateRecommendationMomentumTransition(
                previousTone: .cooling,
                nextTone: .warm
            )
        )
        XCTAssertTrue(
            CommandPaletteAction.shouldCelebrateRecommendationMomentumTransition(
                previousTone: .warm,
                nextTone: .hot
            )
        )
        XCTAssertFalse(
            CommandPaletteAction.shouldCelebrateRecommendationMomentumTransition(
                previousTone: .warm,
                nextTone: .warm
            )
        )
        XCTAssertFalse(
            CommandPaletteAction.shouldCelebrateRecommendationMomentumTransition(
                previousTone: .hot,
                nextTone: .warm
            )
        )
        XCTAssertFalse(
            CommandPaletteAction.shouldCelebrateRecommendationMomentumTransition(
                previousTone: .hot,
                nextTone: .cold
            )
        )
    }

    func testCommandPaletteSessionRecommendationConversionPulseEmitsWhenBestStreakImproves() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let firstOpenStamp = Date(timeIntervalSince1970: 200)
        let secondOpenStamp = Date(timeIntervalSince1970: 260)
        let afterResetStamp = Date(timeIntervalSince1970: 360)

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                at: firstOpenStamp
            )
        )
        XCTAssertEqual(session.recommendationConversionPulseEvent, 1)
        XCTAssertEqual(
            session.recentRecommendationConversionPulse(
                now: firstOpenStamp.addingTimeInterval(6),
                maxAge: 8
            )?.title,
            "Recommendation Streak x1"
        )

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                at: secondOpenStamp
            )
        )
        XCTAssertEqual(session.recommendationConversionPulseEvent, 2)
        XCTAssertEqual(
            session.recentRecommendationConversionPulse(
                now: secondOpenStamp.addingTimeInterval(5),
                maxAge: 8
            )?.title,
            "Recommendation Streak x2"
        )

        session.beginOpen()
        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                at: afterResetStamp
            )
        )
        XCTAssertEqual(session.recommendationConversionOpenStreak, 1)
        XCTAssertEqual(session.recommendationConversionBestOpenStreak, 2)
        XCTAssertEqual(session.recommendationConversionPulseEvent, 2)
    }

    func testCommandPaletteSessionRecommendationConversionPulseRecencyCanExpire() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let stamp = Date(timeIntervalSince1970: 500)

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                at: stamp
            )
        )
        XCTAssertNotNil(
            session.recentRecommendationConversionPulse(
                now: stamp.addingTimeInterval(7),
                maxAge: 8
            )
        )
        XCTAssertNil(
            session.recentRecommendationConversionPulse(
                now: stamp.addingTimeInterval(10),
                maxAge: 8
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescuePulseEmitsForColdHighTrustRecovery() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let sourceActionID = "run-fame-exceptional-loop"
        let recommendedActionID = "run-fame-next-move-copy-drafts"
        let rescueStamp = Date(timeIntervalSince1970: 900)

        for index in 0..<5 {
            session.beginOpen()
            XCTAssertTrue(
                session.recordRecommendationConversion(
                    sourceActionID: sourceActionID,
                    recommendedActionID: recommendedActionID,
                    at: Date(timeIntervalSince1970: Double(100 + index * 20))
                )
            )
        }

        for _ in 0..<7 {
            session.beginOpen()
        }

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: recommendedActionID,
                at: rescueStamp
            )
        )

        XCTAssertEqual(session.recommendationMomentumRescuePulseEvent, 1)
        XCTAssertEqual(session.recommendationMomentumRescueRunsToday, 1)
        XCTAssertEqual(session.recommendationMomentumRescueBestDayRuns, 1)
        let rescuePulse = session.recentRecommendationMomentumRescuePulse(
            now: rescueStamp.addingTimeInterval(7),
            maxAge: 8
        )
        XCTAssertEqual(
            rescuePulse?.title,
            "Momentum Rescue x1"
        )
        XCTAssertEqual(
            rescuePulse?.subtitle,
            "Recovered after 8 opens cold"
        )
        XCTAssertEqual(rescuePulse?.systemImage, "bolt.badge.clock")
        XCTAssertEqual(rescuePulse?.streak, 1)
        XCTAssertEqual(rescuePulse?.bestStreak, 1)
        XCTAssertEqual(rescuePulse?.tierTitle, "Spark")
        XCTAssertEqual(rescuePulse?.didTierUpgrade, false)
        XCTAssertEqual(rescuePulse?.didSetNewBest, true)
        XCTAssertTrue(
            rescuePulse?.helpText.contains("Rescue lane Spark now at x1; next Breakout at x3.")
                ?? false
        )
        XCTAssertNil(
            session.recentRecommendationMomentumRescuePulse(
                now: rescueStamp.addingTimeInterval(11),
                maxAge: 8
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueWeeklyRecordPulseEmitsWhenBestWeekImproves() throws {
        let defaults = try makeDefaults()
        let sourceActionID = "run-fame-exceptional-loop"
        let recommendedActionID = "run-fame-next-move-copy-drafts"
        let now = Date()
        let weekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(now: now)
        defaults.set(
            weekStamp,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardWeekStampKey
        )
        defaults.set(
            5,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardRunsThisWeekKey
        )
        defaults.set(
            5,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardBestWeekRunsKey
        )
        defaults.set(
            4,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardPreviousWeekRunsKey
        )

        let session = CommandPaletteSession(defaults: defaults)

        for index in 0..<5 {
            session.beginOpen()
            XCTAssertTrue(
                session.recordRecommendationConversion(
                    sourceActionID: sourceActionID,
                    recommendedActionID: recommendedActionID,
                    at: now.addingTimeInterval(Double(index * 20))
                )
            )
        }

        for _ in 0..<7 {
            session.beginOpen()
        }

        let rescueStamp = now.addingTimeInterval(1_200)
        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: recommendedActionID,
                at: rescueStamp
            )
        )

        XCTAssertEqual(session.recommendationMomentumRescueRunsThisWeek, 6)
        XCTAssertEqual(session.recommendationMomentumRescueBestWeekRuns, 6)
        XCTAssertEqual(session.recommendationMomentumRescueWeeklyRecordPulseEvent, 1)

        let pulse = session.recentRecommendationMomentumRescueWeeklyRecordPulse(
            now: rescueStamp.addingTimeInterval(7),
            maxAge: 8
        )
        XCTAssertEqual(pulse?.title, "Weekly Record x6")
        XCTAssertEqual(
            pulse?.subtitle,
            "Week 6 beats best x5 (+1) · last week x4."
        )
        XCTAssertEqual(pulse?.systemImage, "trophy.fill")
        XCTAssertEqual(pulse?.runsThisWeek, 6)
        XCTAssertEqual(pulse?.previousBestWeekRuns, 5)
        XCTAssertEqual(pulse?.delta, 1)
        XCTAssertTrue(
            pulse?.helpText.contains("week 6 beats prior best x5 by +1.") ?? false
        )
        XCTAssertNil(
            session.recentRecommendationMomentumRescueWeeklyRecordPulse(
                now: rescueStamp.addingTimeInterval(10),
                maxAge: 8
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueWeeklyRecordPulseSkipsFirstRecordWeek() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let sourceActionID = "run-fame-exceptional-loop"
        let recommendedActionID = "run-fame-next-move-copy-drafts"
        let rescueStamp = Date(timeIntervalSince1970: 2_400)

        for index in 0..<5 {
            session.beginOpen()
            XCTAssertTrue(
                session.recordRecommendationConversion(
                    sourceActionID: sourceActionID,
                    recommendedActionID: recommendedActionID,
                    at: Date(timeIntervalSince1970: Double(100 + index * 20))
                )
            )
        }

        for _ in 0..<7 {
            session.beginOpen()
        }

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: recommendedActionID,
                at: rescueStamp
            )
        )

        XCTAssertEqual(session.recommendationMomentumRescueRunsThisWeek, 1)
        XCTAssertEqual(session.recommendationMomentumRescueBestWeekRuns, 1)
        XCTAssertEqual(session.recommendationMomentumRescueWeeklyRecordPulseEvent, 0)
        XCTAssertNil(
            session.recentRecommendationMomentumRescueWeeklyRecordPulse(
                now: rescueStamp.addingTimeInterval(7),
                maxAge: 8
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescuePulseSkipsLowConfidencePairs() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let sourceActionID = "run-fame-exceptional-loop"
        let recommendedActionID = "run-fame-next-move-copy-drafts"

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: recommendedActionID,
                at: Date(timeIntervalSince1970: 200)
            )
        )
        XCTAssertEqual(session.recommendationMomentumRescuePulseEvent, 0)

        for _ in 0..<9 {
            session.beginOpen()
        }

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: recommendedActionID,
                at: Date(timeIntervalSince1970: 400)
            )
        )
        XCTAssertEqual(
            session.recommendationMomentumRescuePulseEvent,
            0,
            "Rescue pulse should only emit when the pair had high-confidence proof before the comeback."
        )
        XCTAssertEqual(session.recommendationMomentumRescueStreak, 0)
        XCTAssertEqual(session.recommendationMomentumRescueBestStreak, 0)
    }

    func testCommandPaletteSessionRecommendationMomentumRescueImpactPulseRecencyCanExpire() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let stamp = Date(timeIntervalSince1970: 1_200)
        let pulse = CommandPaletteTopPicks.recommendationMomentumRescueImpactPulse(
            actionTitle: "Run Fame Cadence Autopilot Loop",
            currentStreak: 2,
            bestStreak: 5,
            rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 9,
                conversionRatePercent: 75
            )
        )

        session.recordRecommendationMomentumRescueImpactPulse(pulse, at: stamp)
        XCTAssertEqual(session.recommendationMomentumRescueImpactPulseEvent, 1)
        XCTAssertEqual(
            session.recentRecommendationMomentumRescueImpactPulse(
                now: stamp.addingTimeInterval(7),
                maxAge: 8
            )?.title,
            "Rescue Attempt · Spark"
        )
        XCTAssertNil(
            session.recentRecommendationMomentumRescueImpactPulse(
                now: stamp.addingTimeInterval(10),
                maxAge: 8
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueStreakPersistsAndResetsAcrossOpens() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let sourceActionID = "run-fame-exceptional-loop"
        let firstRecommendedActionID = "run-fame-next-move-copy-drafts"
        let secondRecommendedActionID = "run-fame-cadence-autopilot-loop"

        for index in 0..<5 {
            session.beginOpen()
            XCTAssertTrue(
                session.recordRecommendationConversion(
                    sourceActionID: sourceActionID,
                    recommendedActionID: firstRecommendedActionID,
                    at: Date(timeIntervalSince1970: Double(100 + index * 20))
                )
            )
        }

        for index in 0..<5 {
            session.beginOpen()
            XCTAssertTrue(
                session.recordRecommendationConversion(
                    sourceActionID: sourceActionID,
                    recommendedActionID: secondRecommendedActionID,
                    at: Date(timeIntervalSince1970: Double(300 + index * 20))
                )
            )
        }

        for _ in 0..<7 {
            session.beginOpen()
        }

        let firstRescueStamp = Date(timeIntervalSince1970: 900)
        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: firstRecommendedActionID,
                at: firstRescueStamp
            )
        )
        XCTAssertEqual(session.recommendationMomentumRescueStreak, 1)
        XCTAssertEqual(session.recommendationMomentumRescueBestStreak, 1)
        let firstRescuePulse = session.recentRecommendationMomentumRescuePulse(
            now: firstRescueStamp.addingTimeInterval(7),
            maxAge: 8
        )
        XCTAssertEqual(
            firstRescuePulse?.title,
            "Momentum Rescue x1"
        )
        XCTAssertEqual(firstRescuePulse?.systemImage, "bolt.badge.clock")
        XCTAssertTrue(
            firstRescuePulse?.helpText.contains("Rescue lane Spark now at x1; next Breakout at x3.")
                ?? false
        )

        let secondRescueStamp = Date(timeIntervalSince1970: 1200)
        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: secondRecommendedActionID,
                at: secondRescueStamp
            )
        )
        XCTAssertEqual(session.recommendationMomentumRescuePulseEvent, 2)
        XCTAssertEqual(session.recommendationMomentumRescueStreak, 2)
        XCTAssertEqual(session.recommendationMomentumRescueBestStreak, 2)
        let secondRescuePulse = session.recentRecommendationMomentumRescuePulse(
            now: secondRescueStamp.addingTimeInterval(7),
            maxAge: 8
        )
        XCTAssertEqual(
            secondRescuePulse?.title,
            "Momentum Rescue x2"
        )
        XCTAssertEqual(secondRescuePulse?.systemImage, "bolt.badge.clock")
        XCTAssertTrue(
            secondRescuePulse?.helpText.contains("Rescue lane Spark now at x2; next Breakout at x3.")
                ?? false
        )

        let reloadedDuringStreak = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(reloadedDuringStreak.recommendationMomentumRescueStreak, 2)
        XCTAssertEqual(reloadedDuringStreak.recommendationMomentumRescueBestStreak, 2)

        session.beginOpen()
        session.beginOpen()
        XCTAssertEqual(session.recommendationMomentumRescueStreak, 0)
        XCTAssertEqual(session.recommendationMomentumRescueBestStreak, 2)

        let reloadedAfterReset = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(reloadedAfterReset.recommendationMomentumRescueStreak, 0)
        XCTAssertEqual(reloadedAfterReset.recommendationMomentumRescueBestStreak, 2)
    }

    func testCommandPaletteSessionRecommendationMomentumRescueLeaderboardTracksBestDayAndRollsOver() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let sourceActionID = "run-fame-exceptional-loop"
        let recommendedActionID = "run-fame-next-move-copy-drafts"
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let dayStart = todayStart.addingTimeInterval(3_600)

        for index in 0..<5 {
            session.beginOpen()
            XCTAssertTrue(
                session.recordRecommendationConversion(
                    sourceActionID: sourceActionID,
                    recommendedActionID: recommendedActionID,
                    at: dayStart.addingTimeInterval(Double(index * 60))
                )
            )
        }

        for _ in 0..<7 {
            session.beginOpen()
        }

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: recommendedActionID,
                at: dayStart.addingTimeInterval(1_200)
            )
        )
        XCTAssertEqual(session.recommendationMomentumRescueRunsToday, 1)
        XCTAssertEqual(session.recommendationMomentumRescueBestDayRuns, 1)

        for _ in 0..<7 {
            session.beginOpen()
        }

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: recommendedActionID,
                at: dayStart.addingTimeInterval(2_400)
            )
        )
        XCTAssertEqual(session.recommendationMomentumRescueRunsToday, 2)
        XCTAssertEqual(session.recommendationMomentumRescueBestDayRuns, 2)

        let reloadedSameDay = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(reloadedSameDay.recommendationMomentumRescueRunsToday, 2)
        XCTAssertEqual(reloadedSameDay.recommendationMomentumRescueBestDayRuns, 2)

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart) else {
            XCTFail("Expected a valid yesterday date")
            return
        }
        defaults.set(
            String(Int(yesterday.timeIntervalSince1970)),
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardDayStampKey
        )
        defaults.set(
            4,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardRunsTodayKey
        )
        defaults.set(
            6,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardBestDayRunsKey
        )

        let reloadedNextDay = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(reloadedNextDay.recommendationMomentumRescueRunsToday, 0)
        XCTAssertEqual(reloadedNextDay.recommendationMomentumRescueBestDayRuns, 6)
    }

    func testCommandPaletteSessionRecommendationMomentumRescueWeeklyLeaderboardCarriesPreviousWeekAcrossReload() throws {
        let defaults = try makeDefaults()
        let calendar = Calendar.current
        let now = Date()
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            XCTFail("Expected a valid current week start")
            return
        }
        let previousWeekDate = currentWeekStart.addingTimeInterval(-86_400)
        let currentWeekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
            now: now,
            calendar: calendar
        )
        let previousWeekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
            now: previousWeekDate,
            calendar: calendar
        )
        XCTAssertNotEqual(previousWeekStamp, currentWeekStamp)

        defaults.set(
            previousWeekStamp,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardWeekStampKey
        )
        defaults.set(
            6,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardRunsThisWeekKey
        )
        defaults.set(
            9,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardBestWeekRunsKey
        )
        defaults.set(
            0,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardPreviousWeekRunsKey
        )

        let session = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(session.recommendationMomentumRescueRunsThisWeek, 0)
        XCTAssertEqual(session.recommendationMomentumRescueBestWeekRuns, 9)
        XCTAssertEqual(session.recommendationMomentumRescuePreviousWeekRuns, 6)
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardPreviousWeekRunsKey),
            6
        )

        session.beginOpen()
        XCTAssertEqual(
            defaults.string(forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardWeekStampKey),
            currentWeekStamp
        )
        XCTAssertEqual(session.recommendationMomentumRescueRunsThisWeek, 0)
        XCTAssertEqual(session.recommendationMomentumRescuePreviousWeekRuns, 6)

        let sourceActionID = "run-fame-exceptional-loop"
        let recommendedActionID = "run-fame-next-move-copy-drafts"
        for index in 0..<5 {
            session.beginOpen()
            XCTAssertTrue(
                session.recordRecommendationConversion(
                    sourceActionID: sourceActionID,
                    recommendedActionID: recommendedActionID,
                    at: now.addingTimeInterval(Double(index * 60))
                )
            )
        }

        for _ in 0..<7 {
            session.beginOpen()
        }

        session.beginOpen()
        XCTAssertTrue(
            session.recordRecommendationConversion(
                sourceActionID: sourceActionID,
                recommendedActionID: recommendedActionID,
                at: now.addingTimeInterval(1_200)
            )
        )
        XCTAssertEqual(session.recommendationMomentumRescueRunsThisWeek, 1)
        XCTAssertEqual(session.recommendationMomentumRescueBestWeekRuns, 9)
        XCTAssertEqual(session.recommendationMomentumRescuePreviousWeekRuns, 6)

        let reloaded = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(reloaded.recommendationMomentumRescueRunsThisWeek, 1)
        XCTAssertEqual(reloaded.recommendationMomentumRescueBestWeekRuns, 9)
        XCTAssertEqual(reloaded.recommendationMomentumRescuePreviousWeekRuns, 6)
    }

    func testCommandPaletteSessionKeepsRecentCadenceMomentumPulse() {
        let session = CommandPaletteSession()
        let pulse = CommandPaletteCadenceExecutionKitStreak.MomentumPulse(
            title: "Cadence +1 to x4",
            subtitle: "Next milestone x5 in 1 run · Best x7",
            systemImage: "bolt.fill",
            helpText: "Cadence +1 to x4. Next milestone x5 in 1 run · Best x7"
        )
        let recordedAt = Date(timeIntervalSince1970: 200)

        XCTAssertNil(
            session.recentCadenceExecutionKitMomentumPulse(
                now: recordedAt,
                maxAge: 12
            )
        )

        session.recordCadenceExecutionKitMomentumPulse(pulse, at: recordedAt)
        XCTAssertEqual(session.cadenceExecutionKitMomentumPulseEvent, 1)
        XCTAssertEqual(
            session.recentCadenceExecutionKitMomentumPulse(
                now: Date(timeIntervalSince1970: 211),
                maxAge: 12
            ),
            pulse
        )
        XCTAssertNil(
            session.recentCadenceExecutionKitMomentumPulse(
                now: Date(timeIntervalSince1970: 214),
                maxAge: 12
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryReadinessTrendTracksPerOpenAndCapsHistory() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard")
        )
        XCTAssertTrue(session.launchRecoveryHotKeyReadinessHistory.isEmpty)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard")
        )
        session.recordLaunchRecoveryHotKeyReadiness(
            .reroute(actionID: "run-fame-cadence-autopilot-loop")
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyReadinessHistory,
            [.direct]
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .reroute(actionID: "run-fame-cadence-autopilot-loop")
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .unavailable,
            sampleLimit: 2
        )

        XCTAssertEqual(
            session.launchRecoveryHotKeyReadinessHistory,
            [.reroute, .standby]
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyReadinessTrend(limit: 2),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend(
                directCount: 0,
                rerouteCount: 1,
                standbyCount: 1
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryDirectStreakTracksCurrentAndBest() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard")
        )
        XCTAssertEqual(session.launchRecoveryHotKeyDirectStreak, 1)
        XCTAssertEqual(session.launchRecoveryHotKeyBestDirectStreak, 1)

        session.recordLaunchRecoveryHotKeyReadiness(
            .reroute(actionID: "run-fame-cadence-autopilot-loop")
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyDirectStreak,
            1,
            "Duplicate readiness writes in the same open should be ignored."
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard")
        )
        XCTAssertEqual(session.launchRecoveryHotKeyDirectStreak, 2)
        XCTAssertEqual(session.launchRecoveryHotKeyBestDirectStreak, 2)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .reroute(actionID: "run-fame-cadence-autopilot-loop")
        )
        XCTAssertEqual(session.launchRecoveryHotKeyDirectStreak, 0)
        XCTAssertEqual(session.launchRecoveryHotKeyBestDirectStreak, 2)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard")
        )
        XCTAssertEqual(session.launchRecoveryHotKeyDirectStreak, 1)
        XCTAssertEqual(session.launchRecoveryHotKeyBestDirectStreak, 2)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard")
        )
        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard")
        )
        XCTAssertEqual(session.launchRecoveryHotKeyDirectStreak, 3)
        XCTAssertEqual(session.launchRecoveryHotKeyBestDirectStreak, 3)
    }

    func testCommandPaletteSessionLaunchRecoveryConfidencePulseRequiresTierTransitionAndPerOpenDedupe() {
        let session = CommandPaletteSession()

        session.beginOpen()
        XCTAssertNil(
            session.recordLaunchRecoveryHotKeyConfidenceScore(
                makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyConfidencePulseEvent, 0)

        XCTAssertNil(
            session.recordLaunchRecoveryHotKeyConfidenceScore(
                makeLaunchRecoveryConfidenceScore(tier: .prime, points: 92)
            ),
            "Duplicate confidence writes in the same open should be ignored."
        )
        XCTAssertEqual(session.launchRecoveryHotKeyConfidencePulseEvent, 0)

        session.beginOpen()
        let secondOpen = Date(timeIntervalSince1970: 410)
        let secondPulse = session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 67),
            at: secondOpen
        )
        XCTAssertEqual(
            secondPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidencePulse(
                previousTier: .watch,
                nextTier: .steady,
                points: 67
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyConfidencePulseEvent, 1)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyConfidencePulse(
                now: secondOpen.addingTimeInterval(6),
                maxAge: 12
            ),
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidencePulse(
                previousTier: .watch,
                nextTier: .steady,
                points: 67
            )
        )
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyConfidencePulse(
                now: secondOpen.addingTimeInterval(14),
                maxAge: 12
            )
        )

        session.beginOpen()
        XCTAssertNil(
            session.recordLaunchRecoveryHotKeyConfidenceScore(
                makeLaunchRecoveryConfidenceScore(tier: .steady, points: 63)
            )
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyConfidencePulseEvent,
            1,
            "No pulse should emit when tier does not change."
        )

        session.beginOpen()
        let fourthOpen = Date(timeIntervalSince1970: 480)
        let fourthPulse = session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .critical, points: 18),
            at: fourthOpen
        )
        XCTAssertEqual(
            fourthPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidencePulse(
                previousTier: .steady,
                nextTier: .critical,
                points: 18
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyConfidencePulseEvent, 2)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyConfidencePulse(
                now: fourthOpen.addingTimeInterval(5),
                maxAge: 12
            ),
            CommandPaletteTopPicks.launchRecoveryHotKeyConfidencePulse(
                previousTier: .steady,
                nextTier: .critical,
                points: 18
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryMomentumPulseUsesRecencyAndPerOpenDedupe() {
        let session = CommandPaletteSession()
        let steadyMomentum = makeLaunchRecoveryMomentumSnapshot(
            direction: .steady,
            deltaPoints: 0,
            previousScore: 78,
            recentScore: 78
        )
        let risingMomentum = makeLaunchRecoveryMomentumSnapshot(
            direction: .rising,
            deltaPoints: 17,
            previousScore: 71,
            recentScore: 88
        )
        let risingBreakoutMomentum = makeLaunchRecoveryMomentumSnapshot(
            direction: .rising,
            deltaPoints: 29,
            previousScore: 67,
            recentScore: 96
        )
        let fallingMomentum = makeLaunchRecoveryMomentumSnapshot(
            direction: .falling,
            deltaPoints: -15,
            previousScore: 63,
            recentScore: 48
        )

        session.beginOpen()
        XCTAssertNil(
            session.recordLaunchRecoveryHotKeyMomentum(
                steadyMomentum,
                at: Date(timeIntervalSince1970: 520)
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyMomentumPulseEvent, 0)
        XCTAssertNil(
            session.recordLaunchRecoveryHotKeyMomentum(
                risingMomentum,
                at: Date(timeIntervalSince1970: 521)
            ),
            "Duplicate momentum writes in the same open should be ignored."
        )
        XCTAssertEqual(session.launchRecoveryHotKeyMomentumPulseEvent, 0)

        session.beginOpen()
        let secondOpen = Date(timeIntervalSince1970: 560)
        let surgePulse = session.recordLaunchRecoveryHotKeyMomentum(
            risingMomentum,
            at: secondOpen
        )
        XCTAssertEqual(
            surgePulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
                previousMomentum: steadyMomentum,
                nextMomentum: risingMomentum
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyMomentumPulseEvent, 1)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyMomentumPulse(
                now: secondOpen.addingTimeInterval(6),
                maxAge: 12
            ),
            surgePulse
        )
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyMomentumPulse(
                now: secondOpen.addingTimeInterval(14),
                maxAge: 12
            )
        )

        session.beginOpen()
        XCTAssertNil(
            session.recordLaunchRecoveryHotKeyMomentum(
                makeLaunchRecoveryMomentumSnapshot(
                    direction: .rising,
                    deltaPoints: 22,
                    previousScore: 70,
                    recentScore: 92
                ),
                at: Date(timeIntervalSince1970: 610)
            ),
            "No pulse should emit when momentum stays rising without a breakout threshold."
        )
        XCTAssertEqual(session.launchRecoveryHotKeyMomentumPulseEvent, 1)

        session.beginOpen()
        let fourthOpen = Date(timeIntervalSince1970: 650)
        let breakoutPulse = session.recordLaunchRecoveryHotKeyMomentum(
            risingBreakoutMomentum,
            at: fourthOpen
        )
        XCTAssertEqual(
            breakoutPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
                previousMomentum: makeLaunchRecoveryMomentumSnapshot(
                    direction: .rising,
                    deltaPoints: 22,
                    previousScore: 70,
                    recentScore: 92
                ),
                nextMomentum: risingBreakoutMomentum
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyMomentumPulseEvent, 2)

        session.beginOpen()
        let fifthOpen = Date(timeIntervalSince1970: 690)
        let slipPulse = session.recordLaunchRecoveryHotKeyMomentum(
            fallingMomentum,
            at: fifthOpen
        )
        XCTAssertEqual(
            slipPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
                previousMomentum: risingBreakoutMomentum,
                nextMomentum: fallingMomentum
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyMomentumPulseEvent, 3)
    }

    func testCommandPaletteSessionLaunchRecoveryAutoTrustSurgeLeaguePromotionPulseUsesRecency() throws {
        let session = CommandPaletteSession()
        let recordedAt = Date(timeIntervalSince1970: 700)
        let pulse = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeaguePulse(
            fromTier: .rising,
            toTier: .elite,
            runsThisWeek: 6,
            currentStreak: 4
        )

        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse(
                now: recordedAt,
                maxAge: 12
            )
        )

        session.recordLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse(
            try XCTUnwrap(pulse),
            at: recordedAt
        )
        XCTAssertEqual(session.launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseEvent, 1)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse(
                now: recordedAt.addingTimeInterval(6),
                maxAge: 12
            ),
            pulse
        )
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse(
                now: recordedAt.addingTimeInterval(14),
                maxAge: 12
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseUsesRecency() throws {
        let session = CommandPaletteSession()
        let recordedAt = Date(timeIntervalSince1970: 760)
        let pulse = CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse(
            fromTier: .rising,
            toTier: .elite,
            currentWeekRuns: 6,
            currentStreak: 4
        )

        XCTAssertNil(
            session.recentRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse(
                now: recordedAt,
                maxAge: 12
            )
        )

        session.recordRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse(
            try XCTUnwrap(pulse),
            at: recordedAt
        )
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseEvent,
            1
        )
        XCTAssertEqual(
            session.recentRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse(
                now: recordedAt.addingTimeInterval(6),
                maxAge: 12
            ),
            pulse
        )
        XCTAssertNil(
            session.recentRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse(
                now: recordedAt.addingTimeInterval(14),
                maxAge: 12
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueHallOfFameLegendRiskPulseUsesRecencyAndPerOpenDedupe() {
        let session = CommandPaletteSession()
        let delayedForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskWatchForecast(
            nextDefenseMinutes: 8,
            nextDefenseLabel: "in 8m (~11:28)"
        )
        let readyForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskWatchForecast(
            nextDefenseMinutes: 0,
            nextDefenseLabel: "now"
        )
        let alertForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskAlertForecast()
        let firstOpenDate = Date(timeIntervalSince1970: 790)

        XCTAssertNil(
            session.recentRecommendationMomentumRescueHallOfFameLegendRiskPulse(
                now: firstOpenDate,
                maxAge: 12
            )
        )

        session.beginOpen()
        XCTAssertNil(
            session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
                delayedForecast,
                at: firstOpenDate
            )
        )
        XCTAssertEqual(session.recommendationMomentumRescueHallOfFameLegendRiskPulseEvent, 0)
        XCTAssertNil(
            session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
                readyForecast,
                at: firstOpenDate.addingTimeInterval(1)
            ),
            "Duplicate writes in the same open should be ignored."
        )
        XCTAssertEqual(session.recommendationMomentumRescueHallOfFameLegendRiskPulseEvent, 0)

        session.beginOpen()
        let secondOpenDate = Date(timeIntervalSince1970: 840)
        let watchPulse = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            readyForecast,
            at: secondOpenDate
        )
        XCTAssertEqual(
            watchPulse,
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskPulse(
                previousForecast: delayedForecast,
                nextForecast: readyForecast
            )
        )
        XCTAssertEqual(session.recommendationMomentumRescueHallOfFameLegendRiskPulseEvent, 1)
        XCTAssertEqual(
            session.recentRecommendationMomentumRescueHallOfFameLegendRiskPulse(
                now: secondOpenDate.addingTimeInterval(4),
                maxAge: 12
            ),
            watchPulse
        )
        XCTAssertNil(
            session.recentRecommendationMomentumRescueHallOfFameLegendRiskPulse(
                now: secondOpenDate.addingTimeInterval(14),
                maxAge: 12
            )
        )

        session.beginOpen()
        let thirdOpenDate = Date(timeIntervalSince1970: 890)
        let alertPulse = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            alertForecast,
            at: thirdOpenDate
        )
        XCTAssertEqual(
            alertPulse,
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskPulse(
                previousForecast: readyForecast,
                nextForecast: alertForecast
            )
        )
        XCTAssertEqual(session.recommendationMomentumRescueHallOfFameLegendRiskPulseEvent, 2)
        XCTAssertEqual(
            session.recentRecommendationMomentumRescueHallOfFameLegendRiskPulse(
                now: thirdOpenDate.addingTimeInterval(6),
                maxAge: 12
            ),
            alertPulse
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionPersistsForThreeOpensByDefault() {
        let session = CommandPaletteSession()
        let alertForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskAlertForecast()
        let watchForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-next-move-copy-drafts"]

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(alertForecast)
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-next-move-copy-drafts"
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(watchForecast)
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-next-move-copy-drafts"
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(watchForecast)
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-next-move-copy-drafts"
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(watchForecast)
        XCTAssertNil(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionSupportsOneOpenWindow() {
        let session = CommandPaletteSession()
        let alertForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskAlertForecast()
        let watchForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-next-move-copy-drafts"]

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            alertForecast,
            stickyPromotionOpenWindow: 1
        )
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-next-move-copy-drafts"
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            watchForecast,
            stickyPromotionOpenWindow: 1
        )
        XCTAssertNil(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionTracksRemainingOpens() {
        let session = CommandPaletteSession()
        let alertForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskAlertForecast()
        let watchForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-next-move-copy-drafts"]

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(alertForecast)
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            ),
            CommandPaletteSession.RecommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
                actionID: "run-fame-next-move-copy-drafts",
                opensRemaining: 3,
                isHoldUntilRecovered: false
            )
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(watchForecast)
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            ),
            CommandPaletteSession.RecommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
                actionID: "run-fame-next-move-copy-drafts",
                opensRemaining: 2,
                isHoldUntilRecovered: false
            )
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(watchForecast)
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            ),
            CommandPaletteSession.RecommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
                actionID: "run-fame-next-move-copy-drafts",
                opensRemaining: 1,
                isHoldUntilRecovered: false
            )
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(watchForecast)
        XCTAssertNil(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            )
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionCanHoldUntilRecovered() {
        let session = CommandPaletteSession()
        let alertForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskAlertForecast()
        let watchForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-next-move-copy-drafts"]

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            alertForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true
        )
        let firstStickyPromotion = session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )
        XCTAssertEqual(
            firstStickyPromotion?.actionID,
            "run-fame-next-move-copy-drafts"
        )
        XCTAssertTrue(firstStickyPromotion?.isHoldUntilRecovered ?? false)

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            watchForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true
        )
        let secondStickyPromotion = session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )
        XCTAssertEqual(
            secondStickyPromotion?.actionID,
            "run-fame-next-move-copy-drafts",
            "Hold-until-recovered should keep sticky promotion active while forecast is still live."
        )
        XCTAssertTrue(secondStickyPromotion?.isHoldUntilRecovered ?? false)

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            watchForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true
        )
        let thirdStickyPromotion = session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )
        XCTAssertEqual(
            thirdStickyPromotion?.actionID,
            "run-fame-next-move-copy-drafts"
        )
        XCTAssertTrue(thirdStickyPromotion?.isHoldUntilRecovered ?? false)

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            nil,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true
        )
        XCTAssertNil(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            ),
            "Sticky promotion should clear as soon as recovery removes the legend risk forecast."
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionCanFeedTopPicksPromotedOrdering() {
        let session = CommandPaletteSession()
        let alertForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskAlertForecast()
        let watchForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskWatchForecast()
        let actions = [
            CommandPaletteAction(
                id: "run-fame-next-move-copy-drafts",
                title: "Run Fame Next Move + Copy Drafts",
                subtitle: "Rescue next move",
                systemImage: "bolt.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "settings",
                title: "Settings",
                subtitle: "Open settings",
                systemImage: "gearshape",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read",
                systemImage: "text.cursor",
                run: {}
            )
        ]
        let enabledActionIDs = Set(actions.map(\.id))
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(alertForecast)

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(watchForecast)

        let stickyPromotion = session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )
        XCTAssertEqual(stickyPromotion?.actionID, "run-fame-next-move-copy-drafts")

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(
                from: actions,
                context: context,
                favoriteActionIDs: ["settings"],
                promotedActionIDs: stickyPromotion.map { [$0.actionID] } ?? [],
                limit: 3
            ).map(\.id),
            ["settings", "run-fame-next-move-copy-drafts", "read-selected"]
        )
    }

    func testCommandPaletteSessionRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseEmitsOnRecovery() {
        let session = CommandPaletteSession()
        let alertForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskAlertForecast()
        let watchForecast = makeRecommendationMomentumRescueHallOfFameLegendRiskWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-next-move-copy-drafts"]
        let firstOpenDate = Date(timeIntervalSince1970: 1_200)
        let secondOpenDate = Date(timeIntervalSince1970: 1_240)
        let thirdOpenDate = Date(timeIntervalSince1970: 1_280)

        XCTAssertNil(
            session.recentRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
                now: firstOpenDate,
                maxAge: 12
            )
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            alertForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true,
            at: firstOpenDate
        )
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseEvent,
            0
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            watchForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true,
            at: secondOpenDate
        )
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseEvent,
            0
        )
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-next-move-copy-drafts"
        )

        session.beginOpen()
        _ = session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            nil,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true,
            at: thirdOpenDate
        )
        XCTAssertEqual(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseEvent,
            1
        )
        XCTAssertEqual(
            session.recentRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
                now: thirdOpenDate.addingTimeInterval(4),
                maxAge: 12
            ),
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
                actionID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertNil(
            session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            )
        )
        XCTAssertNil(
            session.recentRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
                now: thirdOpenDate.addingTimeInterval(14),
                maxAge: 12
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryAutoTrustSurgeLegendDecayPulseUsesRecencyAndPerOpenDedupe() {
        let session = CommandPaletteSession()
        let alertForecast = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            tone: .alert,
            riskLabel: "High",
            nextDefenseMinutes: 0,
            nextDefenseLabel: "now",
            title: "Legend Decay Forecast",
            subtitle: "Risk High · est. tier slip ~14d · Next defense now",
            systemImage: "hourglass.badge.exclamationmark",
            helpText: "Auto Trust Surge is armed and ready.",
            actionID: "run-fame-cadence-autopilot-loop"
        )
        let watchDelayedForecast = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            tone: .watch,
            riskLabel: "Watch",
            nextDefenseMinutes: 8,
            nextDefenseLabel: "in 8m (~11:28)",
            title: "Legend Stability Forecast",
            subtitle: "Risk Watch · 3w steady · Legend at 24 · Next defense in 8m (~11:28)",
            systemImage: "clock.arrow.circlepath",
            helpText: "Auto Trust Surge is cooling down.",
            actionID: nil
        )
        let watchReadyForecast = CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            tone: .watch,
            riskLabel: "Watch",
            nextDefenseMinutes: 0,
            nextDefenseLabel: "now",
            title: "Legend Stability Forecast",
            subtitle: "Risk Watch · 3w steady · Legend at 24 · Next defense now",
            systemImage: "clock.arrow.circlepath",
            helpText: "Auto Trust Surge is armed and ready.",
            actionID: nil
        )
        let firstOpenDate = Date(timeIntervalSince1970: 810)

        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                now: firstOpenDate,
                maxAge: 12
            )
        )

        session.beginOpen()
        let firstPulse = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            alertForecast,
            at: firstOpenDate
        )
        XCTAssertEqual(
            firstPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                previousForecast: nil,
                nextForecast: alertForecast
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseEvent, 1)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                now: firstOpenDate.addingTimeInterval(6),
                maxAge: 12
            ),
            firstPulse
        )
        XCTAssertNil(
            session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                watchDelayedForecast,
                at: firstOpenDate.addingTimeInterval(1)
            ),
            "Duplicate writes in the same open should be ignored."
        )
        XCTAssertEqual(session.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseEvent, 1)
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                now: firstOpenDate.addingTimeInterval(14),
                maxAge: 12
            )
        )

        session.beginOpen()
        XCTAssertNil(
            session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                watchDelayedForecast,
                at: Date(timeIntervalSince1970: 860)
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseEvent, 1)

        session.beginOpen()
        let thirdOpenDate = Date(timeIntervalSince1970: 910)
        let readyPulse = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            watchReadyForecast,
            at: thirdOpenDate
        )
        XCTAssertEqual(
            readyPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                previousForecast: watchDelayedForecast,
                nextForecast: watchReadyForecast
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseEvent, 2)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                now: thirdOpenDate.addingTimeInterval(4),
                maxAge: 12
            ),
            readyPulse
        )
    }

    func testCommandPaletteSessionLaunchRecoveryHotKeyLegendRiskStickyReleasePulseEmitsOnRecovery() {
        let session = CommandPaletteSession()
        let alertForecast = makeLaunchRecoveryLegendDecayAlertForecast()
        let watchForecast = makeLaunchRecoveryLegendDecayWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-cadence-autopilot-loop"]
        let firstOpenDate = Date(timeIntervalSince1970: 1_000)
        let secondOpenDate = Date(timeIntervalSince1970: 1_040)
        let thirdOpenDate = Date(timeIntervalSince1970: 1_080)

        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyLegendRiskStickyReleasePulse(
                now: firstOpenDate,
                maxAge: 12
            )
        )

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            alertForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true,
            at: firstOpenDate
        )
        XCTAssertEqual(session.launchRecoveryHotKeyLegendRiskStickyReleasePulseEvent, 0)

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            watchForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true,
            at: secondOpenDate
        )
        XCTAssertEqual(session.launchRecoveryHotKeyLegendRiskStickyReleasePulseEvent, 0)
        XCTAssertEqual(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-cadence-autopilot-loop"
        )

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            nil,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true,
            at: thirdOpenDate
        )
        XCTAssertEqual(session.launchRecoveryHotKeyLegendRiskStickyReleasePulseEvent, 1)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyLegendRiskStickyReleasePulse(
                now: thirdOpenDate.addingTimeInterval(4),
                maxAge: 12
            ),
            CommandPaletteTopPicks.launchRecoveryHotKeyLegendRiskStickyReleasePulse(
                actionID: "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertNil(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            )
        )
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyLegendRiskStickyReleasePulse(
                now: thirdOpenDate.addingTimeInterval(14),
                maxAge: 12
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryHotKeyLegendRiskStickyPromotionPersistsForThreeOpensByDefault() {
        let session = CommandPaletteSession()
        let alertForecast = makeLaunchRecoveryLegendDecayAlertForecast()
        let watchForecast = makeLaunchRecoveryLegendDecayWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-cadence-autopilot-loop"]

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(alertForecast)
        XCTAssertEqual(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-cadence-autopilot-loop"
        )

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(watchForecast)
        XCTAssertEqual(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-cadence-autopilot-loop"
        )

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(watchForecast)
        XCTAssertEqual(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-cadence-autopilot-loop"
        )

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(watchForecast)
        XCTAssertNil(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryHotKeyLegendRiskStickyPromotionSupportsOneOpenWindow() {
        let session = CommandPaletteSession()
        let alertForecast = makeLaunchRecoveryLegendDecayAlertForecast()
        let watchForecast = makeLaunchRecoveryLegendDecayWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-cadence-autopilot-loop"]

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            alertForecast,
            stickyPromotionOpenWindow: 1
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-cadence-autopilot-loop"
        )

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            watchForecast,
            stickyPromotionOpenWindow: 1
        )
        XCTAssertNil(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryHotKeyLegendRiskStickyPromotionTracksRemainingOpens() {
        let session = CommandPaletteSession()
        let alertForecast = makeLaunchRecoveryLegendDecayAlertForecast()
        let watchForecast = makeLaunchRecoveryLegendDecayWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-cadence-autopilot-loop"]

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(alertForecast)
        XCTAssertEqual(
            session.launchRecoveryHotKeyLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            ),
            CommandPaletteSession.LaunchRecoveryHotKeyLegendRiskStickyPromotion(
                actionID: "run-fame-cadence-autopilot-loop",
                opensRemaining: 3,
                isHoldUntilRecovered: false
            )
        )

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(watchForecast)
        XCTAssertEqual(
            session.launchRecoveryHotKeyLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            ),
            CommandPaletteSession.LaunchRecoveryHotKeyLegendRiskStickyPromotion(
                actionID: "run-fame-cadence-autopilot-loop",
                opensRemaining: 2,
                isHoldUntilRecovered: false
            )
        )

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(watchForecast)
        XCTAssertEqual(
            session.launchRecoveryHotKeyLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            ),
            CommandPaletteSession.LaunchRecoveryHotKeyLegendRiskStickyPromotion(
                actionID: "run-fame-cadence-autopilot-loop",
                opensRemaining: 1,
                isHoldUntilRecovered: false
            )
        )

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(watchForecast)
        XCTAssertNil(
            session.launchRecoveryHotKeyLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryHotKeyLegendRiskStickyPromotionCanHoldUntilRecovered() {
        let session = CommandPaletteSession()
        let alertForecast = makeLaunchRecoveryLegendDecayAlertForecast()
        let watchForecast = makeLaunchRecoveryLegendDecayWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-cadence-autopilot-loop"]

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            alertForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true
        )
        let firstStickyPromotion = session.launchRecoveryHotKeyLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )
        XCTAssertEqual(
            firstStickyPromotion?.actionID,
            "run-fame-cadence-autopilot-loop"
        )
        XCTAssertTrue(firstStickyPromotion?.isHoldUntilRecovered ?? false)

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            watchForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true
        )
        let secondStickyPromotion = session.launchRecoveryHotKeyLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )
        XCTAssertEqual(
            secondStickyPromotion?.actionID,
            "run-fame-cadence-autopilot-loop",
            "Hold-until-recovered should keep sticky promotion active while forecast is still live."
        )
        XCTAssertTrue(secondStickyPromotion?.isHoldUntilRecovered ?? false)

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            watchForecast,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true
        )
        let thirdStickyPromotion = session.launchRecoveryHotKeyLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )
        XCTAssertEqual(
            thirdStickyPromotion?.actionID,
            "run-fame-cadence-autopilot-loop"
        )
        XCTAssertTrue(thirdStickyPromotion?.isHoldUntilRecovered ?? false)

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            nil,
            stickyPromotionOpenWindow: 1,
            stickyPromotionHoldUntilRecovered: true
        )
        XCTAssertNil(
            session.launchRecoveryHotKeyLegendRiskStickyPromotion(
                enabledActionIDs: enabledActionIDs
            ),
            "Sticky promotion should clear as soon as recovery removes the legend decay forecast."
        )
    }

    func testCommandPaletteSessionLaunchRecoveryHotKeyLegendRiskStickyPromotionSupportsFiveOpenWindow() {
        let session = CommandPaletteSession()
        let alertForecast = makeLaunchRecoveryLegendDecayAlertForecast()
        let watchForecast = makeLaunchRecoveryLegendDecayWatchForecast()
        let enabledActionIDs: Set<String> = ["run-fame-cadence-autopilot-loop"]

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            alertForecast,
            stickyPromotionOpenWindow: 5
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            ),
            "run-fame-cadence-autopilot-loop"
        )

        for _ in 2...5 {
            session.beginOpen()
            _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                watchForecast,
                stickyPromotionOpenWindow: 5
            )
            XCTAssertEqual(
                session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                    enabledActionIDs: enabledActionIDs
                ),
                "run-fame-cadence-autopilot-loop"
            )
        }

        session.beginOpen()
        _ = session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            watchForecast,
            stickyPromotionOpenWindow: 5
        )
        XCTAssertNil(
            session.launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
                enabledActionIDs: enabledActionIDs
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionScoresTrackObservedImpact() {
        let session = CommandPaletteSession()

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            3
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .critical, points: 20)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            3,
            "Intervention run should not evaluate in the same open."
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .critical, points: 18)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            -3,
            "Drop from steady to critical should subtract observed impact."
        )
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionScoresDecayWhenStale() {
        let session = CommandPaletteSession()

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            3
        )

        for _ in 0..<4 {
            session.beginOpen()
        }
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            2,
            "Stale positive intervention score should decay toward neutral."
        )

        for _ in 0..<8 {
            session.beginOpen()
        }
        XCTAssertNil(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            "Stale intervention score should eventually clear out."
        )
    }

    func testCommandPaletteSessionLaunchRecoveryNegativeInterventionScoresDecayWhenStale() {
        let session = CommandPaletteSession()

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .critical, points: 20)
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .critical, points: 18)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            -3
        )

        for _ in 0..<4 {
            session.beginOpen()
        }
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            -1,
            "Critical confidence should accelerate stale negative-score decay."
        )

        for _ in 0..<8 {
            session.beginOpen()
        }
        XCTAssertNil(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"]
        )
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionScoresDecayFasterInCriticalTier() {
        let session = CommandPaletteSession()

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            3
        )

        session.beginOpen()
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            3,
            "Steady confidence should not decay the score after only one open."
        )
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .critical, points: 19)
        )

        session.beginOpen()
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            2,
            "Critical confidence should accelerate stale-score decay."
        )
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionScoresDampenOnNeutralOutcome() {
        let session = CommandPaletteSession()

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            3
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 63)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            2,
            "Neutral outcomes should damp prior positive intervention confidence."
        )
    }

    func testCommandPaletteSessionLaunchRecoveryNegativeScoresDampenOnNeutralOutcome() {
        let session = CommandPaletteSession()

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .critical, points: 20)
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .critical, points: 18)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            -3
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: "run-fame-onboarding-daily-brief")

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .critical, points: 17)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores["run-fame-onboarding-daily-brief"],
            -2,
            "Neutral outcomes should damp prior negative intervention confidence."
        )
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionRecencyTracksRecentAndStaleSignals() {
        let session = CommandPaletteSession()
        let actionID = "run-fame-onboarding-daily-brief"

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionRecency[actionID],
            .recentlyValidated(opensAgo: 0)
        )

        session.beginOpen()
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionRecency[actionID],
            .recentlyValidated(opensAgo: 1)
        )
        session.beginOpen()
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionRecency[actionID],
            .recentlyValidated(opensAgo: 2)
        )
        session.beginOpen()
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionRecency[actionID],
            .stale(opensAgo: 3),
            "Intervention should be tagged stale before the next decay tick."
        )
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionTrustHistoryTracksEachOpen() {
        let session = CommandPaletteSession()
        let actionID = "run-fame-onboarding-daily-brief"

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        let baselineTrust = session.launchRecoveryHotKeyInterventionTrustHistory.last

        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)
        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )
        let improvedTrust = session.launchRecoveryHotKeyInterventionTrustHistory.last
        let trustTrendAfterImpact = session.launchRecoveryHotKeyInterventionTrustTrend

        for _ in 0..<8 {
            session.beginOpen()
        }
        let trustAfterDecay = session.launchRecoveryHotKeyInterventionTrustHistory.last
        let trustTrendAfterDecay = session.launchRecoveryHotKeyInterventionTrustTrend

        XCTAssertEqual(session.openCount, session.launchRecoveryHotKeyInterventionTrustHistory.count)
        XCTAssertNotNil(baselineTrust)
        XCTAssertNotNil(improvedTrust)
        XCTAssertNotNil(trustAfterDecay)
        XCTAssertGreaterThan(improvedTrust ?? 0, baselineTrust ?? 0)
        XCTAssertLessThan(trustAfterDecay ?? 100, improvedTrust ?? 100)
        XCTAssertEqual(trustTrendAfterImpact?.direction, .rising)
        XCTAssertNotNil(trustTrendAfterDecay)
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionTrustPulseCanCelebrateRecoveryRise() throws {
        let session = CommandPaletteSession()
        let actionID = "run-fame-onboarding-daily-brief"

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        session.beginOpen()
        let secondOpen = Date(timeIntervalSince1970: 200)
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64),
            at: secondOpen
        )

        XCTAssertEqual(session.launchRecoveryHotKeyInterventionTrustPulseEvent, 1)
        let risingPulse = try XCTUnwrap(
            session.recentLaunchRecoveryHotKeyInterventionTrustPulse(
                now: secondOpen.addingTimeInterval(5),
                maxAge: 12
            )
        )
        XCTAssertEqual(risingPulse.tone, .rising)

        let trustHistory = session.launchRecoveryHotKeyInterventionTrustHistory
        XCTAssertGreaterThanOrEqual(trustHistory.count, 2)
        XCTAssertEqual(
            risingPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPulse(
                previousPoints: trustHistory[trustHistory.count - 2],
                nextPoints: trustHistory[trustHistory.count - 1]
            )
        )
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyInterventionTrustPulse(
                now: .distantFuture,
                maxAge: 12
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionTrustPulseUsesRecencyAndPerOpenDedupe() throws {
        let session = CommandPaletteSession()
        let actionID = "run-fame-onboarding-daily-brief"

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)
        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 63)
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)
        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 62)
        )

        XCTAssertEqual(session.launchRecoveryHotKeyInterventionScores[actionID], 1)
        let pulseEventBeforeDecay = session.launchRecoveryHotKeyInterventionTrustPulseEvent

        session.beginOpen()
        session.beginOpen()
        session.beginOpen()

        let firstPulse = try XCTUnwrap(
            session.recentLaunchRecoveryHotKeyInterventionTrustPulse(maxAge: 120)
        )
        XCTAssertGreaterThanOrEqual(
            session.launchRecoveryHotKeyInterventionTrustPulseEvent,
            pulseEventBeforeDecay
        )

        let trustHistory = session.launchRecoveryHotKeyInterventionTrustHistory
        XCTAssertGreaterThanOrEqual(trustHistory.count, 2)
        XCTAssertEqual(
            firstPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPulse(
                previousPoints: trustHistory[trustHistory.count - 2],
                nextPoints: trustHistory[trustHistory.count - 1]
            )
        )

        let pulseEventBeforeSameOpenUpdates = session.launchRecoveryHotKeyInterventionTrustPulseEvent
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 62)
        )
        let pulseEventAfterFirstSameOpenUpdate = session.launchRecoveryHotKeyInterventionTrustPulseEvent
        XCTAssertLessThanOrEqual(
            pulseEventAfterFirstSameOpenUpdate - pulseEventBeforeSameOpenUpdates,
            1,
            "At most one trust pulse should be emitted within a single open."
        )
        let pulseAfterFirstSameOpenUpdate = session.recentLaunchRecoveryHotKeyInterventionTrustPulse(
            maxAge: 120
        )

        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 62)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionTrustPulseEvent,
            pulseEventAfterFirstSameOpenUpdate,
            "Trust pulse should not emit again after the first same-open update."
        )
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyInterventionTrustPulse(maxAge: 120),
            pulseAfterFirstSameOpenUpdate
        )
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyInterventionTrustPulse(
                now: .distantFuture,
                maxAge: 12
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionTrustMomentumPulseUsesMilestoneRecencyAndDedupe() throws {
        let session = CommandPaletteSession()
        let actionID = "run-fame-onboarding-daily-brief"

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 46)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 52)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        let milestoneOpen = Date(timeIntervalSince1970: 600)
        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .prime, points: 58),
            at: milestoneOpen
        )

        XCTAssertEqual(session.launchRecoveryHotKeyInterventionTrustMomentumPulseEvent, 1)
        let pulse = try XCTUnwrap(
            session.recentLaunchRecoveryHotKeyInterventionTrustMomentumPulse(
                now: milestoneOpen.addingTimeInterval(5),
                maxAge: 12
            )
        )
        XCTAssertEqual(pulse.streak, 3)
        XCTAssertEqual(pulse.milestone, 3)
        XCTAssertEqual(pulse.title, "Trust Momentum Milestone x3")
        XCTAssertEqual(pulse.systemImage, "flame.fill")
        XCTAssertEqual(
            pulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPulse(
                for: session.launchRecoveryHotKeyInterventionTrustHistory
            )
        )

        let pulseEventAfterMilestone = session.launchRecoveryHotKeyInterventionTrustMomentumPulseEvent
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .prime, points: 64),
            at: milestoneOpen.addingTimeInterval(1)
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionTrustMomentumPulseEvent,
            pulseEventAfterMilestone,
            "At most one trust momentum pulse should emit within a single open."
        )
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyInterventionTrustMomentumPulse(maxAge: 120),
            pulse
        )
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyInterventionTrustMomentumPulse(
                now: .distantFuture,
                maxAge: 12
            )
        )
    }

    func testCommandPaletteSessionLaunchRecoveryInterventionLifecycleCanRerankAfterNeutralAndDecay() {
        let session = CommandPaletteSession()
        let actionID = "run-fame-onboarding-daily-brief"
        let enabledActionIDs: Set<String> = [
            "run-fame-launch-recovery-next",
            "run-fame-onboarding-scorecard",
            "run-fame-onboarding-daily-brief"
        ]

        func interventionOrder() -> [String] {
            CommandPaletteTopPicks.launchRecoveryHotKeyInterventions(
                score: makeLaunchRecoveryConfidenceScore(tier: .watch, points: 45),
                readiness: .unavailable,
                trend: nil,
                coachCue: nil,
                enabledActionIDs: enabledActionIDs,
                interventionScores: session.launchRecoveryHotKeyInterventionScores,
                interventionRecency: session.launchRecoveryHotKeyInterventionRecency,
                limit: 3
            ).map(\.actionID)
        }

        XCTAssertEqual(
            interventionOrder(),
            [
                "run-fame-launch-recovery-next",
                "run-fame-onboarding-scorecard",
                "run-fame-onboarding-daily-brief"
            ]
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )
        XCTAssertEqual(session.launchRecoveryHotKeyInterventionScores[actionID], 3)
        XCTAssertEqual(
            interventionOrder().first,
            actionID,
            "Positive intervention impact should rerank the action to the front."
        )

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 63)
        )
        XCTAssertEqual(session.launchRecoveryHotKeyInterventionScores[actionID], 2)
        XCTAssertEqual(
            interventionOrder().first,
            actionID,
            "Neutral outcomes should damp score but keep ordering while signal remains positive."
        )

        for _ in 0..<8 {
            session.beginOpen()
        }
        XCTAssertNil(session.launchRecoveryHotKeyInterventionScores[actionID])
        XCTAssertEqual(
            interventionOrder(),
            [
                "run-fame-launch-recovery-next",
                "run-fame-onboarding-scorecard",
                "run-fame-onboarding-daily-brief"
            ],
            "Once decayed to neutral, ordering should fall back to base intervention priority."
        )
    }

    func testCommandPaletteSessionPersistsLaunchRecoveryInterventionScoresAcrossSessions() throws {
        let defaults = try makeDefaults()
        let storageKey = "launchRecoveryInterventionScores-\(UUID().uuidString)"
        let actionID = "run-fame-onboarding-daily-brief"

        let session = CommandPaletteSession(
            defaults: defaults,
            launchRecoveryHotKeyInterventionScoresStorageKey: storageKey
        )
        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )
        XCTAssertEqual(session.launchRecoveryHotKeyInterventionScores[actionID], 3)

        let restoredSession = CommandPaletteSession(
            defaults: defaults,
            launchRecoveryHotKeyInterventionScoresStorageKey: storageKey
        )
        XCTAssertEqual(
            restoredSession.launchRecoveryHotKeyInterventionScores[actionID],
            3,
            "Intervention score memory should survive across app sessions."
        )

        for _ in 0..<4 {
            restoredSession.beginOpen()
        }
        XCTAssertEqual(
            restoredSession.launchRecoveryHotKeyInterventionScores[actionID],
            2,
            "Restored scores should continue decaying from the new session baseline."
        )
    }

    func testCommandPaletteSessionNormalizesPersistedLaunchRecoveryInterventionScores() throws {
        let defaults = try makeDefaults()
        let storageKey = "launchRecoveryInterventionScores-\(UUID().uuidString)"
        let payload = [
            "run-fame-onboarding-daily-brief": 99,
            "ask-anything": -4,
            "bogus-action": 2
        ]
        let payloadData = try JSONEncoder().encode(payload)
        defaults.set(payloadData, forKey: storageKey)

        let session = CommandPaletteSession(
            defaults: defaults,
            launchRecoveryHotKeyInterventionScoresStorageKey: storageKey
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyInterventionScores,
            ["run-fame-onboarding-daily-brief": 12],
            "Only valid intervention actions should load, clamped to score bounds."
        )

        let persistedData = try XCTUnwrap(defaults.data(forKey: storageKey))
        let persistedPayload = try JSONDecoder().decode([String: Int].self, from: persistedData)
        XCTAssertEqual(
            persistedPayload,
            ["run-fame-onboarding-daily-brief": 12],
            "Normalized intervention memory should be written back to defaults."
        )
    }

    func testCommandPaletteSessionFameMomentumPanelScoresLearnFromConversionsAndMisses() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let actionID = CommandPaletteAction.launchRecoveryNextActionID

        session.beginOpen()
        XCTAssertTrue(session.recordFameMomentumPanelOpportunity(actionID: actionID))
        XCTAssertTrue(session.recordFameMomentumPanelConversion(actionID: actionID))
        XCTAssertEqual(session.fameMomentumPanelOpportunityCount, 1)
        XCTAssertEqual(session.fameMomentumPanelConversionCount, 1)
        XCTAssertEqual(session.fameMomentumPanelActionScores[actionID], 2)

        session.beginOpen()
        XCTAssertTrue(session.recordFameMomentumPanelOpportunity(actionID: actionID))

        session.beginOpen()
        XCTAssertEqual(session.fameMomentumPanelOpportunityCount, 2)
        XCTAssertEqual(session.fameMomentumPanelConversionCount, 1)
        XCTAssertEqual(
            session.fameMomentumPanelActionScores[actionID],
            1,
            "Missing a suggested panel action should cool its score."
        )
    }

    func testCommandPaletteSessionFameMomentumPanelOpportunitySetsCanConvertAndCoolBothCandidates() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let primaryActionID = "run-trust-fix"
        let secondaryActionID = "run-fame-cadence-autopilot-loop"

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelOpportunity(
                actionIDs: [primaryActionID, secondaryActionID]
            )
        )
        XCTAssertTrue(session.recordFameMomentumPanelConversion(actionID: secondaryActionID))

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelOpportunity(
                actionIDs: [primaryActionID, secondaryActionID]
            )
        )

        session.beginOpen()
        XCTAssertEqual(session.fameMomentumPanelOpportunityCount, 2)
        XCTAssertEqual(session.fameMomentumPanelConversionCount, 1)
        XCTAssertEqual(
            session.fameMomentumPanelActionScores[secondaryActionID],
            1,
            "Secondary candidate should gain conversion credit, then cool by one missed opportunity."
        )
        XCTAssertEqual(
            session.fameMomentumPanelActionScores[primaryActionID],
            -2,
            "Choosing the alternate should immediately cool the skipped primary and another miss should cool it again on the next unconverted open."
        )
    }

    func testCommandPaletteSessionFameMomentumPanelAlternateChoiceCanImmediatelyCoolSkippedPrimary() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let primaryActionID = "run-trust-fix"
        let secondaryActionID = "run-fame-cadence-autopilot-loop"

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelOpportunity(
                actionIDs: [primaryActionID, secondaryActionID]
            )
        )
        XCTAssertTrue(session.recordFameMomentumPanelConversion(actionID: secondaryActionID))

        XCTAssertEqual(
            session.fameMomentumPanelActionScores[secondaryActionID],
            2,
            "Chosen alternate route should gain an immediate positive learning signal."
        )
        XCTAssertEqual(
            session.fameMomentumPanelActionScores[primaryActionID],
            -1,
            "Skipped primary route should cool immediately so ranking adapts inside the same open."
        )
    }

    func testCommandPaletteSessionFameMomentumPanelLearningPulseEmitsForAlternateConversion() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let primaryActionID = "run-trust-fix"
        let secondaryActionID = "run-fame-cadence-autopilot-loop"
        let conversionStamp = Date(timeIntervalSince1970: 1_300)

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelOpportunity(
                actionIDs: [primaryActionID, secondaryActionID]
            )
        )
        XCTAssertTrue(
            session.recordFameMomentumPanelConversion(
                actionID: secondaryActionID,
                at: conversionStamp
            )
        )

        XCTAssertEqual(session.fameMomentumPanelLearningPulseEvent, 1)
        XCTAssertEqual(
            session.recentFameMomentumPanelLearningPulse(
                now: conversionStamp.addingTimeInterval(6),
                maxAge: 8
            )?.title,
            "Learning Updated"
        )
        XCTAssertEqual(
            session.recentFameMomentumPanelLearningPulse(
                now: conversionStamp.addingTimeInterval(6),
                maxAge: 8
            )?.subtitle,
            "Boosted winner, cooled 1 alternate"
        )
    }

    func testCommandPaletteSessionFameMomentumPanelLearningPulseSkipsSingleActionConversions() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let actionID = "run-trust-fix"
        let conversionStamp = Date(timeIntervalSince1970: 1_350)

        session.beginOpen()
        XCTAssertTrue(session.recordFameMomentumPanelOpportunity(actionID: actionID))
        XCTAssertTrue(
            session.recordFameMomentumPanelConversion(
                actionID: actionID,
                at: conversionStamp
            )
        )

        XCTAssertEqual(session.fameMomentumPanelLearningPulseEvent, 0)
        XCTAssertNil(
            session.recentFameMomentumPanelLearningPulse(
                now: conversionStamp.addingTimeInterval(3),
                maxAge: 8
            )
        )
    }

    func testCommandPaletteSessionFameMomentumPanelLearningPulseRecencyCanExpire() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let primaryActionID = "run-trust-fix"
        let secondaryActionID = "run-fame-cadence-autopilot-loop"
        let conversionStamp = Date(timeIntervalSince1970: 1_400)

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelOpportunity(
                actionIDs: [primaryActionID, secondaryActionID]
            )
        )
        XCTAssertTrue(
            session.recordFameMomentumPanelConversion(
                actionID: secondaryActionID,
                at: conversionStamp
            )
        )

        XCTAssertNotNil(
            session.recentFameMomentumPanelLearningPulse(
                now: conversionStamp.addingTimeInterval(7),
                maxAge: 8
            )
        )
        XCTAssertNil(
            session.recentFameMomentumPanelLearningPulse(
                now: conversionStamp.addingTimeInterval(10),
                maxAge: 8
            )
        )
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipPulseEmitsWhenPrimarySuggestionChanges() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let flipStamp = Date(timeIntervalSince1970: 1_460)

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-trust-fix",
            actionPrompt: "Run Trust Fix"
        )
        XCTAssertEqual(session.fameMomentumPanelRouteFlipPulseEvent, 0)

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-fame-cadence-autopilot-loop",
            actionPrompt: "Run Trust Step",
            reasonChips: [
                CommandPaletteTopPicks.FameMomentumPanelReasonChip(
                    title: "Signal Stale",
                    systemImage: "clock.badge.exclamationmark",
                    helpText: "Signal is stale."
                )
            ],
            at: flipStamp
        )

        XCTAssertEqual(session.fameMomentumPanelRouteFlipPulseEvent, 1)
        let pulse = session.recentFameMomentumPanelRouteFlipPulse(
            now: flipStamp.addingTimeInterval(4),
            maxAge: 8
        )
        XCTAssertEqual(pulse?.trigger, .freshSignal)
        XCTAssertEqual(pulse?.title, "Route Flip · Fresh Signal")
        XCTAssertEqual(pulse?.subtitle, "Run Trust Fix → Run Trust Step")
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipPulseCarriesConfidenceAndSignalAgeDelta() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let flipStamp = Date(timeIntervalSince1970: 1_490)

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-trust-fix",
            actionPrompt: "Run Trust Fix",
            actionScore: 214,
            selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
                tier: .split,
                confidencePercent: 20,
                gapPoints: 24,
                title: "Selection Split",
                subtitle: "Gap 24 · backup live",
                systemImage: "arrow.triangle.branch",
                helpText: "Baseline split."
            ),
            actionRecency: .stale(opensAgo: 7)
        )

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-fame-next-move-copy-drafts",
            actionPrompt: "Run Rescue Now",
            actionScore: 276,
            selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
                tier: .leaning,
                confidencePercent: 48,
                gapPoints: 58,
                title: "Selection Leaning",
                subtitle: "Gap 58 · backup live",
                systemImage: "slider.horizontal.2.square",
                helpText: "Improved confidence."
            ),
            actionRecency: .recentlyValidated(opensAgo: 0),
            at: flipStamp
        )

        XCTAssertEqual(session.fameMomentumPanelRouteFlipPulseEvent, 1)
        let pulse = session.recentFameMomentumPanelRouteFlipPulse(
            now: flipStamp.addingTimeInterval(4),
            maxAge: 8
        )
        XCTAssertEqual(pulse?.trigger, .freshSignal)
        XCTAssertEqual(pulse?.confidenceDeltaPoints, 34)
        XCTAssertEqual(pulse?.previousSignalAgeOpens, 7)
        XCTAssertEqual(pulse?.nextSignalAgeOpens, 0)
        XCTAssertEqual(pulse?.previousActionPrompt, "Run Trust Fix")
        XCTAssertEqual(pulse?.nextActionPrompt, "Run Rescue Now")
        XCTAssertEqual(pulse?.previousActionScore, 214)
        XCTAssertEqual(pulse?.nextActionScore, 276)
        XCTAssertEqual(pulse?.routeScoreDelta, 62)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipHistoryAppendsOnFlip() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let flipStamp = Date(timeIntervalSince1970: 1_505)

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-trust-fix",
            actionPrompt: "Run Trust Fix",
            actionScore: 210,
            selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
                tier: .leaning,
                confidencePercent: 46,
                gapPoints: 32,
                title: "Selection Leaning",
                subtitle: "Gap 32 · backup live",
                systemImage: "slider.horizontal.2.square",
                helpText: "Baseline confidence."
            )
        )

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-fame-next-move-copy-drafts",
            actionPrompt: "Run Rescue Now",
            actionScore: 244,
            reasonChips: [
                CommandPaletteTopPicks.FameMomentumPanelReasonChip(
                    title: "Observed +4",
                    systemImage: "arrow.up.right.circle.fill",
                    helpText: "Observed signal surged."
                )
            ],
            selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
                tier: .leaning,
                confidencePercent: 57,
                gapPoints: 50,
                title: "Selection Leaning",
                subtitle: "Gap 50 · backup live",
                systemImage: "slider.horizontal.2.square",
                helpText: "Confidence improved."
            ),
            at: flipStamp
        )

        let history = session.fameMomentumPanelRouteFlipHistory
        XCTAssertEqual(history.count, 1)
        let entry = try XCTUnwrap(history.first)
        XCTAssertEqual(entry.openCount, 2)
        XCTAssertEqual(entry.occurredAt, flipStamp)
        XCTAssertEqual(entry.trigger, .momentumSurge)
        XCTAssertEqual(entry.previousActionPrompt, "Run Trust Fix")
        XCTAssertEqual(entry.nextActionPrompt, "Run Rescue Now")
        XCTAssertEqual(entry.routeScoreDelta, 34)
        XCTAssertEqual(entry.confidenceDeltaPoints, 18)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipHistorySkipsWhenPrimarySuggestionStaysSame() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-trust-fix",
            actionPrompt: "Run Trust Fix",
            actionScore: 220
        )

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-trust-fix",
            actionPrompt: "Run Trust Fix",
            actionScore: 238,
            selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
                tier: .split,
                confidencePercent: 30,
                gapPoints: 20,
                title: "Selection Split",
                subtitle: "Gap 20 · backup live",
                systemImage: "arrow.triangle.branch",
                helpText: "Decision remains split."
            )
        )

        XCTAssertTrue(session.fameMomentumPanelRouteFlipHistory.isEmpty)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipHistoryKeepsLatestThreeEntries() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int, stamp: Date)] = [
            ("route-a", "Route A", 100, 30, Date(timeIntervalSince1970: 1_560)),
            ("route-b", "Route B", 120, 42, Date(timeIntervalSince1970: 1_570)),
            ("route-c", "Route C", 90, 34, Date(timeIntervalSince1970: 1_580)),
            ("route-d", "Route D", 140, 60, Date(timeIntervalSince1970: 1_590)),
            ("route-e", "Route E", 130, 52, Date(timeIntervalSince1970: 1_600)),
        ]

        for step in routeSteps {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
                    tier: .leaning,
                    confidencePercent: 55,
                    gapPoints: step.gapPoints,
                    title: "Selection Leaning",
                    subtitle: "Gap \(step.gapPoints) · backup live",
                    systemImage: "slider.horizontal.2.square",
                    helpText: "Confidence snapshot."
                ),
                at: step.stamp
            )
        }

        let history = session.fameMomentumPanelRouteFlipHistory
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history.map(\.openCount), [5, 4, 3])
        XCTAssertEqual(history.map(\.previousActionPrompt), ["Route D", "Route C", "Route B"])
        XCTAssertEqual(history.map(\.nextActionPrompt), ["Route E", "Route D", "Route C"])
        XCTAssertEqual(history.map(\.routeScoreDelta), [-10, 50, -30])
        XCTAssertEqual(history.map(\.confidenceDeltaPoints), [-8, 26, -8])
        XCTAssertEqual(history.map(\.trigger), [.rerank, .momentumSurge, .rerank])
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipRhythmIsNilWithoutAtLeastTwoFlips() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-a",
            actionPrompt: "Route A",
            actionScore: 120,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 40)
        )

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-b",
            actionPrompt: "Route B",
            actionScore: 126,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 44)
        )

        XCTAssertNil(session.fameMomentumPanelRouteFlipRhythm())
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipRhythmMarksVolatileForRapidThreeFlipRun() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 100, 20),
            ("route-b", "Route B", 112, 28),
            ("route-c", "Route C", 94, 16),
            ("route-d", "Route D", 130, 42),
        ]

        for step in routeSteps {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                )
            )
        }

        let rhythm = try XCTUnwrap(session.fameMomentumPanelRouteFlipRhythm())
        XCTAssertEqual(rhythm.tone, .volatile)
        XCTAssertEqual(rhythm.flipCount, 3)
        XCTAssertEqual(rhythm.openSpan, 3)
        XCTAssertEqual(rhythm.averageAbsRouteScoreDelta, 22)
        XCTAssertEqual(rhythm.averageAbsConfidenceDeltaPoints, 15)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipRhythmMarksWatchForTightFrequentFlips() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 200, 42),
            ("route-b", "Route B", 206, 47),
            ("route-c", "Route C", 202, 44),
        ]

        for step in routeSteps {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                )
            )
        }

        let rhythm = try XCTUnwrap(session.fameMomentumPanelRouteFlipRhythm())
        XCTAssertEqual(rhythm.tone, .watch)
        XCTAssertEqual(rhythm.flipCount, 2)
        XCTAssertEqual(rhythm.openSpan, 2)
        XCTAssertEqual(rhythm.averageAbsRouteScoreDelta, 5)
        XCTAssertEqual(rhythm.averageAbsConfidenceDeltaPoints, 4)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipRhythmMarksStabilizingWhenFlipsSpreadOut() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-a",
            actionPrompt: "Route A",
            actionScore: 120,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 70)
        )

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-b",
            actionPrompt: "Route B",
            actionScore: 188,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 26)
        )

        for _ in 0..<5 {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: "route-b",
                actionPrompt: "Route B",
                actionScore: 188,
                selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 26)
            )
        }

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-c",
            actionPrompt: "Route C",
            actionScore: 102,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 88)
        )

        let rhythm = try XCTUnwrap(session.fameMomentumPanelRouteFlipRhythm())
        XCTAssertEqual(rhythm.tone, .stabilizing)
        XCTAssertEqual(rhythm.flipCount, 2)
        XCTAssertEqual(rhythm.openSpan, 7)
        XCTAssertEqual(rhythm.averageAbsRouteScoreDelta, 77)
        XCTAssertEqual(rhythm.averageAbsConfidenceDeltaPoints, 53)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipRhythmCanSettleWithoutNewFlips() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 120, 80),
            ("route-b", "Route B", 240, 28),
            ("route-c", "Route C", 90, 88),
            ("route-d", "Route D", 260, 24),
        ]

        for step in routeSteps {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                )
            )
        }

        XCTAssertEqual(
            session.fameMomentumPanelRouteFlipRhythm()?.tone,
            .volatile
        )

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-d",
            actionPrompt: "Route D",
            actionScore: 260,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 24)
        )
        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-d",
            actionPrompt: "Route D",
            actionScore: 260,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 24)
        )

        XCTAssertEqual(
            session.fameMomentumPanelRouteFlipRhythm()?.tone,
            .stabilizing
        )
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationPulseEmitsAfterConsecutiveVolatileOpens() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let baseline = Date(timeIntervalSince1970: 1_640)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 100, 32),
            ("route-b", "Route B", 118, 40),
            ("route-c", "Route C", 90, 28),
            ("route-d", "Route D", 130, 48),
            ("route-e", "Route E", 110, 34),
        ]

        for (index, step) in routeSteps.enumerated() {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                ),
                at: baseline.addingTimeInterval(Double(index))
            )
        }

        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationPulseEvent, 1)
        let pulse = session.recentFameMomentumPanelRouteStabilizationPulse(
            now: baseline.addingTimeInterval(8),
            maxAge: 10
        )
        XCTAssertEqual(pulse?.volatileStreak, 2)
        XCTAssertEqual(pulse?.flipCount, 3)
        XCTAssertEqual(pulse?.openSpan, 3)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationPulseRespectsCooldownAndCanReemit() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let baseline = Date(timeIntervalSince1970: 1_680)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 100, 30),
            ("route-b", "Route B", 118, 41),
            ("route-c", "Route C", 92, 26),
            ("route-d", "Route D", 134, 52),
            ("route-e", "Route E", 116, 37),
            ("route-f", "Route F", 142, 56),
            ("route-g", "Route G", 124, 40),
            ("route-h", "Route H", 148, 59),
        ]

        for (index, step) in routeSteps.enumerated() {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                ),
                at: baseline.addingTimeInterval(Double(index))
            )
        }

        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationPulseEvent,
            2,
            "Pulse should emit once when the volatile streak crosses threshold, then re-emit only after cooldown opens."
        )
        XCTAssertEqual(
            session.recentFameMomentumPanelRouteStabilizationPulse(
                now: baseline.addingTimeInterval(12),
                maxAge: 20
            )?.volatileStreak,
            5
        )
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationPulseRecencyCanExpire() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let baseline = Date(timeIntervalSince1970: 1_710)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 100, 32),
            ("route-b", "Route B", 118, 40),
            ("route-c", "Route C", 90, 28),
            ("route-d", "Route D", 130, 48),
            ("route-e", "Route E", 110, 34),
        ]

        for (index, step) in routeSteps.enumerated() {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                ),
                at: baseline.addingTimeInterval(Double(index))
            )
        }

        XCTAssertNotNil(
            session.recentFameMomentumPanelRouteStabilizationPulse(
                now: baseline.addingTimeInterval(9),
                maxAge: 10
            )
        )
        XCTAssertNil(
            session.recentFameMomentumPanelRouteStabilizationPulse(
                now: baseline.addingTimeInterval(20),
                maxAge: 10
            )
        )
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationRunTracksPendingAndDefersOutcomeUntilNextPrimarySuggestion() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 100, 30),
            ("route-a", "Route A", 104, 28),
            ("route-b", "Route B", 118, 41),
            ("route-c", "Route C", 92, 26),
            ("route-d", "Route D", 134, 52),
        ]

        for step in routeSteps {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                )
            )
        }

        XCTAssertEqual(session.fameMomentumPanelRouteFlipRhythm()?.tone, .volatile)

        session.recordFameMomentumPanelRouteStabilizationRun()
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRunCount, 1)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationSuccessCount, 0)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationPendingRunCount, 1)

        session.beginOpen()
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationSuccessCount, 0)
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationPendingRunCount,
            1,
            "Outcome should stay pending until the evaluation open records a primary suggestion."
        )

        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-e",
            actionPrompt: "Route E",
            actionScore: 146,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 58)
        )

        XCTAssertEqual(session.fameMomentumPanelRouteFlipRhythm()?.tone, .volatile)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationSuccessCount, 0)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationPendingRunCount, 0)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationOutcomeCountsSuccessWhenNoNewFlipOccurs() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 100, 30),
            ("route-a", "Route A", 104, 28),
            ("route-b", "Route B", 118, 41),
            ("route-c", "Route C", 92, 26),
            ("route-d", "Route D", 134, 52),
        ]

        for step in routeSteps {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                )
            )
        }

        XCTAssertEqual(session.fameMomentumPanelRouteFlipRhythm()?.tone, .volatile)
        let baselineFlipCount = session.fameMomentumPanelRouteFlipHistory.count
        session.recordFameMomentumPanelRouteStabilizationRun()

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-d",
            actionPrompt: "Route D",
            actionScore: 134,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 52)
        )

        XCTAssertEqual(session.fameMomentumPanelRouteFlipRhythm()?.tone, .volatile)
        XCTAssertEqual(session.fameMomentumPanelRouteFlipHistory.count, baselineFlipCount)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationSuccessCount, 1)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationPendingRunCount, 0)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationOutcomeCountsSuccessWhenToneCalmsAfterNextOpen() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 100, 32),
            ("route-b", "Route B", 118, 40),
            ("route-b", "Route B", 118, 40),
            ("route-c", "Route C", 130, 48),
            ("route-d", "Route D", 110, 34),
        ]

        for step in routeSteps {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                )
            )
        }

        XCTAssertEqual(session.fameMomentumPanelRouteFlipRhythm()?.tone, .volatile)
        session.recordFameMomentumPanelRouteStabilizationRun()

        session.beginOpen()
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationPendingRunCount, 1)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationSuccessCount, 0)

        session.beginOpen()
        XCTAssertNotEqual(session.fameMomentumPanelRouteFlipRhythm()?.tone, .volatile)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationSuccessCount, 1)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationPendingRunCount, 0)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationScoreboardFormatsRateAndPendingState() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 100, 30),
            ("route-a", "Route A", 104, 28),
            ("route-b", "Route B", 118, 41),
            ("route-c", "Route C", 92, 26),
            ("route-d", "Route D", 134, 52),
        ]

        XCTAssertNil(session.fameMomentumPanelRouteStabilizationScoreboard())

        for step in routeSteps {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                )
            )
        }

        session.recordFameMomentumPanelRouteStabilizationRun()
        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-e",
            actionPrompt: "Route E",
            actionScore: 146,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 58)
        )

        session.recordFameMomentumPanelRouteStabilizationRun()
        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-e",
            actionPrompt: "Route E",
            actionScore: 146,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 58)
        )

        let resolvedScoreboard = try XCTUnwrap(
            session.fameMomentumPanelRouteStabilizationScoreboard()
        )
        XCTAssertEqual(resolvedScoreboard.runs, 2)
        XCTAssertEqual(resolvedScoreboard.successes, 1)
        XCTAssertEqual(resolvedScoreboard.pendingRuns, 0)
        XCTAssertEqual(resolvedScoreboard.successRatePercent, 50)
        XCTAssertEqual(resolvedScoreboard.title, "Stabilizer 50%")
        XCTAssertEqual(resolvedScoreboard.subtitle, "1/2 stabilized")
        XCTAssertEqual(resolvedScoreboard.systemImage, "shield.lefthalf.filled")

        session.recordFameMomentumPanelRouteStabilizationRun()
        session.beginOpen()

        let pendingScoreboard = try XCTUnwrap(
            session.fameMomentumPanelRouteStabilizationScoreboard()
        )
        XCTAssertEqual(pendingScoreboard.runs, 3)
        XCTAssertEqual(pendingScoreboard.successes, 1)
        XCTAssertEqual(pendingScoreboard.pendingRuns, 1)
        XCTAssertEqual(pendingScoreboard.successRatePercent, 33)
        XCTAssertEqual(pendingScoreboard.title, "Stabilizer 33%")
        XCTAssertEqual(pendingScoreboard.subtitle, "1/3 stabilized · 1 pending")
        XCTAssertEqual(pendingScoreboard.systemImage, "clock.arrow.circlepath")
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationRecoverySuggestionTelemetryTracksShownRunAndBlocked() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let disabledRecoveryAction = CommandPaletteAction(
            id: "run-fame-recovery-sprint",
            title: "Run Fame Recovery Sprint",
            systemImage: "bolt.shield.fill",
            isEnabled: false,
            disabledReason: "Recovery data missing",
            run: {}
        )
        let enabledRecoveryAction = CommandPaletteAction(
            id: "run-fame-launch-recovery-next",
            title: "Run Fame Launch Recovery Next",
            systemImage: "arrow.clockwise.circle.fill",
            run: {}
        )
        let enabledUnblockAction = CommandPaletteAction(
            id: "run-fame-launch-control-health",
            title: "Run Fame Launch Control Health",
            systemImage: "cross.case.fill",
            run: {}
        )

        XCTAssertFalse(
            session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionRun(),
            "Run telemetry should require an active open."
        )
        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionExposure(
                action: disabledRecoveryAction
            )
        )
        XCTAssertFalse(
            session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionExposure(
                action: disabledRecoveryAction
            ),
            "Recovery suggestion exposure should count once per open."
        )

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionExposure(
                action: enabledRecoveryAction
            )
        )
        XCTAssertTrue(session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionRun())
        session.recordFameMomentumPanelRouteStabilizationRun()

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionExposure(
                action: enabledUnblockAction
            )
        )
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionRun(
                usedUnblockAction: true
            )
        )
        session.recordFameMomentumPanelRouteStabilizationRun()

        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount, 3)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount, 2)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount, 1)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount, 1)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount, 1)

        let scoreboard = try XCTUnwrap(session.fameMomentumPanelRouteStabilizationScoreboard())
        XCTAssertEqual(scoreboard.runs, 2)
        XCTAssertEqual(scoreboard.pendingRuns, 2)
        XCTAssertTrue(scoreboard.subtitle.contains("2/3 recovery") == true)
        XCTAssertTrue(scoreboard.subtitle.contains("1 recovery runs") == true)
        XCTAssertTrue(scoreboard.subtitle.contains("1 unblock runs") == true)
        XCTAssertTrue(scoreboard.subtitle.contains("1 blocked") == true)
        XCTAssertTrue(scoreboard.helpText.contains("Recovery CTA shown 3 times") == true)
        XCTAssertTrue(scoreboard.helpText.contains("Run mix: 1 recovery-route run(s), 1 unblock-route run(s).") == true)
    }

    func testCommandPaletteSessionTracksAndPersistsFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let disabledRecoveryAction = CommandPaletteAction(
            id: "run-fame-launch-recovery-next",
            title: "Run Fame Launch Recovery Next",
            systemImage: "arrow.clockwise.circle.fill",
            isEnabled: false,
            disabledReason: "Needs setup",
            run: {}
        )
        let enabledRecoveryAction = CommandPaletteAction(
            id: "run-fame-launch-recovery-next",
            title: "Run Fame Launch Recovery Next",
            systemImage: "arrow.clockwise.circle.fill",
            run: {}
        )

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionExposure(
                action: disabledRecoveryAction
            )
        )
        XCTAssertTrue(session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionRun())
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory.count,
            1
        )
        let firstSample = try XCTUnwrap(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory.last
        )
        XCTAssertTrue((1...99).contains(firstSample))

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionExposure(
                action: enabledRecoveryAction
            )
        )
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory.count,
            2
        )
        let secondSample = try XCTUnwrap(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory.last
        )
        XCTAssertTrue((1...99).contains(secondSample))
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount,
            3
        )
        XCTAssertGreaterThan(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
            0
        )
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration?.sampleCount,
            3
        )

        let storedHistory = defaults.array(
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey
        ) as? [Int]
        XCTAssertEqual(
            storedHistory,
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey
            ),
            3
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey
            ),
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore
        )

        let restoredSession = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(
            restoredSession.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory,
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory
        )
        XCTAssertEqual(
            restoredSession.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount,
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount
        )
        XCTAssertEqual(
            restoredSession.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore
        )
    }

    func testCommandPaletteSessionDecaysFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationAcrossIdleOpens() throws {
        let defaults = try makeDefaults()
        defaults.set(
            9,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
        )
        defaults.set(
            8,
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey
        )
        defaults.set(
            12,
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey
        )

        let session = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
            8
        )
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount,
            12
        )

        for _ in 0..<4 {
            session.beginOpen()
        }
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
            7
        )
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount,
            12
        )

        for _ in 0..<3 {
            session.beginOpen()
        }
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
            6
        )
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount,
            11
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey
            ),
            6
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey
            ),
            11
        )
    }

    func testCommandPaletteSessionClampsPersistedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory() throws {
        let defaults = try makeDefaults()
        defaults.set(
            4,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
        )
        defaults.set(
            [0, 120, 37],
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey
        )
        defaults.set(
            120,
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey
        )
        defaults.set(
            999,
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey
        )

        let clampedSession = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(
            clampedSession.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory,
            [1, 99, 37]
        )
        XCTAssertEqual(
            clampedSession.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
            36
        )
        XCTAssertEqual(
            clampedSession.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount,
            160
        )
        XCTAssertEqual(
            defaults.array(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey
            ) as? [Int],
            [1, 99, 37]
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey
            ),
            36
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey
            ),
            160
        )

        defaults.set(
            -2,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
        )
        defaults.set(
            [41, 38],
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey
        )
        defaults.set(
            -3,
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey
        )
        defaults.set(
            12,
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey
        )

        let resetSession = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(
            resetSession.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory,
            []
        )
        XCTAssertEqual(
            resetSession.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount,
            0
        )
        XCTAssertEqual(
            resetSession.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
            0
        )
        XCTAssertNil(
            defaults.array(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey
            )
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey
            ),
            0
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey
            ),
            0
        )
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipPulseSkipsWhenPrimarySuggestionStaysSame() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-trust-fix",
            actionPrompt: "Run Trust Fix"
        )

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-trust-fix",
            actionPrompt: "Run Trust Fix",
            reasonChips: [
                CommandPaletteTopPicks.FameMomentumPanelReasonChip(
                    title: "Observed +3",
                    systemImage: "arrow.up.right.circle.fill",
                    helpText: "Observed signal rose."
                )
            ]
        )

        XCTAssertEqual(session.fameMomentumPanelRouteFlipPulseEvent, 0)
        XCTAssertNil(session.recentFameMomentumPanelRouteFlipPulse(maxAge: 12))
    }

    func testCommandPaletteSessionFameMomentumPanelRouteFlipPulseRecencyCanExpire() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let flipStamp = Date(timeIntervalSince1970: 1_520)

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-trust-fix",
            actionPrompt: "Run Trust Fix"
        )

        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "run-fame-next-move-copy-drafts",
            actionPrompt: "Run Rescue Now",
            reasonChips: [
                CommandPaletteTopPicks.FameMomentumPanelReasonChip(
                    title: "Observed +4",
                    systemImage: "arrow.up.right.circle.fill",
                    helpText: "Observed signal surged."
                )
            ],
            at: flipStamp
        )

        XCTAssertEqual(session.fameMomentumPanelRouteFlipPulseEvent, 1)
        XCTAssertEqual(
            session.recentFameMomentumPanelRouteFlipPulse(
                now: flipStamp.addingTimeInterval(5),
                maxAge: 8
            )?.trigger,
            .momentumSurge
        )
        XCTAssertNil(
            session.recentFameMomentumPanelRouteFlipPulse(
                now: flipStamp.addingTimeInterval(10),
                maxAge: 8
            )
        )
    }

    func testCommandPaletteSessionFameMomentumPanelActionRecencyTracksFreshAgingAndStaleSignals() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let actionID = "run-trust-fix"

        session.beginOpen()
        XCTAssertTrue(session.recordFameMomentumPanelOpportunity(actionID: actionID))
        XCTAssertTrue(session.recordFameMomentumPanelConversion(actionID: actionID))

        if case .recentlyValidated(let opensAgo)? = session.fameMomentumPanelActionRecency[actionID] {
            XCTAssertEqual(opensAgo, 0)
        } else {
            XCTFail("Expected a fresh signal in the open where conversion is recorded.")
        }

        session.beginOpen()
        if case .recentlyValidated(let opensAgo)? = session.fameMomentumPanelActionRecency[actionID] {
            XCTAssertEqual(opensAgo, 1)
        } else {
            XCTFail("Expected signal to stay recent one open after conversion.")
        }

        session.beginOpen()
        session.beginOpen()
        if case .aging(let opensAgo)? = session.fameMomentumPanelActionRecency[actionID] {
            XCTAssertEqual(opensAgo, 3)
        } else {
            XCTFail("Expected signal to age before turning stale.")
        }

        session.beginOpen()
        session.beginOpen()
        if case .stale(let opensAgo)? = session.fameMomentumPanelActionRecency[actionID] {
            XCTAssertEqual(opensAgo, 5)
        } else {
            XCTFail("Expected signal to become stale after multiple unvalidated opens.")
        }
    }

    func testCommandPaletteSessionFameMomentumPanelAdaptiveScoresMergeInterventionAndPanelSignals() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let actionID = "run-fame-onboarding-scorecard"

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .watch, points: 40)
        )
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyConfidenceScore(
            makeLaunchRecoveryConfidenceScore(tier: .steady, points: 64)
        )
        XCTAssertEqual(session.launchRecoveryHotKeyInterventionScores[actionID], 3)

        XCTAssertTrue(session.recordFameMomentumPanelOpportunity(actionID: actionID))
        XCTAssertTrue(session.recordFameMomentumPanelConversion(actionID: actionID))
        XCTAssertEqual(session.fameMomentumPanelActionScores[actionID], 2)
        XCTAssertEqual(
            session.fameMomentumPanelAdaptiveActionScores[actionID],
            5,
            "Fame panel ranking should blend intervention impact with panel click feedback."
        )
    }

    func testCommandPaletteSessionPersistsFameMomentumPanelTelemetryAndActionScores() throws {
        let defaults = try makeDefaults()
        let storageKey = "fameMomentumPanelActionScores-\(UUID().uuidString)"
        let actionID = CommandPaletteAction.launchRecoveryNextActionID

        let session = CommandPaletteSession(
            defaults: defaults,
            fameMomentumPanelActionScoresStorageKey: storageKey
        )
        session.beginOpen()
        XCTAssertTrue(session.recordFameMomentumPanelOpportunity(actionID: actionID))
        XCTAssertTrue(session.recordFameMomentumPanelConversion(actionID: actionID))
        XCTAssertEqual(session.fameMomentumPanelActionScores[actionID], 2)

        let restoredSession = CommandPaletteSession(
            defaults: defaults,
            fameMomentumPanelActionScoresStorageKey: storageKey
        )
        XCTAssertEqual(
            restoredSession.fameMomentumPanelActionScores[actionID],
            2
        )
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelOpportunityCountKey),
            1
        )
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelConversionCountKey),
            1
        )
    }

    func testCommandPaletteSessionPersistsFameMomentumPanelRouteStabilizationTelemetry() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let routeSteps: [(id: String, prompt: String, score: Int, gapPoints: Int)] = [
            ("route-a", "Route A", 100, 30),
            ("route-a", "Route A", 104, 28),
            ("route-b", "Route B", 118, 41),
            ("route-c", "Route C", 92, 26),
            ("route-d", "Route D", 134, 52),
        ]

        for step in routeSteps {
            session.beginOpen()
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: step.id,
                actionPrompt: step.prompt,
                actionScore: step.score,
                selectionConfidence: makeFameMomentumSelectionConfidence(
                    gapPoints: step.gapPoints
                )
            )
        }

        XCTAssertEqual(session.fameMomentumPanelRouteFlipRhythm()?.tone, .volatile)

        session.recordFameMomentumPanelRouteStabilizationRun()
        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-d",
            actionPrompt: "Route D",
            actionScore: 134,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 52)
        )

        session.recordFameMomentumPanelRouteStabilizationRun()
        session.beginOpen()
        session.recordFameMomentumPanelPrimarySuggestion(
            actionID: "route-e",
            actionPrompt: "Route E",
            actionScore: 146,
            selectionConfidence: makeFameMomentumSelectionConfidence(gapPoints: 58)
        )

        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRunCount, 2)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationSuccessCount, 1)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationPendingRunCount, 0)
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationRunCountKey),
            2
        )
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationSuccessCountKey),
            1
        )

        let restoredSession = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(restoredSession.fameMomentumPanelRouteStabilizationRunCount, 2)
        XCTAssertEqual(restoredSession.fameMomentumPanelRouteStabilizationSuccessCount, 1)
        XCTAssertEqual(restoredSession.fameMomentumPanelRouteStabilizationPendingRunCount, 0)
        XCTAssertEqual(
            restoredSession.fameMomentumPanelRouteStabilizationScoreboard()?.successRatePercent,
            50
        )
    }

    func testCommandPaletteSessionClampsPersistedFameMomentumPanelRouteStabilizationTelemetry() throws {
        let defaults = try makeDefaults()
        defaults.set(
            3,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRunCountKey
        )
        defaults.set(
            9,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationSuccessCountKey
        )

        _ = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationRunCountKey),
            3
        )
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationSuccessCountKey),
            3
        )

        defaults.set(
            -4,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRunCountKey
        )
        defaults.set(
            5,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationSuccessCountKey
        )

        _ = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationRunCountKey),
            0
        )
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationSuccessCountKey),
            0
        )
    }

    func testCommandPaletteSessionClampsPersistedFameMomentumPanelRouteStabilizationRecoverySuggestionTelemetry() throws {
        let defaults = try makeDefaults()
        defaults.set(
            2,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
        )
        defaults.set(
            9,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey
        )
        defaults.set(
            1,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
        )
        defaults.set(
            4,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
        )
        defaults.set(
            5,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey
        )

        let clampedSession = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(clampedSession.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount, 2)
        XCTAssertEqual(clampedSession.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount, 2)
        XCTAssertEqual(clampedSession.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount, 1)
        XCTAssertEqual(clampedSession.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount, 1)
        XCTAssertEqual(clampedSession.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount, 2)
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
            ),
            2
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey
            ),
            2
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
            ),
            1
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
            ),
            1
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey
            ),
            2
        )

        defaults.set(
            -4,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
        )
        defaults.set(
            3,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey
        )
        defaults.set(
            2,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
        )
        defaults.set(
            2,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
        )
        defaults.set(
            2,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey
        )

        let resetSession = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(resetSession.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount, 0)
        XCTAssertEqual(resetSession.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount, 0)
        XCTAssertEqual(resetSession.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount, 0)
        XCTAssertEqual(resetSession.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount, 0)
        XCTAssertEqual(resetSession.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount, 0)
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
            ),
            0
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey
            ),
            0
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
            ),
            0
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
            ),
            0
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey
            ),
            0
        )
    }

    func testCommandPaletteSessionMigratesLegacyRecoverySuggestionRunTelemetryIntoRecoveryRunBucket() throws {
        let defaults = try makeDefaults()
        defaults.set(
            3,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
        )
        defaults.set(
            2,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey
        )
        defaults.removeObject(
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
        )
        defaults.removeObject(
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
        )

        let session = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount, 2)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount, 2)
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount, 0)
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
            ),
            2
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
            ),
            0
        )
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationResetCueTracksDailyAndSuggestsRecoveryAfterThreshold() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let baseline = Date()

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
                now: baseline
            )
        )
        XCTAssertFalse(
            session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
                now: baseline.addingTimeInterval(1)
            ),
            "Reset cue should count only once per open."
        )
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationResetCueCountToday, 1)
        XCTAssertNil(session.fameMomentumPanelRouteStabilizationRecoverySuggestion())

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
                now: baseline.addingTimeInterval(30)
            )
        )

        let suggestion = try XCTUnwrap(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestion()
        )
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationResetCueCountToday, 2)
        XCTAssertEqual(suggestion.resetCountToday, 2)
        XCTAssertEqual(suggestion.title, "Recovery Loop Suggested")
        XCTAssertEqual(suggestion.buttonTitle, "Run Recovery Loop")
        XCTAssertTrue(suggestion.subtitle.contains("x2") == true)
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationResetCueCountTodayKey),
            2
        )
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationRecoverySuggestionEscalatesButtonCopyAfterRepeatedResets() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let baseline = Date()

        for resetIndex in 0..<4 {
            session.beginOpen()
            XCTAssertTrue(
                session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
                    now: baseline.addingTimeInterval(TimeInterval(resetIndex * 60))
                )
            )
        }

        let suggestion = try XCTUnwrap(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestion()
        )
        XCTAssertEqual(suggestion.resetCountToday, 4)
        XCTAssertEqual(suggestion.title, "Recovery Loop Recommended")
        XCTAssertEqual(suggestion.buttonTitle, "Run Full Recovery")
        XCTAssertTrue(suggestion.subtitle.contains("x4") == true)
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationRecoverySuggestionCanTriggerEarlyUnderBlockedPressure() throws {
        let defaults = try makeDefaults()
        defaults.set(
            6,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
        )
        defaults.set(
            4,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey
        )
        defaults.set(
            4,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
        )
        defaults.set(
            0,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
        )
        defaults.set(
            3,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey
        )
        let session = CommandPaletteSession(defaults: defaults)
        let baseline = Date()

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
                now: baseline
            )
        )

        let suggestion = try XCTUnwrap(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestion()
        )
        XCTAssertEqual(suggestion.resetCountToday, 1)
        XCTAssertEqual(suggestion.title, "Unblock Route Recommended")
        XCTAssertEqual(suggestion.buttonTitle, "Run Unblock Plan")
        XCTAssertTrue(suggestion.subtitle.contains("x1") == true)
        XCTAssertTrue(suggestion.subtitle.contains("3/6") == true)
        XCTAssertTrue(suggestion.helpText.contains("50% blocked across 6 cues") == true)
        XCTAssertTrue(
            suggestion.helpText.contains(
                "Run mix: 4 recovery-route run(s), 0 unblock-route run(s)."
            ) == true
        )
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationRecoverySuggestionKeepsDefaultThresholdWhenBlockedPressureHasHealthyUnblockCoverage() throws {
        let defaults = try makeDefaults()
        defaults.set(
            6,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
        )
        defaults.set(
            6,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey
        )
        defaults.set(
            3,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
        )
        defaults.set(
            3,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
        )
        defaults.set(
            3,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey
        )
        let session = CommandPaletteSession(defaults: defaults)
        let baseline = Date()

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
                now: baseline
            )
        )
        XCTAssertNil(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestion(),
            "Balanced unblock coverage should keep the default two-reset threshold."
        )

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
                now: baseline.addingTimeInterval(60)
            )
        )
        let suggestion = try XCTUnwrap(
            session.fameMomentumPanelRouteStabilizationRecoverySuggestion()
        )
        XCTAssertEqual(suggestion.title, "Recovery Loop Suggested")
        XCTAssertEqual(suggestion.buttonTitle, "Run Recovery Loop")
    }

    func testCommandPaletteSessionFameMomentumPanelRouteStabilizationResetCueDailyCounterCanResetAcrossDays() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)
        let dayOne = Date()
        let dayTwo = dayOne.addingTimeInterval(60 * 60 * 25)

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
                now: dayOne
            )
        )
        XCTAssertEqual(session.fameMomentumPanelRouteStabilizationResetCueCountToday, 1)

        session.beginOpen()
        XCTAssertTrue(
            session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
                now: dayTwo
            )
        )
        XCTAssertEqual(
            session.fameMomentumPanelRouteStabilizationResetCueCountToday,
            1,
            "Day rollover should reset the daily reset-cue count before recording the new day."
        )
        XCTAssertNil(session.fameMomentumPanelRouteStabilizationRecoverySuggestion())
    }

    func testCommandPaletteSessionClampsPersistedFameMomentumPanelRouteStabilizationResetCueTelemetry() throws {
        let defaults = try makeDefaults()
        defaults.set(
            -3,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationResetCueCountTodayKey
        )
        defaults.set(
            "",
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationResetCueDayStampKey
        )

        _ = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationResetCueCountTodayKey),
            0
        )
        let normalizedDayStamp = defaults.string(
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationResetCueDayStampKey
        )
        XCTAssertEqual(
            normalizedDayStamp,
            CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp()
        )
    }

    func testCommandPaletteSessionPersistsLaunchRecoveryReadinessHistoryAndStreaks() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .reroute(actionID: "run-fame-cadence-autopilot-loop")
        )
        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard")
        )
        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard")
        )

        XCTAssertEqual(
            defaults.stringArray(forKey: AppDefaults.fameLaunchRecoveryHotKeyReadinessHistoryKey),
            ["reroute", "direct", "direct"]
        )
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyDirectStreakKey),
            2
        )
        XCTAssertEqual(
            defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyBestDirectStreakKey),
            2
        )

        let restoredSession = CommandPaletteSession(defaults: defaults)
        XCTAssertEqual(
            restoredSession.launchRecoveryHotKeyReadinessHistory,
            [.reroute, .direct, .direct]
        )
        XCTAssertEqual(restoredSession.launchRecoveryHotKeyDirectStreak, 2)
        XCTAssertEqual(restoredSession.launchRecoveryHotKeyBestDirectStreak, 2)
    }

    func testCommandPaletteSessionLaunchRecoveryRestorePulseRequiresNonDirectToDirectTransition() {
        let session = CommandPaletteSession()

        session.beginOpen()
        let firstOpen = Date(timeIntervalSince1970: 100)
        session.recordLaunchRecoveryHotKeyReadiness(
            .reroute(actionID: "run-fame-cadence-autopilot-loop"),
            at: firstOpen
        )
        XCTAssertEqual(session.launchRecoveryHotKeyRestorePulseEvent, 0)
        XCTAssertNil(session.recentLaunchRecoveryHotKeyRestorePulse())

        session.beginOpen()
        let secondOpen = Date(timeIntervalSince1970: 200)
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard"),
            at: secondOpen
        )
        XCTAssertEqual(session.launchRecoveryHotKeyRestorePulseEvent, 1)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyRestorePulse(
                now: secondOpen.addingTimeInterval(5),
                maxAge: 12
            ),
            CommandPaletteTopPicks.launchRecoveryHotKeyRestorePulse(previousState: .reroute)
        )
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyRestorePulse(
                now: secondOpen.addingTimeInterval(14),
                maxAge: 12
            )
        )

        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard"),
            at: secondOpen
        )
        XCTAssertEqual(session.launchRecoveryHotKeyRestorePulseEvent, 1)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard"),
            at: Date(timeIntervalSince1970: 240)
        )
        XCTAssertEqual(session.launchRecoveryHotKeyRestorePulseEvent, 1)

        session.beginOpen()
        session.recordLaunchRecoveryHotKeyReadiness(
            .unavailable,
            at: Date(timeIntervalSince1970: 260)
        )
        session.beginOpen()
        let fifthOpen = Date(timeIntervalSince1970: 280)
        session.recordLaunchRecoveryHotKeyReadiness(
            .direct(actionID: "run-fame-onboarding-scorecard"),
            at: fifthOpen
        )
        XCTAssertEqual(session.launchRecoveryHotKeyRestorePulseEvent, 2)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyRestorePulse(
                now: fifthOpen.addingTimeInterval(5),
                maxAge: 12
            ),
            CommandPaletteTopPicks.launchRecoveryHotKeyRestorePulse(previousState: .standby)
        )
    }

    func testCommandPaletteSessionLaunchRecoveryDecayPulseRequiresRepeatedCoachCue() {
        let session = CommandPaletteSession()
        let cue = CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue(
            title: "Coach: Restore ⌥⇧L Direct",
            subtitle: "Reroute leads 4/6 opens. Run Fill Onboarding Gap to restore direct launch recovery.",
            systemImage: "arrow.triangle.2.circlepath",
            actionID: "run-fame-onboarding-fill-gap"
        )

        session.beginOpen()
        let firstOpenPulse = session.recordLaunchRecoveryHotKeyCoachCue(cue, repeatThreshold: 2)
        XCTAssertNil(firstOpenPulse)
        XCTAssertEqual(session.launchRecoveryHotKeyDecayPulseEvent, 0)
        XCTAssertNil(session.recentLaunchRecoveryHotKeyDecayPulse())

        let duplicateOpenPulse = session.recordLaunchRecoveryHotKeyCoachCue(cue, repeatThreshold: 2)
        XCTAssertNil(duplicateOpenPulse)
        XCTAssertEqual(session.launchRecoveryHotKeyDecayPulseEvent, 0)

        session.beginOpen()
        let secondOpenDate = Date(timeIntervalSince1970: 300)
        let secondOpenPulse = session.recordLaunchRecoveryHotKeyCoachCue(
            cue,
            at: secondOpenDate,
            repeatThreshold: 2
        )
        XCTAssertEqual(
            secondOpenPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyDecayPulse(
                coachCue: cue,
                streakCount: 2
            )
        )
        XCTAssertEqual(session.launchRecoveryHotKeyDecayPulseEvent, 1)
        XCTAssertEqual(
            session.recentLaunchRecoveryHotKeyDecayPulse(
                now: secondOpenDate.addingTimeInterval(6),
                maxAge: 12
            ),
            CommandPaletteTopPicks.launchRecoveryHotKeyDecayPulse(
                coachCue: cue,
                streakCount: 2
            )
        )
        XCTAssertNil(
            session.recentLaunchRecoveryHotKeyDecayPulse(
                now: secondOpenDate.addingTimeInterval(14),
                maxAge: 12
            )
        )

        session.beginOpen()
        let thirdOpenPulse = session.recordLaunchRecoveryHotKeyCoachCue(cue, repeatThreshold: 2)
        XCTAssertNil(thirdOpenPulse)
        XCTAssertEqual(
            session.launchRecoveryHotKeyDecayPulseEvent,
            1,
            "Decay pulse should fire only on threshold crossing."
        )

        session.beginOpen()
        let resetPulse = session.recordLaunchRecoveryHotKeyCoachCue(nil, repeatThreshold: 2)
        XCTAssertNil(resetPulse)

        session.beginOpen()
        let postResetFirstPulse = session.recordLaunchRecoveryHotKeyCoachCue(cue, repeatThreshold: 2)
        XCTAssertNil(postResetFirstPulse)
        session.beginOpen()
        let postResetSecondPulse = session.recordLaunchRecoveryHotKeyCoachCue(cue, repeatThreshold: 2)
        XCTAssertEqual(
            postResetSecondPulse,
            CommandPaletteTopPicks.launchRecoveryHotKeyDecayPulse(
                coachCue: cue,
                streakCount: 2
            )
        )
        XCTAssertEqual(
            session.launchRecoveryHotKeyDecayPulseEvent,
            2,
            "Reset cue should allow a new threshold crossing pulse."
        )
    }

    func testCommandPaletteRefreshClockCanPublishTicks() {
        let clock = CommandPaletteRefreshClock()

        XCTAssertEqual(clock.tick, 0)
        clock.bump()
        XCTAssertEqual(clock.tick, 1)
        clock.bump()
        XCTAssertEqual(clock.tick, 2)
    }

    func testCadenceExecutionKitStreakReadsDefaultsAndNormalizesBest() throws {
        let defaults = try makeDefaults()
        defaults.set(4, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(2, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)

        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.currentStreak(defaults: defaults),
            4
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.bestStreak(defaults: defaults),
            4
        )

        defaults.set(-3, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(7, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)

        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.currentStreak(defaults: defaults),
            0
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.bestStreak(defaults: defaults),
            7
        )
    }

    func testCadenceExecutionKitStreakBadgeVisibilityRequiresStreakAndRelevantTopPick() {
        XCTAssertFalse(
            CommandPaletteCadenceExecutionKitStreak.shouldShowBadge(
                currentStreak: 0,
                topPickActionIDs: ["run-fame-next-move-cadence-execution-kit"]
            )
        )
        XCTAssertFalse(
            CommandPaletteCadenceExecutionKitStreak.shouldShowBadge(
                currentStreak: 3,
                topPickActionIDs: ["run-fame-next-move", "run-fame-next-move-copy-drafts"]
            )
        )
        XCTAssertTrue(
            CommandPaletteCadenceExecutionKitStreak.shouldShowBadge(
                currentStreak: 3,
                topPickActionIDs: ["run-fame-next-move-cadence-execution-kit"]
            )
        )
        XCTAssertTrue(
            CommandPaletteCadenceExecutionKitStreak.shouldShowBadge(
                currentStreak: 2,
                topPickActionIDs: ["copy-next-move-cadence-execution-kit"]
            )
        )
        XCTAssertFalse(
            CommandPaletteCadenceExecutionKitStreak.shouldShowBadge(
                currentStreak: 2,
                topPickActionIDs: ["copy-next-move-cadence-execution-kit"],
                badgeEnabled: false
            )
        )
    }

    func testCadenceExecutionKitStreakBadgeCopyAndSymbolReflectStreakLevel() {
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.badgeLabel(streak: 3),
            "Cadence x3"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.badgeSystemImage(streak: 3),
            "bolt.fill"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.badgeSystemImage(streak: 5),
            "rocket.fill"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.badgeHelpText(streak: 3, bestStreak: 7),
            "Cadence execution kit streak: 3. Best: 7."
        )
    }

    func testCadenceExecutionKitMomentumHelpersExposeTargetsCopyAndSymbols() throws {
        XCTAssertTrue(
            CommandPaletteCadenceExecutionKitStreak.isCadenceExecutionKitAction(
                "run-fame-next-move-cadence-execution-kit"
            )
        )
        XCTAssertTrue(
            CommandPaletteCadenceExecutionKitStreak.isCadenceExecutionKitAction(
                "copy-next-move-cadence-execution-kit"
            )
        )
        XCTAssertTrue(
            CommandPaletteCadenceExecutionKitStreak.isCadenceExecutionKitAction(
                "run-fame-cadence-autopilot-loop"
            )
        )
        XCTAssertFalse(
            CommandPaletteCadenceExecutionKitStreak.isCadenceExecutionKitAction(
                "run-fame-next-move"
            )
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.runActionIDCandidate(),
            "run-fame-next-move-cadence-execution-kit"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.copyActionIDCandidate(),
            "copy-next-move-cadence-execution-kit"
        )

        XCTAssertEqual(CommandPaletteCadenceExecutionKitStreak.nextMilestoneTarget(after: 0), 3)
        XCTAssertEqual(CommandPaletteCadenceExecutionKitStreak.nextMilestoneTarget(after: 3), 5)
        XCTAssertEqual(CommandPaletteCadenceExecutionKitStreak.nextMilestoneTarget(after: 5), 10)
        XCTAssertEqual(CommandPaletteCadenceExecutionKitStreak.nextMilestoneTarget(after: 10), 15)
        XCTAssertEqual(CommandPaletteCadenceExecutionKitStreak.nextMilestoneTarget(after: 15), 20)

        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumTitle(streak: 4, bestStreak: 7),
            "Cadence momentum x4"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumTitle(streak: 0, bestStreak: 7),
            "Cadence momentum reset"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumTitle(streak: 0, bestStreak: 0),
            "Cadence momentum"
        )

        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumSubtitle(streak: 4, bestStreak: 7),
            "Next milestone x5 in 1 run · Best x7"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumSubtitle(streak: 0, bestStreak: 7),
            "Best x7. Restart and hit x3."
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumSubtitle(streak: 0, bestStreak: 0),
            "Start now. First milestone x3."
        )

        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumSystemImage(streak: 0),
            "arrow.clockwise"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumSystemImage(streak: 3),
            "bolt.fill"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumSystemImage(streak: 6),
            "rocket.fill"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumSystemImage(streak: 10),
            "trophy.fill"
        )
        XCTAssertEqual(
            CommandPaletteCadenceExecutionKitStreak.momentumHelpText(streak: 4, bestStreak: 7),
            "Cadence momentum x4. Next milestone x5 in 1 run · Best x7"
        )

        XCTAssertNil(
            CommandPaletteCadenceExecutionKitStreak.momentumPulse(
                previousStreak: 3,
                nextStreak: 3,
                bestStreak: 7
            )
        )

        let pulse = try XCTUnwrap(
            CommandPaletteCadenceExecutionKitStreak.momentumPulse(
                previousStreak: 3,
                nextStreak: 4,
                bestStreak: 7
            )
        )
        XCTAssertEqual(pulse.title, "Cadence +1 to x4")
        XCTAssertEqual(pulse.subtitle, "Next milestone x5 in 1 run · Best x7")
        XCTAssertEqual(pulse.systemImage, "bolt.fill")
        XCTAssertEqual(
            pulse.helpText,
            "Cadence +1 to x4. Next milestone x5 in 1 run · Best x7"
        )

        let milestonePulse = try XCTUnwrap(
            CommandPaletteCadenceExecutionKitStreak.momentumPulse(
                previousStreak: 4,
                nextStreak: 5,
                bestStreak: 7
            )
        )
        XCTAssertEqual(milestonePulse.title, "Cadence +1 to x5")
        XCTAssertEqual(milestonePulse.subtitle, "Milestone x5 unlocked · Best x7")
        XCTAssertEqual(milestonePulse.systemImage, "rocket.fill")

        let resetPulse = try XCTUnwrap(
            CommandPaletteCadenceExecutionKitStreak.momentumPulse(
                previousStreak: 4,
                nextStreak: 0,
                bestStreak: 7
            )
        )
        XCTAssertEqual(resetPulse.title, "Cadence streak reset")
        XCTAssertEqual(resetPulse.subtitle, "Best x7 saved. Run again to rebuild.")
        XCTAssertEqual(resetPulse.systemImage, "arrow.counterclockwise.circle.fill")
    }

    func testCadenceExecutionKitMomentumCardVisibilityUsesCurrentOrBestStreakWhenEnabled() {
        XCTAssertFalse(
            CommandPaletteCadenceExecutionKitStreak.shouldShowMomentumCard(
                currentStreak: 0,
                bestStreak: 0
            )
        )
        XCTAssertTrue(
            CommandPaletteCadenceExecutionKitStreak.shouldShowMomentumCard(
                currentStreak: 2,
                bestStreak: 2
            )
        )
        XCTAssertTrue(
            CommandPaletteCadenceExecutionKitStreak.shouldShowMomentumCard(
                currentStreak: 0,
                bestStreak: 5
            )
        )
        XCTAssertFalse(
            CommandPaletteCadenceExecutionKitStreak.shouldShowMomentumCard(
                currentStreak: 4,
                bestStreak: 7,
                momentumCardEnabled: false
            )
        )
    }

    func testTopPicksIdleStateCanSurfaceNarrativeLabActions() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-narrative-lab",
                title: "Run Fame Narrative Lab",
                subtitle: "Generate publish-ready narrative routes",
                systemImage: "text.bubble",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-narrative-lab",
                title: "Open Latest Narrative Lab",
                subtitle: "Open latest narrative lab",
                systemImage: "text.bubble",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-narrative-lab",
                "open-latest-narrative-lab"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceSpotlightPackActions() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-spotlight-pack",
                title: "Run Fame Spotlight Pack",
                subtitle: "Generate channel-ready spotlight drafts",
                systemImage: "megaphone",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-spotlight-pack",
                title: "Open Latest Spotlight Pack",
                subtitle: "Open latest spotlight pack",
                systemImage: "megaphone",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-spotlight-pack",
                "open-latest-spotlight-pack"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceLaunchDayScriptActions() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-day-script",
                title: "Run Fame Launch Day Script",
                subtitle: "Generate timed launch script + copy blocks",
                systemImage: "flag.checkered.2.crossed",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-launch-day-script",
                title: "Open Latest Launch Day Script",
                subtitle: "Open latest launch day script",
                systemImage: "flag.checkered.2.crossed",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-day-script",
                "open-latest-launch-day-script"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceLaunchCountdownActions() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-countdown",
                title: "Run Fame Launch Countdown",
                subtitle: "Generate real-time launch step tracker",
                systemImage: "timer",
                run: {}
            ),
            CommandPaletteAction(
                id: "open-latest-launch-countdown",
                title: "Open Latest Launch Countdown",
                subtitle: "Open latest launch countdown",
                systemImage: "timer",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-countdown",
                "open-latest-launch-countdown"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeLaunchCountdownAlertCard() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-alert",
                title: "Launch Countdown: T-20m",
                subtitle: "Next: T-20m: Publish now",
                systemImage: "timer",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Autopilot move",
                systemImage: "paperplane",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-alert",
                "run-fame-next-move"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeLaunchControlHealthCard() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-control-health",
                title: "Launch Health: Risk · T+18m",
                subtitle: "Urgency High (overdue by 18m) · Next: T+18m: Recover · click: Run Launch Rescue Burst",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-alert",
                title: "Launch Countdown: T+18m",
                subtitle: "Urgency High (overdue by 18m) · Next: T+18m: Recover",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-control-health",
                "run-fame-launch-alert"
            ]
        )
    }

    func testTopPicksIdleStatePromotesBestChannelLaunchPackForLaunchHealthRisk() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-control-health",
                title: "Launch Health: Risk · T+18m",
                subtitle: "Urgency High (overdue by 18m) · Next: T+18m: Recover · click: Run Launch Rescue Burst",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-alert",
                title: "Launch Countdown: T+18m",
                subtitle: "Urgency High (overdue by 18m) · Next: T+18m: Recover",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-best-channel-launch-pack",
                title: "Copy Best Channel Launch Pack",
                subtitle: "Best channel now: LinkedIn · copy post + launch pack",
                systemImage: "star.bubble",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-best-channel-draft",
                title: "Copy Best Channel Draft",
                subtitle: "Best channel now: LinkedIn · copy first cadence draft",
                systemImage: "star.circle",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 7).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-control-health",
                "copy-next-move-best-channel-launch-pack",
                "copy-next-move-best-channel-draft",
                "run-fame-launch-alert"
            ]
        )
    }

    func testTopPicksIdleStateDoesNotPromoteBestChannelLaunchPackForLaunchHealthReady() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-control-health",
                title: "Launch Health: Ready · T-20m",
                subtitle: "Urgency Ready (starts in 20m) · Next: T-20m: Publish · click: Run Launch Control Brief",
                systemImage: "checkmark.circle",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-alert",
                title: "Launch Countdown: T-20m",
                subtitle: "Urgency Ready (starts in 20m) · Next: T-20m: Publish",
                systemImage: "timer",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-best-channel-launch-pack",
                title: "Copy Best Channel Launch Pack",
                subtitle: "Best channel now: X · copy post + launch pack",
                systemImage: "star.bubble",
                run: {}
            ),
            CommandPaletteAction(
                id: "copy-next-move-best-channel-draft",
                title: "Copy Best Channel Draft",
                subtitle: "Best channel now: X · copy first cadence draft",
                systemImage: "star.circle",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 7).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-control-health",
                "run-fame-launch-alert",
                "copy-next-move-best-channel-launch-pack",
                "copy-next-move-best-channel-draft"
            ]
        )
    }

    func testBestChannelLaunchPackPressureCardUsesAlertToneForCriticalPulse() {
        let launchPackAction = CommandPaletteAction(
            id: "copy-next-move-best-channel-launch-pack",
            title: "Copy Best Channel Launch Pack",
            subtitle: "Best channel now: LinkedIn · copy post + launch pack",
            systemImage: "star.bubble",
            run: {}
        )
        let pulseAlertAction = CommandPaletteAction(
            id: "run-fame-pulse-alert",
            title: "Fame Pulse Alert: MUST SHIP",
            subtitle: "Risk Critical · MUST SHIP in next 2h",
            systemImage: "exclamationmark.triangle.fill",
            run: {}
        )

        let card = CommandPaletteTopPicks.bestChannelLaunchPackPressureCard(
            launchPackAction: launchPackAction,
            pulseAlertAction: pulseAlertAction,
            launchHealthAction: nil,
            launchAlertAction: nil,
            momentumPulse: nil
        )

        XCTAssertEqual(card?.tone, .alert)
        XCTAssertEqual(card?.actionID, "copy-next-move-best-channel-launch-pack")
    }

    func testBestChannelLaunchPackPressureCardUsesWatchToneForLaunchHealthWatch() {
        let launchPackAction = CommandPaletteAction(
            id: "copy-next-move-best-channel-launch-pack",
            title: "Copy Best Channel Launch Pack",
            subtitle: "Best channel now: LinkedIn · copy post + launch pack",
            systemImage: "star.bubble",
            run: {}
        )
        let launchHealthAction = CommandPaletteAction(
            id: "run-fame-launch-control-health",
            title: "Launch Health: Watch · T-20m",
            subtitle: "Urgency Watch · Keep launch kit warm",
            systemImage: "eye.trianglebadge.exclamationmark",
            run: {}
        )

        let card = CommandPaletteTopPicks.bestChannelLaunchPackPressureCard(
            launchPackAction: launchPackAction,
            pulseAlertAction: nil,
            launchHealthAction: launchHealthAction,
            launchAlertAction: nil,
            momentumPulse: nil
        )

        XCTAssertEqual(card?.tone, .watch)
        XCTAssertEqual(card?.actionID, "copy-next-move-best-channel-launch-pack")
    }

    func testBestChannelLaunchPackPressureCardReturnsNilWithoutPressureSignals() {
        let launchPackAction = CommandPaletteAction(
            id: "copy-next-move-best-channel-launch-pack",
            title: "Copy Best Channel Launch Pack",
            subtitle: "Best channel now: LinkedIn · copy post + launch pack",
            systemImage: "star.bubble",
            run: {}
        )
        let launchHealthAction = CommandPaletteAction(
            id: "run-fame-launch-control-health",
            title: "Launch Health: Ready · T-20m",
            subtitle: "Urgency Ready · Keep monitoring cadence",
            systemImage: "checkmark.circle",
            run: {}
        )

        let card = CommandPaletteTopPicks.bestChannelLaunchPackPressureCard(
            launchPackAction: launchPackAction,
            pulseAlertAction: nil,
            launchHealthAction: launchHealthAction,
            launchAlertAction: nil,
            momentumPulse: nil
        )

        XCTAssertNil(card)
    }

    func testBestChannelLaunchPackPressureBadgeHelpersFormatWinRateAndTone() {
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureBadgeTitle(
                opportunities: 4,
                conversions: 3,
                streak: 2
            ),
            "Launch Pack 75% · x2"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureBadgeSystemImage(tone: .alert),
            "bolt.trianglebadge.exclamationmark"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureBadgeSystemImage(tone: .watch),
            "eye.trianglebadge.exclamationmark"
        )
        XCTAssertNil(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureBadgeTitle(
                opportunities: 0,
                conversions: 0,
                streak: 0
            )
        )
    }

    func testBestChannelLaunchPackPressurePerformanceLineFormatsProgress() {
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressurePerformanceLine(
                opportunities: 0,
                conversions: 0,
                streak: 0,
                bestStreak: 0
            ),
            "No pressure runs yet · first clutch run starts streak."
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressurePerformanceLine(
                opportunities: 5,
                conversions: 3,
                streak: 2,
                bestStreak: 4
            ),
            "60% win rate · streak x2 · best x4"
        )
    }

    func testBestChannelLaunchPackPressureModeBadgeHelpersMapTrendStates() {
        XCTAssertNil(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeTitle(
                trend: .noOpportunities
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeTitle(
                trend: .noWins
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeTitle(
                trend: .compounding
            ),
            "Pressure Mode: Compounding"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeTitle(
                trend: .rebuilding
            ),
            "Pressure Mode: Rebuilding"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeTitle(
                trend: .cooling
            ),
            "Pressure Mode: Cooling"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeSystemImage(
                trend: .compounding
            ),
            "arrow.up.right.circle.fill"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeSystemImage(
                trend: .rebuilding
            ),
            "arrow.triangle.2.circlepath.circle.fill"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeSystemImage(
                trend: .cooling
            ),
            "snowflake.circle.fill"
        )
    }

    func testBestChannelLaunchPackPressureModeBadgeHelpTextIncludesGuidanceAndPerformance() {
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeHelpText(
                trend: .compounding,
                opportunities: 8,
                conversions: 6,
                streak: 6,
                bestStreak: 6
            ),
            "Conversions are matching your best streak. Keep shipping the best channel while momentum is compounding. 75% win rate · streak x6 · best x6"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeHelpText(
                trend: .rebuilding,
                opportunities: 8,
                conversions: 5,
                streak: 2,
                bestStreak: 5
            ),
            "Wins are recovering but still below your best streak. Pair draft prep with launch-pack execution to close the gap. 63% win rate · streak x2 · best x5"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeHelpText(
                trend: .cooling,
                opportunities: 8,
                conversions: 5,
                streak: 0,
                bestStreak: 5
            ),
            "Latest pressure cycle cooled off after a miss. Relaunch the best channel now to restart streak momentum. 63% win rate · streak x0 · best x5"
        )
    }

    func testBestChannelLaunchPackGuidanceButtonTitleAdaptsToTrendAndTone() {
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackGuidanceButtonTitle(
                trend: .compounding,
                tone: .alert
            ),
            "Ship Momentum"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackGuidanceButtonTitle(
                trend: .compounding,
                tone: .watch
            ),
            "Keep Momentum"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackGuidanceButtonTitle(
                trend: .rebuilding,
                tone: .alert
            ),
            "Rebuild Streak"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackGuidanceButtonTitle(
                trend: .cooling,
                tone: .watch
            ),
            "Restart Streak"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackGuidanceButtonTitle(
                trend: .noWins,
                tone: .alert
            ),
            "Start Streak"
        )
    }

    func testBestChannelLaunchPackPressureCardHelpTextAddsModeShiftIntensity() {
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureCardHelpText(
                tone: .alert,
                trend: .rebuilding,
                actionTitle: "Copy Best Channel Launch Pack",
                opportunities: 8,
                conversions: 5,
                streak: 2,
                bestStreak: 5,
                modeTransitionCount: 4,
                modeTransitionLatestToken: "cooling-to-rebuilding"
            ),
            "High launch pressure with rebuilding momentum. Run Copy Best Channel Launch Pack now to lock recovery. Latest mode shift Cooling -> Rebuilding. One more win can restore compounding pace. 63% win rate · streak x2 · best x5"
        )
    }

    func testBestChannelLaunchPackPressureCardHelpTextAddsMomentumStreakWhenAvailable() {
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureCardHelpText(
                tone: .watch,
                trend: .compounding,
                actionTitle: "Copy Best Channel Launch Pack",
                opportunities: 9,
                conversions: 7,
                streak: 4,
                bestStreak: 6,
                modeTransitionCount: 5,
                modeTransitionLatestToken: "rebuilding-to-compounding",
                modeMomentumStreak: 3
            ),
            "Launch pressure is elevated while momentum compounds. Run Copy Best Channel Launch Pack now to keep launch copy warm. Latest mode shift Rebuilding -> Compounding. Protect this upswing with immediate shipping. Mode momentum is rising (upshift streak x3). 78% win rate · streak x4 · best x6"
        )
    }

    func testBestChannelLaunchPackPressurePriorityPromotionBiasesRecentMomentumUpshift() {
        let watchCard = CommandPaletteTopPicks.BestChannelLaunchPackPressureCard(
            tone: .watch,
            title: "Launch Pressure Watch",
            subtitle: "Stage now",
            systemImage: "eye.trianglebadge.exclamationmark",
            helpText: "Stage best channel",
            actionID: "copy-next-move-best-channel-launch-pack"
        )
        let enabledActionIDs: Set<String> = [
            "copy-next-move-best-channel-launch-pack",
            "copy-next-move-best-channel-draft",
            "run-fame-cadence-autopilot-loop"
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressurePriorityPromotedActionIDs(
                card: watchCard,
                opportunities: 8,
                conversions: 6,
                streak: 6,
                bestStreak: 6,
                enabledActionIDs: enabledActionIDs,
                modeTransitionCount: 4,
                modeTransitionLatestToken: "rebuilding-to-compounding"
            ),
            [
                "copy-next-move-best-channel-launch-pack",
                "run-fame-cadence-autopilot-loop"
            ]
        )
    }

    func testBestChannelLaunchPackPressurePriorityPromotionBiasesRecentCoolingDownshift() {
        let alertCard = CommandPaletteTopPicks.BestChannelLaunchPackPressureCard(
            tone: .alert,
            title: "Launch Pressure Alert",
            subtitle: "Ship now",
            systemImage: "bolt.trianglebadge.exclamationmark",
            helpText: "Ship best channel",
            actionID: "copy-next-move-best-channel-launch-pack"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressurePriorityPromotedActionIDs(
                card: alertCard,
                opportunities: 8,
                conversions: 5,
                streak: 0,
                bestStreak: 5,
                enabledActionIDs: [
                    "copy-next-move-best-channel-launch-pack",
                    "copy-next-move-best-channel-draft",
                    "run-fame-cadence-autopilot-loop"
                ],
                modeTransitionCount: 5,
                modeTransitionLatestToken: "compounding-to-cooling"
            ),
            [
                "copy-next-move-best-channel-launch-pack",
                "run-fame-cadence-autopilot-loop",
                "copy-next-move-best-channel-draft"
            ]
        )
    }

    func testBestChannelLaunchPackPressurePriorityPromotionUsesMomentumStreakFallbackWhenTokenMissing() {
        let watchCard = CommandPaletteTopPicks.BestChannelLaunchPackPressureCard(
            tone: .watch,
            title: "Launch Pressure Watch",
            subtitle: "Stage now",
            systemImage: "eye.trianglebadge.exclamationmark",
            helpText: "Stage best channel",
            actionID: "copy-next-move-best-channel-launch-pack"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressurePriorityPromotedActionIDs(
                card: watchCard,
                opportunities: 8,
                conversions: 6,
                streak: 6,
                bestStreak: 6,
                enabledActionIDs: [
                    "copy-next-move-best-channel-launch-pack",
                    "copy-next-move-best-channel-draft",
                    "run-fame-cadence-autopilot-loop"
                ],
                modeTransitionCount: 7,
                modeTransitionLatestToken: "invalid",
                modeMomentumStreak: 3
            ),
            [
                "copy-next-move-best-channel-launch-pack",
                "run-fame-cadence-autopilot-loop"
            ]
        )
    }

    func testBestChannelLaunchPackPressureTrendClassifiesCoreStates() {
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureTrend(
                opportunities: 0,
                conversions: 0,
                streak: 0,
                bestStreak: 0
            ),
            .noOpportunities
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureTrend(
                opportunities: 4,
                conversions: 0,
                streak: 0,
                bestStreak: 0
            ),
            .noWins
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureTrend(
                opportunities: 8,
                conversions: 5,
                streak: 0,
                bestStreak: 5
            ),
            .cooling
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureTrend(
                opportunities: 8,
                conversions: 5,
                streak: 2,
                bestStreak: 5
            ),
            .rebuilding
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureTrend(
                opportunities: 8,
                conversions: 6,
                streak: 6,
                bestStreak: 5
            ),
            .compounding
        )
    }

    func testBestChannelLaunchPackPressureModeTransitionAfterOpportunityRecord() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        let previousTrend = bestChannelLaunchPackPressureTrend(for: session)
        XCTAssertEqual(previousTrend, .noOpportunities)
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureOpportunity(tone: .alert))

        let nextTrend = bestChannelLaunchPackPressureTrend(for: session)
        XCTAssertEqual(nextTrend, .noWins)
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeTransition(
                previousTrend: previousTrend,
                trend: nextTrend
            ),
            CommandPaletteTopPicks.BestChannelLaunchPackPressureModeTransition(
                previousTrend: .noOpportunities,
                trend: .noWins
            )
        )
    }

    func testBestChannelLaunchPackPressureModeTransitionAfterConversionRecord() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureOpportunity(tone: .alert))
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureConversion(tone: .alert))
        session.beginOpen()
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureOpportunity(tone: .alert))
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureConversion(tone: .alert))
        session.beginOpen()
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureOpportunity(tone: .alert))
        session.beginOpen()

        XCTAssertEqual(bestChannelLaunchPackPressureTrend(for: session), .cooling)
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureOpportunity(tone: .watch))

        let previousTrend = bestChannelLaunchPackPressureTrend(for: session)
        XCTAssertEqual(previousTrend, .cooling)
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureConversion(tone: .watch))

        let nextTrend = bestChannelLaunchPackPressureTrend(for: session)
        XCTAssertEqual(nextTrend, .rebuilding)
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeTransition(
                previousTrend: previousTrend,
                trend: nextTrend
            ),
            CommandPaletteTopPicks.BestChannelLaunchPackPressureModeTransition(
                previousTrend: .cooling,
                trend: .rebuilding
            )
        )
    }

    func testBestChannelLaunchPackPressureModeTransitionOnStateRefresh() throws {
        let defaults = try makeDefaults()
        let session = CommandPaletteSession(defaults: defaults)

        session.beginOpen()
        XCTAssertTrue(session.recordBestChannelLaunchPackPressureOpportunity(tone: .watch))

        let openingTrend = bestChannelLaunchPackPressureTrend(for: session)
        XCTAssertEqual(openingTrend, .noWins)
        XCTAssertNil(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeTransition(
                previousTrend: nil,
                trend: openingTrend
            )
        )

        XCTAssertTrue(session.recordBestChannelLaunchPackPressureConversion(tone: .watch))
        let refreshedTrend = bestChannelLaunchPackPressureTrend(for: session)
        XCTAssertEqual(refreshedTrend, .compounding)
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeTransition(
                previousTrend: openingTrend,
                trend: refreshedTrend
            ),
            CommandPaletteTopPicks.BestChannelLaunchPackPressureModeTransition(
                previousTrend: .noWins,
                trend: .compounding
            )
        )
    }

    func testBestChannelLaunchPackPressureModeTransitionDedupesRepeatedTrend() {
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeTransition(
                previousTrend: .rebuilding,
                trend: .compounding
            ),
            CommandPaletteTopPicks.BestChannelLaunchPackPressureModeTransition(
                previousTrend: .rebuilding,
                trend: .compounding
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeTransition(
                previousTrend: .compounding,
                trend: .compounding
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.bestChannelLaunchPackPressureModeTransition(
                previousTrend: nil,
                trend: .cooling
            )
        )
    }

    func testBestChannelLaunchPackPressurePriorityPromotionAdaptsToTrend() {
        let watchCard = CommandPaletteTopPicks.BestChannelLaunchPackPressureCard(
            tone: .watch,
            title: "Launch Pressure Watch",
            subtitle: "Stage now",
            systemImage: "eye.trianglebadge.exclamationmark",
            helpText: "Stage best channel",
            actionID: "copy-next-move-best-channel-launch-pack"
        )
        let enabledActionIDs: Set<String> = [
            "copy-next-move-best-channel-launch-pack",
            "copy-next-move-best-channel-draft",
            "run-fame-cadence-autopilot-loop"
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressurePriorityPromotedActionIDs(
                card: watchCard,
                opportunities: 5,
                conversions: 0,
                streak: 0,
                bestStreak: 0,
                enabledActionIDs: enabledActionIDs
            ),
            [
                "copy-next-move-best-channel-launch-pack",
                "copy-next-move-best-channel-draft"
            ]
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressurePriorityPromotedActionIDs(
                card: watchCard,
                opportunities: 8,
                conversions: 6,
                streak: 6,
                bestStreak: 5,
                enabledActionIDs: enabledActionIDs
            ),
            []
        )
    }

    func testBestChannelLaunchPackPressurePriorityPromotionKeepsAlertAndFallsBackToCadence() {
        let alertCard = CommandPaletteTopPicks.BestChannelLaunchPackPressureCard(
            tone: .alert,
            title: "Launch Pressure Alert",
            subtitle: "Ship now",
            systemImage: "bolt.trianglebadge.exclamationmark",
            helpText: "Ship best channel",
            actionID: "copy-next-move-best-channel-launch-pack"
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressurePriorityPromotedActionIDs(
                card: alertCard,
                opportunities: 8,
                conversions: 6,
                streak: 6,
                bestStreak: 5,
                enabledActionIDs: [
                    "copy-next-move-best-channel-launch-pack",
                    "run-fame-cadence-autopilot-loop"
                ]
            ),
            ["copy-next-move-best-channel-launch-pack"]
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.bestChannelLaunchPackPressurePriorityPromotedActionIDs(
                card: alertCard,
                opportunities: 4,
                conversions: 0,
                streak: 0,
                bestStreak: 0,
                enabledActionIDs: [
                    "copy-next-move-best-channel-launch-pack",
                    "run-fame-cadence-autopilot-loop"
                ]
            ),
            [
                "copy-next-move-best-channel-launch-pack",
                "run-fame-cadence-autopilot-loop"
            ]
        )
    }

    func testRecommendationPairPromotionReturnsRecommendedActionForHighTrustPair() {
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 6,
                conversions: 5,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testRecommendationPairPromotionSkipsLowAndCalibratingPairs() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 6,
                conversions: 2,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            )
        )
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 2,
                conversions: 2,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            )
        )
    }

    func testRecommendationPairPromotionSkipsDisabledRecommendedAction() {
        XCTAssertNil(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 6,
                conversions: 5,
                enabledActionIDs: ["run-fame-cadence-autopilot-loop"]
            )
        )
    }

    func testRecommendationPairPromotionCandidatesPreferBroaderHighTrustSample() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 5,
                conversions: 5
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 8,
                conversions: 6
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ]
            ),
            "run-fame-cadence-autopilot-loop"
        )
    }

    func testRecommendationPairPromotionCandidatesIgnoreDisabledAndLowTrustPairs() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 6
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 8,
                conversions: 7
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-alert",
                recommendedActionID: "run-fame-launch-health-check",
                opportunities: 9,
                conversions: 1
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                candidates: candidates,
                enabledActionIDs: ["run-fame-next-move-copy-drafts"]
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testRecommendationPairPromotionCandidatesCanFavorRecentMomentum() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 6,
                conversions: 5,
                opensSinceLastConversion: 1
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 12
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ]
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testRecommendationPairPromotionCandidatesCanEscalateColdRecoveryWhenRescueLaneIsActive() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 1
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 9
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ],
                activeRescueStreak: 1
            ),
            "run-fame-next-move-copy-drafts"
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ],
                activeRescueStreak: 5
            ),
            "run-fame-cadence-autopilot-loop"
        )
    }

    func testRecommendationPairPromotionCandidatesDoNotBoostLowTrustColdPairsDuringRescueLane() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 1
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 12,
                conversions: 3,
                opensSinceLastConversion: 16
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ],
                activeRescueStreak: 8
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testRecommendationPairPromotionCandidatesRemainConservativeWithLargeSampleGap() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 6,
                conversions: 5,
                opensSinceLastConversion: 1
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 12,
                conversions: 9,
                opensSinceLastConversion: 14
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ]
            ),
            "run-fame-cadence-autopilot-loop"
        )
    }

    func testRecommendationPairPromotionCandidatesDemoteLongColdStreaks() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 11,
                conversions: 9,
                opensSinceLastConversion: 20
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 1
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairPromotedActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ]
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testRecommendationPairRescueActionIDPrefersColdestHighConfidencePair() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 9
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 11,
                conversions: 8,
                opensSinceLastConversion: 14
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-alert",
                recommendedActionID: "run-fame-launch-control-brief",
                opportunities: 9,
                conversions: 7,
                opensSinceLastConversion: 14
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairRescueActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop",
                    "run-fame-launch-control-brief"
                ]
            ),
            "run-fame-cadence-autopilot-loop"
        )
    }

    func testRecommendationPairRescueActionIDRequiresColdHighConfidenceEnabledCandidate() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 3
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 10,
                conversions: 3,
                opensSinceLastConversion: 12
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-alert",
                recommendedActionID: "run-fame-launch-control-brief",
                opportunities: 11,
                conversions: 8,
                opensSinceLastConversion: 16
            )
        ]

        XCTAssertNil(
            CommandPaletteTopPicks.recommendationPairRescueActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ]
            )
        )
    }

    func testRecommendationPairRescueActionIDCanTuneColdThreshold() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 9
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 10,
                conversions: 8,
                opensSinceLastConversion: 12
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairRescueActionID(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ],
                minimumColdOpensSinceLastConversion: 10
            ),
            "run-fame-cadence-autopilot-loop"
        )
    }

    func testRecommendationPairRescuePlanIncludesProofAndStalenessMetrics() {
        let candidates = [
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-exceptional-loop",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 10,
                conversions: 8,
                opensSinceLastConversion: 13
            ),
            CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: "run-fame-launch-recovery-next",
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 10
            )
        ]

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairRescuePlan(
                candidates: candidates,
                enabledActionIDs: [
                    "run-fame-next-move-copy-drafts",
                    "run-fame-cadence-autopilot-loop"
                ]
            ),
            CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-next-move-copy-drafts",
                opportunities: 10,
                conversions: 8,
                opensSinceLastConversion: 13,
                conversionRatePercent: 80
            )
        )
    }

    func testRecommendationMomentumRescueImpactPulseFormatsRunIntentAndProof() {
        let pulse = CommandPaletteTopPicks.recommendationMomentumRescueImpactPulse(
            actionTitle: "Run Fame Cadence Autopilot Loop",
            currentStreak: 3,
            bestStreak: 5,
            rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 12,
                conversionRatePercent: 75
            )
        )

        XCTAssertEqual(pulse.title, "Rescue Attempt · Breakout")
        XCTAssertEqual(
            pulse.subtitle,
            "Running Run Fame Cadence Autopilot Loop · last win 12 opens ago"
        )
        XCTAssertEqual(pulse.systemImage, "sparkles")
        XCTAssertTrue(
            pulse.helpText.contains(
                "Rescue Now launched Run Fame Cadence Autopilot Loop to recover a cold high-confidence recommendation pair (6/8, 75% conversion, last win 12 opens ago)."
            )
        )
        XCTAssertTrue(
            pulse.helpText.contains("Rescue lane x3 · best x5.")
        )
    }

    func testRecommendationMomentumRescueFollowthroughCueHighlightsNewBestUpside() {
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueFollowthroughCue(
                actionTitle: "Run Fame Cadence Autopilot Loop",
                currentStreak: 3,
                bestStreak: 3,
                rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                    recommendedActionID: "run-fame-cadence-autopilot-loop",
                    opportunities: 8,
                    conversions: 6,
                    opensSinceLastConversion: 12,
                    conversionRatePercent: 75
                )
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueFollowthroughCue(
                title: "Rescue Upside · New Best",
                subtitle: "If Run Fame Cadence Autopilot Loop converts, lane reaches x4 (Breakout) and sets a new best x4.",
                systemImage: "trophy.fill",
                helpText: "Rescue attempt is live for Run Fame Cadence Autopilot Loop (6/8, 75% conversion, last win 12 opens ago). A conversion this open would move rescue lane to x4 and best x4."
            )
        )
    }

    func testRecommendationMomentumRescueFollowthroughCueCanFormatLegendPaceFallback() {
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueFollowthroughCue(
                actionTitle: "   ",
                currentStreak: 7,
                bestStreak: 9,
                rescuePlan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                    recommendedActionID: "run-fame-cadence-autopilot-loop",
                    opportunities: 12,
                    conversions: 10,
                    opensSinceLastConversion: 8,
                    conversionRatePercent: 83
                )
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueFollowthroughCue(
                title: "Rescue Upside · Legend Pace",
                subtitle: "If recommended rescue action converts, lane reaches x8 with legend pace locked.",
                systemImage: "crown.fill",
                helpText: "Rescue attempt is live for recommended rescue action (10/12, 83% conversion, last win 8 opens ago). A conversion this open would move rescue lane to x8 and best x9."
            )
        )
    }

    func testRecommendationMomentumRescueCelebrationCueFormatsNewBestCopy() {
        let cue = CommandPaletteTopPicks.recommendationMomentumRescueCelebrationCue(
            pulse: CommandPaletteSession.RecommendationMomentumRescuePulse(
                title: "Momentum Rescue x4",
                subtitle: "Recovered after 9 opens cold",
                systemImage: "sparkles",
                helpText: "Cold high-trust recommendation recovered (8/10). Rescue lane Breakout now at x4; next Fame at x5.",
                streak: 4,
                bestStreak: 4,
                tierTitle: "Breakout",
                didTierUpgrade: false,
                didSetNewBest: true
            )
        )

        XCTAssertEqual(
            cue,
            CommandPaletteTopPicks.RecommendationMomentumRescueCelebrationCue(
                title: "Rescue Landed · New Best x4",
                subtitle: "Lane reached Breakout with a new rescue best. Keep stacking this momentum.",
                systemImage: "trophy.fill",
                helpText: "Cold high-trust recommendation recovered (8/10). Rescue lane Breakout now at x4; next Fame at x5. Next target: Fame at x5."
            )
        )
    }

    func testRecommendationMomentumRescueCelebrationCueFormatsTierPromotionAndLegendFallback() {
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueCelebrationCue(
                pulse: CommandPaletteSession.RecommendationMomentumRescuePulse(
                    title: "Momentum Rescue x3",
                    subtitle: "Recovered after 7 opens cold",
                    systemImage: "sparkles",
                    helpText: "Cold high-trust recommendation recovered (6/8). Rescue lane Breakout now at x3; next Fame at x5.",
                    streak: 3,
                    bestStreak: 8,
                    tierTitle: "Breakout",
                    didTierUpgrade: true,
                    didSetNewBest: false
                )
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueCelebrationCue(
                title: "Rescue Landed · Breakout Tier Up",
                subtitle: "Lane promoted to Breakout at x3.",
                systemImage: "arrow.up.forward.circle.fill",
                helpText: "Cold high-trust recommendation recovered (6/8). Rescue lane Breakout now at x3; next Fame at x5. Next target: Fame at x5."
            )
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationMomentumRescueCelebrationCue(
                pulse: CommandPaletteSession.RecommendationMomentumRescuePulse(
                    title: "Momentum Rescue x9",
                    subtitle: "Recovered after 10 opens cold",
                    systemImage: "crown.fill",
                    helpText: "Cold high-trust recommendation recovered (9/11). Rescue lane Legend is locked at x9.",
                    streak: 9,
                    bestStreak: 12,
                    tierTitle: "Legend",
                    didTierUpgrade: false,
                    didSetNewBest: false
                )
            ),
            CommandPaletteTopPicks.RecommendationMomentumRescueCelebrationCue(
                title: "Rescue Landed · Legend",
                subtitle: "Lane stabilized at x9 (Legend).",
                systemImage: "crown.fill",
                helpText: "Cold high-trust recommendation recovered (9/11). Rescue lane Legend is locked at x9. Legend pace is locked."
            )
        )
    }

    func testRecommendationPairRescueConfidenceChipFormatsStrongProof() {
        let chip = CommandPaletteTopPicks.recommendationPairRescueConfidenceChip(
            plan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                recommendedActionID: "run-fame-cadence-autopilot-loop",
                opportunities: 8,
                conversions: 6,
                opensSinceLastConversion: 12,
                conversionRatePercent: 75
            )
        )

        XCTAssertEqual(
            chip,
            CommandPaletteTopPicks.RecommendationPairRescueConfidenceChip(
                tone: .strong,
                title: "Win Chance 75%",
                systemImage: "chart.line.uptrend.xyaxis",
                helpText: "Rescue proof High · 6/8 converted (75%). Last win 12 opens ago."
            )
        )
    }

    func testRecommendationPairRescueConfidenceChipCanSurfaceProvenAndWatchTones() {
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairRescueConfidenceChip(
                plan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                    recommendedActionID: "run-fame-cadence-autopilot-loop",
                    opportunities: 12,
                    conversions: 11,
                    opensSinceLastConversion: 8,
                    conversionRatePercent: 92
                )
            ),
            CommandPaletteTopPicks.RecommendationPairRescueConfidenceChip(
                tone: .proven,
                title: "Win Chance 92%",
                systemImage: "sparkles",
                helpText: "Rescue proof High · 11/12 converted (92%). Last win 8 opens ago."
            )
        )
        XCTAssertEqual(
            CommandPaletteTopPicks.recommendationPairRescueConfidenceChip(
                plan: CommandPaletteTopPicks.RecommendationPairRescuePlan(
                    recommendedActionID: "run-fame-cadence-autopilot-loop",
                    opportunities: 9,
                    conversions: 4,
                    opensSinceLastConversion: 1,
                    conversionRatePercent: 44
                )
            ),
            CommandPaletteTopPicks.RecommendationPairRescueConfidenceChip(
                tone: .watch,
                title: "Win Chance 44%",
                systemImage: "clock.badge.exclamationmark",
                helpText: "Rescue proof Medium · 4/9 converted (44%). Last win 1 open ago."
            )
        )
    }

    func testTopPicksIdleStateCanPrioritizeLaunchRecoveryNextCard() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-recovery-next",
                title: "Launch Recovery Next: Run First-Week Fame Scorecard (1 artifact left)",
                subtitle: "One-click launch recovery route · 1 artifact left · Next Run First-Week Fame Scorecard",
                systemImage: "checkmark.seal",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-alert",
                title: "Launch Countdown: T+18m",
                subtitle: "Urgency High (overdue by 18m) · Next: T+18m: Recover",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-recovery-next",
                "run-fame-launch-alert"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceLaunchRescueBurst() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-rescue-burst",
                title: "Run Launch Rescue Burst",
                subtitle: "Generate launch countdown + next-move handoff + recovery checklist",
                systemImage: "bolt.shield",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-operator-dashboard",
                title: "Run Fame Operator Dashboard",
                subtitle: "Generate operator dashboard",
                systemImage: "gauge.open.with.lines.needle.33percent",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-rescue-burst",
                "run-fame-operator-dashboard"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeLaunchThresholdAlertsUnmuteCard() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "unmute-fame-launch-threshold-alerts-now",
                title: "Launch Alert: Unmute Threshold Alerts",
                subtitle: "Urgency High (overdue by 18m) · HUD/flash launch alerts muted · unmute now",
                systemImage: "bell.slash.circle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-alert",
                title: "Launch Countdown: T+18m",
                subtitle: "Urgency High (overdue by 18m) · Next: T+18m: Recover",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "unmute-fame-launch-threshold-alerts-now",
                "run-fame-launch-alert"
            ]
        )
    }

    func testTopPicksIdleStateCanSurfaceRecommendedLaunchThresholdAlertsSnoozeCard() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "snooze-fame-launch-threshold-alerts-recommended",
                title: "Smart Snooze (Recommended 10m)",
                subtitle: "Urgency High (overdue by 18m) · quiet launch threshold alerts for 10m",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-alert",
                title: "Launch Countdown: T+18m",
                subtitle: "Urgency High (overdue by 18m) · Next: T+18m: Recover",
                systemImage: "exclamationmark.triangle.fill",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "snooze-fame-launch-threshold-alerts-recommended",
                "run-fame-launch-alert"
            ]
        )
    }

    func testTopPicksIdleStateCanPrioritizeSnoozeEndingSoonUnmuteReminderCard() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "unmute-fame-launch-threshold-alerts-snooze-ending-soon",
                title: "Launch Alert: Snooze Ends in 3m",
                subtitle: "Urgency Hot (overdue by 4m) · Threshold alerts auto-unmute in 3m · unmute now or smart snooze 30m · Why now: snooze ends in 3m and urgency is Hot",
                systemImage: "hourglass.circle.fill",
                run: {}
            ),
            CommandPaletteAction(
                id: "extend-fame-launch-threshold-alerts-snooze-ending-soon",
                title: "Launch Alert: Extend Snooze 30m",
                subtitle: "Urgency Hot (overdue by 4m) · 3m left · extend snooze by 30m now",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "snooze-fame-launch-threshold-alerts-recommended",
                title: "Smart Snooze (Recommended 30m)",
                subtitle: "Urgency Hot (overdue by 4m) · quiet launch threshold alerts for 30m",
                systemImage: "sparkles",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "unmute-fame-launch-threshold-alerts-snooze-ending-soon",
                "extend-fame-launch-threshold-alerts-snooze-ending-soon"
            ]
        )
    }

    func testTopPicksIdleStateCanDeprioritizeCooldownSnoozeReminderCards() {
        let actions = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Read from screen",
                systemImage: "lasso",
                run: {}
            ),
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Read selected text",
                systemImage: "text.cursor",
                run: {}
            ),
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask a one-off question",
                systemImage: "sparkles",
                run: {}
            ),
            CommandPaletteAction(
                id: "unmute-fame-launch-threshold-alerts-snooze-ending-soon",
                title: "Launch Alert: Snooze Ends in 3m",
                subtitle: "Urgency Hot (overdue by 4m) · Threshold alerts auto-unmute in 3m",
                systemImage: "hourglass.circle.fill",
                isEnabled: false,
                disabledReason: "Cooldown 2s",
                run: {}
            ),
            CommandPaletteAction(
                id: "extend-fame-launch-threshold-alerts-snooze-ending-soon",
                title: "Launch Alert: Extend Snooze 30m",
                subtitle: "Urgency Hot (overdue by 4m) · 3m left · extend snooze by 30m now",
                systemImage: "sparkles",
                isEnabled: false,
                disabledReason: "Cooldown 2s",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-launch-alert",
                title: "Launch Countdown: T+4m",
                subtitle: "Urgency Hot (overdue by 4m) · Next: T+4m: Recover",
                systemImage: "timer",
                run: {}
            ),
            CommandPaletteAction(
                id: "run-fame-next-move",
                title: "Run Fame Next Move",
                subtitle: "Autopilot move",
                systemImage: "paperplane",
                run: {}
            )
        ]
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false
        )

        XCTAssertEqual(
            CommandPaletteTopPicks.pickActions(from: actions, context: context, limit: 5).map(\.id),
            [
                "pick-and-read",
                "read-selected",
                "ask-anything",
                "run-fame-launch-alert",
                "run-fame-next-move"
            ]
        )
    }

    private func makeLaunchRecoveryLegendDecayAlertForecast(
        actionID: String = "run-fame-cadence-autopilot-loop"
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast {
        CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            tone: .alert,
            riskLabel: "High",
            nextDefenseMinutes: 0,
            nextDefenseLabel: "now",
            title: "Legend Decay Forecast",
            subtitle: "Risk High · est. tier slip ~14d · Next defense now",
            systemImage: "hourglass.badge.exclamationmark",
            helpText: "Auto Trust Surge is armed and ready.",
            actionID: actionID
        )
    }

    private func makeRecommendationMomentumRescueHallOfFameLegendRiskAlertForecast(
        actionID: String? = "run-fame-next-move-copy-drafts"
    ) -> CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecast {
        CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecast(
            tone: .alert,
            riskLabel: "High",
            nextDefenseMinutes: 0,
            nextDefenseLabel: "now",
            title: "Hall-of-Fame Legend Risk",
            subtitle: "Risk High · Defense League Drift -9 (Δ-9) · Next defense now",
            systemImage: "exclamationmark.shield.fill",
            helpText: "Hall-of-Fame auto-defense is armed and ready.",
            actionID: actionID
        )
    }

    private func makeLaunchRecoveryMomentumSnapshot(
        direction: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum.Direction,
        deltaPoints: Int,
        previousScore: Int,
        recentScore: Int,
        windowSize: Int = 4
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum {
        CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum(
            direction: direction,
            deltaPoints: deltaPoints,
            previousScore: previousScore,
            recentScore: recentScore,
            windowSize: windowSize,
            title: "momentum",
            systemImage: "sparkles",
            helpText: "momentum"
        )
    }

    private func makeLaunchRecoveryLegendDecayWatchForecast()
        -> CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast {
        CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            tone: .watch,
            riskLabel: "Watch",
            nextDefenseMinutes: 9,
            nextDefenseLabel: "in 9m (~11:29)",
            title: "Legend Stability Forecast",
            subtitle: "Risk Watch · 3w steady · Legend at 24 · Next defense in 9m (~11:29)",
            systemImage: "clock.arrow.circlepath",
            helpText: "Auto Trust Surge is cooling down.",
            actionID: nil
        )
    }

    private func makeRecommendationMomentumRescueHallOfFameLegendRiskWatchForecast(
        nextDefenseMinutes: Int = 9,
        nextDefenseLabel: String = "in 9m (~11:29)",
        actionID: String? = nil
    ) -> CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecast {
        CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecast(
            tone: .watch,
            riskLabel: "Watch",
            nextDefenseMinutes: nextDefenseMinutes,
            nextDefenseLabel: nextDefenseLabel,
            title: "Hall-of-Fame Legend Stability",
            subtitle: "Risk Watch · 3w steady · Legend at 24 · Next defense \(nextDefenseLabel)",
            systemImage: "clock.arrow.circlepath",
            helpText: "Hall-of-Fame auto-defense is armed and ready.",
            actionID: actionID
        )
    }

    private func makeLaunchRecoveryConfidenceScore(
        tier: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore.Tier,
        points: Int
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore {
        CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore(
            points: points,
            tier: tier,
            title: "Confidence \(points)",
            subtitle: "stub",
            systemImage: "sparkles",
            helpText: "stub"
        )
    }

    private func makeFameMomentumSelectionConfidence(
        tier: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidenceTier = .leaning,
        confidencePercent: Int = 55,
        gapPoints: Int
    ) -> CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence {
        CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence(
            tier: tier,
            confidencePercent: confidencePercent,
            gapPoints: gapPoints,
            title: "Selection Leaning",
            subtitle: "Gap \(gapPoints) · backup live",
            systemImage: "slider.horizontal.2.square",
            helpText: "Confidence snapshot."
        )
    }

    private func makeFameMomentumRouteStabilizationScoreboard(
        runs: Int,
        successes: Int,
        pendingRuns: Int
    ) -> CommandPaletteSession.FameMomentumPanelRouteStabilizationScoreboard {
        let normalizedRuns = max(0, runs)
        let normalizedSuccesses = max(0, min(normalizedRuns, successes))
        let normalizedPendingRuns = max(0, min(normalizedRuns, pendingRuns))
        let successRatePercent: Int
        if normalizedRuns > 0 {
            successRatePercent = Int(
                round((Double(normalizedSuccesses) / Double(normalizedRuns)) * 100)
            )
        } else {
            successRatePercent = 0
        }

        return CommandPaletteSession.FameMomentumPanelRouteStabilizationScoreboard(
            runs: normalizedRuns,
            successes: normalizedSuccesses,
            pendingRuns: normalizedPendingRuns,
            successRatePercent: successRatePercent,
            title: "Stabilizer \(successRatePercent)%",
            subtitle: "sample",
            systemImage: "shield",
            helpText: "sample"
        )
    }

    private func bestChannelLaunchPackPressureTrend(
        for session: CommandPaletteSession
    ) -> CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend {
        CommandPaletteTopPicks.bestChannelLaunchPackPressureTrend(
            opportunities: session.bestChannelLaunchPackPressureOpportunities,
            conversions: session.bestChannelLaunchPackPressureConversions,
            streak: session.bestChannelLaunchPackPressureConversionStreak,
            bestStreak: session.bestChannelLaunchPackPressureBestStreak
        )
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
