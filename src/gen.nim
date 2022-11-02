import hangover
import objects
import levels
import glm

proc genLevel*(): Level =
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

      verts &= [
        Vert(x: x1, y: 0, z: y1, u: 0, v: unit(3), yn: -1),
        Vert(x: x2, y: 0, z: y2, u: 1, v: unit(2), yn: -1),
        Vert(x: x2, y: 0, z: y1, u: 1, v: unit(3), yn: -1),
        Vert(x: x1, y: 0, z: y1, u: 0, v: unit(3), yn: -1),
        Vert(x: x2, y: 0, z: y2, u: 1, v: unit(2), yn: -1),
        Vert(x: x1, y: 0, z: y2, u: 0, v: unit(2), yn: -1),
      ]
  for a in -10..10:
    var z1: float32 = 0
    var z2: float32 = 5
    var x1: float32 = a.float32 * 5
    var y1: float32 = 50
    var x2: float32 = a.float32 * 5 + 5
    var y2: float32 = 50
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
    verts &= [
      Vert(x: x1, y: z1, z: -y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
      Vert(x: x2, y: z2, z: -y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
      Vert(x: x2, y: z1, z: -y2, u: 1, v: unit(0), xn: -normx, zn: -normy),
      Vert(x: x1, y: z1, z: -y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
      Vert(x: x2, y: z2, z: -y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
      Vert(x: x1, y: z2, z: -y1, u: 0, v: unit(1), xn: -normx, zn: -normy),
    ]
    verts &= [
      Vert(z: x1, y: z1, x: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
      Vert(z: x2, y: z2, x: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
      Vert(z: x2, y: z1, x: y2, u: 1, v: unit(0), xn: -normx, zn: -normy),
      Vert(z: x1, y: z1, x: y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
      Vert(z: x2, y: z2, x: y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
      Vert(z: x1, y: z2, x: y1, u: 0, v: unit(1), xn: -normx, zn: -normy),
    ]
    verts &= [
      Vert(z: x1, y: z1, x: -y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
      Vert(z: x2, y: z2, x: -y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
      Vert(z: x2, y: z1, x: -y2, u: 1, v: unit(0), xn: -normx, zn: -normy),
      Vert(z: x1, y: z1, x: -y1, u: 0, v: unit(0), xn: -normx, zn: -normy),
      Vert(z: x2, y: z2, x: -y2, u: 1, v: unit(1), xn: -normx, zn: -normy),
      Vert(z: x1, y: z2, x: -y1, u: 0, v: unit(1), xn: -normx, zn: -normy),
    ]
  result.vertCount = len(verts)

  glGenBuffers(1, addr result.VBO)
  glBindBuffer(GL_ARRAY_BUFFER, result.VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts[0]) * len(verts), addr verts[0], GL_STATIC_DRAW)
  result.model = mat4(1'f32)