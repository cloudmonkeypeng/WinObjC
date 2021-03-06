//******************************************************************************
//
// Copyright (c) 2016 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

#import <CoreText/CTFontManager.h>
#import <StubReturn.h>

#import <UIFontInternal.h>
#import <UIKit/UIFont.h>

extern "C" {
#include <ft2build.h>
#include FT_FREETYPE_H
#include <ftglyph.h>
#include <tttables.h>
#include <ftadvanc.h>
#include <ftsizes.h>
#include <ftsnames.h>
#include <ttnameid.h>
}

const CFStringRef kCTFontManagerRegisteredFontsChangedNotification =
    static_cast<CFStringRef>(@"kCTFontManagerRegisteredFontsChangedNotification");
const CFStringRef kCTFontManagerErrorDomain = static_cast<CFStringRef>(@"kCTFontManagerErrorDomain");
const CFStringRef kCTFontManagerErrorFontURLsKey = static_cast<CFStringRef>(@"kCTFontManagerErrorFontURLsKey");

/**
 @Status Stub
 @Notes
*/
CFArrayRef CTFontManagerCreateFontDescriptorsFromURL(CFURLRef fileURL) {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
bool CTFontManagerRegisterFontsForURL(CFURLRef fontURL, CTFontManagerScope scope, CFErrorRef _Nullable* error) {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
bool CTFontManagerUnregisterFontsForURL(CFURLRef fontURL, CTFontManagerScope scope, CFErrorRef _Nullable* error) {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
bool CTFontManagerRegisterFontsForURLs(CFArrayRef fontURLs, CTFontManagerScope scope, CFArrayRef _Nullable* errors) {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
bool CTFontManagerUnregisterFontsForURLs(CFArrayRef fontURLs, CTFontManagerScope scope, CFArrayRef _Nullable* errors) {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Interoperable
*/
bool CTFontManagerRegisterGraphicsFont(CGFontRef font, CFErrorRef* error) {
    // Call into UIFont to do the actual work
    return [static_cast<UIFont*>(font) _CTFontManagerRegisterGraphicsFont:font withError:error];
}

/**
 @Status Stub
 @Notes
*/
bool CTFontManagerUnregisterGraphicsFont(CGFontRef font, CFErrorRef _Nullable* error) {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
bool CTFontManagerIsSupportedFont(CFURLRef fontURL) {
    UNIMPLEMENTED();
    return StubReturn();
}
