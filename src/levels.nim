import hangover
import objects
import strutils
import data
import glm
import algorithm

type
  Level* = ref object of Object
    walls*: seq[Wall]
    floors*: seq[Floor]
    fogColor*: Color
    fogDensity*: float32

  Wall* = object
    x1*, y1*: float32
    x2*, y2*: float32
    top*: float32
    bot*: float32
    cnorm*: Vec3[float32]
  Floor* = object
    x1*, y1*: float32
    x2*, y2*: float32
    x3*, y3*: float32
    z*: float32

template unit*(x: float32): float32 = x / 3

proc newLevel*(file: string): Level =
  result = Level()
  result.tex = newTexture("content/images/level.png")

  var verts: seq[Vert]

  for x in -10..10:
    for y in -10..10:
      var
        x1: float32 = 5 * x.float32
        y1: float32 = 5 * y.float32
        x2: float32 = 5 * x.float32 + 5
        y2: float32 = 5 * y.float32 + 5

      result.floors &= Floor(
        x1: x1, y1: y1,
        x2: x2, y2: y2,
        x3: x1, y3: y2,
        z: 0
      )
      result.floors &= Floor(
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

  for line in lines(file.open(fmRead)):
    var cmd = line.split(' ')[0]
    case cmd:
    of "wall":
      var z1 = line.split(' ')[1].parseFloat() / 10
      var z2 = line.split(' ')[2].parseFloat() / 10
      var x1 = line.split(' ')[3].parseFloat()
      var y1 = line.split(' ')[4].parseFloat()
      var x2 = line.split(' ')[5].parseFloat()
      var y2 = line.split(' ')[6].parseFloat()
      var normy = x2 - x1
      var normx = y2 - y1

      result.walls &= Wall(
        x1: x1, y1: y1,
        x2: x2, y2: y2,
        top: z2, bot: z1,
        cnorm: normalize(vec3(-normx.float32, 0, -normy.float32))
      )

      verts &= [
        Vert(x: x1, y: z1, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x2, y: z2, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
        Vert(x: x2, y: z1, z: y2, u: 1, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x1, y: z1, z: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
        Vert(x: x2, y: z2, z: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
        Vert(x: x1, y: z2, z: y1, u: 0, v: unit(1), xn: -normx, zn: -normy),
      ]
    of "floor":
      var z  = line.split(' ')[1].parseFloat() / 10
      var x1 = line.split(' ')[2].parseFloat()
      var y1 = line.split(' ')[3].parseFloat()
      var x2 = line.split(' ')[4].parseFloat()
      var y2 = line.split(' ')[5].parseFloat()
      var x3 = line.split(' ')[6].parseFloat()
      var y3 = line.split(' ')[7].parseFloat()

      result.floors &= Floor(
        x1: x1, y1: y1,
        x2: x2, y2: y2,
        x3: x3, y3: y3,
        z: z
      )
      verts &= [
        Vert(x: x1, y: z, z: y1, u: 0.0, v: unit(1), yn: -1),
        Vert(x: x2, y: z, z: y2, u: 1.0, v: unit(2), yn: -1),
        Vert(x: x3, y: z, z: y3, u: 0.0, v: unit(2), yn: -1),
      ]
  result.vertCount = len(verts)

  glGenBuffers(1, addr result.VBO)
  glBindBuffer(GL_ARRAY_BUFFER, result.VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts[0]) * len(verts), addr verts[0], GL_STATIC_DRAW)
  result.model = mat4(1'f32)
  result.fogDensity = 0.05

proc sign*(p1, p2, p3: Vec2[float32]): float =
  return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)

proc collide*(level: Level, p: Vec3[float32], vel: var Vec3[float32]) =
  var pos = inverse(level.model) * vec4(p, 1.0)
  var vy = vel.y
  vel.y = 0
  for wall in level.walls:
    if pos.y - PLAYER_HEIGHT + 0.5 in wall.bot..wall.top:
      var dir = normalize(vel)
      var v1 = pos.xz - vec2[float32](wall.x1, wall.y1)
      var v2 = vec2[float32](wall.x2, wall.y2) - vec2[float32](wall.x1, wall.y1)
      var v3 = vec2[float32](-dir.z, dir.x)

      var dp = dot(v2, v3)
      if abs(dp) < 0.000001:
        continue
      
      var t1 = (v2.x * v1.y - v1.x * v2.y) / dp
      var t2 = dot(v1, v3) / dp

      if t1 >= 0.0 and t1 <= vel.length() and (t2 >= -0.1 and t2 <= 1.1):
        vel -= dot(vel, wall.cnorm) * wall.cnorm
  vel.y = vy
  var pt = vec2[float32](pos.x, pos.z)
  var under: seq[float32]
  for floor in level.floors:
    var
      t1 = vec2[float32](floor.x1, floor.y1)
      t2 = vec2[float32](floor.x2, floor.y2)
      t3 = vec2[float32](floor.x3, floor.y3)
      
      d1 = sign(pt, t1, t2)
      d2 = sign(pt, t2, t3)
      d3 = sign(pt, t3, t1)
      
      has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
      has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)

    if not(has_neg and has_pos) and floor.z > min(pos.y, pos.y + vel.y) - PLAYER_HEIGHT:
      under &= floor.z

  under.sort()
  for u in under:

    # Bump up
    if (u - pos.y) <= 0:
      vel.y = (u + PLAYER_HEIGHT) - pos.y
    # collide
    if (u + PLAYER_HEIGHT - pos.y) <= abs(vel.y):
      vel.y = (u + PLAYER_HEIGHT - pos.y)
