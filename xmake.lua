-- 🔊 espeak-ng xmake build
-- Phoneme engine for speech synthesis

local espeak_root = os.scriptdir()
local data_path = path.join(espeak_root, "espeak-ng-data")

----------------------------------------------------------------------
-- 📦 espeak-ng — phoneme / TTS library (single static lib)
----------------------------------------------------------------------
target("espeak-ng")
    set_kind("static")
    set_languages("c11", "cxx11")

    -- Core library sources
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
        "src/libespeak-ng/espeak_api.c",
        "src/libespeak-ng/klatt.c",
        "src/libespeak-ng/sPlayer.c"
    )

    -- ucd (Unicode character database) — bundled
    add_files("src/ucd-tools/src/*.c")

    -- speechPlayer (formant synthesiser) — bundled
    add_files("src/speechPlayer/src/*.cpp")

    -- Include paths
    add_includedirs(".", { public = false })                  -- config.h
    add_includedirs("src/include", { public = true })         -- public API
    add_includedirs("src/ucd-tools/src/include", { public = false })
    add_includedirs("src/speechPlayer/include", { public = false })

    add_includedirs("src/include/compat", { public = false })

    -- Preprocessor
    add_defines("LIBESPEAK_NG_EXPORT=1", { public = true })
    add_defines('PATH_ESPEAK_DATA="' .. data_path .. '"')

    -- Linux needs _GNU_SOURCE for strdup, fileno, etc.
    if is_plat("linux") then
        add_defines("_GNU_SOURCE")
    end

    -- MSVC: suppress deprecated POSIX name warnings (strdup → _strdup etc.)
    if is_plat("windows") then
        add_defines("_CRT_NONSTDC_NO_WARNINGS", "_CRT_SECURE_NO_WARNINGS")
        add_syslinks("advapi32")
    end

    -- Suppress warnings in upstream code we don't own
    set_warnings("none")

    -- System libs
    if not is_plat("windows") then
        add_syslinks("m")
    end

    -- Public headers for install
    add_headerfiles("src/include/(espeak-ng/*.h)")
target_end()

----------------------------------------------------------------------
-- 🛠️  espeak-ng-bin — CLI tool (compiles phoneme data during build)
----------------------------------------------------------------------
target("espeak-ng-bin")
    set_kind("binary")
    set_languages("c11")
    set_basename("espeak-ng-cli")
    add_files("src/espeak-ng.c")
    add_includedirs(".", "src/include", "src/include/compat")
    add_defines("LIBESPEAK_NG_EXPORT=1")
    add_deps("espeak-ng")

    -- Windows: getopt implementation + registry API
    if is_plat("windows") then
        add_files("src/compat/getopt.c")
        add_defines("_CRT_NONSTDC_NO_WARNINGS", "_CRT_SECURE_NO_WARNINGS")
        set_warnings("none")
    end

    -- After building the binary, compile the phoneme data & dictionaries
    after_build(function (target)
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

        print("  📝 Compiling intonations...")
        os.cd(phsource_dir)
        os.vrunv(espeak_bin, {"--compile-intonations"})

        print("  📝 Compiling phonemes...")
        os.vrunv(espeak_bin, {"--compile-phonemes"})

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
