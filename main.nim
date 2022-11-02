import hangover
import src/camera
import src/objects
import src/obj2d
import src/levels
import src/data
import src/gen
import src/portal
import src/entity
import glm
import glfw

const
  fragCode = staticRead("static/frag.glsl")
  vertCode = staticRead("static/vert.glsl")
  geomCode = staticRead("static/geom.glsl")
  
Game:
  var
    bg: Color

    prog: Shader
    cam: Camera

    lastPos: Vector2
    size: Vector2

    moveDir: Vector2

    level: Level

    portals: seq[Portal]

    viewStack: seq[Mat4[float32]]

    objs: seq[Object]
    entities: seq[Entity2D]
    objs2d: seq[Obj2D]

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

  proc Initialize(ctx: var GraphicsContext) =
    setPercent(0)
    setStatus("Init objects")

    glEnable(GL_DEPTH_TEST)
    prog = newShader(vertCode, geomCode, fragCode)
    prog.registerParam("view", SPKProj4)
    prog.registerParam("model", SPKProj4)
    prog.registerParam("proj", SPKProj4)
    prog.registerParam("WIN_SCALE", SPKFloat2)
    prog.registerParam("lightPos", SPKFloat4)
    prog.registerParam("brightness", SPKFloat1)

    setPercent(0.5)
    setStatus("Init objects")

    # level = genLevel()

    level = newLevel("content/levels/1.lvl")

    portals &= newPortal(
      size,
      scale(mat4(1'f32), vec3(2'f32, 4, 2))
    ) 

    # objs &= newObject("scenes/room.obj", "scenes/tex_1.png")

    # entities &= newEntity2D(newTexture("content/images/rock.png"))
    
    cam = newCamera()
    size = newVector2(800, 600)

    createListener(EVENT_MOUSE_MOVE, moveMouse)
    createListener(EVENT_RESIZE, resize)
    createListener(EVENT_PRESS_KEY, keyDown)
    createListener(EVENT_RELEASE_KEY, keyUp)
    setPercent(1.0)
    setStatus("Done")

  proc Update(dt: float, delayed: bool): bool =
    cam.vel = (cam.forward.xyz * moveDir.y + cam.right.xyz * moveDir.x) * dt * WALK_SPEED
    cam.vel.y += GRAVITY * dt
    
    var pv = cam.getMat()

    if level != nil:
      level.collide(cam.pos.xyz, cam.vel)

    cam.update(dt)

    for o in 0..<len entities:
      entities[o].update(level, dt)

    var
      al = inverse(pv) * vec4(0'f32, 0, 0, 1)
      bl = inverse(cam.getMat()) * vec4(0'f32, 0, 0, 1)

    var tp = -1
    for pi in 0..<len portals:
      if portals[pi].contains(cam, vec3(al.x, al.y, al.z), vec3(bl.z, bl.y, bl.z)):
        tp = pi
    if tp != -1:
      cam.view = portals[tp].getView(cam.view, portals[portals[tp].dst])

  proc drawScene(rec: int = 0, outer: int = -1)

  proc clipPortal(outer: int): Rect =
    result.x = 0
    result.y = 0
    result.width = size.x
    result.height = size.y

    for v in viewStack[0..^2]:
      var
        p: array[4, Vec4[float32]]
        found_neg_w: bool
      for pi in 0..<4:
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

      for i in 0..<4:
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
      if outer == -1 or pi == outer:
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
    if level != nil:
      level.draw(prog)
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

    drawScene()

  proc gameClose() =
    discard
