import httpclient
import streams
import nimwebp.decoder
import base64
import hangover
import locks
import data
import json
import os

type
  OutputProcType = proc (str: pointer, base64: string, w, h: cint) {.closure, gcsafe, locks: "unknown".}

  GenThreadData = object  
    client*: HttpClient
    texture*: string
    prompt*: string
    default*: JsonNode
    outputProc*: OutputProcType

var
  globalClient: HttpClient

  thr: Thread[GenThreadData]

proc generateThread(input: GenThreadData) {.thread.} =
  try:
    var body = input.default
    body["prompt"] = %input.prompt

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
      echo $checkjson["wait_time"].getInt()
      sleep(1000)

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

  except ProtocolError, KeyError:
    discard

proc initHorde*() =
  globalClient = newHttpClient()

proc sendRequest*(prompt: string, texture: string, outputProc: OutputProcType ) =
  if not thr.running:
    echo prompt
    createThread(thr, generateThread, GenThreadData(prompt: prompt, client: globalClient, outputProc: outputProc, texture: texture, default: HORDE_DEFAULT))
  