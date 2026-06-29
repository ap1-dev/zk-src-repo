#include "hasher.hpp"

#include <catch2/catch_test_macros.hpp>

TEST_CASE("sha256 of hello is stable", "[hasher]") {
    REQUIRE(
        demo::sha256_hex("hello") ==
        "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
    );
}
