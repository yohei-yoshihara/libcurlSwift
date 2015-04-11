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

#ifndef __Curl__
#define __Curl__

#include <stdio.h>
#include <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CurlCode) {
  CurlCode_OK = 0,
  CurlCode_UnsupportedProtocol,
  CurlCode_FailedInit,
  CurlCode_URLMalformat,
  CurlCode_NotBuiltIn,
  CurlCode_CouldntResolveProxy,
  CurlCode_CouldntResolveHost,
  CurlCode_CouldntConnect,
  CurlCode_FTPWeirdServerReply,
  CurlCode_RemoteAccessDenied,
  CurlCode_FTPAcceptFailed,
  CurlCode_FTPWeirdPassReply,
  CurlCode_FTPAcceptTimeout,
  CurlCode_FTPWeirdPasvReply,
  CurlCode_FTPWeird227Format,
  CurlCode_FTPCantGetHost,
  CurlCode_HTTP2,
  CurlCode_FTPCouldntSetType,
  CurlCode_PartialFile,
  CurlCode_FTPCouldntRetrFile,
  CurlCode_Obsolete20,
  CurlCode_QuoteError,
  CurlCode_HTTPReturnedError,
  CurlCode_WriteError,
  CurlCode_Obsolete24,
  CurlCode_UploadFailed,
  CurlCode_ReadError,
  CurlCode_OutOfMemory,
  CurlCode_OperationTimedout,
  CurlCode_Obsolete29,
  CurlCode_FTPPortFailed,
  CurlCode_FTPCouldntUseRest,
  CurlCode_Obsolete32,
  CurlCode_RangeError,
  CurlCode_HTTPPostError,
  CurlCode_SSLConnectError,
  CurlCode_BadDownloadResume,
  CurlCode_FileCouldntReadFile,
  CurlCode_LDAPCannotBind,
  CurlCode_LDAPSearchFailed,
  CurlCode_Obsolete40,
  CurlCode_FunctionNotFound,
  CurlCode_AbortedByCallback,
  CurlCode_BadFunctionArgument,
  CurlCode_Obsolete44,
  CurlCode_InterfaceFailed,
  CurlCode_Obsolete46,
  CurlCode_TooManyRedirects,
  CurlCode_UnknownOption,
  CurlCode_TelnetOptionSyntax,
  CurlCode_Obsolete50,
  CurlCode_PeerFailedVerification,
  CurlCode_GotNothing,
  CurlCode_SSLEngineNotfound,
  CurlCode_SSLEngineSetFailed,
  CurlCode_SendError,
  CurlCode_RecvError,
  CurlCode_Obsolete57,
  CurlCode_SSLCertProblem,
  CurlCode_SSLCipher,
  CurlCode_SSLCACert,
  CurlCode_BadContentEncoding,
  CurlCode_LDAPInvalidURL,
  CurlCode_FilesizeExceeded,
  CurlCode_UseSSLFailed,
  CurlCode_SendFailRewind,
  CurlCode_SSLEngineInitFailed,
  CurlCode_LoginDenied,
  CurlCode_TFTPNotfound,
  CurlCode_TFTPPerm,
  CurlCode_RemoteDiskFull,
  CurlCode_TFTPIllegal,
  CurlCode_TFTPUnknownId,
  CurlCode_RemoteFileExists,
  CurlCode_TFTPNoSuchUser,
  CurlCode_ConvFailed,
  CurlCode_ConvReqd,
  CurlCode_SSLCACertBadfile,
  CurlCode_RemoteFileNotFound,
  CurlCode_SSH,
  CurlCode_SSLShutdownFailed,
  CurlCode_Again,
  CurlCode_SSLCRLBadfile,
  CurlCode_SSLIssuerError,
  CurlCode_FTPPretFailed,
  CurlCode_RTSPCseqError,
  CurlCode_RTSPSessionError,
  CurlCode_FTPBadFileList,
  CurlCode_ChunkFailed,
  CurlCode_NoConnectionAvailable,
  CurlCode_SSLPinnedPubKeyNotMatch,
  CurlCode_SSLInvalidCertStatus,
};

typedef NS_ENUM(NSInteger, CurlUseSSL) {
  CurlUseSSL_None,
  CurlUseSSL_Try,
  CurlUseSSL_Control,
  CurlUseSSL_All,
  CurlUseSSL_Last,
};

typedef NS_ENUM(NSInteger, CurlProgress) {
  CurlProgress_Continue = 0,
  CurlProgress_Abort = 1,
};

typedef NS_OPTIONS(NSUInteger, CurlHTTPAuth) {
  CurlHTTPAuth_None      = 0,
  CurlHTTPAuth_Basic     = (1 << 0),
  CurlHTTPAuth_Digest    = (1 << 1),
  CurlHTTPAuth_DigestIE  = (1 << 4),
  CurlHTTPAuth_Any       = ~CurlHTTPAuth_DigestIE,
  CurlHTTPAuth_AnySafe   = ~(CurlHTTPAuth_Basic | CurlHTTPAuth_DigestIE),
};

typedef NS_OPTIONS(NSUInteger, CurlHTTPVersion) {
  CurlHTTPVersion_None = 0,
  CurlHTTPVersion_HTTP10,
  CurlHTTPVersion_HTTP11,
  CurlHTTPVersion_HTTP20,
};

@class Curl;
@class CurlInfo;

typedef NSInteger (^WriteFunction)(const unsigned char *buffer, NSInteger size);
typedef NSInteger (^ReadFunction)(unsigned char *buffer, NSInteger size);
typedef CurlProgress (^ProgressFunction)(double downloadTotal, double downloadNow,
                                      double uploadTotal, double uploadNow);
typedef CurlProgress (^XferInfoFunction)(long downloadTotal, long downloadNow,
                                         long uploadTotal, long uploadNow);
typedef NSInteger (^HeaderFunction)(const unsigned char *buffer, NSInteger size);
typedef CurlCode (^SSLCtxFunction)(Curl *curl, void *sslCtx);

typedef void (^SetOptErrorCallback)(CurlCode errorCode);
typedef void (^GetInfoErrorCallback)(CurlCode errorCode);

@interface Curl : NSObject

@property (nonatomic, assign, readonly) CurlCode lastError;

#pragma mark - GLOBAL FUNCTIONS
/**
 curl_global_init - Global libcurl initialisation
 */
+ (CurlCode)globalInit;
/**
 curl_global_cleanup - global libcurl cleanup
 */
+ (void)globalCleanup;
/**
 curl_easy_strerror - return string describing error code
 */
+ (NSString *)errorString:(CurlCode)code;

#pragma mark - BEHAVIOR OPTIONS
/**
 CURLOPT_VERBOSE - Display verbose information.
 */
@property (nonatomic, assign) BOOL verbose;
/**
 CURLOPT_HEADER - Include the header in the body output.
 */
@property (nonatomic, assign) BOOL header;
/**
 CURLOPT_NOPROGRESS - switch off the progress meter
 */
@property (nonatomic, assign) BOOL noProgress;
/**
 CURLOPT_NOSIGNAL - skip all signal handling
 */
@property (nonatomic, assign) BOOL noSignal;
/**
 CURLOPT_WILDCARDMATCH - enable directory wildcard transfers
 */
@property (nonatomic, assign) BOOL wildCardMatch;

#pragma mark - CALLBACK OPTIONS
/**
 CURLOPT_WRITEFUNCTION - set callback for writing received data
 */
@property (nonatomic, copy) WriteFunction writeFunction;
/**
 CURLOPT_READFUNCTION - read callback for data uploads
 */
@property (nonatomic, copy) ReadFunction readFunction;
/**
 CURLOPT_PROGRESSFUNCTION - callback to progress meter function
 */
@property (nonatomic, copy) ProgressFunction progressFunction;
/**
 CURLOPT_XFERINFOFUNCTION - callback to progress meter function
 */
@property (nonatomic, copy) XferInfoFunction xferInfoFunction;
/**
 CURLOPT_HEADERFUNCTION - callback that receives header data
 */
@property (nonatomic, copy) HeaderFunction headerFunction;
/**
 CURLOPT_SSL_CTX_FUNCTION - openssl specific callback to do SSL magic
 */
@property (nonatomic, copy) SSLCtxFunction SSLCtxFunction;

#pragma mark - ERROR OPTIONS
/**
 CURLOPT_FAILONERROR - request failure on HTTP response >= 400
 */
@property (nonatomic, assign) BOOL failOnError;

#pragma mark - NETWORK OPTIONS
/**
 CURLOPT_URL - provide the URL to use in the request
 */
@property (nonatomic, copy) NSString *URL;
/**
 CURLOPT_PROXY - set proxy to use
 */
@property (nonatomic, copy) NSString *proxy;
/**
 CURLOPT_PROXYPORT - port number the proxy listens on
 */
@property (nonatomic, assign) NSInteger proxyPort;
/**
 CURLOPT_NOPROXY - disable proxy use for specific hosts
 */
@property (nonatomic, copy) NSString *noProxy;

#pragma mark - NAMES and PASSWORDS OPTIONS
/**
 CURLOPT_USERNAME - user name to use in authentication
 */
@property (nonatomic, copy) NSString *username;
/**
 CURLOPT_PASSWORD - password to use in authentication
 */
@property (nonatomic, copy) NSString *password;
/**
 CURLOPT_PROXYUSERNAME - user name to use for proxy authentication
 */
@property (nonatomic, copy) NSString *proxyUsername;
/**
 CURLOPT_PROXYPASSWORD - password to use with proxy authentication
 */
@property (nonatomic, copy) NSString *proxyPassword;
/**
 CURLOPT_HTTPAUTH - set HTTP server authentication methods to try
 */
@property (nonatomic, assign) CurlHTTPAuth HTTPAuth;

#pragma mark - HTTP OPTIONS
/**
 CURLOPT_ACCEPT_ENCODING - enables automatic decompression of HTTP downloads
 */
@property (nonatomic, copy) NSString *acceptEncoding;
/**
 CURLOPT_FOLLOWLOCATION - follow HTTP 3xx redirects
 */
@property (nonatomic, assign) BOOL followLocation;
/**
 CURLOPT_PUT - make a HTTP PUT request
 */
@property (nonatomic, assign) BOOL HTTPPut;
/**
 CURLOPT_POST - request a HTTP POST
 */
@property (nonatomic, assign) BOOL HTTPPost;
/**
 CURLOPT_COPYPOSTFIELDS - have libcurl copy data to POST
 */
@property (nonatomic, copy) NSData *postFields;
/**
 CURLOPT_USERAGENT - set HTTP user-agent header
 */
@property (nonatomic, copy) NSString *userAgent;
/**
 CURLOPT_HTTPHEADER - set custom HTTP headers
 */
@property (nonatomic, copy) NSArray *HTTPHeader;
/**
 CURLOPT_COOKIE - set contents of HTTP Cookie header
 */
@property (nonatomic, copy) NSString *cookie;
/**
 CURLOPT_HTTPGET - ask for a HTTP GET request
 */
@property (nonatomic, assign) BOOL HTTPGet;
/**
 CURLOPT_HTTP_VERSION - specify HTTP protocol version to use
 */
@property (nonatomic, assign) CurlHTTPVersion HTTPVersion;

#pragma mark - FTP OPTIONS
/**
 CURLOPT_QUOTE - (S)FTP commands to run before transfer
 */
@property (nonatomic, copy) NSArray *quote;
/**
 CURLOPT_POSTQUOTE - (S)FTP commands to run after the transfer
 */
@property (nonatomic, copy) NSArray *postQuote;
/**
 CURLOPT_PREQUOTE - commands to run before FTP or SFTP transfer
 */
@property (nonatomic, copy) NSString *preQuote;
/**
 CURLOPT_FTP_CREATE_MISSING_DIRS - create missing dirs for FTP and SFTP
 */
@property (nonatomic, assign) BOOL createMissingDir;

#pragma mark - PROTOCOL OPTIONS
/**
 CURLOPT_TRANSFERTEXT - request a text based transfer for FTP
 */
@property (nonatomic, assign) BOOL transferText;
/**
 CURLOPT_CUSTOMREQUEST - custom string for request
 */
@property (nonatomic, assign) NSString *customRequest;
/**
 CURLOPT_FILETIME - get the modification time of the remote resource
 */
@property (nonatomic, assign) BOOL fileTime;
/**
 CURLOPT_DIRLISTONLY - ask for names only in a directory listing
 */
@property (nonatomic, assign) BOOL dirListOnly;
/**
 CURLOPT_NOBODY - do the download request without getting the body
 */
@property (nonatomic, assign) BOOL noBody;
/**
 CURLOPT_INFILESIZE_LARGE - set size of the input file to send off
 */
@property (nonatomic, assign) long inFileSize;
/**
 CURLOPT_UPLOAD - enable data upload
 */
@property (nonatomic, assign) BOOL upload;

#pragma mark - CONNECTION OPTIONS
/**
 CURLOPT_USE_SSL - request using SSL / TLS for the transfer
 */
@property (nonatomic, assign) CurlUseSSL useSSL;

#pragma mark - SSL and SECURITY OPTIONS
/**
 CURLOPT_SSL_VERIFYHOST - verify the certificate's name against host
 */
@property (nonatomic, assign) BOOL SSLVerifyHost;
/**
 CURLOPT_SSL_VERIFYPEER - verify the peer's SSL certificate
 */
@property (nonatomic, assign) BOOL SSLVerifyPeer;
/**
 CURLOPT_SSL_VERIFYSTATUS - verify the certificate's status
 */
@property (nonatomic, assign) BOOL SSLVerifyStatus;
/**
 curl_easy_getinfo - extract information from a curl handle
 */
@property (nonatomic, strong, readonly) CurlInfo *info;
/**
 curl_easy_perform - perform a blocking file transfer
 */
- (CurlCode)perform;
/**
 curl_easy_reset - reset all options of a libcurl session handle
 */
- (void)reset;

- (void)cleanup;
@end

#pragma mark - CurlInfo

@interface CurlInfo : NSObject
@property (nonatomic, assign, readonly) CurlCode lastError;
/**
 CURLINFO_EFFECTIVE_URL - receive the last used effective URL.
 */
@property (nonatomic, readonly) NSString *effectiveURL;
/**
 CURLINFO_RESPONSE_CODE - receive the last received HTTP, FTP or SMTP response code.
 */
@property (nonatomic, readonly) NSInteger responseCode;
/**
 CURLINFO_FILETIME - receive the remote time of the retrieved document.
 */
@property (nonatomic, readonly) long fileTime;
/**
 CURLINFO_CONTENT_LENGTH_DOWNLOAD - receive the content-length of the download.
 */
@property (nonatomic, readonly) double contentLengthDownload;
/**
 CURLINFO_CONTENT_LENGTH_UPLOAD - receive the specified size of the upload.
 */
@property (nonatomic, readonly) double contentLengthUpload;
/**
 CURLINFO_SSL_VERIFYRESULT - receive the result of the certification verification that was requested.
 */
@property (nonatomic, readonly) NSInteger SSLVerifyResult;
/**
 CURLINFO_CONTENT_TYPE - receive the content-type of the downloaded object.
 */
@property (nonatomic, readonly) NSString *contentType;
/**
 CURLINFO_FTP_ENTRY_PATH - receive a pointer to a string holding the path of the entry path.
 */
@property (nonatomic, readonly) NSString *FTPEntryPath;
@end

#endif /* defined(__Curl__) */
