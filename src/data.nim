import hangover
import json
import os

type
  WorldData* = object
    models*: seq[string]
    pix*: seq[string]
    ceiling*: bool
    tex*: string
    mapsizex*: HSlice[int, int]
    mapsizey*: HSlice[int, int]
    tilesize*: HSlice[float, float]
    height*: HSlice[float, float]
    spacer*: HSlice[float, float]
    doors*: HSlice[int, int]
    fogColor*: Color
    fogDensity*: float32

var
  HORDE_DEFAULT* = %*{
    "params": {
      "n": 1,
      "width": 64,
      "height": 192,
      "steps": 50,
      "sampler_name": "k_euler",
      "cfg_scale": 15,
      "seed": "",
      "denoising_strength": 0.25
    },
    "nsfw": false,
    "models": ["stable_diffusion"]
  }
  FOVY*: float32 = 45
  ZNEAR*: float32 = 0.1
  ZFAR*: float32 = 1000
  RECURSION*: int = 1
  BG_COLOR*: Color = newColor(145, 145, 255, 255)
  SENSITIVITY*: float32 = 0.05
  WALK_SPEED*: float32 = 10
  PLAYER_HEIGHT*: float32 = 2.0
  GRAVITY*: float32 = -5

  UI_MULT*: float32 = 20
  UI_SCALE*: float32 = 1 / 10
  UI_BORDER*: float32 = 1 / 10
  FONT_MULT*: float32 = 7
  FONT_SIZE*: int = 48

  WORLD_SPACING*: float32 = 300

  PROC_DATA* = @[
    WorldData(
      models: @[
        "content/objects/grave1.obj"
      ],
      pix: @[
        "content/images/uv.png"
      ],
      tex: "content/images/level1.png",
      ceiling: false,
      mapsizex: 5..7,
      mapsizey: 5..7,
      doors: 2..4,
      tilesize: 3.0..3.0,
      height: 3.0..3.0,
      spacer: 0.0..0.0, 
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    ),
    WorldData(
      models: @[
        "content/objects/bed1.obj",
        "content/objects/chair1.obj",
      ],
      pix: @[
        "content/images/rock.png",
        "content/images/musk.png"
      ],
      tex: "content/images/level2.png",
      ceiling: true,
      mapsizex: 5..7,
      mapsizey: 5..7,
      doors: 2..4,
      tilesize: 3.0..3.0,
      height: 3.0..3.0,
      spacer: 3.0..4.0,
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    ),
    WorldData(
      models: @[
        "content/objects/couch1.obj"
      ],
      pix: @[
        "content/images/rock.png",
        "content/images/musk.png"
      ],
      tex: "content/images/level3.png",
      ceiling: true,
      mapsizex: 2..3,
      mapsizey: 20..25,
      doors: 2..4,
      tilesize: 3.0..3.0,
      height: 3.0..3.0,
      spacer: 3.0..4.0,
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    ),
    WorldData(
      models: @[
        "content/objects/mushroomT1.obj",
        "content/objects/mushroomT2.obj",
        "content/objects/mushroomT3.obj",
      ],
      pix: @[
        "content/images/uv.png"
      ],
      tex: "content/images/level4.png",
      ceiling: false,
      mapsizex: 10..12,
      mapsizey: 10..12,
      doors: 2..4,
      tilesize: 3.0..3.0,
      height: 3.0..3.0,
      spacer: 30.0..30.0, 
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    ),
  ]

proc getNode(n: JsonNode): JsonNode = n

proc getColor(n: JsonNode): Color =
  result = newColor(255, 255, 255, 255)
  if n{"r"} != nil:
    result.r = n{"r"}.getInt().uint8
  if n{"g"} != nil:
    result.r = n{"g"}.getInt().uint8
  if n{"b"} != nil:
    result.r = n{"b"}.getInt().uint8
  if n{"a"} != nil:
    result.r = n{"a"}.getInt().uint8

proc getRooms(n: JsonNode): seq[WorldData] =
  for room in n.getElems:
    template setRange(v: untyped, getter: untyped, keys: varargs[string]): untyped =
      if room{keys} != nil:
        v = room{keys}{"min"}.getter()..room{keys}{"max"}.getter()
    result &= WorldData(
      tilesize: 3.0..3.0,
      height: 3.0..3.0,
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    )
    if room{"models"} != nil:
      for model in room{"models"}:
        result[^1].models &= model.getStr()
    if room{"texture"} != nil:
      result[^1].tex = room{"texture"}.getStr()
    if room{"ceiling"} != nil:
      result[^1].ceiling = room{"ceiling"}.getBool()
    setRange(result[^1].mapsizex, getInt, "mapsizex")
    setRange(result[^1].mapsizey, getInt, "mapsizey")
    setRange(result[^1].doors, getInt, "doorcount")
    setRange(result[^1].spacer, getFloat, "spacer")

proc initData*() =
  if existsFile("content/debug.json"):
    var cfg_json = parseJson(readFile("content/debug.json"))

    template setJson(v: untyped, getter: untyped, keys: varargs[string]): untyped =
      if cfg_json{keys} != nil:
        v = cfg_json{keys}.getter()

    setJson(HORDE_DEFAULT, getNode, "horde_config")

    setJson(FOVY, getFloat, "view", "fovy")
    setJson(ZNEAR, getFloat, "view", "znear")
    setJson(ZFAR, getFloat, "view", "zfar")
    setJson(RECURSION, getInt, "view", "recursion")
    setJson(BG_COLOR, getColor, "view", "bg")
    setJson(WORLD_SPACING, getFloat, "view", "worldspacing")

    setJson(SENSITIVITY, getFloat, "input", "sensitivity")
    setJson(WALK_SPEED, getFloat, "input", "walkspeed")
    setJson(GRAVITY, getFloat, "input", "gravity")

    setJson(UI_MULT, getFloat, "ui", "mult")
    setJson(UI_SCALE, getFloat, "ui", "texscale")
    setJson(UI_BORDER, getFloat, "ui", "texborder")
    setJson(FONT_MULT, getFloat, "ui", "fontmult")
    setJson(FONT_SIZE, getInt, "ui", "fontsize")

    setJson(PROC_DATA, getRooms, "rooms")