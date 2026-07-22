-- this is the first file executed when the application starts
-- we have to load the first modules form here

-- updater and services config
Services = {
    updater = "http://192.168.10.164:8000/api/updater.php",
    status = "http://192.168.10.164:8000/login.php",
    websites = "http://192.168.10.164:8000/?subtopic=accountmanagement",
    createAccount = "http://192.168.10.164:8000/clientcreateaccount.php",
    getCoinsUrl = "http://192.168.10.164:8000/?subtopic=shop&step=terms",
    clientAssets = {
        enabled = false, -- Desactivado para evitar descargas externas durante pruebas locales
        repository = "dudantas/tibia-client",
        installSounds = true,
        strictManifestSha256 = true,
        allowRawFallbackHashMismatch = false,
        allowMissingPackedRawFallback = true,
        preferArchive = true,
        fallbackToArchiveOnManifestFailure = false,
        installArchiveExtras = true,
        archiveExtraPrefixes = { "bin" },
        installPackagedFiles = true
    },
}

--- Enables or disables the entire server configuration block.
local ENABLE_SERVERS = true

Servers_init = {}

if ENABLE_SERVERS then
    Servers_init = {
        -- Servidor local apuntando a tu MyAAC (Protocolo 13.10)
        ["http://192.168.10.164:8000/login.php"] = {
            port = 8000,
            protocol = 1310,
            httpLogin = true,
            useAuthenticator = false
        }
    }
end

g_app.setName("Zephyr OT");
g_app.setCompactName("zephyrot");
g_app.setOrganizationName("zephyrot");

g_app.hasUpdater = function()
    return (Services.updater and Services.updater ~= "" and g_modules.getModule("updater"))
end

-- setup logger
g_logger.setLogFile(g_resources.getWorkDir() .. g_app.getCompactName() .. '.log')
g_logger.info("Operating system: " .. g_platform.getOSName())

-- print first terminal message
g_logger.info(g_app.getName() .. ' ' .. g_app.getVersion() .. ' rev ' .. g_app.getBuildRevision() .. ' (' ..
    g_app.getBuildCommit() .. ') built on ' .. g_app.getBuildDate() .. ' for arch ' ..
    g_app.getBuildArch())

-- setup lua debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
    g_logger.debug("Started LUA debugger.")
else
    g_logger.debug("LUA debugger not started (not launched with VSCode local-lua).")
end

-- add data directory to the search path
if not g_resources.addSearchPath(g_resources.getWorkDir() .. 'data', true) then
    g_logger.fatal('Unable to add data directory to the search path.')
end

-- add modules directory to the search path
if not g_resources.addSearchPath(g_resources.getWorkDir() .. 'modules', true) then
    g_logger.fatal('Unable to add modules directory to the search path.')
end

g_html.addGlobalStyle('/data/styles/html.css')
g_html.addGlobalStyle('/data/styles/custom.css')

-- try to add mods path too
g_resources.addSearchPath(g_resources.getWorkDir() .. 'mods', true)

-- setup directory for saving configurations
g_resources.setupUserWriteDir(('%s/'):format(g_app.getCompactName()))

-- search all packages
g_resources.searchAndAddPackages('/', '.otpkg', true)

-- load settings
g_configs.loadSettings('/config.otml')

g_modules.discoverModules()

-- libraries modules 0-99
g_modules.autoLoadModules(99)
g_modules.ensureModuleLoaded('corelib')
g_modules.ensureModuleLoaded('gamelib')
g_modules.ensureModuleLoaded('modulelib')
g_modules.ensureModuleLoaded("startup")

g_modules.autoLoadModules(999)
g_modules.ensureModuleLoaded('game_shaders') -- pre load

local function loadModules()
    -- client modules 100-499
    g_modules.autoLoadModules(499)
    g_modules.ensureModuleLoaded('client')

    -- game modules 500-999
    g_modules.autoLoadModules(999)
    g_modules.ensureModuleLoaded('game_interface')

    -- mods 1000-9999
    g_modules.autoLoadModules(9999)
    g_modules.ensureModuleLoaded('client_mods')

    local script = '/' .. g_app.getCompactName() .. 'rc.lua'

    if g_resources.fileExists(script) then
        dofile(script)
    end
end

-- run updater, must use data.zip
if g_app.hasUpdater() then
    g_modules.ensureModuleLoaded("updater")
    return Updater.init(loadModules)
end

loadModules()
