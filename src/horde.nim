import httpclient
import streams
import nimwebp.decoder
import base64
import hangover
import locks
import json
import os

type
  OutputProcType = proc (str: pointer, base64: string, w, h: cint) {.closure, gcsafe, locks: "unknown".}

  GenThreadData = object  
    client*: HttpClient
    texture*: string
    prompt*: string
    outputProc*: OutputProcType

var
  globalClient: HttpClient

  thr: Thread[GenThreadData]

proc generateThread(input: GenThreadData) {.thread.} =
  echo input.prompt

  try:
    var body = %*{
      "prompt": input.prompt,
      "params": {
        "n": 1,
        "width": 64,
        "height": 128 + 64,
        "steps": 50,
        "sampler_name": "k_euler",
        "cfg_scale": 15,
        "seed": "",
        "denoising_strength": 0.25
      },
      "nsfw": false,
      "models": ["stable_diffusion"]
    }
    if input.texture != "":
      body["source_image"] = %input.texture

    let headers = newHttpHeaders()
    headers["Content-Type"] = "application/json"
    # headers["apikey"] = "P6xbWJRH7m-XorIMPkUsXw"
    headers["apikey"] = "0000000000"

    let
      response = input.client.request("https://stablehorde.net/api/v2/generate/async", headers = headers, httpMethod = HttpPost, body = $body)
      data = response.bodyStream.readAll()
      json = parseJson(data)
    echo $json
    let
      id = json["id"].getStr()

    while true:
      var got: bool
      var checkresp: Response
      while not got:
        try:
          checkresp = input.client.request("https://stablehorde.net/api/v2/generate/check/" & id)
          got = true
        except:
          sleep(1000)
      let
        checkdata = checkresp.bodyStream.readAll()
        checkjson = parseJson(checkdata)

      if checkjson["done"].getBool:
        break
      echo $checkjson
      sleep(1000)

    echo "generated"

    let
      statusresp = input.client.request("https://stablehorde.net/api/v2/generate/status/" & id)
      statusdata = statusresp.bodyStream.readAll()
      statusjson = parseJson(statusdata)
      base64 = statusjson["generations"][^1]["img"].getStr()
      decoded = decode(statusjson["generations"][^1]["img"].getStr())
    var
      dataBuff = cast[ptr uint8](addr decoded[0])
      dataSize = len(decoded)
      w: cint
      h: cint
    var decodedbytes = webpDecodeRGBA(dataBuff, dataSize.cint, addr w, addr h)

    input.outputProc(decodedbytes, base64, w, h)

    echo "done"
  except ProtocolError:
    echo ":("

proc initHorde*() =
  globalClient = newHttpClient()

proc sendRequest*(prompt: string, texture: string, outputProc: OutputProcType ) =
  if not thr.running:
    createThread(thr, generateThread, GenThreadData(prompt: prompt, client: globalClient, outputProc: outputProc, texture: texture))

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
  