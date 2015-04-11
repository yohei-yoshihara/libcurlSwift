/**
 The MIT License (MIT)
 
 Copyright (c) 2015 Yohei Yoshihara
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#include "Curl.h"
#include <curl/curl.h>

static size_t write_callback(char *buffer, size_t size, size_t nitems, void *userdata)
{
  Curl* curl = (__bridge Curl *)userdata;
  return curl.writeFunction((const unsigned char *)buffer, size * nitems);
}

static size_t header_callback(char *buffer, size_t size, size_t nitems, void *userdata)
{
  Curl* curl = (__bridge Curl *)userdata;
  return curl.headerFunction((const unsigned char *)buffer, size * nitems);
}

static size_t read_callback(char *buffer, size_t size, size_t nitems, void *userdata)
{
  Curl* curl = (__bridge Curl *)userdata;
  return curl.readFunction((unsigned char *)buffer, size * nitems);
}

static int progress_callback(void *userdata, double dltotal, double dlnow, double ultotal, double ulnow)
{
  Curl* curl = (__bridge Curl *)userdata;
  return curl.progressFunction(dltotal, dlnow, ultotal, ulnow);
}

static int xferinfo_callback(void *userdata, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow)
{
  Curl* curl = (__bridge Curl *)userdata;
  return curl.xferInfoFunction(dltotal, dlnow, ultotal, ulnow);
}

static CURLcode ssl_ctx_callback(CURL *_curl, void *ssl_ctx, void *userdata)
{
  Curl* curl = (__bridge Curl *)userdata;
  return (CURLcode)curl.SSLCtxFunction(curl, ssl_ctx);
}

@interface Curl ()
@property (nonatomic, assign) CURL *curl;
@property (nonatomic, assign) struct curl_slist *internal_httpHeader;
@property (nonatomic, assign) struct curl_slist *internal_quote;
@property (nonatomic, assign) struct curl_slist *internal_postQuote;
@end

@interface CurlInfo ()
@property (nonatomic, assign) CURL *curl;
@end

#pragma mark - Curl

@implementation Curl

+ (CurlCode)globalInit
{
  return (CurlCode)curl_global_init(CURL_GLOBAL_DEFAULT);
}

+ (void)globalCleanup
{
  curl_global_cleanup();
}

+ (NSString *)errorString:(CurlCode)code
{
  const char *s = curl_easy_strerror((CURLcode)code);
  return [NSString stringWithUTF8String:s];
}

- (instancetype)init
{
  CURLAUTH_BASIC;
  self = [super init];
  if (self) {
    [self resetProperties];
    _curl = curl_easy_init();
    _info = [[CurlInfo alloc] init];
    _info.curl = _curl;
  }
  return self;
}

- (void)dealloc
{
  [self resetProperties];
  
  if (_curl != NULL) {
    curl_easy_cleanup(_curl);
  }
}

#pragma mark - BEHAVIOR OPTIONS

- (void)setVerbose:(BOOL)verbose
{
  _verbose = verbose;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_VERBOSE, _verbose ? 1L : 0L);
}

- (void)setHeader:(BOOL)header
{
  _header = header;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_HEADER, _header ? 1L : 0L);
}

- (void)setNoProgress:(BOOL)noProgress
{
  _noProgress = noProgress;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_NOPROGRESS, _noProgress ? 1L : 0L);
}

- (void)setNoSignal:(BOOL)noSignal
{
  _noSignal = noSignal;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_NOSIGNAL, _noSignal ? 1L : 0L);
}

- (void)setWildCardMatch:(BOOL)wildCardMatch
{
  _wildCardMatch = wildCardMatch;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_WILDCARDMATCH, _wildCardMatch ? 1L : 0L);
}

#pragma mark - CALLBACK OPTIONS

- (void)setWriteFunction:(WriteFunction)writeFunction
{
  _writeFunction = [writeFunction copy];
  if (_writeFunction != nil) {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(self.curl, CURLOPT_WRITEDATA, self);
  }
  else {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_WRITEFUNCTION, NULL);
    curl_easy_setopt(self.curl, CURLOPT_WRITEDATA, NULL);
  }
}

- (void)setReadFunction:(ReadFunction)readFunction
{
  _readFunction = [readFunction copy];
  if (_readFunction != nil) {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_READFUNCTION, read_callback);
    curl_easy_setopt(self.curl, CURLOPT_READDATA, self);
  }
  else {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_READFUNCTION, NULL);
    curl_easy_setopt(self.curl, CURLOPT_READDATA, NULL);
  }
}

- (void)setProgressFunction:(ProgressFunction)progressFunction
{
  _progressFunction = [progressFunction copy];
  if (_progressFunction != nil) {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_PROGRESSFUNCTION, progress_callback);
    curl_easy_setopt(self.curl, CURLOPT_PROGRESSDATA, self);
  }
  else {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_PROGRESSFUNCTION, NULL);
    curl_easy_setopt(self.curl, CURLOPT_PROGRESSDATA, NULL);
  }
}

- (void)setXferInfoFunction:(XferInfoFunction)xferInfoFunction
{
  _xferInfoFunction = [xferInfoFunction copy];
  if (_xferInfoFunction != nil) {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_XFERINFOFUNCTION, xferinfo_callback);
    curl_easy_setopt(self.curl, CURLOPT_XFERINFODATA, self);
  }
  else {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_XFERINFOFUNCTION, NULL);
    curl_easy_setopt(self.curl, CURLOPT_XFERINFODATA, NULL);
  }
}

- (void)setHeaderFunction:(HeaderFunction)headerFunction
{
  _headerFunction = [headerFunction copy];
  if (_headerFunction != nil) {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_HEADERFUNCTION, header_callback);
    curl_easy_setopt(self.curl, CURLOPT_HEADERDATA, self);
  }
  else {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_HEADERFUNCTION, NULL);
    curl_easy_setopt(self.curl, CURLOPT_HEADERDATA, NULL);
  }
}

- (void)setSSLCtxFunction:(SSLCtxFunction)SSLCtxFunction
{
  _SSLCtxFunction = SSLCtxFunction;
  if (_SSLCtxFunction != nil) {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_SSL_CTX_FUNCTION, ssl_ctx_callback);
    curl_easy_setopt(self.curl, CURLOPT_SSL_CTX_DATA, self);
  }
  else {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_SSL_CTX_FUNCTION, NULL);
    curl_easy_setopt(self.curl, CURLOPT_SSL_CTX_DATA, NULL);
  }
}

#pragma mark - ERROR OPTIONS

- (void)setFailOnError:(BOOL)failOnError
{
  _failOnError = failOnError;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_FAILONERROR, _failOnError ? 1L : 0L);
}

#pragma mark - NETWORK OPTIONS

- (void)setURL:(NSString *)url
{
  _URL = url.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_URL, [_URL cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setProxy:(NSString *)proxy
{
  _proxy = proxy.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_PROXY, [_proxy cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setProxyPort:(NSInteger)proxyPort
{
  _proxyPort = proxyPort;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_PROXYPORT, (long)_proxyPort);
}

- (void)setNoProxy:(NSString *)noProxy
{
  _noProxy = noProxy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_NOPROXY, [_noProxy cStringUsingEncoding:NSUTF8StringEncoding]);
}

#pragma mark - NAMES and PASSWORDS OPTIONS

- (void)setUsername:(NSString *)username
{
  _username = username.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_USERNAME, [_username cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setPassword:(NSString *)password
{
  _password = password.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_PASSWORD, [_password cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setProxyUsername:(NSString *)proxyUsername
{
  _proxyUsername = proxyUsername.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_PROXYUSERNAME, [_proxyUsername cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setProxyPassword:(NSString *)proxyPassword
{
  _proxyPassword = proxyPassword.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_PROXYPASSWORD, [_proxyPassword cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setHTTPAuth:(CurlHTTPAuth)HTTPAuth
{
  _HTTPAuth = HTTPAuth;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_HTTPAUTH, (long)_HTTPAuth);
}

#pragma mark - HTTP OPTIONS

- (void)setAcceptEncoding:(NSString *)acceptEncoding
{
  _acceptEncoding = acceptEncoding.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_ACCEPT_ENCODING, [_acceptEncoding cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setFollowLocation:(BOOL)followLocation
{
  _followLocation = followLocation;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_FOLLOWLOCATION, _followLocation ? 1L : 0L);
}

- (void)setHTTPPut:(BOOL)HTTPPut
{
  _HTTPPut = HTTPPut;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_PUT, _HTTPPut ? 1L : 0L);
}

- (void)setHTTPPost:(BOOL)HTTPPost
{
  _HTTPPost = HTTPPost;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_POST, _HTTPPost ? 1L : 0L);
}

- (void)setPostFields:(NSData *)postFields
{
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_POSTFIELDSIZE, postFields.length);
  if (_lastError != CurlCode_OK) {
    return;
  }
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_COPYPOSTFIELDS, postFields.bytes);
}

- (NSData *)postFields
{
  NSAssert(NO, @"not supported");
  return nil;
}

- (void)setUserAgent:(NSString *)userAgent
{
  _userAgent = userAgent.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_USERAGENT, [_userAgent cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setHTTPHeader:(NSArray *)HTTPHeader
{
  _HTTPHeader = [HTTPHeader copy];
  if (_internal_httpHeader != NULL) {
    curl_slist_free_all(_internal_httpHeader);
    _internal_httpHeader = NULL;
  }
  if (_HTTPHeader != nil && _HTTPHeader.count > 0) {
    for (NSString *header in _HTTPHeader) {
      _internal_httpHeader = curl_slist_append(_internal_httpHeader, [header cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_HTTPHEADER, _internal_httpHeader);
  }
  else {
    _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_HTTPHEADER, NULL);
  }
}

- (void)setCookie:(NSString *)cookie
{
  _cookie = cookie.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_COOKIE, [_cookie cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setHTTPGet:(BOOL)HTTPGet
{
  _HTTPGet = HTTPGet;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_HTTPGET, _HTTPGet ? 1L : 0L);
}

- (void)setHTTPVersion:(CurlHTTPVersion)HTTPVersion
{
  _HTTPVersion = HTTPVersion;
  long ver;
  switch (HTTPVersion) {
    case CurlHTTPVersion_None:
      ver = CURL_HTTP_VERSION_NONE;
      break;
    case CurlHTTPVersion_HTTP10:
      ver = CURL_HTTP_VERSION_1_0;
      break;
    case CurlHTTPVersion_HTTP11:
      ver = CURL_HTTP_VERSION_1_1;
      break;
    case CurlHTTPVersion_HTTP20:
      ver = CURL_HTTP_VERSION_2_0;
      break;
  }
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_HTTP_VERSION, ver);
}

#pragma mark - FTP OPTIONS

- (void)setQuote:(NSArray *)quote
{
  _quote = quote.copy;
  if (_internal_quote) {
    curl_slist_free_all(_internal_quote);
    _internal_quote = NULL;
  }
  for (NSString *cmd in quote) {
    _internal_quote = curl_slist_append(_internal_quote, [cmd cStringUsingEncoding:NSUTF8StringEncoding]);
  }
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_QUOTE, _internal_quote);
}

- (void)setPostQuote:(NSArray *)postQuote
{
  _postQuote = postQuote.copy;
  if (_internal_postQuote) {
    curl_slist_free_all(_internal_postQuote);
    _internal_postQuote = NULL;
  }
  for (NSString *cmd in postQuote) {
    _internal_postQuote = curl_slist_append(_internal_postQuote, [cmd cStringUsingEncoding:NSUTF8StringEncoding]);
  }
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_POSTQUOTE, _internal_postQuote);
}

- (void)setPreQuote:(NSString *)preQuote
{
  _preQuote = preQuote.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_PREQUOTE, [_preQuote cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setCreateMissingDir:(BOOL)createMissingDir
{
  _createMissingDir = createMissingDir;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_FTP_CREATE_MISSING_DIRS, _createMissingDir ? 1L : 0L);
}

- (void)setTransferText:(BOOL)transferText
{
  _transferText = transferText;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_TRANSFERTEXT, _transferText ? 1L : 0L);
}

- (void)setCustomRequest:(NSString *)customRequest
{
  _customRequest = customRequest.copy;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_CUSTOMREQUEST, [_customRequest cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)setFileTime:(BOOL)fileTime
{
  _fileTime = fileTime;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_FILETIME, _fileTime ? 1L : 0L);
}

- (void)setDirListOnly:(BOOL)dirListOnly
{
  _dirListOnly = dirListOnly;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_DIRLISTONLY, _dirListOnly ? 1L : 0L);
}

- (void)setNoBody:(BOOL)noBody
{
  _noBody = noBody;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_NOBODY, _noBody ? 1L : 0L);
}

- (void)setInFileSize:(long)inFileSize
{
  _inFileSize = inFileSize;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_INFILESIZE_LARGE, (curl_off_t)_inFileSize);
}

- (void)setUpload:(BOOL)upload
{
  _upload = upload;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_UPLOAD, _upload ? 1L : 0L);
}

- (void)setUseSSL:(CurlUseSSL)useSSL
{
  _useSSL = useSSL;
  curl_usessl useSSL_;
  switch (useSSL) {
    case CurlUseSSL_None:
      useSSL_ = CURLUSESSL_NONE;
      break;
    case CurlUseSSL_Try:
      useSSL_ = CURLUSESSL_TRY;
      break;
    case CurlUseSSL_Control:
      useSSL_ = CURLUSESSL_CONTROL;
      break;
    case CurlUseSSL_All:
      useSSL_ = CURLUSESSL_ALL;
      break;
    case CurlUseSSL_Last:
      useSSL_ = CURLUSESSL_LAST;
      break;
  }
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_USE_SSL, useSSL_);
}

- (void)setSSLVerifyHost:(BOOL)sslVerifyHost
{
  _SSLVerifyHost = sslVerifyHost;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_SSL_VERIFYHOST, _SSLVerifyHost ? 1L : 0L);
}

- (void)setSSLVerifyPeer:(BOOL)sslVerifyPeer
{
  _SSLVerifyPeer = sslVerifyPeer;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_SSL_VERIFYPEER, _SSLVerifyPeer ? 1L : 0L);
}

- (void)setSSLVerifyStatus:(BOOL)SSLVerifyStatus
{
  _SSLVerifyStatus = SSLVerifyStatus;
  _lastError = (CurlCode)curl_easy_setopt(self.curl, CURLOPT_SSL_VERIFYSTATUS, _SSLVerifyStatus ? 1L : 0L);
}

- (CurlCode)perform
{
  return (CurlCode)curl_easy_perform(self.curl);
}

- (void)resetProperties
{
  _lastError = CurlCode_OK;
  
  _verbose = NO;
  _header = NO;
  _noProgress = YES;
  _noSignal = NO;
  _wildCardMatch = YES;
  
  _writeFunction = nil;
  _readFunction = nil;
  _progressFunction = nil;
  _xferInfoFunction = nil;
  _headerFunction = nil;
  _SSLCtxFunction = nil;
  
  _failOnError = NO;
  
  _URL = nil;
  _proxy = nil;
  _proxyPort = 0;
  _noProxy = nil;
  
  _username = nil;
  _password = nil;
  _proxyUsername = nil;
  _proxyPassword = nil;
  _HTTPAuth = CurlHTTPAuth_Basic;
  
  _acceptEncoding = nil;
  _followLocation = NO;
  _HTTPPut = NO;
  _HTTPPost = NO;
//  _postFields = nil;
  _userAgent = nil;
  _HTTPHeader = nil;
  _cookie = nil;
  _HTTPGet = NO;
  _HTTPVersion = CurlHTTPVersion_None;
  
  _quote = nil;
  if (_internal_quote) {
    curl_slist_free_all(_internal_quote);
    _internal_quote = NULL;
  }
  _postQuote = nil;
  if (_internal_postQuote) {
    curl_slist_free_all(_internal_postQuote);
    _internal_postQuote = NULL;
  }
  _preQuote = nil;
  _createMissingDir = NO;
  
  _transferText = NO;
  _customRequest = nil;
  _fileTime = NO;
  _dirListOnly = NO;
  _noBody = NO;
  _inFileSize = 0;
  _upload = NO;
  
  _useSSL = NO;
  _SSLVerifyHost = YES;
  _SSLVerifyPeer = YES;
  _SSLVerifyStatus = NO;
}

- (void)reset
{
  curl_easy_reset(self.curl);
  [self resetProperties];
}

- (void)cleanup
{
  [self resetProperties];
  
  if (_curl != NULL) {
    curl_easy_cleanup(_curl);
    _curl = NULL;
  }
}

@end

#pragma mark - CurlInfo

@implementation CurlInfo

- (NSString *)effectiveURL
{
  char *url;
  _lastError = (CurlCode)curl_easy_getinfo(self.curl, CURLINFO_EFFECTIVE_URL, &url);
  return [[NSString alloc] initWithUTF8String:url];
}

- (NSInteger)responseCode
{
  long reponseCode;
  _lastError = (CurlCode)curl_easy_getinfo(self.curl, CURLINFO_RESPONSE_CODE, &reponseCode);
  return reponseCode;
}

- (long)fileTime
{
  long fileTime;
  _lastError = (CurlCode)curl_easy_getinfo(self.curl, CURLINFO_FILETIME, &fileTime);
  return fileTime;
}

- (double)contentLengthDownload
{
  double contentLengthDownload;
  _lastError = (CurlCode)curl_easy_getinfo(self.curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD, &contentLengthDownload);
  return contentLengthDownload;
}

- (double)contentLengthUpload
{
  double contentLengthUpload;
  _lastError = (CurlCode)curl_easy_getinfo(self.curl, CURLINFO_CONTENT_LENGTH_UPLOAD, &contentLengthUpload);
  return contentLengthUpload;
}

- (NSInteger)SSLVerifyResult
{
  long SSLVerifyResult;
  _lastError = (CurlCode)curl_easy_getinfo(self.curl, CURLINFO_SSL_VERIFYRESULT, &SSLVerifyResult);
  return SSLVerifyResult;
}

- (NSString *)contentType
{
  char *contentType;
  _lastError = (CurlCode)curl_easy_getinfo(self.curl, CURLINFO_CONTENT_TYPE, &contentType);
  return [[NSString alloc] initWithUTF8String:contentType];
}

- (NSString *)FTPEntryPath
{
  char *FTPEntryPath;
  _lastError = (CurlCode)curl_easy_getinfo(self.curl, CURLINFO_FTP_ENTRY_PATH, &FTPEntryPath);
  return [[NSString alloc] initWithUTF8String:FTPEntryPath];
}

@end
