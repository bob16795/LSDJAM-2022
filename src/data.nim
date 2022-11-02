import hangover

const
  FOVY* = 45'f32
  ZNEAR* = 0.01'f32
  ZFAR* = 1000
  #BG_COLOR* = newColor(246, 231, 193, 255)
  RECURSION* = 3
  BG_COLOR* = newColor(145, 145, 255, 255)
  SENSITIVITY* = 0.05
  WALK_SPEED* = 6
  PLAYER_HEIGHT* = 2.0
  GRAVITY* = -5