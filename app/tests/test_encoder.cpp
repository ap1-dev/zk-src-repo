#include "encoder.hpp"

#include <catch2/catch_test_macros.hpp>

TEST_CASE("reverse_text reverses input", "[encoder]") {
    REQUIRE(demo::reverse_text("sovereign") == "ngierevos");
}

TEST_CASE("uppercase_text uppercases input", "[encoder]") {
    REQUIRE(demo::uppercase_text("zk-cicd") == "ZK-CICD");
}
