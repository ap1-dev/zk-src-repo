find_package(Catch2 CONFIG REQUIRED)

add_executable(demo_hasher_tests
    test_hasher.cpp
    test_encoder.cpp
)

target_link_libraries(demo_hasher_tests
    PRIVATE
        demo_hasher_lib
        Catch2::Catch2WithMain
)

include(CTest)
include(Catch)
catch_discover_tests(demo_hasher_tests)
