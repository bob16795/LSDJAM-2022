import data
import glm

type
  Camera* = object
    view*: Mat4[float32]
    vel*: Vec3[float32]
    rvel*: Vec3[float32]

    ratio*: float32

proc pos*(c: Camera): Vec3[float32] =
  return (c.view.inverse() * vec4(0'f32, 0, 0, 1)).xyz
    
proc forward*(c: Camera): Vec3[float32] =
  return (c.view.inverse() * vec4(0'f32, 0, -1, 0)).xyz

proc right*(c: Camera): Vec3[float32] =
  return (c.view.inverse() * vec4(-1'f32, 0, 0, 0)).xyz
    
proc newCamera*(): Camera =
  result.view = lookAt(vec3(0'f32, 4, 0), vec3(-5'f32, 4, -5), vec3(0'f32, 1,0))

proc update*(c: var Camera, dt: float) =
  c.view = rotate(mat4(1.0'f32), radians(c.rvel.x), vec3(0'f32, 1, 0)) * c.view
  c.view = c.view * translate(mat4(1.0'f32), -c.vel)
  if dt * CAM_FRICTION > 1:
    c.rvel = vec3(0'f32, 0, 0)
    c.vel = vec3(0'f32, 0, 0)
  else:
    c.rvel -= (c.rvel) * dt * CAM_FRICTION
    c.vel -= (c.vel) * dt * CAM_FRICTION

proc getMat*(c: var Camera): Mat4[float32] =
  return c.view
