// windows/runner/yawala_native_stub.h - Safe-fallback response table for the
// Yawala Files method channel on the Windows runner.
//
// The Dart-side NativeChannelGateway already degrades every invocation to a
// safe fallback; this table lets the generated Windows runner answer with
// identical payloads once flutter_window.cpp registers a
// flutter::MethodChannel backed by yawala_stub::responseFor().
#pragma once

#include <string>

namespace yawala_stub {

inline const char* kFilesChannelName = "com.yawalasiwala/files";

/// Returns the stubbed JSON payload for [method] (StandardMethodCodec
/// encoding) on the files channel.
inline std::string responseFor(const std::string& method) {
  if (method == "pickFiles" || method == "pickDirectory") {
    return "null";
  }
  if (method == "listStorageVolumes") {
    return "[{\"name\":\"Stub volume\",\"rootPath\":\"/\","
           "\"isRemovable\":false,\"freeBytes\":0,\"totalBytes\":0}]";
  }
  if (method == "requestDirectoryAccess") {
    return "\"unsupported\"";
  }
  return "null";
}

}  // namespace yawala_stub
