import hangover
import obj
import glm

type
  Vert* = object
    x*, y*, z*: GLfloat
    xn*, yn*, zn*: GLfloat
    u*, v*: GLfloat
  Object* = ref object of RootObj
    VBO*: GLuint
    EBO*: GLuint
    tex*: Texture
    vertCount*: int
    model*: Mat4[float32]

proc newObject*(obj: string, png = "", model = mat4(1'f32)): Object =
  result = Object()
  var obj = getObjFile(obj)
  if png != "":
    result.tex = newTexture(png)
  var verts: seq[Vert]
  for f in obj.data_face:
    var v = Vert(
      x: obj.data_vert[f[0] - 1][1],
      y: obj.data_vert[f[0] - 1][2],
      z: obj.data_vert[f[0] - 1][3]
    )
    if f[1] != 0:
      v.u = obj.data_tex[f[1] - 1][0]
      v.v = 1.0 - obj.data_tex[f[1] - 1][1]
    if f[2] != 0:
      v.xn = obj.data_nrml[f[2] - 1][1]
      v.yn = obj.data_nrml[f[2] - 1][2]
      v.zn = obj.data_nrml[f[2] - 1][3]
    verts &= v
  result.vertCount = len(verts)
  glGenBuffers(1, addr result.VBO)
  glBindBuffer(GL_ARRAY_BUFFER, result.VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts[0]) * len(verts), addr verts[0], GL_STATIC_DRAW)
  result.model = model

proc cloneObject*(o: Object, model = o.model): Object =
  result.VBO = o.VBO
  result.EBO = o.EBO
  result.tex = o.tex
  result.vertCount = o.vertCount
  result.model = model

method draw*(o: Object, p: var Shader) =
  p.use()
  p.setParam("model", o.model.caddr)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, o.EBO)
  glBindBuffer(GL_ARRAY_BUFFER, o.VBO)
  glVertexAttribPointer(0, 3, cGLFLOAT, GL_FALSE, sizeof(Vert).GLsizei, cast[pointer](0))
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(1, 3, cGLFLOAT, GL_FALSE, sizeof(Vert).GLsizei, cast[pointer](3 * sizeof(GLfloat)))
  glEnableVertexAttribArray(1)
  glVertexAttribPointer(2, 2, cGLFLOAT, GL_FALSE, sizeof(Vert).GLsizei, cast[pointer](6 * sizeof(GLfloat)))
  glEnableVertexAttribArray(2)
  if o.tex != nil:
    glBindTexture(GL_TEXTURE_2D, o.tex.tex)
  if o.EBO != 0:
    glDrawElements(GL_TRIANGLES, o.vertCount.GLsizei, GL_UNSIGNED_INT, nil)
  else:
    glDrawArrays(GL_TRIANGLES, 0, o.vertCount.GLsizei)
  glBindTexture(GL_TEXTURE_2D, 0)
