import hangover
import glm
import objects
import data

type
  Obj2D* = ref object
    tex: Texture
    pos*: Vec3[float32]
    ebo: GLuint
    vbo: GLuint

const objverts = [
    vec3(-0.5.GLfloat, -0.5, 0),
    vec3( 0.5.GLfloat, -0.5, 0),
    vec3(-0.5.GLfloat,  0.5, 0),
    vec3( 0.5.GLfloat,  0.5, 0)
]

const indices = [0.GLuint, 3, 2, 0, 3, 1]

proc newObj2d*(tex: Texture): Obj2D =
  result = Obj2D()

  result.tex = tex

  glGenBuffers(1, addr result.vbo)
  glGenBuffers(1, addr result.ebo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.ebo)
  glBindBuffer(GL_ARRAY_BUFFER, result.vbo)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices[0]) * len(indices), addr indices, GL_STATIC_DRAW)

proc draw*(obj: Obj2D, camera: Mat4[float32]) =
  var rws = vec3(camera[0][0], camera[1][0], camera[2][0])
  var uws = vec3(camera[0][1], camera[1][1], camera[2][1])

  var data: array[0..3, ObjVert]

  for i in 0..3:
    var ss = obj.pos + (rws * objverts[i].x * 1) + (uws * objverts[i].y * 1)
    data[i].x = ss.x 
    data[i].y = ss.y 
    data[i].z = ss.z 
    if i mod 2 == 0:
      data[i].u = 1.0
    if i mod 4 < 2:
      data[i].v = 1.0

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.ebo)
  glBindBuffer(GL_ARRAY_BUFFER, obj.vbo)
  glBufferData(GL_ARRAY_BUFFER, sizeof(data[0]) * len(data), addr data, GL_STATIC_DRAW)

  glBindTexture(GL_TEXTURE_2D, obj.tex.tex)
  glVertexAttribPointer(0, 3, cGLFLOAT, GL_FALSE, sizeof(ObjVert).GLsizei, cast[pointer](0))
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(1, 3, cGLFLOAT, GL_FALSE, sizeof(ObjVert).GLsizei, cast[pointer](3 * sizeof(GLfloat)))
  glEnableVertexAttribArray(1)
  glVertexAttribPointer(2, 2, cGLFLOAT, GL_FALSE, sizeof(ObjVert).GLsizei, cast[pointer](6 * sizeof(GLfloat)))
  glEnableVertexAttribArray(2)
  glDrawElements(GL_TRIANGLES, len(indices).GLsizei, GL_UNSIGNED_INT, nil)