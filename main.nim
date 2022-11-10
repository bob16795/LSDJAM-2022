import hangover
import src/camera
import src/objects
import src/obj2d
import src/levels
import src/data
import src/gen
import src/fsm
import src/portal
import src/entity
import src/horde
import src/ui
import strutils
import random
import glm
import json
import base64
import glfw

const
  fragCode = staticRead("static/frag.glsl")
  vertCode = staticRead("static/vert.glsl")
  geomCode = staticRead("static/geom.glsl")
  
Game:
  type TexData = ref object
    data: pointer
    size: Vector2

  var
    bg: Color

    prog: Shader
    cam: Camera

    prompts: seq[string]

    lastPos: Vector2
    size: Vector2

    moveDir: Vector2

    levels: seq[Level]

    portals: seq[Portal]

    viewStack: seq[Mat4[float32]]

    textures: TextureAtlas

    uiFont: Font
    uv: Texture

    fsm: StateMachine

    objs: seq[Object]
    entities: seq[Entity2D]
    objs2d: seq[Obj2D]

    images: seq[string]
    
    tex: Texture
    texdata {.global.}: pointer

  template currentWorld(pos: Vec3[float32]): int =
    ((pos.x / WORLD_SPACING) + 0.5).int


  proc drawLoading(pc: float32, loadStatus: string, ctx: GraphicsContext, size: Point) =
    clearBuffer(ctx, bg)

  proc Setup(): AppData =
    bg = BG_COLOR
    result = newAppData()
    result.color = bg
    result.name = "Convolution"

  proc resize(data: pointer): bool =
    var dat = cast[ptr tuple[x, y: int32]](data)[]
    size = newVector2(dat.x.float32, dat.y.float32)
    screenSize = size

    cam.ratio = dat.x.float32 / dat.y.float32
  
    var dat2 = [dat.x.GLfloat, dat.y.GLfloat]
  
    prog.setParam("WIN_SCALE", addr dat2)

    for p in 0..<len portals:
      portals[p].respawn(size)
    
  var firstMove: bool = true

  proc moveMouse(data: pointer): bool =
    var dat = cast[ptr tuple[x, y: float64]](data)[]
      
    var
      xoffset = dat.x - lastPos.x
      yoffset = lastPos.y - dat.y

    lastPos.x = dat.x.float32
    lastPos.y = dat.y.float32

    if firstMove:
      firstMove = false
      return

    xoffset *= SENSITIVITY
    yoffset *= SENSITIVITY

    cam.rvel.x += xoffset
    cam.rvel.y -= yoffset

    #cam.yaw += xoffset
    #cam.pitch += yoffset
    #cam.pitch = clamp(cam.pitch, -89, 89)
 
  proc keyDown(data: pointer): bool =
    var dat = cast[ptr Key](data)[]

    case dat:
      of keyW:
        moveDir.y += 1
      of Key.keyS:
        moveDir.y -= 1
      of keyA:
        moveDir.x += 1
      of keyD:
        moveDir.x -= 1
      of keyH:
        echo len(levels)
      else: discard
  
  proc keyUp(data: pointer): bool =
    var dat = cast[ptr Key](data)[]

    case dat:
      of keyW:
        moveDir.y -= 1
      of Key.keyS:
        moveDir.y += 1
      of keyA:
        moveDir.x -= 1
      of keyD:
        moveDir.x += 1
      else: discard

  proc addDst(pi: int) =
    if portals[pi].dst != -1: return
    var done: bool
    if rand(1..10) < 3:
      var ct: seq[int]
      for pj in 0..<len portals:
        if pj != pi and portals[pj].dst == -1:
          ct &= pj
      if ct.len > 1:
        portals[pi].dst = ct[rand(len(ct) - 1)]
        done = true
    if not done:
      var l = genLevel(translate(mat4(1'f32), vec3(WORLD_SPACING * len(levels).float32, 0, 0)), len(levels))
      levels &= l.level
      portals[pi].dst = portals.len()
      objs &= l.objects
      portals &= l.portals
    portals[portals[pi].dst].dst = pi
  
  proc setFlag(d: pointer): bool =
    fsm.setFlag(cast[ptr int](d)[])


  proc newTex(data: pointer, base64: string, w, h: cint) =
    {.cast(gcsafe).}:
      images &= base64
      texdata = data

  proc Initialize(ctx: var GraphicsContext) =
    for l in 1..4:
      images &= encode(readFile("content/images/level" & $l & ".png"))

    prompts = readFile("content/prompts.txt").split("\n")

    initHorde()
    setPercent(0)
    setStatus("Init data")

    initData()
    
    setPercent(0.1)
    setStatus("Init shaders")

    tex = newTexture(newVector2(128, 384))

    fsm = initMainMachine()

    glEnable(GL_DEPTH_TEST)
    prog = newShader(vertCode, geomCode, fragCode)
    prog.registerParam("view", SPKProj4)
    prog.registerParam("shift", SPKProj4)
    prog.registerParam("model", SPKProj4)
    prog.registerParam("texuv", SPKInt1)
    prog.registerParam("proj", SPKProj4)
    prog.registerParam("WIN_SCALE", SPKFloat2)
    prog.registerParam("lightPos", SPKFloat4)
    prog.registerParam("brightness", SPKFloat1)
    prog.registerParam("fogColor", SPKFloat4)
    prog.registerParam("fogDensity", SPKFloat1)

    var uvid: int = 1

    prog.setParam("texuv", addr uvid)

    setPercent(0.25)
    setStatus("Init textures")

    textures = newTextureAtlas()
    textures &= newTextureData("content/images/level1.png", "ui")
    textures.pack()
    uv = newTexture("content/images/uv.png")
    uv.bindTo(GL_TEXTURE1)

    uiFont = newFont("content/font.ttf", FONT_SIZE)

    setupUI(textures, uiFont)

    setPercent(0.5)
    setStatus("Init objects")

    randomize()

    var l = genLevel()

    levels = @[]
    portals = @[]

    levels &= l.level
    portals &= l.portals
    objs &= l.objects

    for pj in 0..<len portals:
      addDst(pj)
    
    cam = newCamera()
    size = newVector2(800, 600)

    createListener(EVENT_MOUSE_MOVE, moveMouse)
    createListener(EVENT_RESIZE, resize)
    createListener(EVENT_PRESS_KEY, keyDown)
    createListener(EVENT_RELEASE_KEY, keyUp)
    createListener(EVENT_PRESS_UI, setFlag)

    setPercent(1.0)
    setStatus("Done")

    var dataI = FE_LOAD
    discard setFlag(addr dataI)
  
  var
    fps: int
    timer: float32
    imglen: int
    tottime: float32

  proc Update(dt: float, delayed: bool): bool =
    fps += 1
    timer += dt
    tottime += dt
    if timer > 0.25:
      framerate = "FPS: " & ($(fps.float32 / timer))[0..5] & "\nTEX: " & $imglen & "\nROOM: " & $(len(levels))
      fps = 0
      timer = 0

    if texdata != nil:
      tex = newTexture(newVector2(128, 384))
      tex.bindTo(GL_TEXTURE0)
      # tex nothing
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, HORDE_DEFAULT{"params", "width"}.getInt().cint, HORDE_DEFAULT{"params", "height"}.getInt().cint,
          0, GL_RGBA, GL_UNSIGNED_BYTE, texdata)
      newRoom(tex)
      imglen = tex.tex.int

      texdata = nil
    else:
      sendRequest(sample(prompts), sample(images), newTex)

    cam.vel = (cam.forward.xyz * moveDir.y + cam.right.xyz * moveDir.x) * dt * WALK_SPEED
    cam.vel.y += GRAVITY * dt

    if levels != @[]:
      levels[currentWorld(cam.pos)].collide(cam.pos.xyz, cam.vel)

    var pv = cam.pos
    
    cam.update(dt)

    # for o in 0..<len entities:
    #   entities[o].update(level, dt)

    for pi in 0..<len portals:
      if currentWorld(cam.pos) != portals[pi].level: continue
      if portals[pi].contains(pv, cam.pos):
        # if portals[pi].dst == -1:
        #   addDst(pi)
        for pj in 0..<len portals:
          if portals[pj].level == portals[portals[pi].dst].level:
            addDst(pj)
        cam.view = portals[pi].getView(cam.view, portals[portals[pi].dst])
        break

  proc drawScene(rec: int = 0, outer: int = -1)

  proc clipPortal(outer: int): Rect =
    result.x = 0
    result.y = 0
    result.width = size.x
    result.height = size.y

    for v in viewStack[0..^2]:
      var
        p: array[8, Vec4[float32]]
        found_neg_w: bool
      for pi in 0..<8:
        var pnt = portals[outer].verts[pi]
        p[pi] = (perspective(radians(FOVY), cam.ratio, ZNEAR, ZFAR) * v * portals[outer].model) * vec4(pnt.x, pnt.y, pnt.z, 1.0)
        if p[pi].w < 0.0:
          found_neg_w = true
        else:
          p[pi].x /= p[pi].w
          p[pi].y /= p[pi].w
      if found_neg_w:
        continue
    
      var
        min_x, min_y, max_x, max_y: Vec4[float32] = p[0]

      for i in 0..<8:
        if (p[i].x < min_x.x): min_x = p[i]
        if (p[i].x > max_x.x): max_x = p[i]
        if (p[i].y < min_y.y): min_y = p[i]
        if (p[i].y > max_y.y): max_y = p[i]

      min_x.x = (max(-1.0f, min_x.x) + 1) / 2 * size.x
      max_x.x = (min( 1.0f, max_x.x) + 1) / 2 * size.x
      min_y.y = (max(-1.0f, min_y.y) + 1) / 2 * size.y
      max_y.y = (min( 1.0f, max_y.y) + 1) / 2 * size.y

      result.x = min_x.x
      result.y = min_y.y
      result.width = max_x.x - min_x.x
      result.height = max_y.y - min_y.y
      if result.width <= 0 or result.height <= 0: 
        return Rect()

  proc drawPortals(rec: int, outer: int) =
    var
      save_stencil: bool

    glGetBooleanv(GL_STENCIL_TEST, addr save_stencil)
    glEnable(GL_STENCIL_TEST)
    glEnable(GL_SCISSOR_TEST)
    for pi in 0..<len portals:
      if (outer == -1 or pi == outer) and portals[pi].dst != -1:
        var
          portalCam = portals[pi].getView(viewStack[^1], portals[portals[pi].dst])
        viewStack &= portalCam
        prog.setParam("view", viewStack[^1].caddr)
        drawScene(rec + 1, pi)
        viewStack = viewStack[0 ..< ^1]
        prog.setParam("view", viewStack[^1].caddr)
    if not save_stencil:
      glDisable(GL_STENCIL_TEST)
      glDisable(GL_SCISSOR_TEST)
    glClear(GL_DEPTH_BUFFER_BIT)
   
    var save_color_mask: array[0..3, GLboolean]
    var save_depth_mask: GLboolean
  
    glGetBooleanv(GL_COLOR_WRITEMASK, cast[ptr GLboolean](addr save_color_mask))
    glGetBooleanv(GL_DEPTH_WRITEMASK, addr save_depth_mask)

    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE)
    glDepthMask(GL_TRUE)

    for p in portals:
      if currentWorld(cam.pos) != p.level: continue
      if p.dst != -1:
        prog.setParam("model", p.toWorld.caddr)
        p.draw(prog)
    
    glColorMask(save_color_mask[0], save_color_mask[1], save_color_mask[2], save_color_mask[3])
    glDepthMask(save_depth_mask)


  proc drawScene(rec: int = 0, outer: int = -1) =
    if rec > RECURSION:
      return
      
    var scissor:Rect
    
    if outer != -1:
      scissor = clipPortal(outer)
      if scissor == Rect(): return
    
    prog.setParam("view", viewStack[^1].caddr)

    glClear(GL_DEPTH_BUFFER_BIT)
   
    drawPortals(rec, outer)
    
    if outer != -1:
      glScissor(scissor.x.GLint, scissor.y.GLint, scissor.width.GLsizei, scissor.height.GLsizei)

      var save_color_mask: array[0..3, GLboolean]
      var save_depth_mask: GLboolean
      
      glGetBooleanv(GL_COLOR_WRITEMASK, cast[ptr GLboolean](addr save_color_mask))
      glGetBooleanv(GL_DEPTH_WRITEMASK, addr save_depth_mask)

      glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE)
      glDepthMask(GL_FALSE)
      glStencilFunc(GL_NEVER, 0, 0xFF)
      glStencilOp(GL_INCR, GL_KEEP, GL_KEEP)

      glClear(GL_STENCIL_BUFFER_BIT)
      prog.setParam("view", viewStack[0].caddr)
      var tmp = portals[outer].toWorld
      prog.setParam("model", tmp.caddr)

      portals[outer].draw(prog)

      for v in 1..<(len viewStack) - 1:
        glStencilFunc(GL_EQUAL, 0, 0xFF)
        glStencilOp(GL_INCR, GL_KEEP, GL_KEEP)
        var tmp = viewStack[v]
        prog.setParam("view", tmp.caddr)
        portals[outer].draw(prog)

        glStencilFunc(GL_NEVER, 0, 0xFF);
        glStencilOp(GL_DECR, GL_KEEP, GL_KEEP)
        tmp = viewStack[v - 1]
        prog.setParam("view", tmp.caddr)
        portals[outer].draw(prog)
      
      glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
      glDepthMask(GL_TRUE)
      glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP)

      glStencilFunc(GL_LEQUAL, 1, 0xFF)
      
      glColorMask(save_color_mask[0], save_color_mask[1], save_color_mask[2], save_color_mask[3])
      glDepthMask(save_depth_mask)

      prog.setParam("view", viewStack[^1].caddr)

    var val: GLfloat = 0
    prog.setParam("brightness", addr val)
    if outer != -1:
      try:
        levels[portals[portals[outer].dst].level].draw(prog)
      except:
        discard
    else:
      levels[currentWorld(cam.pos)].draw(prog)
    for o in 0..<len objs:
      var shift = translate(mat4(1'f32), vec3(0'f32, sin(tottime + o.float32) * BOB_AMP, 0))
      prog.setParam("shift", shift.caddr)
      objs[o].draw(prog)
    var shift = mat4(1'f32)
    prog.setParam("shift", shift.caddr)

  proc Draw(ctx: var GraphicsContext) =
    # update ui
    var sc = newVector2(size.x.float32 / 100, size.y.float32 / 100)
    var scale = min(sc.x, sc.y)
    uiScaleMult = scale / UI_MULT

    glClear(GL_DEPTH_BUFFER_BIT)
    case fsm.currentState:
    of FS_LOADING:
      setUIActive(0, true)
    of FS_TITLE:
      setUIActive(0, true)
      setShowMouse(ctx, true)
    of FS_GAME:
      setUIActive(0, false)
      setShowMouse(ctx, false)
      glEnable(GL_DEPTH_TEST)
      glDepthFunc(GL_LEQUAL)
      glEnable(GL_BLEND)
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      viewStack = @[cam.view]

      prog.use()

      var proj = perspective(radians(FOVY), cam.ratio, ZNEAR, ZFAR)

      prog.setParam("proj", proj.caddr)
      var pos = inverse(cam.getMat()) * vec4(0'f32, 0, 0, 1)
      prog.setParam("lightPos", pos.caddr)

      glClear(GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

      var c = [levels[0].fogColor.rf, levels[0].fogColor.gf, levels[0].fogColor.bf, levels[0].fogColor.af]
      prog.setParam("fogColor", c.addr)
      prog.setParam("fogDensity", levels[0].fogDensity.addr)

      clearBuffer(ctx, levels[0].fogColor)
      
      drawScene()
    else:
      discard

  proc gameClose() =
    discard
