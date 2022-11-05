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
  RECURSION* = 1
  BG_COLOR* = newColor(145, 145, 255, 255)
  SENSITIVITY* = 0.05
  WALK_SPEED* = 10
  PLAYER_HEIGHT* = 2.0
  GRAVITY* = -5

  UI_MULT* = 20
  UI_SCALE* = 1 / 10
  UI_BORDER* = 1 / 10
  FONT_MULT* = 7
  FONT_SIZE* = 48

  PROC_DATA* = [
    WorldData(
      models: @[
        "content/objects/grave1.obj"
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
    ),
    WorldData(
      models: @[
        "content/objects/bed1.obj",
        "content/objects/chair1.obj",
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
      spacer: 3.0..4.0,
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    ),
    WorldData(
      models: @[
        "content/objects/couch1.obj"
      ],
      pix: @[
        "content/images/rock.png",
        "content/images/musk.png"
      ],
      tex: "content/images/level3.png",
      ceiling: true,
      mapsizex: 2..3,
      mapsizey: 20..25,
      doors: 2..4,
      tilesize: 3.0..3.0,
      height: 3.0..3.0,
      spacer: 3.0..4.0,
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    ),
    WorldData(
      models: @[
        "content/objects/mushroomT1.obj",
        "content/objects/mushroomT2.obj",
        "content/objects/mushroomT3.obj",
      ],
      pix: @[
        "content/images/uv.png"
      ],
      tex: "content/images/level4.png",
      ceiling: false,
      mapsizex: 10..12,
      mapsizey: 10..12,
      doors: 2..4,
      tilesize: 3.0..3.0,
      height: 3.0..3.0,
      spacer: 30.0..30.0, 
      fogColor: newColor(193, 193, 193, 255),
      fogDensity: 0.05
    ),
  ]