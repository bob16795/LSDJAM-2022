import nimres

const root = currentSourcePath() & "/.."

resToc(root, "content.bin",
  "prompts.txt",
  "font.ttf",

  "images/level1.png",
  "images/level2.png",
  "images/level3.png",
  "images/level4.png",
  "images/ui.png",
  "images/uv.png",

  # objects
  "objects/bed1.obj|tools/obj2bin",
  "objects/bookshelf1.obj|tools/obj2bin",
  "objects/chair1.obj|tools/obj2bin",
  "objects/coffeetable1.obj|tools/obj2bin",
  "objects/couch1.obj|tools/obj2bin",
  "objects/desk1.obj|tools/obj2bin",
  "objects/grave1.obj|tools/obj2bin",
  "objects/lamp1.obj|tools/obj2bin",
  "objects/lamp2.obj|tools/obj2bin",
  "objects/log2T.obj|tools/obj2bin",
  "objects/mushroomT1.obj|tools/obj2bin",
  "objects/mushroomT2.obj|tools/obj2bin",
  "objects/mushroomT3.obj|tools/obj2bin",
  "objects/stove1.obj|tools/obj2bin",
  "objects/table1.obj|tools/obj2bin",
  "objects/tv1.obj|tools/obj2bin",
)

static:
  echo staticExec("cp content.bin ../content.bin")