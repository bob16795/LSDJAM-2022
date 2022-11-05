import hangover

createEvent(EVENT_FSM_EVENT)

const
  FE_LOAD* = 0
  FE_PAUSE* = 1
  FE_DELETE* = 2
  FE_SETTINGS* = 3
  FE_QUIT* = 4

  FS_LOADING* = 0
  FS_TITLE* = 1
  FS_SETTINGS* = 2
  FS_GAME* = 3
  FS_PAUSE* = 4
  FS_PSETTINGS* = 5

  FS_QUIT* = 6

proc initMainMachine*(): StateMachine =
  return newStateMachine(@[
    # 0: loading
    newState(@[
      newFlag(FE_LOAD, FS_TITLE),
    ]),
    # 1: title
    newState(@[
      newFlag(FE_LOAD, FS_GAME),
      newFlag(FE_QUIT, FS_QUIT),
      newFlag(FE_SETTINGS, FS_SETTINGS),
    ]),
    # 2: settings
    newState(@[
      newFlag(FE_SETTINGS, FS_TITLE),
      newFlag(FE_QUIT, FS_TITLE),
    ]),
    # 3: game
    newState(@[
      newFlag(FE_PAUSE, FS_PAUSE),
    ]),
    # 4: pause
    newState(@[
      newFlag(FE_PAUSE, FS_GAME),
      newFlag(FE_SETTINGS, FS_PSETTINGS),
      newFlag(FE_QUIT, FS_TITLE),
    ]),
    # 5: psettings
    newState(@[
      newFlag(FE_SETTINGS, FS_PAUSE),
      newFlag(FE_QUIT, FS_PAUSE),
    ]),
    # 6: Quit
    newState(@[
    ])
  ])