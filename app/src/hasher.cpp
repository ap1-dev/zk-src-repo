#include "hasher.hpp"

#include <openssl/sha.h>

#include <iomanip>
#include <sstream>

namespace demo {

std::string sha256_hex(const std::string& input) {
    unsigned char hash[SHA256_DIGEST_LENGTH];

    SHA256(
        reinterpret_cast<const unsigned char*>(input.data()),
        input.size(),
        hash
    );

    std::ostringstream output;
    for (unsigned char byte : hash) {
        output << std::hex << std::setw(2) << std::setfill('0')
               << static_cast<int>(byte);
    }

    return output.str();
}

}
