import opengl
import strutils
import streams
import binaryparse
import os

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
  vert* = array[1 .. 3,GLfloat]
type
  face* = array[0 .. 2,GLuint]
type
  tex* = array[0 .. 1,GLfloat]

type
  obj_data* = object
    data_vert* : seq[vert]
    data_face* : seq[face]
    data_nrml* : seq[vert]
    data_tex* : seq[tex]
    mtl* : string
    grp* : string
    use* : string
    s*: string

proc parse_face(s:string): array[0..2, face] =
   var a = split(s,' ')
   for i in 1..a.high:
    var c = split(a[i],'/')
    for d in 0..c.high:
      if c[d] == "":
       continue
      else:
       var z = parseInt(c[d])
       result[i - 1][d] = z.GLuint

proc parse_2f(s:string): tex =
   var a = split(s,' ')
   for i in 1..a.high:
      var f = parseFloat(a[i])
      result[i - 1] = f.GLfloat

proc parse_3f(s:string): vert =
   var a = split(s,' ')
   for i in 1 .. a.high:
      var p = parseFloat(a[i])
      result[i] = p.GLfloat

proc parse_mtllib(s:string): string =
   var a : string = strip(s,true,true)
   delete(a,0,6)
   return a

proc parse_group(s:string): string =
  var a : string = strip(s,true,true)
  delete(a,0,1)
  return a

proc getObjFile*(path:string): obj_data =
  var data : array[1,string] = [readFile(path).string]
  var str_seq = splitLines(data[0])
  var t : int = str_seq.len.int
  result.data_vert = @[]
  result.data_face = @[]
  result.data_nrml = @[]
  result.data_tex = @[]

  for i in 0..<t.int:
    if startsWith(str_seq[i],"#") == true:
      continue

    if find(str_seq[i],"usemtl") != -1.int:
      result.mtl = parse_mtllib(str_seq[i])
      continue

    if find(str_seq[i],"mtllib") != -1.int:
      result.mtl = parse_mtllib(str_seq[i])
      continue

    if startsWith(str_seq[i],"o") == true:
      result.grp = parse_group(str_seq[i])
      continue

    if startsWith(str_seq[i],"s") == true:
      result.s = parse_group(str_seq[i])
      continue

    if startsWith(str_seq[i],"f") == true:
      var f = parse_face(str_seq[i])
      result.data_face.add(f)
      continue

    if startsWith(str_seq[i],"vn") == true:
      var vn = parse_3f(str_seq[i])
      result.data_nrml.add(vn)
      continue

    if startsWith(str_seq[i],"vt") == true:
      var vt = parse_2f(str_seq[i])
      result.data_tex.add(vt)
      continue

    if startsWith(str_seq[i],"v") == true:
      var v = parse_3f(str_seq[i])
      result.data_vert.add(v)
      continue

    if startsWith(str_seq[i]," ") == true:
      continue

var data = getObjFile(paramStr(1))

var outputData: typeGetter(Obj)

outputData.vertslen = data.data_vert.len().uint32
outputData.normslen = data.data_nrml.len().uint32
outputData.cordslen = data.data_tex.len().uint32
outputData.faceslen = data.data_face.len().uint32

for v in 0..<len(data.data_vert):
  var tmp: typeGetter(Vert)
  tmp.x = data.data_vert[v][1]
  tmp.y = data.data_vert[v][2]
  tmp.z = data.data_vert[v][3]
  outputData.verts &= tmp
for v in 0..<len(data.data_nrml):
  var tmp: typeGetter(Vert)
  tmp.x = data.data_nrml[v][1]
  tmp.y = data.data_nrml[v][2]
  tmp.z = data.data_nrml[v][3]
  outputData.norms &= tmp
for v in 0..<len(data.data_tex):
  var tmp: typeGetter(Cord)
  tmp.u = data.data_tex[v][0]
  tmp.v = data.data_tex[v][1]
  outputData.cords &= tmp
for v in 0..<len(data.data_face):
  var tmp: typeGetter(Face)
  tmp.vert = data.data_face[v][0]
  tmp.norm = data.data_face[v][2]
  tmp.cord = data.data_face[v][1]
  outputData.faces &= tmp

var output = newFileStream(paramStr(2), fmWrite)
Obj.put(output, outputData)
output.close()