import glm

type
  Camera* = object
    view*: Mat4[float32]
    vel*: Vec3[float32]
    rvel*: Vec3[float32]

    forward*: Vec4[float32]
    right*: Vec4[float32]
    pos*: Vec4[float32]

    ratio*: float32
    
proc newCamera*(): Camera =
  result.pos = vec4(0'f32, 4, 0, 1)
  result.forward = vec4(vec3(-5'f32, 0, -5).normalize(), 1'f32)

proc update*(c: var Camera, dt: float) =
  c.view = lookAt(c.pos.xyz, c.pos.xyz + c.forward.xyz, vec3(0'f32, 1,0))

  c.right = rotate(mat4(1.0'f32), radians(90'f32), vec3(0'f32, 1, 0)) * c.forward
  c.forward = rotate(mat4(1.0'f32), radians(-c.rvel.x), vec3(0'f32, 1, 0)) * c.forward
  c.pos += vec4(c.vel, 0.0)
  if dt * 20 > 1:
    c.rvel = vec3(0'f32, 0, 0)
  else:
    c.rvel += (c.rvel) * dt * -20


proc getMat*(c: var Camera): Mat4[float32] =
  return c.view
