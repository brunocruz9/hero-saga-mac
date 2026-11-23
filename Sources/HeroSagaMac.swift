// Hero Saga para Mac — launcher que roda o cliente Windows via WineCX (open-source, LGPL).
import SwiftUI
import AppKit

// MARK: - Modelo de opções

struct GameOptions: Codable, Equatable {
    var width = 1024
    var height = 768
    var fullscreen = true
    var spriteQuality = 0      // 0 baixa, 1 média, 2 alta
    var textureQuality = 0
    var trilinear = false
    var minEffects = true
    var aura = false
    var fog = false
    var lightmap = false
    var screenShake = false
    var weather = false
    var fpsLimit = 60
    var vsync = false

    static let performance = GameOptions()
    static let balanced = GameOptions(width: 1280, height: 800, fullscreen: true, spriteQuality: 1, textureQuality: 1,
                                      trilinear: false, minEffects: false, aura: true, fog: false, lightmap: false,
                                      screenShake: true, weather: false, fpsLimit: 60, vsync: false)
    static let quality = GameOptions(width: 1440, height: 900, fullscreen: true, spriteQuality: 2, textureQuality: 2,
                                     trilinear: true, minEffects: false, aura: true, fog: true, lightmap: true,
                                     screenShake: true, weather: true, fpsLimit: 75, vsync: false)
}

enum Preset: String, Codable, CaseIterable, Identifiable {
    case performance = "Desempenho", balanced = "Equilíbrio", quality = "Qualidade", custom = "Personalizado"
    var id: String { rawValue }
    var options: GameOptions? {
        switch self {
        case .performance: return .performance
        case .balanced: return .balanced
        case .quality: return .quality
        case .custom: return nil
        }
    }
}

struct AppConfig: Codable {
    var gamePath: String = ""
    var preset: Preset = .performance
    var options: GameOptions = .performance
    var quickLaunch: Bool? = false   // abrir o jogo direto, sem mostrar a janela (segure Option para ver)
}

// MARK: - Informações do Mac

struct MacInfo {
    let chip: String
    let isAppleSilicon: Bool
    let memoryGB: Int
    let screen: String

    static func detect() -> MacInfo {
        func sysctlString(_ name: String) -> String {
            var size = 0
            sysctlbyname(name, nil, &size, nil, 0)
            guard size > 0 else { return "" }
            var buf = [CChar](repeating: 0, count: size)
            sysctlbyname(name, &buf, &size, nil, 0)
            return String(cString: buf)
        }
        var mem: UInt64 = 0
        var memSize = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &mem, &memSize, nil, 0)
        var arm: Int32 = 0
        var armSize = MemoryLayout<Int32>.size
        sysctlbyname("hw.optional.arm64", &arm, &armSize, nil, 0)
        var screen = "?"
        if let s = NSScreen.main {
            screen = "\(Int(s.frame.width))x\(Int(s.frame.height))"
        }
        return MacInfo(chip: sysctlString("machdep.cpu.brand_string"), isAppleSilicon: arm == 1,
                       memoryGB: Int(mem / 1_073_741_824), screen: screen)
    }

    var recommended: Preset {
        guard isAppleSilicon else { return .performance }             // Macs Intel: vídeo integrado fraco
        let c = chip
        if c.contains("M1") && !(c.contains("Pro") || c.contains("Max") || c.contains("Ultra")) { return .performance }
        if c.contains("M1") || c.contains("M2") { return .balanced }
        if memoryGB < 16 { return .balanced }
        return .quality                                               // M3, M4 e superiores
    }

    var summary: String {
        "\(chip.isEmpty ? "Mac" : chip) · \(memoryGB) GB · tela \(screen)"
    }
}

// MARK: - Motor (Wine) e jogo

final class Engine: ObservableObject {
    @Published var status = ""
    @Published var running = false
    @Published var busy = false
    @Published var showAdvanced = false
    @Published var config = AppConfig()

    let mac = MacInfo.detect()
    let support: URL
    let prefix: URL
    let engineDir: URL
    var process: Process?

    init() {
        support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HeroSagaMac")
        prefix = support.appendingPathComponent("prefix")
        engineDir = Bundle.main.resourceURL!.appendingPathComponent("engine")
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        load()
        if config.gamePath.isEmpty {
            let guess = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads/Hero Saga v1.7").path
            if FileManager.default.fileExists(atPath: guess + "/Hero.exe") { config.gamePath = guess }
            config.preset = mac.recommended
            config.options = mac.recommended.options ?? .performance
            save()
        }
        status = gameFound ? "Pronto para jogar." : "Escolha a pasta do Hero Saga para começar."
        if config.quickLaunch == true && gameFound && !NSEvent.modifierFlags.contains(.option) {
            quitWhenGameCloses = true
            DispatchQueue.main.async {
                NSApp.windows.forEach { $0.miniaturize(nil) }
                self.play()
            }
        }
    }

    var quitWhenGameCloses = false

    var configURL: URL { support.appendingPathComponent("config.json") }
    var wine: URL { engineDir.appendingPathComponent("wswine.bundle/bin/wine") }
    var gameFound: Bool { FileManager.default.fileExists(atPath: config.gamePath + "/Hero.exe") }

    func load() {
        if let d = try? Data(contentsOf: configURL), let c = try? JSONDecoder().decode(AppConfig.self, from: d) { config = c }
    }
    func save() {
        if let d = try? JSONEncoder().encode(config) { try? d.write(to: configURL) }
    }

    var env: [String: String] {
        var e = ProcessInfo.processInfo.environment
        e["WINEPREFIX"] = prefix.path
        e["WINEDEBUG"] = "-all"
        e["WINEMSYNC"] = "1"
        e["WINEDLLOVERRIDES"] = "mscoree,mshtml="
        e["DYLD_FALLBACK_LIBRARY_PATH"] = engineDir.path + ":/usr/lib"
        return e
    }

    @discardableResult
    func runWine(_ args: [String], cwd: String? = nil, wait: Bool = true) -> Process? {
        let p = Process()
        p.executableURL = wine
        p.arguments = args
        p.environment = env
        if let cwd { p.currentDirectoryURL = URL(fileURLWithPath: cwd) }
        let logURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/HeroSagaMac.log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        if let h = try? FileHandle(forWritingTo: logURL) { h.seekToEndOfFile(); p.standardOutput = h; p.standardError = h }
        do { try p.run() } catch { DispatchQueue.main.async { self.status = "Erro ao iniciar o Wine: \(error.localizedDescription)" }; return nil }
        if wait { p.waitUntilExit() }
        return p
    }

    var gameAlreadyOpen: Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        p.arguments = ["-f", "Hero\\.exe"]
        p.standardOutput = FileHandle.nullDevice
        try? p.run(); p.waitUntilExit()
        return p.terminationStatus == 0
    }

    var rosettaReady: Bool {
        if !mac.isAppleSilicon { return true }
        return FileManager.default.fileExists(atPath: "/Library/Apple/usr/libexec/oah/libRosettaRuntime")
    }

    /// Cria a garrafa e aplica as correções descobertas para o Hero Saga.
    func ensurePrefix() {
        let mark = prefix.appendingPathComponent(".herosaga-ok")
        if FileManager.default.fileExists(atPath: mark.path) { return }
        setStatus("Preparando o ambiente Windows (só na primeira vez, ~1 min)...")
        runWine(["wineboot", "-i"])
        // Sem estas chaves o Hero.exe abre o Setup.exe toda vez.
        runWine(["reg", "add", "HKCU\\Software\\Gravity Soft\\RenewSetup", "/f"])
        runWine(["reg", "add", "HKLM\\Software\\Gravity Soft\\RenewSetup", "/f", "/reg:32"])
        runWine(["reg", "add", "HKLM\\Software\\Gravity Soft\\Ragnarok", "/f", "/reg:32"])
        FileManager.default.createFile(atPath: mark.path, contents: nil)
    }

    func setStatus(_ s: String) { DispatchQueue.main.async { self.status = s } }

    // MARK: Configurações do jogo

    func applyOptions() throws {
        let o = config.options
        let save = config.gamePath + "/savedata"
        let lua = save + "/OptionInfo.lua"
        let ini = save + "/HeroOptions.ini"
        try? FileManager.default.createDirectory(atPath: save, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: lua) && !FileManager.default.fileExists(atPath: lua + ".original") {
            try? FileManager.default.copyItem(atPath: lua, toPath: lua + ".original")
        }
        var text = (try? String(contentsOfFile: lua, encoding: .utf8)) ?? ""
        func setLua(_ table: String, _ key: String, _ value: String) {
            let prefixStr = "\(table)[\"\(key)\"] = "
            var lines = text.components(separatedBy: "\n")
            if let i = lines.firstIndex(where: { $0.hasPrefix(prefixStr) }) { lines[i] = prefixStr + value }
            else { lines.insert(prefixStr + value, at: max(lines.count - 1, 0)) }
            text = lines.joined(separator: "\n")
        }
        let b = { (v: Bool) in v ? "1" : "0" }
        setLua("OptionInfoList", "RENDERSYSTEM", "2")          // DirectX 9 (o modo DX12 trava no Mac)
        setLua("OptionInfoList", "ISFULLSCREENMODE", b(o.fullscreen))
        setLua("OptionInfoList", "WIDTH", "\(o.width)")
        setLua("OptionInfoList", "HEIGHT", "\(o.height)")
        setLua("OptionInfoList", "OLD_WIDTH", "\(o.width)")
        setLua("OptionInfoList", "OLD_HEIGHT", "\(o.height)")
        setLua("OptionInfoList", "SPRITEMODE", "\(o.spriteQuality)")
        setLua("OptionInfoList", "TEXTUREMODE", "\(o.textureQuality)")
        setLua("OptionInfoList", "Trilinear", b(o.trilinear))
        setLua("OptionInfoList", "Window_XPos", "40")
        setLua("OptionInfoList", "Window_YPos", "40")
        setLua("CmdOnOffList", "/mineffect", b(o.minEffects))
        setLua("CmdOnOffList", "/aura", b(o.aura))
        setLua("CmdOnOffList", "/aura2", b(o.aura))
        setLua("CmdOnOffList", "/fog", b(o.fog))
        setLua("CmdOnOffList", "/lightmap", b(o.lightmap))
        setLua("CmdOnOffList", "/quake", b(o.screenShake))
        try text.write(toFile: lua, atomically: true, encoding: .utf8)

        var iniText = (try? String(contentsOfFile: ini, encoding: .utf8)) ?? "[Hero]\n"
        func setIni(_ key: String, _ value: String) {
            var lines = iniText.components(separatedBy: "\n")
            if let i = lines.firstIndex(where: { $0.hasPrefix(key + "=") }) { lines[i] = "\(key)=\(value)" }
            else if let h = lines.firstIndex(of: "[Hero]") { lines.insert("\(key)=\(value)", at: h + 1) }
            else { lines.insert(contentsOf: ["[Hero]", "\(key)=\(value)"], at: 0) }
            iniText = lines.joined(separator: "\n")
        }
        setIni("weather_rain", b(o.weather))
        setIni("weather_clouds", b(o.weather))
        setIni("shake", b(o.screenShake))
        setIni("vsync", b(o.vsync))
        setIni("fps_limit", "\(o.fpsLimit)")
        try iniText.write(toFile: ini, atomically: true, encoding: .utf8)
    }

    // MARK: Ações

    func play() {
        guard gameFound, !running else { return }
        if gameAlreadyOpen {
            status = "O Hero Saga já está aberto. Feche-o antes de abrir de novo."
            return
        }
        guard rosettaReady else {
            status = "Instale o Rosetta: abra o Terminal e rode  softwareupdate --install-rosetta"
            return
        }
        busy = true
        save()
        DispatchQueue.global().async {
            self.ensurePrefix()
            do { try self.applyOptions() } catch { self.setStatus("Não consegui salvar as opções: \(error.localizedDescription)") }
            self.setStatus("Abrindo o Hero Saga...")
            guard let p = self.runWine(["Hero.exe"], cwd: self.config.gamePath, wait: false) else {
                DispatchQueue.main.async { self.busy = false }; return
            }
            DispatchQueue.main.async { self.process = p; self.running = true; self.busy = false
                self.status = "Jogo aberto. Para trocar opções, saia do jogo pelo menu." }
            p.waitUntilExit()
            DispatchQueue.main.async { self.running = false; self.process = nil
                self.status = "Jogo fechado. Dica: se aparecer \"Recusado pelo servidor\", espere 5 minutos."
                if self.quitWhenGameCloses { NSApp.terminate(nil) } }
        }
    }

    func runUpdater() {
        guard gameFound, !running else { return }
        busy = true
        DispatchQueue.global().async {
            self.ensurePrefix()
            self.setStatus("Atualizador aberto...")
            self.runWine(["Atualizador Hero Saga.exe"], cwd: self.config.gamePath)
            DispatchQueue.main.async { self.busy = false; self.status = "Atualização concluída." }
        }
    }

    func repair() {
        guard !running else { return }
        busy = true
        DispatchQueue.global().async {
            self.runWine(["wineboot", "-k"])
            try? FileManager.default.removeItem(at: self.prefix)
            self.ensurePrefix()
            DispatchQueue.main.async { self.busy = false; self.status = "Ambiente recriado. Pronto para jogar." }
        }
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Selecione a pasta do Hero Saga (a que contém Hero.exe)"
        if panel.runModal() == .OK, let url = panel.url {
            config.gamePath = url.path
            save()
            status = gameFound ? "Pasta do jogo encontrada. Pronto para jogar." : "Hero.exe não está nessa pasta."
        }
    }
}

// MARK: - Interface

struct ContentView: View {
    @StateObject var engine = Engine()


    let resolutions: [(Int, Int)] = [(1024, 768), (1280, 720), (1280, 800), (1440, 900), (1600, 900), (1920, 1080)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Hero Saga").font(.system(size: 28, weight: .bold))
                Text("para Mac").font(.title3).foregroundStyle(.secondary)
                Spacer()
            }
            Text(engine.mac.summary).font(.callout).foregroundStyle(.secondary)

            GroupBox {
                HStack {
                    Image(systemName: engine.gameFound ? "checkmark.circle.fill" : "folder.badge.questionmark")
                        .foregroundStyle(engine.gameFound ? .green : .orange)
                    Text(engine.gameFound ? engine.config.gamePath : "Pasta do jogo não definida")
                        .lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button("Escolher pasta…") { engine.chooseFolder() }
                }.padding(4)
            }

            GroupBox("Qualidade gráfica") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("", selection: Binding(get: { engine.config.preset }, set: { p in
                        engine.config.preset = p
                        if let o = p.options { engine.config.options = o } else { engine.showAdvanced = true }
                        engine.save()
                    })) {
                        ForEach(Preset.allCases) { p in
                            Text(p == engine.mac.recommended ? "\(p.rawValue) ★" : p.rawValue).tag(p)
                        }
                    }.pickerStyle(.segmented).labelsHidden()
                    Text("★ recomendado para o seu Mac").font(.caption).foregroundStyle(.secondary)

                    DisclosureGroup("Opções avançadas", isExpanded: $engine.showAdvanced) {
                        advanced.padding(.top, 6)
                    }
                }.padding(4)
            }

            HStack(spacing: 10) {
                Button {
                    engine.play()
                } label: {
                    Label(engine.running ? "Jogando…" : "Jogar", systemImage: "play.fill")
                        .frame(minWidth: 140).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(!engine.gameFound || engine.running || engine.busy)
                .keyboardShortcut(.defaultAction)

                Button("Atualizar jogo") { engine.runUpdater() }
                    .disabled(!engine.gameFound || engine.running || engine.busy)
                Button("Reparar") { engine.repair() }
                    .disabled(engine.running || engine.busy)
                Spacer()
                if engine.busy { ProgressView().controlSize(.small) }
            }

            Toggle("Abrir o jogo direto nas próximas vezes (segure Option ao abrir para ver esta janela)",
                   isOn: Binding(get: { engine.config.quickLaunch == true },
                                 set: { engine.config.quickLaunch = $0; engine.save() }))
                .font(.callout)

            Text(engine.status).font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .frame(width: 560)
    }

    var opt: Binding<GameOptions> {
        Binding(get: { engine.config.options }, set: { if engine.config.options != $0 { engine.config.options = $0; engine.config.preset = .custom; engine.save() } })
    }

    var advanced: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            GridRow {
                Text("Resolução")
                Picker("", selection: Binding(get: { "\(opt.wrappedValue.width)x\(opt.wrappedValue.height)" }, set: { v in
                    let parts = v.split(separator: "x").compactMap { Int($0) }
                    if parts.count == 2 { opt.wrappedValue.width = parts[0]; opt.wrappedValue.height = parts[1] }
                })) {
                    ForEach(resolutions.map { "\($0.0)x\($0.1)" }, id: \.self) { key in let r = key.split(separator: "x").map { String($0) }; Text("\(r[0]) × \(r[1])").tag(key) }
                }.labelsHidden().frame(width: 160)
            }
            GridRow { Text("Tela cheia"); Toggle("", isOn: opt.fullscreen).labelsHidden() }
            GridRow {
                Text("Sprites")
                Picker("", selection: opt.spriteQuality) { Text("Baixa").tag(0); Text("Média").tag(1); Text("Alta").tag(2) }
                    .pickerStyle(.segmented).labelsHidden().frame(width: 220)
            }
            GridRow {
                Text("Texturas")
                Picker("", selection: opt.textureQuality) { Text("Baixa").tag(0); Text("Média").tag(1); Text("Alta").tag(2) }
                    .pickerStyle(.segmented).labelsHidden().frame(width: 220)
            }
            GridRow {
                Text("Limite de FPS")
                Picker("", selection: opt.fpsLimit) { ForEach([30, 60, 75, 120], id: \.self) { Text("\($0)").tag($0) } }
                    .pickerStyle(.segmented).labelsHidden().frame(width: 220)
            }
            GridRow {
                Text("Efeitos")
                HStack {
                    Toggle("Mínimos", isOn: opt.minEffects)
                    Toggle("Aura", isOn: opt.aura)
                    Toggle("Tremor", isOn: opt.screenShake)
                }
            }
            GridRow {
                Text("Ambiente")
                HStack {
                    Toggle("Clima", isOn: opt.weather)
                    Toggle("Neblina", isOn: opt.fog)
                    Toggle("Lightmap", isOn: opt.lightmap)
                }
            }
            GridRow {
                Text("Imagem")
                HStack {
                    Toggle("Filtro trilinear", isOn: opt.trilinear)
                    Toggle("V-Sync", isOn: opt.vsync)
                }
            }
        }
    }
}

@main
struct HeroSagaMacApp: App {
    var body: some Scene {
        WindowGroup("Hero Saga para Mac") { ContentView() }
            .windowResizability(.contentSize)
    }
}
