//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
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

#include "Starboard.h"
#include "StubReturn.h"

using WCHAR = wchar_t;

#include <string>
#include "Foundation/NSMutableData.h"
#include "Foundation/NSError.h"
#include "Foundation/NSString.h"
#include "Foundation/NSMutableArray.h"
#include "Foundation/NSValue.h"
#include <UWP/WindowsStorageStreams.h>
#include <UWP/WindowsSecurityCryptography.h>

#include <COMIncludes.h>
#include "ErrorHandling.h"
#include "RawBuffer.h"
#include <wrl\wrappers\corewrappers.h>
#include <windows.security.cryptography.h>
#include <windows.storage.streams.h>
#include <COMIncludes_End.h>
#include <string>
#include <sstream>
#include <iomanip>

#include "StringHelpers.h"

using namespace Microsoft::WRL;
using namespace ABI::Windows::Security::Cryptography;
using namespace ABI::Windows::Storage::Streams;
using namespace Windows::Foundation;

@implementation NSData

/**
 @Status Caveat
*/
- (NSString*)base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)options {
    // TODO: support the different options. Mostly these around ignoring unknown characters / new lines etc.
    // Windows has no notion of this so we either need to manually decode or process after the fact wehre possible.

    ComPtr<IBuffer> wrlBuffer = BufferFromRawData(_bytes, _length);
    if (!wrlBuffer) {
        return nil;
    }

    ComPtr<ICryptographicBufferStatics> cryptographicBufferStatics;
    RETURN_NULL_IF_FAILED(
        GetActivationFactory(Wrappers::HStringReference(RuntimeClass_Windows_Security_Cryptography_CryptographicBuffer).Get(),
                             &cryptographicBufferStatics));

    Wrappers::HString encodedString;
    RETURN_NULL_IF_FAILED(cryptographicBufferStatics->EncodeToBase64String(wrlBuffer.Get(), encodedString.GetAddressOf()));

    unsigned int rawLength;
    const wchar_t* rawEncodedString = WindowsGetStringRawBuffer(encodedString.Get(), &rawLength);

    return [[[NSString alloc] initWithBytes:rawEncodedString length:(rawLength * sizeof(wchar_t)) encoding:NSUnicodeStringEncoding]
        autorelease];
}

/**
 @Status Caveat
*/
- (instancetype)initWithBase64EncodedString:(NSString*)base64String options:(NSDataBase64DecodingOptions)options {
    // TODO: support the different options. Mostly these around ignoring unknown characters / new lines etc.
    // Windows has no notion of this so we either need to manually decode or process after the fact wehre possible.

    ComPtr<ICryptographicBufferStatics> cryptographicBufferStatics;
    RETURN_NULL_IF_FAILED(
        GetActivationFactory(Wrappers::HStringReference(RuntimeClass_Windows_Security_Cryptography_CryptographicBuffer).Get(),
                             &cryptographicBufferStatics));

    Wrappers::HString wrlBase64String = Strings::NarrowToWide<HSTRING>(base64String);

    ComPtr<IBuffer> wrlBuffer;
    RETURN_NULL_IF_FAILED(cryptographicBufferStatics->DecodeFromBase64String(wrlBase64String.Get(), wrlBuffer.GetAddressOf()));

    ComPtr<IBufferByteAccess> bufferAccess;
    RETURN_NULL_IF_FAILED(wrlBuffer.As(&bufferAccess));

    uint8_t* rawBuffer;
    RETURN_NULL_IF_FAILED(bufferAccess->Buffer(&rawBuffer));

    unsigned int bufferLength;
    RETURN_NULL_IF_FAILED(wrlBuffer->get_Length(&bufferLength));

    return [self initWithBytes:rawBuffer length:bufferLength];
}

/**
 @Status Interoperable
*/
+ (instancetype)dataWithData:(NSData*)data {
    return [[[self alloc] initWithData:data] autorelease];
}

/**
 @Status Interoperable
*/
+ (instancetype)data {
    return [[[self alloc] init] autorelease];
}

/**
 @Status Interoperable
*/
+ (instancetype)dataWithBytes:(const void*)bytes length:(unsigned)length {
    return [[[self alloc] initWithBytes:bytes length:length] autorelease];
}

/**
 @Status Interoperable
*/
+ (instancetype)dataWithBytesNoCopy:(void*)bytes length:(unsigned)length {
    return [[[self alloc] initWithBytesNoCopy:(void*)bytes length:length freeWhenDone:TRUE] autorelease];
}

/**
 @Status Caveat
 @Notes The CRT used between Islandwood and the application must match if freeWhenDone=TRUE
*/
+ (instancetype)dataWithBytesNoCopy:(void*)bytes length:(unsigned)length freeWhenDone:(BOOL)free {
    return [[[self alloc] initWithBytesNoCopy:(void*)bytes length:length freeWhenDone:free] autorelease];
}

- (instancetype)init {
    return [self initWithBytes:"" length:0];
}

/**
 @Status Interoperable
*/
- (instancetype)initWithData:(NSData*)data {
    return [self initWithBytes:[data bytes] length:[data length]];
}

/**
 @Status Interoperable
*/
- (instancetype)initWithBytes:(const void*)bytes length:(unsigned)length {
    _bytes = nullptr;
    _freeWhenDone = TRUE;
    _length = length;

    if (_length) {
        _bytes = (uint8_t*)EbrMalloc(_length);
        if (!_bytes) {
            [self release];
            return nil;
        }
    }

    if (_length && _bytes) {
        memcpy(_bytes, bytes, _length);
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeBytes:_bytes length:_length forKey:@"NS.data"];
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    NSData* nsData = [coder decodeObjectForKey:@"NS.data"];

    return [self initWithData:nsData];
}

/**
 @Status Caveat
 @Notes The CRT used between Islandwood and the application must match if freeWhenDone=TRUE
*/
- (instancetype)initWithBytesNoCopy:(void*)bytes length:(unsigned)length freeWhenDone:(BOOL)freeWhenDone {
    _bytes = (uint8_t*)bytes;
    _length = length;
    _freeWhenDone = freeWhenDone;

    return self;
}

/**
 @Status Interoperable
*/
- (instancetype)initWithBytesNoCopy:(void*)bytes length:(unsigned)length {
    _bytes = (uint8_t*)bytes;
    _length = length;
    _freeWhenDone = TRUE;

    return self;
}

/**
 @Status Interoperable
*/
- (void)getBytes:(void*)dest {
    memcpy(dest, _bytes, _length);
}

/**
 @Status Interoperable
*/
- (void)getBytes:(void*)dest length:(unsigned)length {
    if (length > _length) {
        length = _length;
    }
    memcpy(dest, _bytes, length);
}

/**
 @Status Interoperable
*/
- (void)getBytes:(void*)dest range:(NSRange)range {
    assert(range.location + range.length <= _length);

    memcpy(dest, &_bytes[range.location], range.length);
}

/**
 @Status Caveat
 @Notes File is not mapped; defers to initWithContentsOfFile:
*/
- (instancetype)initWithContentsOfMappedFile:(NSString*)filename {
    EbrDebugLog("Not actually mapping file ...\n");
    return [self initWithContentsOfFile:filename];
}

/**
 @Status Interoperable
*/
- (instancetype)initWithContentsOfFile:(NSString*)filename {
    return [self initWithContentsOfFile:filename options:0 error:nullptr];
}

/**
 @Status Caveat
 @Notes atomically parameter not supported
*/
- (BOOL)writeToFile:(NSString*)filename atomically:(BOOL)atomically {
    char* fname = (char*)[filename UTF8String];

    EbrDebugLog("NSData writing %s (%d bytes)\n", fname, _length);
    if (!fname) {
        EbrDebugLog("Filename is null!\n");
        return FALSE;
    }
    EbrFile* fpOut = EbrFopen((const char*)fname, "wb");
    if (fpOut) {
        EbrFwrite(_bytes, 1, _length, fpOut);
        EbrFclose(fpOut);

        return TRUE;
    } else {
        EbrDebugLog("NSData couldn't open %s for write\n", fname);
        return FALSE;
    }
}

/**
 @Status Caveat
 @Notes Only file:// URLs supported. atomically parameter not supported.
*/
- (BOOL)writeToURL:(NSURL*)url atomically:(BOOL)atomically {
    if (![url isFileURL]) {
        EbrDebugLog("-[NSData::writeToURL]: Only file: URLs are supported. (%s)", [[url absoluteString] UTF8String]);
        return NO;
    }
    return [self writeToFile:[url path] atomically:atomically];
}

/**
 @Status Caveat
 @Notes options parameter not supported
*/
- (BOOL)writeToFile:(NSString*)filename options:(NSDataWritingOptions)options error:(NSError**)error {
    char* fname = (char*)[filename UTF8String];

    EbrDebugLog("NSData writing %s (%d bytes)\n", fname, _length);
    EbrFile* fpOut = EbrFopen((const char*)fname, "wb");
    if (fpOut) {
        EbrFwrite(_bytes, 1, _length, fpOut);
        EbrFclose(fpOut);

        return TRUE;
    } else {
        EbrDebugLog("NSData couldn't open %s for write (with options)\n", fname);
        return FALSE;
    }
}

/**
 @Status Caveat
 @Notes options parameter not supported
*/
- (BOOL)writeToURL:(NSURL*)url options:(NSDataWritingOptions)options error:(NSError**)errorp {
    if (![url isFileURL]) {
        EbrDebugLog("-[NSData::writeToURL]: Only file: URLs are supported. (%s)", [[url absoluteString] UTF8String]);
        return NO;
    }

    return [self writeToFile:[url path] options:options error:errorp];
}

/**
 @Status Interoperable
*/
+ (instancetype)dataWithContentsOfFile:(NSString*)filename {
    return [[[self alloc] initWithContentsOfFile:filename] autorelease];
}

/**
 @Status Caveat
 @Notes File is not mapped; defers to initWithContentsOfFile:
*/
+ (instancetype)dataWithContentsOfMappedFile:(NSString*)filename {
    return [[[self alloc] initWithContentsOfMappedFile:filename] autorelease];
}

/**
 @Status Caveat
 @Notes options parameter not supported
*/
- (instancetype)initWithContentsOfFile:(NSString*)filename options:(NSDataReadingOptions)options error:(NSError**)error {
    _bytes = nullptr;
    _length = 0;

    if (filename == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"NSData" code:100 userInfo:nil];
        }
        [self release];
        return nil;
    }

    char* fname = (char*)[filename UTF8String];

    EbrDebugLog("NSData extended-opening %s\n", fname);
    EbrFile* fpIn = EbrFopen(fname, "rb");
    if (fpIn) {
        auto closeFile = wil::ScopeExit([&]() { EbrFclose(fpIn); });

        EbrFseek(fpIn, 0, SEEK_END);
        size_t length = EbrFtell(fpIn);
        EbrFseek(fpIn, 0, SEEK_SET);

        if (length) {
            _bytes = (uint8_t*)EbrMalloc(length);
            if (!_bytes) {
                if (error) {
                    *error = [NSError errorWithDomain:@"NSData" code:100 userInfo:nil];
                }
                [self release];
                return nil;
            }

            _freeWhenDone = TRUE;
            _length = EbrFread(_bytes, 1, length, fpIn);
        }
    } else {
        EbrDebugLog("NSData couldn't open %s for read (extended)\n", fname);
        if (error) {
            *error = [NSError errorWithDomain:@"NSData" code:100 userInfo:nil];
        }
        [self release];
        return nil;
    }

    return self;
}

/**
 @Status Stub
*/
- (instancetype)initWithBase64EncodedData:(NSData*)base64Data options:(NSDataBase64DecodingOptions)options {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Stub
*/
- (instancetype)initWithBase64Encoding:(NSString*)base64String {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Stub
*/
- (instancetype)initWithBytesNoCopy:(void*)bytes
                             length:(NSUInteger)length
                        deallocator:(void (^)(void* bytes, NSUInteger length))deallocator {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Stub
*/
- (void)enumerateByteRangesUsingBlock:(void (^)(const void* bytes, NSRange byteRange, BOOL* stop))block {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (NSRange)rangeOfData:(NSData*)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange {
    UNIMPLEMENTED();
    return NSMakeRange(0, 0);
}

/**
 @Status Stub
*/
- (NSData*)base64EncodedDataWithOptions:(NSDataBase64EncodingOptions)options {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Stub
*/
- (NSString*)base64Encoding {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Caveat
 @Notes options parameter not supported
*/
+ (instancetype)dataWithContentsOfFile:(NSString*)filename options:(NSDataReadingOptions)options error:(NSError**)error {
    return [[[self alloc] initWithContentsOfFile:filename options:options error:error] autorelease];
}

/**
 @Status Caveat
 @Notes options parameter not supported
*/
+ (instancetype)dataWithContentsOfURL:(NSURL*)url options:(NSDataReadingOptions)options error:(NSError**)error {
    id ret = [self alloc];
    return [[ret initWithContentsOfURL:url options:options error:error] autorelease];
}

/**
 @Status Interoperable
*/
+ (instancetype)dataWithContentsOfURL:(NSURL*)url {
    id ret = [self alloc];
    return [[ret initWithContentsOfURL:url] autorelease];
}

/**
 @Status Interoperable
*/
- (instancetype)initWithContentsOfURL:(NSURL*)url {
    return [self initWithContentsOfURL:url options:0 error:NULL];
}

/**
 @Status Caveat
 @Notes options parameter not supported
*/
- (instancetype)initWithContentsOfURL:(NSURL*)url options:(NSDataReadingOptions)options error:(NSError**)error {
    EbrDebugLog("initWithContentsOfURL: %s\n", [[url absoluteString] UTF8String]);

    if ([url isFileURL]) {
        return [self initWithContentsOfFile:[url path] options:options error:error];
    }

    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    id response; // what type is this?
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];

    return [self initWithData:data];
}

/**
 @Status Interoperable
*/
- (instancetype)subdataWithRange:(NSRange)range {
    return [NSData dataWithBytes:_bytes + range.location length:range.length];
}

- (id)copyWithZone:(NSZone*)zone {
    return [self retain];
}

- (NSMutableData*)mutableCopyWithZone:(void**)zone {
    return [[NSMutableData alloc] initWithData:self];
}

/**
 @Status Interoperable
*/
- (BOOL)isEqualToData:(NSData*)data {
    NSData* other = (NSData*)data;
    if (_length != other->_length) {
        return false;
    }
    return memcmp(_bytes, other->_bytes, _length) == 0;
}

- (BOOL)isEqual:(id)objAddr {
    if (objAddr == self) {
        return TRUE;
    }
    if (objAddr != nil && [objAddr isKindOfClass:[NSData class]]) {
        return [self isEqualToData:objAddr];
    }

    return FALSE;
}

/**
 @Status Interoperable
*/
- (NSString*)description {
    const char* bytes = (const char*)[self bytes];
    NSUInteger length = [self length];

    const int tmpBufSize = 16 + length * 2 + (length / 4);
    std::vector<char> tmpBuf(tmpBufSize);
    int tmpBufLen = 0;

    tmpBuf[tmpBufLen++] = '<';

    for (auto i = 0; i < length;) {
        int outDigit = ((bytes[i] & 0xF0) >> 4);
        if (outDigit < 10) {
            tmpBuf[tmpBufLen++] = '0' + outDigit;
        } else {
            tmpBuf[tmpBufLen++] = 'A' + outDigit - 10;
        }
        assert(tmpBufLen < tmpBufSize);
        outDigit = bytes[i] & 0xF;
        if (outDigit < 10) {
            tmpBuf[tmpBufLen++] = '0' + outDigit;
        } else {
            tmpBuf[tmpBufLen++] = 'A' + outDigit - 10;
        }
        assert(tmpBufLen < tmpBufSize);
        i++;

        if ((i % 4) == 0 && i < length) {
            tmpBuf[tmpBufLen++] = ' ';
            assert(tmpBufLen < tmpBufSize);
        }
    }
    tmpBuf[tmpBufLen++] = '>';

    NSString* ret = [[NSString alloc] initWithCString:tmpBuf.data() length:tmpBufLen];

    return [ret autorelease];
}

/**
 @Status Interoperable
*/
- (const void*)bytes {
    return _bytes;
}

/**
 @Status Interoperable
*/
- (unsigned)length {
    return _length;
}

- (void)dealloc {
    if (_freeWhenDone && _bytes) {
        free(_bytes);
        _bytes = nullptr;
    }

    [super dealloc];
}

/**
 @Status Stub
 @Notes
*/
+ (BOOL)supportsSecureCoding {
    UNIMPLEMENTED();
    return StubReturn();
}

@end
