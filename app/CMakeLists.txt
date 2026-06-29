cmake_minimum_required(VERSION 3.20)

project(demo_hasher VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(fmt CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)

add_library(demo_hasher_lib
    src/hasher.cpp
    src/encoder.cpp
    src/json_output.cpp
)

target_include_directories(demo_hasher_lib PUBLIC src)

target_link_libraries(demo_hasher_lib
    PUBLIC
        fmt::fmt
        nlohmann_json::nlohmann_json
        OpenSSL::SSL
        OpenSSL::Crypto
)

add_executable(demo-hasher src/main.cpp)

target_link_libraries(demo-hasher PRIVATE demo_hasher_lib)

enable_testing()
add_subdirectory(tests)
