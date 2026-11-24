# Builds FragUnlock.dylib for arm64 iOS.
# - On macOS: uses Xcode's xcrun to find clang + the iPhoneOS SDK.
# - On Linux (CI): uses $THEOS/toolchain/linux/iphone + $THEOS/sdks/$SDK_NAME.

NAME       := FragUnlock
OUT        := $(NAME).dylib
MIN_IOS    := 14.0

SRCS       := Tweak.mm ModMenu.mm StoreKitHooks.mm UnityBridge.mm ReceiptForge.mm JailbreakScrub.mm
OBJS       := $(SRCS:.mm=.o)

# ---- Toolchain selection ---------------------------------------------------

ifneq ($(THEOS),)
  # Linux cross-compile via theos
  ifeq ($(SDK_NAME),)
    SDK_NAME := $(shell ls $(THEOS)/sdks 2>/dev/null | grep -E '^iPhoneOS[0-9.]+\.sdk$$' | sort -V | tail -1)
  endif
  SDK      := $(THEOS)/sdks/$(SDK_NAME)
  BIN      := $(THEOS)/toolchain/linux/iphone/bin
  CXX      := $(BIN)/clang++
  STRIP    := $(BIN)/strip
  EXTRA    := -stdlib=libc++ -F$(SDK)/System/Library/Frameworks
else ifneq ($(shell uname -s 2>/dev/null),Darwin)
  $(error No toolchain: on Linux set THEOS=/path/to/theos; on Windows use the CI workflow)
else
  SDK      := $(shell xcrun --sdk iphoneos --show-sdk-path)
  CXX      := $(shell xcrun --sdk iphoneos -f clang++)
  STRIP    := $(shell xcrun --sdk iphoneos -f strip)
  EXTRA    :=
endif

# ---- Flags -----------------------------------------------------------------

FRAMEWORKS := -framework UIKit -framework Foundation -framework StoreKit \
              -framework QuartzCore -framework CoreGraphics -framework Security

CFLAGS     := -isysroot $(SDK) -target arm64-apple-ios$(MIN_IOS) \
              -O2 -fobjc-arc -fmodules -fno-common -fvisibility=hidden \
              -Wno-deprecated-declarations -Wno-unused-function $(EXTRA)

LDFLAGS    := -dynamiclib -isysroot $(SDK) -target arm64-apple-ios$(MIN_IOS) \
              -install_name @executable_path/Frameworks/$(OUT) \
              $(FRAMEWORKS) -Xlinker -dead_strip $(EXTRA)

ifeq ($(V),1)
  Q :=
else
  Q := @
endif

.PHONY: all clean info
all: $(OUT)

info:
	@echo "== toolchain =="
	@echo "SDK_NAME = $(SDK_NAME)"
	@echo "SDK      = $(SDK)"
	@echo "CXX      = $(CXX)"
	@echo "STRIP    = $(STRIP)"
	@echo "CFLAGS   = $(CFLAGS)"
	@echo "LDFLAGS  = $(LDFLAGS)"
	@test -d "$(SDK)" || (echo "ERROR: SDK not found at $(SDK)" && exit 1)
	@test -x "$(CXX)" || (echo "ERROR: CXX not executable at $(CXX)" && exit 1)

%.o: %.mm
	$(Q)$(CXX) $(CFLAGS) -c $< -o $@

$(OUT): $(OBJS)
	$(Q)$(CXX) $(LDFLAGS) -o $(OUT) $(OBJS)
	-$(Q)$(STRIP) -x $(OUT) 2>/dev/null || true

clean:
	rm -f $(OBJS) $(OUT)
