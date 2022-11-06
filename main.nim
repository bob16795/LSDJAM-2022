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

    fsm: StateMachine

    objs: seq[Object]
    entities: seq[Entity2D]
    objs2d: seq[Obj2D]

    images: seq[string]
    
    tex: Texture
    texdata {.global.}: pointer

  proc drawLoading(pc: float32, loadStatus: string, ctx: GraphicsContext, size: Point) =
    clearBuffer(ctx, bg)

  proc Setup(): AppData =
    bg = BG_COLOR
    result = newAppData()
    result.color = bg
    result.name = "APOP"

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
    if rand(1..10) < 8:
      var ct: seq[int]
      for pj in 0..<len portals:
        if pj != pi and portals[pj].dst == -1:
          ct &= pj
      if ct.len > 1:
        portals[pi].dst = ct[rand(len(ct) - 1)]
        done = true
    if not done:
      var l = genLevel(translate(mat4(1'f32), vec3(300'f32 * len(levels).float32, 0, 0)), len(levels))
      levels &= l.level
      portals[pi].dst = portals.len()
      objs &= l.objects
      portals &= l.portals
    portals[portals[pi].dst].dst = pi
  
  proc setFlag(d: pointer): bool =
    fsm.setFlag(cast[ptr int](d)[])


  proc newTex(data: pointer, base64: string, w, h: cint) =
    {.cast(gcsafe).}:
      texdata = data
      images &= base64

  proc Initialize(ctx: var GraphicsContext) =
    images &= "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"
    
    prompts = readFile("content/prompts.txt").split("\n")

    initHorde()
    setPercent(0)
    setStatus("Init shaders")

    tex = newTexture(newVector2(128, 384))

    fsm = initMainMachine()

    glEnable(GL_DEPTH_TEST)
    prog = newShader(vertCode, geomCode, fragCode)
    prog.registerParam("view", SPKProj4)
    prog.registerParam("model", SPKProj4)
    prog.registerParam("proj", SPKProj4)
    prog.registerParam("WIN_SCALE", SPKFloat2)
    prog.registerParam("lightPos", SPKFloat4)
    prog.registerParam("brightness", SPKFloat1)
    prog.registerParam("fogColor", SPKFloat4)
    prog.registerParam("fogDensity", SPKFloat1)

    setPercent(0.25)
    setStatus("Init textures")

    textures = newTextureAtlas()
    textures &= newTextureData("content/images/level1.png", "ui")

    textures.pack()

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

  proc Update(dt: float, delayed: bool): bool =
    if texdata != nil:
      tex = newTexture(newVector2(128, 384))
      tex.bindTo(GL_TEXTURE0)
      # tex nothing
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, 64, 192,
          0, GL_RGBA, GL_UNSIGNED_BYTE, texdata)
      newRoom(tex)

      texdata = nil
    else:
      sendRequest(sample(prompts), images[^1], newTex)


    cam.vel = (cam.forward.xyz * moveDir.y + cam.right.xyz * moveDir.x) * dt * WALK_SPEED
    cam.vel.y += GRAVITY * dt

    if levels != @[]:
      for l in levels:
        l.collide(cam.pos.xyz, cam.vel)

    var pv = cam.pos
    
    cam.update(dt)

    # for o in 0..<len entities:
    #   entities[o].update(level, dt)

    for pi in 0..<len portals:
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
      if p.dst != -1:
        prog.setParam("model", p.toWorld.caddr)
        p.draw(prog)
    
    glColorMask(save_color_mask[0], save_color_mask[1], save_color_mask[2], save_color_mask[3])
    glDepthMask(save_depth_mask)

    for p in portals:
      if p.dst == -1:
        prog.setParam("model", p.toWorld.caddr)
        p.draw(prog)


  proc drawScene(rec: int = 0, outer: int = -1) =
    if rec > RECURSION:
      return
      
    var scissor:Rect

    # update ui
    var sc = newVector2(size.x.float32 / 100, size.y.float32 / 100)
    var scale = min(sc.x, sc.y)
    uiScaleMult = scale / UI_MULT
    
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
      for l in levels:
        l.draw(prog)
    for o in 0..<len objs:
      objs[o].draw(prog)
    
    val = 0.75
    prog.setParam("brightness", addr val)

    for o in 0..<len entities:
      entities[o].drawBase(prog)

    val = 0.0
    prog.setParam("brightness", addr val)
      
    glClear(GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
    
    var ident = mat4(1'f32)
    prog.setParam("model", ident.caddr)

    for o in 0..<len objs2d:
      objs2d[o].draw(viewStack[^1])
    for o in 0..<len entities:
      entities[o].draw(viewStack[^1])

  proc Draw(ctx: var GraphicsContext) =
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
    if tex != nil:
      tex.draw(newRect(0, 0, 1, 1), newRect(0, 0, 128, 384))

  proc gameClose() =
    discard
