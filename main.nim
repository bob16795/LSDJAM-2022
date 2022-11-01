import hangover
import src/camera
import src/objects
import src/obj2d
import src/levels
import src/data
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

    level = newLevel("content/levels/1.lvl")

    # objs &= newObject("scenes/room.obj", "scenes/tex_1.png")

    entities &= newEntity2D(newTexture("content/images/rock.png"))
    
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

    if level != nil:
      level.collide(cam.pos.xyz, cam.vel)

    cam.update(dt)

    for o in 0..<len entities:
      entities[o].update(level, dt)

  proc drawScene(rec: int = 0, outer: int = -1) =
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
