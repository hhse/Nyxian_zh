/*
 Copyright (C) 2025 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <LindChain/Synpush/Synpush.h>
#import <pthread.h>
#import <dispatch/dispatch.h>
#import <string.h>
#import <strings.h>

#pragma mark - Small C helpers

static inline const char* cxstring_to_cstr_dup(CXString s) {
    const char* cstr = clang_getCString(s);
    char* result = cstr ? strdup(cstr) : NULL;
    clang_disposeString(s);
    return result;
}

static inline char* build_completion_typed_or_text(CXCompletionString cs) {
    unsigned n = clang_getNumCompletionChunks(cs);

    for (unsigned i = 0; i < n; ++i) {
        enum CXCompletionChunkKind kind = clang_getCompletionChunkKind(cs, i);
        if (kind == CXCompletionChunk_TypedText) {
            CXString s = clang_getCompletionChunkText(cs, i);
            const char* c = clang_getCString(s);
            char* out = c ? strdup(c) : NULL;
            clang_disposeString(s);
            return out;
        }
    }

    size_t total = 0;
    for (unsigned i = 0; i < n; ++i) {
        enum CXCompletionChunkKind kind = clang_getCompletionChunkKind(cs, i);
        if (kind == CXCompletionChunk_TypedText || kind == CXCompletionChunk_Text) {
            CXString s = clang_getCompletionChunkText(cs, i);
            const char* c = clang_getCString(s);
            if (c) total += strlen(c);
            clang_disposeString(s);
        }
    }
    if (total == 0) return NULL;

    char* out = (char*)malloc(total + 1);
    out[0] = '\0';
    for (unsigned i = 0; i < n; ++i) {
        enum CXCompletionChunkKind kind = clang_getCompletionChunkKind(cs, i);
        if (kind == CXCompletionChunk_TypedText || kind == CXCompletionChunk_Text) {
            CXString s = clang_getCompletionChunkText(cs, i);
            const char* c = clang_getCString(s);
            if (c) strcat(out, c);
            clang_disposeString(s);
        }
    }
    return out;
}

static inline uint8_t mapSeverity(enum CXDiagnosticSeverity severity) {
    switch (severity) {
        case CXDiagnostic_Note:    return 0;
        case CXDiagnostic_Warning: return 1;
        case CXDiagnostic_Error:
        case CXDiagnostic_Fatal:   return 2;
        default:                   return 2;
    }
}

#pragma mark - SynpushServer

@interface SynpushServer () {
    CXIndex _index;
    CXTranslationUnit _unit;
    struct CXUnsavedFile _unsaved;
    NSData *_contentData;
    NSString *_filepath;
    char *_cFilename;
    int _argc;
    char **_args;
    pthread_mutex_t _mutex;
}
@end

@implementation SynpushServer

- (instancetype)init:(NSString*)filepath
                args:(NSArray*)args
{
    self = [super init];
    if (!self) return nil;

    _filepath = [filepath copy];
    _cFilename = strdup(_filepath.UTF8String);

    _argc = (int)args.count;
    _args = (char**)calloc((size_t)_argc, sizeof(char*));
    for (int i = 0; i < _argc; ++i) {
        _args[i] = strdup([args[i] UTF8String]);
    }

    _index = clang_createIndex(0, 0);

    _contentData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    _unsaved.Filename = _cFilename;
    _unsaved.Contents = (const char*)_contentData.bytes;
    _unsaved.Length   = (unsigned long)_contentData.length;

    unsigned tuFlags =
        CXTranslationUnit_PrecompiledPreamble |
        CXTranslationUnit_CacheCompletionResults |
        CXTranslationUnit_KeepGoing |
        CXTranslationUnit_IncludeBriefCommentsInCodeCompletion |
        CXTranslationUnit_DetailedPreprocessingRecord;

    enum CXErrorCode err = clang_parseTranslationUnit2(
        _index,
        _cFilename,
        (const char *const *)_args, _argc,
        &_unsaved, 1,
        tuFlags,
        &_unit);

    if (err != CXError_Success || !_unit) {
        if (_unit) clang_disposeTranslationUnit(_unit);
        clang_disposeIndex(_index);
        for (int i = 0; i < _argc; ++i) free(_args[i]);
        free(_args);
        free(_cFilename);
        return nil;
    }

    pthread_mutex_init(&_mutex, NULL);
    return self;
}

#pragma mark - Reparse (incremental)

- (void)reparseFile:(NSString*)content
{
    pthread_mutex_lock(&_mutex);

    NSData *newData = [content dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    if (!newData) { pthread_mutex_unlock(&_mutex); return; }
    _contentData = newData;

    _unsaved.Filename = _cFilename;
    _unsaved.Contents = (const char*)_contentData.bytes;
    _unsaved.Length   = (unsigned long)_contentData.length;

    clang_reparseTranslationUnit(_unit, 1, &_unsaved, clang_defaultReparseOptions(_unit));

    pthread_mutex_unlock(&_mutex);
}

- (NSArray<Synitem *> *)getDiagnostics
{
    pthread_mutex_lock(&_mutex);

    unsigned count = clang_getNumDiagnostics(_unit);
    NSMutableArray<Synitem *> *items = [NSMutableArray arrayWithCapacity:count];

    for (unsigned i = 0; i < count; ++i) {
        CXDiagnostic diag = clang_getDiagnostic(_unit, i);
        enum CXDiagnosticSeverity severity = clang_getDiagnosticSeverity(diag);
        if (severity == CXDiagnostic_Ignored) { clang_disposeDiagnostic(diag); continue; }

        CXSourceLocation loc = clang_getDiagnosticLocation(diag);
        CXFile file; unsigned line = 0, col = 0;
        clang_getSpellingLocation(loc, &file, &line, &col, NULL);

        CXString fileName = clang_getFileName(file);
        const char *fn = clang_getCString(fileName);
        BOOL sameFile = (fn && _cFilename) ? (strcmp(fn, _cFilename) == 0) : NO;
        clang_disposeString(fileName);
        if (!sameFile) { clang_disposeDiagnostic(diag); continue; }

        CXString diagStr = clang_getDiagnosticSpelling(diag);
        const char *cmsg = clang_getCString(diagStr);

        NSMutableArray<NSString*> *fixits = [NSMutableArray array];

        Synitem *item = [[Synitem alloc] init];
        item.line    = line;
        item.column  = col;
        item.type    = mapSeverity(severity);
        if (fixits.count) {
            item.message = [NSString stringWithFormat:@"%s (fix-its: %@)", cmsg ?: "", [fixits componentsJoinedByString:@" | "]];
        } else {
            item.message = [NSString stringWithFormat:@"%s", cmsg ?: ""];
        }
        [items addObject:item];

        clang_disposeString(diagStr);
        clang_disposeDiagnostic(diag);
    }

    pthread_mutex_unlock(&_mutex);
    return items;
}

#pragma mark - Code Completion

static inline NSString* sp_extractPrefix(NSString *lineUpToCursor) {
    if (lineUpToCursor.length == 0) return @"";
    NSMutableString *prefix = [NSMutableString string];
    NSCharacterSet *valid = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"];
    for (NSInteger i = (NSInteger)lineUpToCursor.length - 1; i >= 0; --i) {
        unichar c = [lineUpToCursor characterAtIndex:(NSUInteger)i];
        if ([valid characterIsMember:c]) {
            [prefix insertString:[NSString stringWithCharacters:&c length:1] atIndex:0];
        } else {
            break;
        }
    }
    return prefix;
}

- (void)updateBuffer:(NSString *)content
{
    pthread_mutex_lock(&_mutex);

    NSData *newData = [content dataUsingEncoding:NSUTF8StringEncoding
                           allowLossyConversion:NO];
    if (newData) {
        _contentData = newData;
        _unsaved.Filename = _cFilename;
        _unsaved.Contents = (const char *)_contentData.bytes;
        _unsaved.Length   = (unsigned long)_contentData.length;
    }

    pthread_mutex_unlock(&_mutex);
}

- (NSArray<NSString*>*)getAutocompletionsAtLine:(UInt32)line
                                       atColumn:(UInt32)column
{
    pthread_mutex_lock(&_mutex);

    NSString *codeStr = [[NSString alloc] initWithData:_contentData encoding:NSUTF8StringEncoding];
    if (!codeStr) { pthread_mutex_unlock(&_mutex); return @[]; }

    __block NSString *currentLine = nil;
    __block NSUInteger startOfLine = 0;
    __block NSUInteger currentLineIndex = 1;
    [codeStr enumerateSubstringsInRange:NSMakeRange(0, codeStr.length)
                                options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                             usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if (currentLineIndex == line) {
            currentLine = [codeStr substringWithRange:enclosingRange];
            startOfLine = enclosingRange.location;
            *stop = YES;
        }
        currentLineIndex++;
    }];

    if (!currentLine) { pthread_mutex_unlock(&_mutex); return @[]; }
    NSUInteger colIndex = MIN((NSUInteger)MAX(1, column) - 1, currentLine.length);
    NSString *lineUpToCursor = [currentLine substringToIndex:colIndex];

    NSString *prefixStr = sp_extractPrefix(lineUpToCursor);
    if (prefixStr.length == 0) { pthread_mutex_unlock(&_mutex); return @[]; }
    const char *prefix = prefixStr.UTF8String;
    const size_t prefix_len = strlen(prefix);

    unsigned ccOpts = clang_defaultCodeCompleteOptions();

    CXCodeCompleteResults *results = clang_codeCompleteAt(
        _unit,
        _cFilename,
        line,
        column,
        &_unsaved,
        1,
        ccOpts);

    if (!results) { pthread_mutex_unlock(&_mutex); return @[]; }

    clang_sortCodeCompletionResults(results->Results, results->NumResults);

    NSMutableArray<NSString*> *completions = [NSMutableArray array];

    for (unsigned i = 0; i < results->NumResults; ++i) {
        CXCompletionString cs = results->Results[i].CompletionString;
        char *typed = build_completion_typed_or_text(cs);
        if (!typed) continue;
        if (strncasecmp(typed, prefix, prefix_len) == 0) {
            const char *suffix = typed + prefix_len;
            if (*suffix) {
                [completions addObject:[NSString stringWithUTF8String:suffix]];
            } else {
                [completions addObject:@""];
            }
        }
        free(typed);
        if (completions.count >= 100) break; // protect UI; keep it snappy
    }

    clang_disposeCodeCompleteResults(results);

    pthread_mutex_unlock(&_mutex);
    return completions;
}

- (void)dealloc
{
    pthread_mutex_lock(&_mutex);
    if (_unit) clang_disposeTranslationUnit(_unit);
    if (_index) clang_disposeIndex(_index);
    pthread_mutex_unlock(&_mutex);

    for (int i = 0; i < _argc; ++i) free(_args[i]);
    free(_args);

    free(_cFilename);
    pthread_mutex_destroy(&_mutex);
}

@end

