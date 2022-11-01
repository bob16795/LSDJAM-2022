import hangover
import obj

type
  SkyboxVert = object
    x, y, z: GLfloat
    xn, yn, zn: GLfloat
    u, v: GLfloat

  Skybox* = object
    VBO: GLuint
    tex: Texture


proc newSkybox*(scale: float32): Skybox =
  var obj = getObjFile("objs/skybox.obj")
  result.tex = newTexture("objs/skybox.png")
  var verts: seq[SkyboxVert]
  for f in obj.data_face:
    var v = SkyboxVert(
      x: obj.data_vert[f[0] - 1][1] * scale,
      y: obj.data_vert[f[0] - 1][2] * scale,
      z: obj.data_vert[f[0] - 1][3] * scale
    )
    if f[1] != 0:
      v.u = obj.data_tex[f[1] - 1][0]
      v.v = 1.0 - obj.data_tex[f[1] - 1][1]
    if f[2] != 0:
      v.xn = obj.data_nrml[f[2] - 1][1]
      v.yn = obj.data_nrml[f[2] - 1][2]
      v.zn = obj.data_nrml[f[2] - 1][3]
    verts &= v
  glGenBuffers(1, addr result.VBO)
  glBindBuffer(GL_ARRAY_BUFFER, result.VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts[0]) * len(verts), addr verts[0], GL_STATIC_DRAW)

proc draw*(s: Skybox) =
  glBindBuffer(GL_ARRAY_BUFFER, s.VBO)
  glVertexAttribPointer(0, 3, cGLFLOAT, GL_FALSE, sizeof(SkyboxVert).GLsizei, cast[pointer](0))
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(1, 3, cGLFLOAT, GL_FALSE, sizeof(SkyboxVert).GLsizei, cast[pointer](3 * sizeof(GLfloat)))
  glEnableVertexAttribArray(1)
  glVertexAttribPointer(2, 2, cGLFLOAT, GL_FALSE, sizeof(SkyboxVert).GLsizei, cast[pointer](6 * sizeof(GLfloat)))
  glEnableVertexAttribArray(2)
  glBindTexture(GL_TEXTURE_2D, s.tex.tex)
  glDrawArrays(GL_TRIANGLES, 0, 36)
  glBindTexture(GL_TEXTURE_2D, 0)
