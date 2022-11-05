import httpclient
import streams
import nimwebp.decoder
import base64
import locks
import json
import os

type
  GenThreadData = object  
    client*: HttpClient
    prompt*: string
    outputProc*: proc (str: pointer, w, h: cint) {.closure, gcsafe, locks: "unknown".}

var
  globalClient: HttpClient
  genLock: Lock

  thr: Thread[GenThreadData]

proc generateThread(input: GenThreadData) {.thread.} =
  acquire(genLock)

  try:
    let body = %*{
      "prompt": input.prompt,
      "params": {
        "n": 1,
        "width": 128,
        "height": 384,
        "steps": 30,
        "sampler_name": "k_euler",
        "cfg_scale": 7.5,
        "seed": "",
      },
      "nsfw": false,
      "models": ["stable_diffusion"]
    }

    let headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    # headers["apikey"] = "P6xbWJRH7m-XorIMPkUsXw"
    headers["apikey"] = "0000000000"

    let
      response = input.client.request("https://stablehorde.net/api/v2/generate/async", headers = headers, httpMethod = HttpPost, body = $body)
      data = response.bodyStream.readAll()
      json = parseJson(data)
      id = json["id"].getStr()

    while true:
      let
        checkresp = input.client.request("https://stablehorde.net/api/v2/generate/check/" & id)
        checkdata = checkresp.bodyStream.readAll()
        checkjson = parseJson(checkdata)

      if checkjson["done"].getBool:
        break
      echo $checkjson
      sleep(1000)

    let
      statusresp = input.client.request("https://stablehorde.net/api/v2/generate/status/" & id)
      statusdata = statusresp.bodyStream.readAll()
      statusjson = parseJson(statusdata)
      decoded = decode(statusjson["generations"][^1]["img"].getStr())
    var
      dataBuff = cast[ptr uint8](addr decoded[0])
      dataSize = len(decoded)
      w: cint
      h: cint
    var decodedbytes = webpDecodeRGBA(dataBuff, dataSize.cint, addr w, addr h)

    input.outputProc(decodedbytes, w, h)

    echo "done"
  except ProtocolError:
    echo ":("

  release(genLock)

proc initHorde*() =
  globalClient = newHttpClient()
  initLock(genLock)

proc sendRequest*(prompt: string, outputProc: proc (data: pointer, w, h: cint) {.closure, gcsafe, locks: "unknown".} ) =
  if not thr.running:
    createThread(thr, generateThread, GenThreadData(prompt: prompt, client: globalClient, outputProc: outputProc))


# when isMainModule:
#   var output = proc (data: pointer, w, h: cint) {.closure, gcsafe, locks: "unknown".} =
#     var f = open("lol.webp", fmWrite)
#     f.write(data)
#     f.close()

#   initHorde()
#   sendRequest("grass", output)
#   deinitLock(genLock)

#   while true:
#     if not thr.running:
#       break
#   echo "done"
  