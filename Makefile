# Builds FragUnlock.dylib for arm64 iOS.
# - On macOS: uses Xcode's xcrun to find clang + the iPhoneOS SDK.
# - On Linux (CI): uses $THEOS/toolchain/linux/iphone + $THEOS/sdks/$SDK_NAME,
#   which gives a darwin-targeting clang that cross-compiles Mach-O arm64.

NAME       := FragUnlock
OUT        := $(NAME).dylib

ARCH       := arm64
MIN_IOS    := 14.0

SRCS       := Tweak.mm ModMenu.mm StoreKitHooks.mm UnityBridge.mm ReceiptForge.mm JailbreakScrub.mm
OBJS       := $(SRCS:.mm=.o)

# ---- Toolchain selection ---------------------------------------------------

ifneq ($(THEOS),)
  # Linux cross-compile via theos
  SDK_NAME ?= iPhoneOS16.5.sdk
  SDK      := $(THEOS)/sdks/$(SDK_NAME)
  BIN      := $(THEOS)/toolchain/linux/iphone/bin
  CXX      := $(BIN)/clang++
  STRIP    := $(BIN)/strip
  # On linux theos, clang++ needs -stdlib=libc++ and the right framework path
  EXTRA    := -stdlib=libc++ -F$(SDK)/System/Library/Frameworks
else ifneq ($(shell uname -s 2>/dev/null),Darwin)
  $(error No toolchain available: on Linux set THEOS=/path/to/theos; on Windows use the GitHub Actions workflow)
else
  # macOS with Xcode CLT
  SDK      := $(shell xcrun --sdk iphoneos --show-sdk-path)
  CXX      := $(shell xcrun --sdk iphoneos -f clang++)
  STRIP    := $(shell xcrun --sdk iphoneos -f strip)
  EXTRA    :=
endif

# ---- Flags -----------------------------------------------------------------

FRAMEWORKS := -framework UIKit -framework Foundation -framework StoreKit \
              -framework QuartzCore -framework CoreGraphics -framework Security

CFLAGS     := -arch $(ARCH) -isysroot $(SDK) -target arm64-apple-ios$(MIN_IOS) \
              -O2 -fobjc-arc -fmodules -fno-common -fvisibility=hidden \
              -Wno-deprecated-declarations -Wno-unused-function $(EXTRA)

LDFLAGS    := -dynamiclib -arch $(ARCH) -isysroot $(SDK) \
              -target arm64-apple-ios$(MIN_IOS) \
              -install_name @executable_path/Frameworks/$(OUT) \
              $(FRAMEWORKS) -Xlinker -dead_strip $(EXTRA)

.PHONY: all clean info
all: $(OUT)

info:
	@echo SDK   = $(SDK)
	@echo CXX   = $(CXX)
	@echo STRIP = $(STRIP)

%.o: %.mm
	$(CXX) $(CFLAGS) -c $< -o $@

$(OUT): $(OBJS)
	$(CXX) $(LDFLAGS) -o $(OUT) $(OBJS)
	-$(STRIP) -x $(OUT) 2>/dev/null || true

clean:
	rm -f $(OBJS) $(OUT)
