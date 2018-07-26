//
//  base64 encoding and decoding with C++.
//  Version: 1.01.00
//

#ifndef BASE64_H_C0CE2A47_D10E_42C9_A27C_C883944E704A
#define BASE64_H_C0CE2A47_D10E_42C9_A27C_C883944E704A

#include <string>

// modification: change unsigned char const* bytes_to_encode to unsigned char* bytes_to_encode (not really good practice, but I don't feel like casting it!)

std::string base64_encode(unsigned char* , unsigned int len);
std::string base64_decode(std::string const& s);

#endif /* BASE64_H_C0CE2A47_D10E_42C9_A27C_C883944E704A */
