-- 🔊 espeak-ng xmake build
-- Phoneme engine for speech synthesis

-- Anchor all paths to THIS file's directory so includes() from other repos work correctly
local espeak_root = path.directory(os.scriptdir())
-- If this file IS at the repo root, os.scriptdir() is already correct
if os.isdir(path.join(os.scriptdir(), "src")) then
    espeak_root = os.scriptdir()
end

-- Where espeak-ng-data lives at runtime.
-- Consumers can override this by passing their own path to espeak_ng_InitializePath().
local data_path = path.join(espeak_root, "espeak-ng-data")

----------------------------------------------------------------------
-- 📦 ucd — Unicode character database helpers
----------------------------------------------------------------------
target("ucd")
    set_kind("static")
    set_languages("c11")
    add_files("src/ucd-tools/src/*.c")
    add_includedirs("src/ucd-tools/src/include", { public = true })
target_end()

----------------------------------------------------------------------
-- 📦 speechPlayer — formant speech synthesiser (C++)
----------------------------------------------------------------------
target("speechPlayer")
    set_kind("static")
    set_languages("cxx11")
    add_files("src/speechPlayer/src/*.cpp")
    add_includedirs("src/speechPlayer/include", { public = true })
target_end()

----------------------------------------------------------------------
-- 📦 espeak-ng — the main phoneme / TTS library
----------------------------------------------------------------------
target("espeak-ng")
    set_kind("static")
    set_languages("c11")

    -- Core sources (always compiled)
    add_files(
        "src/libespeak-ng/common.c",
        "src/libespeak-ng/mnemonics.c",
        "src/libespeak-ng/error.c",
        "src/libespeak-ng/ieee80.c",
        "src/libespeak-ng/compiledata.c",
        "src/libespeak-ng/compiledict.c",
        "src/libespeak-ng/dictionary.c",
        "src/libespeak-ng/encoding.c",
        "src/libespeak-ng/intonation.c",
        "src/libespeak-ng/langopts.c",
        "src/libespeak-ng/numbers.c",
        "src/libespeak-ng/phoneme.c",
        "src/libespeak-ng/phonemelist.c",
        "src/libespeak-ng/readclause.c",
        "src/libespeak-ng/setlengths.c",
        "src/libespeak-ng/soundicon.c",
        "src/libespeak-ng/spect.c",
        "src/libespeak-ng/ssml.c",
        "src/libespeak-ng/synthdata.c",
        "src/libespeak-ng/synthesize.c",
        "src/libespeak-ng/tr_languages.c",
        "src/libespeak-ng/translate.c",
        "src/libespeak-ng/translateword.c",
        "src/libespeak-ng/voices.c",
        "src/libespeak-ng/wavegen.c",
        "src/libespeak-ng/speech.c",
        "src/libespeak-ng/espeak_api.c"
    )

    -- Klatt formant synthesis (USE_KLATT=1)
    add_files("src/libespeak-ng/klatt.c")

    -- SpeechPlayer bridge (USE_SPEECHPLAYER=1)
    add_files("src/libespeak-ng/sPlayer.c")

    -- Include paths
    add_includedirs(".", { public = false })               -- config.h lives here
    add_includedirs("src/include", { public = true })      -- public API headers
    add_includedirs("src/include/compat", { public = false })

    -- Preprocessor
    add_defines("LIBESPEAK_NG_EXPORT=1", { public = true })
    add_defines('PATH_ESPEAK_DATA="' .. data_path .. '"')

    -- Dependencies
    add_deps("ucd", "speechPlayer")
    add_links("m")
target_end()

----------------------------------------------------------------------
-- 🛠️  espeak-ng-bin — CLI tool (used to compile phoneme data)
----------------------------------------------------------------------
target("espeak-ng-bin")
    set_kind("binary")
    set_languages("c11")
    set_filename("espeak-ng")
    add_files("src/espeak-ng.c")
    add_includedirs(".", "src/include", "src/include/compat")
    add_defines("LIBESPEAK_NG_EXPORT=1")
    add_deps("espeak-ng")

    -- After building the binary, compile the phoneme data & dictionaries
    after_build(function (target)
        -- 🐛 Must use absolute path — cd changes cwd and relative targetfile() breaks
        local espeak_bin = path.absolute(target:targetfile())
        local data_dir = path.join(espeak_root, "espeak-ng-data")
        local phsource_dir = path.join(espeak_root, "phsource")
        local dictsource_dir = path.join(espeak_root, "dictsource")

        -- Only compile data if phondata doesn't exist yet
        if os.isfile(path.join(data_dir, "phondata")) then
            print("✅ espeak-ng data already compiled, skipping")
            return
        end

        print("🔨 Compiling espeak-ng phoneme data...")
        os.setenv("ESPEAK_DATA_PATH", espeak_root)
        local olddir = os.curdir()

        -- 1. Compile intonations
        print("  📝 Compiling intonations...")
        os.cd(phsource_dir)
        os.vrunv(espeak_bin, {"--compile-intonations"})

        -- 2. Compile phonemes
        print("  📝 Compiling phonemes...")
        os.vrunv(espeak_bin, {"--compile-phonemes"})

        -- 3. Compile dictionaries (just English for now — others on demand)
        local dicts = { "en" }
        os.cd(dictsource_dir)
        for _, lang in ipairs(dicts) do
            print("  📝 Compiling dictionary: " .. lang)
            os.vrunv(espeak_bin, {"--compile=" .. lang})
        end

        os.cd(olddir)

        print("✅ espeak-ng data compiled!")
    end)
target_end()
