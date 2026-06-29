#include "encoder.hpp"

#include <algorithm>
#include <cctype>

namespace demo {

std::string reverse_text(const std::string& input) {
    std::string output = input;
    std::reverse(output.begin(), output.end());
    return output;
}

std::string uppercase_text(const std::string& input) {
    std::string output = input;

    std::transform(
        output.begin(),
        output.end(),
        output.begin(),
        [](unsigned char c) {
            return static_cast<char>(std::toupper(c));
        }
    );

    return output;
}

}
