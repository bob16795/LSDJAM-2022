import ../../content/files

import random
import strutils
import tables
import json

# A game texture of {surfaces} by {artists}, {styles}

var dicts: Table[string, seq[string]]
var prompts: seq[string]

proc regDict*(name: string, data: string) =
  dicts[name] = @[]
  for l in data.split("\n"):
    dicts[name] &= l

proc regPrompt*(prompt: string) =
  prompts &= prompt

proc genprompt*(): string =
  var
    temp = sample(prompts)
    prompt = ""
    inCurly = false

    curly = ""

  for ch in temp:
    case ch:
    of '{':
      inCurly = true
      
    of '}':
      inCurly = false

      prompt &= sample(dicts[curly])
      curly = ""
    else:
      if inCurly:
        curly &= ch
      else:
        prompt &= ch
  
  return prompt

proc importPromptJson*(data: string) =
  var json = parseJson(data)

  for node in json["files"]:
    regDict(node["name"].getStr(), $res(node["file"].getStr()))

  for node in json["prompts"]:
    regPrompt(node["prompt"].getStr())