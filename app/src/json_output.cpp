#include "json_output.hpp"

#include "encoder.hpp"
#include "hasher.hpp"

#include <nlohmann/json.hpp>

namespace demo {

std::string build_json_output(const std::string& input) {
    nlohmann::json output = {
        {"app", "demo-hasher"},
        {"input", input},
        {"sha256", sha256_hex(input)},
        {"reverse", reverse_text(input)},
        {"uppercase", uppercase_text(input)}
    };

    return output.dump();
}

}
