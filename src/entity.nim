import hangover
import obj2d
import objects
import levels
import glm

type
  Entity2D* = ref object
    model: Obj2D
    base: Object
    pos: Vec3[float32]
    vel: Vec3[float32]

proc newEntity2D*(tex: Texture): Entity2D =
  result = Entity2D()

  result.model = newObj2d(tex)
  result.vel = vec3(0.0'f32, 0, 1.0)
  result.pos = vec3(0.0'f32, 2.0, 0)

  result.base = newObject("content/objects/person.obj", "content/images/rock.png")

proc update*(e: var Entity2D, lev: Level, dt: float32) =
  var vel = e.vel * dt 
  lev.collide(e.pos, vel)
  e.pos += vel

  e.model.pos = e.pos + vec3(0'f32, 0.75, 0)
  e.base.model = translate(mat4(1'f32), e.pos - vec3(0'f32, 2.5, 0)).scale(vec3(2.0'f32, 2.0, 2.0))

proc draw*(e: var Entity2D, m: Mat4[float32]) =
  e.model.draw(m)

proc drawbase*(e: var Entity2D, prog: var Shader) =
  e.base.draw(prog)