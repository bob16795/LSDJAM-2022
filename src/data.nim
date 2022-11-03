import hangover

type
  WorldData* = object
    models*: seq[string]
    pix*: seq[string]
    ceiling*: bool
    tex*: string
    mapsizex*: HSlice[int, int]
    mapsizey*: HSlice[int, int]
    tilesize*: HSlice[float, float]
    height*: HSlice[float, float]
    spacer*: HSlice[float, float]
    doors*: HSlice[int, int]
    fogColor*: Color
    fogDensity*: float32

const
  FOVY* = 45'f32
  ZNEAR* = 0.01'f32
  ZFAR* = 1000
  #BG_COLOR* = newColor(246, 231, 193, 255)
  RECURSION* = 1
  BG_COLOR* = newColor(145, 145, 255, 255)
  SENSITIVITY* = 0.05
  WALK_SPEED* = 5
  PLAYER_HEIGHT* = 2.0
  GRAVITY* = -5

  PROC_DATA* = [
    WorldData(
      models: @[
        "content/objects/person.obj"
      ],
      pix: @[
        "content/images/rock.png",
        "content/images/musk.png"
      ],
      tex: "content/images/level2.png",
      ceiling: true,
      mapsizex: 5..7,
      mapsizey: 5..7,
      doors: 2..4,
      tilesize: 3.0..3.0,
      height: 3.0..3.0,
      spacer: 0.5..1.0,
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    ),
    WorldData(
      models: @[
        "content/objects/person.obj"
      ],
      pix: @[
        "content/images/uv.png"
      ],
      tex: "content/images/level1.png",
      ceiling: false,
      mapsizex: 5..7,
      mapsizey: 5..7,
      doors: 2..4,
      tilesize: 3.0..3.0,
      height: 3.0..3.0,
      spacer: 0.0..0.0, 
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    )
  ]