cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "welmi")
set(APPLICATION_ID "com.example.welmi")

cmake_policy(SET CMP0063 NEW)

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

# Include the flutter library and its dependencies.
include("${FLUTTER_MANAGED_DIR}/generated_plugins.cmake")

# Flutter execution environment.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Define the build target.
add_executable(${BINARY_NAME}
  "runner/main.cc"
  "runner/my_application.cc"
  "runner/utils.cc"
  ${FLUTTER_MANAGED_SOURCES}
)

# Apply configurations to the target.
apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_TARGET_CANONICAL_PATH=\"${CMAKE_SOURCE_DIR}/lib/main.dart\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "VERSION_AS_NUMBER=${FLUTTER_VERSION_MAJOR}.${FLUTTER_VERSION_MINOR}.${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "VERSION_AS_STRING=\"${FLUTTER_VERSION}\"")
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE "${FLUTTER_LIBRARY}")
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
add_dependencies(${BINARY_NAME} flutter_assemble)

# Extract generated plugin targets.
foreach(plugin ${FLUTTER_MANAGED_PLUGINS})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin})
endforeach()
