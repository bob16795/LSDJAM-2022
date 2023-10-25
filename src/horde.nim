import httpclient
import streams
import nimwebp.decoder
import base64
import hangover
import locks
import data
import json
import os
import stablediffusion
import cppstl

type
  OutputProcType = proc (str: pointer, base64: string, w, h: cint) {.closure, gcsafe, locks: "unknown".}

  GenThreadData = object
    texture*: string
    prompt*: string
    default*: JsonNode
    outputProc*: OutputProcType

var
  thr: Thread[GenThreadData]
  sd: StableDiffusion

proc generateThread(input: GenThreadData) {.thread.} =
    let vec = sd.txt2img(initCppString(input.prompt), initCppString(""), 7.5, 128, 128 * 3, DPM2, 1, 1024)

    input.outputProc(unsafeAddr vec[0], "", 128, 128 * 3)

proc initHorde*() =
  sd = constructstablediffusion()
  if sd.loadFromFile(initCppString("test.bin")):
    echo "loaded ai"

proc sendRequest*(prompt: string, texture: string, outputProc: OutputProcType ) =
  if not thr.running:
    echo prompt
    createThread(thr, generateThread, GenThreadData(prompt: prompt, outputProc: outputProc, texture: texture, default: HORDE_DEFAULT))
  
