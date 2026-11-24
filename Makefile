SDK        := $(shell xcrun --sdk iphoneos --show-sdk-path)
CXX        := $(shell xcrun --sdk iphoneos -f clang++)
STRIP      := $(shell xcrun --sdk iphoneos -f strip)
CODESIGN   ?= codesign
LDID       ?= ldid

NAME       := FragUnlock
OUT        := $(NAME).dylib

ARCH       := arm64
MIN_IOS    := 14.0

SRCS       := Tweak.mm ModMenu.mm StoreKitHooks.mm UnityBridge.mm ReceiptForge.mm JailbreakScrub.mm
OBJS       := $(SRCS:.mm=.o)

FRAMEWORKS := -framework UIKit -framework Foundation -framework StoreKit \
              -framework QuartzCore -framework CoreGraphics -framework Security

CFLAGS     := -arch $(ARCH) -isysroot $(SDK) -target arm64-apple-ios$(MIN_IOS) \
              -O2 -fobjc-arc -fmodules -fno-common -fvisibility=hidden \
              -Wno-deprecated-declarations -Wno-unused-function

LDFLAGS    := -dynamiclib -arch $(ARCH) -isysroot $(SDK) \
              -target arm64-apple-ios$(MIN_IOS) \
              -install_name @executable_path/Frameworks/$(OUT) \
              $(FRAMEWORKS) -Xlinker -dead_strip

.PHONY: all clean sign
all: $(OUT)

%.o: %.mm
	$(CXX) $(CFLAGS) -c $< -o $@

$(OUT): $(OBJS)
	$(CXX) $(LDFLAGS) -o $(OUT) $(OBJS)
	$(STRIP) -x $(OUT)
	-$(LDID) -S $(OUT) 2>/dev/null || true

sign: $(OUT)
	$(LDID) -S $(OUT)

clean:
	rm -f $(OBJS) $(OUT)
