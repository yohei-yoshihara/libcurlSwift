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

import Foundation

func httpput() {
  let file = "/tmp/a.txt"
  let url = "http://example.com/test.php"
  
  let fmgr = NSFileManager.defaultManager()
  let attributes = fmgr.attributesOfItemAtPath(file, error: nil)!
  let fileSize = attributes[NSFileSize] as! NSNumber
  
  let src = NSInputStream(fileAtPath: file)!
  
  Curl.globalInit()
  let curl = Curl()
  curl.verbose = true
  curl.readFunction = {(buffer, size) in
    return src.read(buffer, maxLength: size)
  }
  curl.upload = true
  curl.HTTPPut = true
  curl.URL = url
  curl.inFileSize = fileSize.longValue
  let res = curl.perform()
  if (res != CurlCode.OK) {
    let errmsg = Curl.errorString(res)
    println("curl.perform() failed: \(errmsg)")
  }
  src.close()
  Curl.globalCleanup()
}

