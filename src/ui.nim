import hangover
import sugar
import data
import fsm

createEvent(EVENT_PRESS_UI)

template newUiRect(a, b, c, d, e, f, g, h: untyped): UIRectangle =
  newUIRectangle(a * UI_MULT / 10, b * UI_MULT / 10, c * UI_MULT / 10, d * UI_MULT / 10, e, f, g, h)

template uiCenterAt(ox, oy: int, x, y: int, w, h: int, border: float32): Rect =
  newRect((x + 1) * border * UI_SCALE, (y + 1) * border, w * border * UI_SCALE, h * border).offset(newVector2(ox * UI_SCALE, oy))


var
  uiButtonSN, uiButtonSD, uiButtonSF: UISprite

  framerate: string

proc setupUI*(textures: TextureAtlas, font: Font) =
  proc setUIFlag(e: int) =
    var data = e
    sendEvent(EVENT_PRESS_UI, addr data)

  uiButtonSN = newUISprite(textures["ui"], newRect((1 + UI_BORDER) * UI_SCALE,
                                              (0 + UI_BORDER),
                                              (1 - UI_BORDER * 2) * UI_SCALE,
                                              (1 - UI_BORDER * 2)),
                                      uiCenterAt(1, 0, 3, 3, 2, 2, UI_BORDER)).scale(newVector2(UI_MULT / UI_SCALE, UI_MULT))
  uiButtonSD = newUISprite(textures["ui"], newRect((6 + UI_BORDER) * UI_SCALE,
                                              (0 + UI_BORDER),
                                              (1 - UI_BORDER * 2) * UI_SCALE,
                                              (1 - UI_BORDER * 2)),
                                      uiCenterAt(6, 0, 3, 3, 2, 2, UI_BORDER)).scale(newVector2(UI_MULT / UI_SCALE, UI_MULT))
  uiButtonSF = newUISprite(textures["ui"], newRect((2 + UI_BORDER) * UI_SCALE,
                                              (0 + UI_BORDER),
                                              (1 - UI_BORDER * 2) * UI_SCALE,
                                              (1 - UI_BORDER * 2)),
                                      uiCenterAt(2, 0, 3, 3, 2, 2, UI_BORDER)).scale(newVector2(UI_MULT / UI_SCALE, UI_MULT))
  createUIElems mainUI:
    # main menu
    - UIGroup:
      bounds = newUIRect(0, 0, 0, 0, 0, 0, 1, 1)
      elements:
        - UIButton:
          bounds = newUIRect(0, 2, 0, -2, 0.3, 4/6, 0.7, 5/6)
          font = addr font
          fontmult = FONT_MULT

          normalUI = uiButtonSN
          focusedUI = uiButtonSF
          disabledUI = uiButtonSD
          hasTexture = true

          color = newColor(0, 0, 0)

          action = (b: int) => setUIFlag(FE_LOAD)
          text = "New Game"
        - UIButton:
          bounds = newUIRect(0, 2, 0, -2, 0.3, 5/6, 0.7, 6/6)
          font = addr font
          fontmult = FONT_MULT

          normalUI = uiButtonSN
          focusedUI = uiButtonSF
          disabledUI = uiButtonSD
          hasTexture = true

          color = newColor(0, 0, 0)

          action = (b: int) => setUIFlag(FE_QUIT)
          text = "Quit"

  for e in mainUI:
    addUIElement(e)