import hangover
import objects
import portal
import levels
import random
import data
import glm

type
  GenOutput* = object
    level*: Level
    portals*: seq[Portal]
    objects*: seq[Object]
  RoomStats* = object
    models*: seq[Object]
    ceiling*: bool
    tex*: Texture
    mapsizex*: HSlice[int, int]
    mapsizey*: HSlice[int, int]
    tilesize*: HSlice[float, float]
    height*: HSlice[float, float]
    spacer*: HSlice[float, float]
    doors*: HSlice[int, int]
    fogColor*: Color
    fogDensity*: float32


var
  screenSize*: Vector2

  roomData*: seq[RoomStats]

proc newRoom*(tex: Texture) =
  roomData &= RoomStats()
  var d = sample(PROC_DATA)
  for m in d.models:
    roomData[^1].models &= newObject(m)
  roomData[^1].ceiling = d.ceiling
  roomData[^1].mapsizex = d.mapsizex
  roomData[^1].mapsizey = d.mapsizey
  roomData[^1].tilesize = d.tilesize
  roomData[^1].height = d.height
  roomData[^1].spacer = d.spacer
  roomData[^1].doors = d.doors
  roomData[^1].fogColor = d.fogColor
  roomData[^1].fogDensity = d.fogDensity
  roomData[^1].tex = tex

proc genData*() =
  var d = sample(PROC_DATA)
  roomData &= RoomStats()
  for m in d.models:
    roomData[^1].models &= newObject(m)
  roomData[^1].ceiling = d.ceiling
  roomData[^1].tex = newTexture(d.tex)
  roomData[^1].mapsizex = d.mapsizex
  roomData[^1].mapsizey = d.mapsizey
  roomData[^1].tilesize = d.tilesize
  roomData[^1].height = d.height
  roomData[^1].spacer = d.spacer
  roomData[^1].doors = d.doors
  roomData[^1].fogColor = d.fogColor
  roomData[^1].fogDensity = d.fogDensity
    
proc genLevel*(translate = mat4(1'f32), idx = 0, seed = 0, rec = 0): GenOutput =
  result.level = Level()

  if seed != 0:
    randomize(seed)

  if roomData == @[]:
    genData()

  var data = sample(roomData)

  result.level.tex = data.tex
  

  ## Generate world
  var verts: seq[Vert]
  var sizex: int = rand(data.mapsizex)
  var sizey: int = rand(data.mapsizey)
  var height: float = rand(data.height)
  var spacer: float = rand(data.spacer)

  var tilesize: float = rand(data.tilesize)

  for x in -sizex..sizex:
    for y in -sizey..sizey:
      var
        x1: float32 = tilesize * x.float32 - tilesize / 2
        y1: float32 = tilesize * y.float32 - tilesize / 2
        x2: float32 = tilesize * x.float32 + tilesize / 2
        y2: float32 = tilesize * y.float32 + tilesize / 2

      result.level.floors &= Floor(
        x1: x1, y1: y1,
        x2: x2, y2: y2,
        x3: x1, y3: y2,
        z: 0
      )
      result.level.floors &= Floor(
        x1: x1, y1: y1,
        x2: x2, y2: y2,
        x3: x2, y3: y1,
        z: 0
      )

      verts &= [
        Vert(x: x1, y: 0, z: y1, u: 0, v: unit(3), yn: -1),
        Vert(x: x2, y: 0, z: y2, u: 1, v: unit(2), yn: -1),
        Vert(x: x2, y: 0, z: y1, u: 1, v: unit(3), yn: -1),
        Vert(x: x1, y: 0, z: y1, u: 0, v: unit(3), yn: -1),
        Vert(x: x2, y: 0, z: y2, u: 1, v: unit(2), yn: -1),
        Vert(x: x1, y: 0, z: y2, u: 0, v: unit(2), yn: -1),
      ]
      if data.ceiling:
        verts &= [
          Vert(x: x1, y: height + spacer, z: y1, u: 0, v: unit(2), yn: -1),
          Vert(x: x2, y: height + spacer, z: y2, u: 1, v: unit(1), yn: -1),
          Vert(x: x2, y: height + spacer, z: y1, u: 1, v: unit(2), yn: -1),
          Vert(x: x1, y: height + spacer, z: y1, u: 0, v: unit(2), yn: -1),
          Vert(x: x2, y: height + spacer, z: y2, u: 1, v: unit(1), yn: -1),
          Vert(x: x1, y: height + spacer, z: y2, u: 0, v: unit(1), yn: -1),
        ]
  var dc = rand(data.doors)
  var doors: seq[int]
  for di in 0..dc:
    var side = rand(0..1)
    case side:
    of 0:
      doors &= rand(2..sizex * 4 - 4)
    of 1:
      doors &= rand(2..sizey * 4 - 4) + 4 * sizex
    else:
      discard
  
  var idx = 0

  for a in -sizex..sizex:
    var z1: float32 = 0
    var z2: float32 = height
    var z3: float32 = height + spacer
    var x1: float32 = a.float32 * tilesize + tilesize / 2
    var y1: float32 = sizey.float32 * tilesize
    var x2: float32 = a.float32 * tilesize - tilesize / 2
    var y2: float32 = sizey.float32 * tilesize
    var normy = x2 - x1
    var normx = y2 - y1

    verts &= [
        Vert(x: x1, y: z2, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x2, y: z3, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
        Vert(x: x2, y: z2, z: y2, u: 1, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x1, y: z2, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x2, y: z3, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
        Vert(x: x1, y: z3, z: y1, u: 0, v: unit(1), xn: -normx, zn: -normy),
      ]

    if not(idx in doors) or abs(a) == sizex:
      verts &= [
        Vert(x: x1, y: z1, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x2, y: z2, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
        Vert(x: x2, y: z1, z: y2, u: 1, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x1, y: z1, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x2, y: z2, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
        Vert(x: x1, y: z2, z: y1, u: 0, v: unit(1), xn: -normx, zn: -normy),
      ]
      result.level.walls &= Wall(
        x1: x1, y1: y1,
        x2: x2, y2: y2,
        top: z2, bot: z1,
        cnorm: normalize(vec3(-normx.float32, 0, -normy.float32))
      )
    else:
      result.portals &= newPortal(
        screenSize,
        translate *
        scale(mat4(1'f32), vec3(tilesize.float32 / 2, height / 2, tilesize / 2)) *
        translate(mat4(1'f32), vec3(a.float32 * 2, 1, sizey.float32 * 2))
      ) 


    idx += 1

    verts &= [
        Vert(x: x1, y: z2, z: -y1, u: 0, v: unit(0), xn: normx, zn: -normy),
        Vert(x: x2, y: z3, z: -y2, u: 1, v: unit(1), xn: normx, zn: -normy),
        Vert(x: x2, y: z2, z: -y2, u: 1, v: unit(0), xn: normx, zn: -normy),
        Vert(x: x1, y: z2, z: -y1, u: 0, v: unit(0), xn: normx, zn: -normy),
        Vert(x: x2, y: z3, z: -y2, u: 1, v: unit(1), xn: normx, zn: -normy),
        Vert(x: x1, y: z3, z: -y1, u: 0, v: unit(1), xn: normx, zn: -normy),
    ]

    if not(idx in doors) or abs(a) == sizex:
      verts &= [
        Vert(x: x1, y: z1, z: -y1, u: 0, v: unit(0), xn: normx, zn: -normy),
        Vert(x: x2, y: z2, z: -y2, u: 1, v: unit(1), xn: normx, zn: -normy),
        Vert(x: x2, y: z1, z: -y2, u: 1, v: unit(0), xn: normx, zn: -normy),
        Vert(x: x1, y: z1, z: -y1, u: 0, v: unit(0), xn: normx, zn: -normy),
        Vert(x: x2, y: z2, z: -y2, u: 1, v: unit(1), xn: normx, zn: -normy),
        Vert(x: x1, y: z2, z: -y1, u: 0, v: unit(1), xn: normx, zn: -normy),
      ]
      result.level.walls &= Wall(
          x1: x1, y1: -y1,
          x2: x2, y2: -y2,
          top: z2, bot: z1,
          cnorm: normalize(vec3(normx.float32, 0, -normy.float32))
        )
    else:
      result.portals &= newPortal(
        screenSize,
        translate *
        scale(mat4(1'f32), vec3(tilesize.float32 / 2, height / 2, tilesize / 2)) *
        translate(mat4(1'f32), vec3(a.float32 * 2, 1, -sizey.float32 * 2)) *
        rotate(mat4(1'f32), radians(180'f32), vec3(0'f32, 1.0, 0))
      ) 

    idx += 1

  for a in -sizey..sizey:
    var z1: float32 = 0
    var z2: float32 = height
    var z3: float32 = height + spacer
    var x1: float32 = sizex.float32 * tilesize
    var y1: float32 = a.float32 * tilesize + tilesize / 2
    var x2: float32 = sizex.float32 * tilesize
    var y2: float32 = a.float32 * tilesize - tilesize / 2
    var normy = x2 - x1
    var normx = y2 - y1

    verts &= [
      Vert(x: x1, y: z2, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
      Vert(x: x2, y: z3, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
      Vert(x: x2, y: z2, z: y2, u: 1, v: unit(0), xn: -normx, zn: -normy),
      Vert(x: x1, y: z2, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
      Vert(x: x2, y: z3, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
      Vert(x: x1, y: z3, z: y1, u: 0, v: unit(1), xn: -normx, zn: -normy),
    ]

    if not(idx in doors) or abs(a) == sizey:
      verts &= [
        Vert(x: x1, y: z1, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x2, y: z2, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
        Vert(x: x2, y: z1, z: y2, u: 1, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x1, y: z1, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x2, y: z2, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
        Vert(x: x1, y: z2, z: y1, u: 0, v: unit(1), xn: -normx, zn: -normy),
      ]
      result.level.walls &= Wall(
        x1: x1, y1: y1,
        x2: x2, y2: y2,
        top: z2, bot: z1,
        cnorm: normalize(vec3(-normx.float32, 0, -normy.float32))
      )
    else:
      result.portals &= newPortal(
        screenSize,
        translate *
        scale(mat4(1'f32), vec3(tilesize.float32 / 2, height / 2, tilesize / 2)) *
        translate(mat4(1'f32), vec3(a.float32 * 2, 1, sizex.float32 * 2).zyx) *
        rotate(mat4(1'f32), radians(90'f32), vec3(0'f32, 1.0, 0))
      ) 

    idx += 1

    verts &= [
      Vert(x: -x1, y: z2, z: y1, u: 0, v: unit(0), xn: -normx, zn: normy),
      Vert(x: -x2, y: z3, z: y2, u: 1, v: unit(1), xn: -normx, zn: normy),
      Vert(x: -x2, y: z2, z: y2, u: 1, v: unit(0), xn: -normx, zn: normy),
      Vert(x: -x1, y: z2, z: y1, u: 0, v: unit(0), xn: -normx, zn: normy),
      Vert(x: -x2, y: z3, z: y2, u: 1, v: unit(1), xn: -normx, zn: normy),
      Vert(x: -x1, y: z3, z: y1, u: 0, v: unit(1), xn: -normx, zn: normy),
    ]

    if not(idx in doors) or abs(a) == sizey:
      verts &= [
        Vert(x: -x1, y: z1, z: y1, u: 0, v: unit(0), xn: -normx, zn: normy),
        Vert(x: -x2, y: z2, z: y2, u: 1, v: unit(1), xn: -normx, zn: normy),
        Vert(x: -x2, y: z1, z: y2, u: 1, v: unit(0), xn: -normx, zn: normy),
        Vert(x: -x1, y: z1, z: y1, u: 0, v: unit(0), xn: -normx, zn: normy),
        Vert(x: -x2, y: z2, z: y2, u: 1, v: unit(1), xn: -normx, zn: normy),
        Vert(x: -x1, y: z2, z: y1, u: 0, v: unit(1), xn: -normx, zn: normy),
      ]
      result.level.walls &= Wall(
        x1: -x1, y1: y1,
        x2: -x2, y2: y2,
        top: z2, bot: z1,
        cnorm: normalize(vec3(-normx.float32, 0, normy.float32))
      )
    else:
      result.portals &= newPortal(
        screenSize,
        translate *
        scale(mat4(1'f32), vec3(tilesize.float32 / 2, height / 2, tilesize / 2)) *
        translate(mat4(1'f32), vec3(a.float32 * 2, 1, -sizex.float32 * 2).zyx) *
        rotate(mat4(1'f32), radians(270'f32), vec3(0'f32, 1.0, 0))
      ) 
    idx += 1

  result.level.vertCount = len(verts)

  glGenBuffers(1, addr result.level.VBO)
  glBindBuffer(GL_ARRAY_BUFFER, result.level.VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts[0]) * len(verts), addr verts[0], GL_STATIC_DRAW)
  result.level.model = mat4(1'f32) * translate
  result.level.fogColor = data.fogColor
  result.level.fogDensity = data.fogDensity

  result.objects &= cloneObject(sample(data.models), translate)

  for p in result.portals:
    p.level = idx