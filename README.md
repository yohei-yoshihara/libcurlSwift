# libcurlSwift

libcurlSwift is the simple wrapper (Objective-C classes) to access libcurl from Swift.

## Installation
Copy "Curl.h" and "Curl.m" to your project.

## Example

### HTTP Get
```Swift
Curl.globalInit()

let curl = Curl()
curl.URL = "http://example.com"
let res = curl.perform()
if res != CurlCode.OK {
  let errmsg = Curl.errorString(res)
  println("curl.perform() failed: \(errmsg)")
}

Curl.globalCleanup()
```

### HTTP Get (Write the received body to a file)
```Swift
Curl.globalInit()

let body = NSOutputStream(toFileAtPath: "/tmp/body.txt", append: false)!
body.open()

let curl = Curl()
curl.URL = "http://example.com"
curl.writeFunction = {(buffer, size) in
  return body.write(buffer, maxLength: size)
}
curl.perform()

body.close()

Curl.globalCleanup()
```

## License

MIT License
