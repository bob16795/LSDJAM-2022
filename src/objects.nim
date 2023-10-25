import hangover
import obj
import glm
import binaryparse
import ../content/files

createParser(Vert):
  f32: x
  f32: y
  f32: z

createParser(Face):
  u32: vert
  u32: norm
  u32: cord

createParser(Cord):
  f32: u
  f32: v

createParser(Obj):
  u32: vertslen
  u32: normslen
  u32: cordslen
  u32: faceslen
  *Vert(): verts[vertslen]
  *Vert(): norms[normslen]
  *Cord(): cords[cordslen]
  *Face(): faces[faceslen]

type
  ObjVert* = object
    x*, y*, z*: GLfloat
    xn*, yn*, zn*: GLfloat
    u*, v*: GLfloat
  Object* = ref object of RootObj
    VBO*: GLuint
    EBO*: GLuint
    tex*: Texture
    vertCount*: int
    model*: Mat4[float32]
    level*: int

proc newObject*(objname: string, png = "", model = mat4(1'f32)): Object =
  result = Object()

  var stream = res(objname).openStream()
  var obj = Obj.get(stream)
  stream.close()
  
  if png != "":
    echo png
    result.tex = newTextureMem(png.res().getPointer(), png.res().size.cint)
  else:
    result.tex = newTextureMem(res"uv.png".getPointer(), res"uv.png".size.cint)
  var verts: seq[ObjVert]
  for fi in 0..<len obj.faces:
    var f = obj.faces[fi]
    var v = ObjVert(
      x: obj.verts[f.vert - 1].x,
      y: obj.verts[f.vert - 1].y,
      z: obj.verts[f.vert - 1].z
    )
    try:
      if f.cord != 0:
        v.u = obj.cords[f.cord - 1].u
        v.v = 1.0 - obj.cords[f.cord - 1].v
      if f.norm != 0:
        v.xn = obj.norms[f.norm - 1].x
        v.yn = obj.norms[f.norm - 1].y
        v.zn = obj.norms[f.norm - 1].z
    except: discard
    verts &= v
  result.vertCount = len(verts)
  glGenBuffers(1, addr result.VBO)
  glBindBuffer(GL_ARRAY_BUFFER, result.VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts[0]) * len(verts), addr verts[0], GL_STATIC_DRAW)
  result.model = model

proc cloneObject*(o: Object, model = o.model): Object =
  result = Object()
  result.VBO = o.VBO
  result.EBO = o.EBO
  result.tex = o.tex
  result.vertCount = o.vertCount
  result.model = model

method draw*(o: Object, p: var Shader) =
  if o == nil: return

  p.use()
  p.setParam("model", o.model.caddr)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, o.EBO)
  glBindBuffer(GL_ARRAY_BUFFER, o.VBO)
  glVertexAttribPointer(0, 3, cGLFLOAT, GL_FALSE, sizeof(ObjVert).GLsizei, cast[pointer](0))
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(1, 3, cGLFLOAT, GL_FALSE, sizeof(ObjVert).GLsizei, cast[pointer](3 * sizeof(GLfloat)))
  glEnableVertexAttribArray(1)
  glVertexAttribPointer(2, 2, cGLFLOAT, GL_FALSE, sizeof(ObjVert).GLsizei, cast[pointer](6 * sizeof(GLfloat)))
  glEnableVertexAttribArray(2)
  if o.tex != nil:
    glBindTexture(GL_TEXTURE_2D, o.tex.tex)
  if o.EBO != 0:
    glDrawElements(GL_TRIANGLES, o.vertCount.GLsizei, GL_UNSIGNED_INT, cast[pointer](0))
  else:
    glDrawArrays(GL_TRIANGLES, 0, o.vertCount.GLsizei)
  glBindTexture(GL_TEXTURE_2D, 0)
