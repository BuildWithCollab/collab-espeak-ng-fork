#include <catch2/catch_test_macros.hpp>

#include <espeak-ng/speak_lib.h>

#include <string>

TEST_CASE("smoke: espeak_Info returns version", "[smoke]") {
    const char* version = espeak_Info(NULL);
    REQUIRE(version != NULL);
    CHECK(std::string(version).find("1.52") != std::string::npos);
}
