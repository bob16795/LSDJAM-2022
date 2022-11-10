import hangover
import camera
import glm
import objects
import data

type
  Portal* = ref object of Object
    verts*: array[8, Vert]
    dst*: int

const
  indices = [
    0.GLuint,1,3,  3,2,0,
    4,5,6, 6,5,7,
    0,4,2, 2,4,6,
    5,1,7, 7,1,3,
  ]

template portalVerts(dx, dy, dz: float32): untyped =
  [
    Vert(x: -1.GLfloat, y: -1, z: 0),
    Vert(x:  1.GLfloat, y: -1, z: 0),
    Vert(x: -1.GLfloat, y:  1, z: 0),
    Vert(x:  1.GLfloat, y:  1, z: 0),
    
    Vert(x: -(1-dx), y: -(1-dy), z: 0-dz),
    Vert(x:  (1-dx), y: -(1-dy), z: 0-dz),
    Vert(x: -(1-dx), y:  (1-dy), z: 0-dz),
    Vert(x:  (1-dx), y:  (1-dy), z: 0-dz),
  ]

proc newPortal*(size: Vector2, Tw: Mat4[float32]): Portal =
  result = Portal()
  result.dst = -1

  var
    aspect = size.x / size.y
    fovy_rad = FOVY * PI / 180
    fovx_rad = fovy_rad / aspect
    
    dz = max(ZNEAR / cos(fovx_rad), ZNEAR / cos(fovy_rad))
    dx = tan(fovx_rad) * dz
    dy = tan(fovy_rad) * dz
    verts = portalVerts(dx, dy, dz)

  glGenBuffers(1, addr result.VBO)
  glBindBuffer(GL_ARRAY_BUFFER, result.VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts), addr verts, GL_STATIC_DRAW)

  glGenBuffers(1, addr result.EBO)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.EBO)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), addr indices, GL_STATIC_DRAW)

  result.verts = verts
  result.model = Tw
  result.vertCount = len(indices)

proc respawn*(p: var Portal, size: Vector2) =
  var
    aspect = size.x / size.y
    fovy_rad = FOVY * PI / 180
    fovx_rad = fovy_rad / aspect
    
    dz = max(ZNEAR / cos(fovx_rad), ZNEAR / cos(fovy_rad))
    dx = tan(fovx_rad) * dz
    dy = tan(fovy_rad) * dz
    verts = portalVerts(dx, dy, dz)

  glGenBuffers(1, addr p.VBO)
  glBindBuffer(GL_ARRAY_BUFFER, p.VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts), addr verts, GL_STATIC_DRAW)

  glGenBuffers(1, addr p.EBO)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, p.EBO)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), addr indices, GL_STATIC_DRAW)

  p.verts = verts

template toWorld*(p: Portal): Mat4[float32] =
  p.model

proc getView*(p: Portal, orig_view: Mat4[float32], dst: Portal): Mat4[float32] =
  var mv = orig_view * p.model
  result = mv * rotate(mat4(1.0'f32), radians(180.0'f32), vec3(0.0'f32,1.0,0.0)) * inverse(dst.model)

proc toGLM*(p: Portal, v: int): Vec3[float32] =
  var r = vec4(p.verts[v].x, p.verts[v].y, p.verts[v].z, 1.0)
  return vec3(r.x, r.y, r.z)

proc contains*(p: Portal, start, stop: Vec3[float32]): bool =
  if start == stop:
    return false

  var
    ap = inverse(p.model) * vec4(start, 1.0)
    bp = inverse(p.model) * vec4(stop, 1.0)

  if ap.y in -1'f32..1'f32:
    var dir = normalize(bp.xz - ap.xz)
    var v1 = ap.xz - vec2[float32](1, 0)
    var v2 = vec2[float32](-2, 0)
    var v3 = vec2[float32](-dir.y, dir.x)

    var dp = dot(v2, v3)
    if abs(dp) < 0.000001:
      return false
    
    var t1 = (v2.x * v1.y - v1.x * v2.y) / dp
    var t2 = dot(v1, v3) / dp

    if t1 >= 0.0 and t1 <= (bp.xz - ap.xz).length() and (t2 >= -0.1 and t2 <= 1.1):
      return true
  return false