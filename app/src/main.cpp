#include "json_output.hpp"

#include <fmt/core.h>

#include <iostream>
#include <string>

int main(int argc, char** argv) {
    if (argc != 2) {
        fmt::print(stderr, "usage: demo-hasher <text>\n");
        return 1;
    }

    const std::string input = argv[1];
    std::cout << demo::build_json_output(input) << std::endl;

    return 0;
}
