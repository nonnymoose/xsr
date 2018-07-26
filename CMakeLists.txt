cmake_minimum_required (VERSION 3.1.0)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

project (xsr)
# Use pthread
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

# Need libx11-dev
find_package(X11 REQUIRED)

# Need libpng-dev
find_package(PNG REQUIRED)
include_directories(${PNG_INCLUDE_DIRS})

add_executable (xsr arg_parser.cpp signal_handler.cpp main.cpp)
target_link_libraries (xsr Threads::Threads X11 PNG::PNG)
