module SlamData.App.Notebook.Settings
  ( settings
  , SettingsProps()
  , SettingsTab()
  ) where

  import Control.Lens ((.~), (%~), (..), (^.), LensP())

  import Data.Function (runFn2, Fn2(), runFn3, Fn3())
  import Data.Maybe (Maybe(..))
  import Data.Tuple (Tuple(..))

  import React (getProps, mkUI, readState, spec, writeState, ReadProps(), UI())

  import SlamData.Helpers (defaultSEConfig, getOrElse)
  import SlamData.Lens
  import SlamData.Types
    ( Mounting()
    , SaveSettings()
    , Settings()
    , SDConfig()
    , SEConfig()
    )

  import qualified Data.Map as M
  import qualified React.DOM as D

  data SettingsTab = SlamDataTab
                   | SlamEngineTab

  instance eqSettingsTab :: Eq SettingsTab where
    (==) SlamDataTab   SlamDataTab   = true
    (==) SlamEngineTab SlamEngineTab = true
    (==) _             _             = false

    (/=) st            st'           = not (st == st')

  instance showSettingsTab :: Show SettingsTab where
    show SlamDataTab   = "SlamData"
    show SlamEngineTab = "SlamEngine"

  type SettingsProps eff =
    { saveSettings :: SaveSettings eff
    , settings :: Settings
    }

  type SettingsState =
    { active :: SettingsTab
    , settings :: Settings
    }

  sdConfig :: forall a r r'. LensP {settings :: Settings | r} SDConfig
  sdConfig = _settings.._sdConfig

  seConfig :: forall a r r'. LensP {settings :: Settings | r} SEConfig
  seConfig = _settings.._seConfig

  sdServer :: forall r. LensP {settings :: Settings | r} {location :: String, port :: Number}
  sdServer = sdConfig.._sdConfigRec.._server

  seServer :: forall r. LensP {settings :: Settings | r} {port :: Number}
  seServer = seConfig.._seConfigRec.._server

  nodeWebkit :: forall r. LensP {settings :: Settings | r} {java :: String}
  nodeWebkit = sdConfig.._sdConfigRec.._nodeWebkit

  seMountings :: forall r. LensP {settings :: Settings | r} (M.Map String Mounting)
  seMountings = seConfig.._seConfigRec.._mountings

  settings :: forall eff. SettingsProps eff -> UI
  settings = mkUI spec{getInitialState = initialState} do
    props <- getProps
    state <- readState
    let mountings = M.toList $ state^.seConfig.._seConfigRec.._mountings
    pure $ D.div
      [D.className "vertical"]
      [ D.div
          [ D.className "small-1  columns"
          , D.idProp "settings-category"
          ]
          [D.dl
              [D.className "tabs vertical"]
              [ D.dd
                  [D.className $ "tab" ++ activate SlamEngineTab state.active]
                  [D.a
                      [D.onClick \_ -> writeState state{active = SlamEngineTab}]
                      [D.text $ show SlamEngineTab]
                  ]
              , D.dd
                  [D.className $ "tab" ++ activate SlamDataTab state.active]
                  [D.a
                      [D.onClick \_ -> writeState state{active = SlamDataTab}]
                      [D.text $ show SlamDataTab]
                  ]
              ]
          ]
      , D.div
          [ D.className "small-11 columns"
          , D.idProp "settings-content"
          ]
          [D.div
              [D.className "tabs-content vertical"]
              [ D.div
                  [D.className $ "content" ++ activate SlamEngineTab state.active]
                  [ D.h6' [D.text "Settings for the local instance of SlamEngine"]
                  , D.form'
                      [ D.fieldset'
                          [ D.legend' [D.text "Server"]
                          , D.div'
                              [ D.label
                                  [D.htmlFor "slamengine-port"]
                                  [D.text "Port"]
                              , D.input
                                  [ D.name "slamengine-port"
                                  , D.placeholder "8080"
                                  , D.onChange \e -> do
                                    let state' = state # seServer.._port .~ e.target.value
                                    runFn3 wtfIsUpWithEvents writeState props.saveSettings state'
                                  , D.value $ show $ state^.seServer.._port
                                  ]
                                  []
                              ]
                          ]
                      -- This fieldset should be a list of mountings,
                      -- rather than just one.
                      , D.fieldset'
                          [ D.legend' [D.text "MongoDB mountings"]
                          , D.div' $ mountings >>= \(Tuple path mounting) ->
                              [ D.label
                                  [D.htmlFor "mongodb-path"]
                                  [D.text "Path"]
                              , D.input
                                  [ D.name "mongodb-mongouri"
                                  , D.placeholder "/"
                                  , D.onChange \e -> do
                                    let state' = state # seMountings%~ (M.delete path)
                                    let state'' = state' # seMountings%~ (M.insert e.target.value mounting)
                                    runFn3 wtfIsUpWithEvents writeState props.saveSettings state''
                                  , D.value path
                                  ]
                                  []
                              , D.label
                                  [D.htmlFor "mongodb-mongouri"]
                                  [D.text "MongoUri"]
                              , D.input
                                  [ D.name "mongodb-mongouri"
                                  , D.placeholder "mongodb://localhost:27017"
                                  , D.onChange \e -> do
                                    let state' = state # seMountings%~ (M.update (\m -> Just (m # _mountingRec.._connectionUri.~ e.target.value)) path)
                                    runFn3 wtfIsUpWithEvents writeState props.saveSettings state'
                                  , D.value $ mounting^._mountingRec.._connectionUri
                                  ]
                                  []
                              , D.label
                                  [D.htmlFor "mongodb-database"]
                                  [D.text "Database"]
                              , D.input
                                  [ D.name "mongodb-database"
                                  , D.placeholder "test"
                                  , D.onChange \e -> do
                                    let state' = state # seMountings%~ (M.update (\m -> Just (m # _mountingRec.._database.~ e.target.value)) path)
                                    runFn3 wtfIsUpWithEvents writeState props.saveSettings state'
                                  , D.value $ mounting^._mountingRec.._database
                                  ]
                                  []
                              ]
                          ]
                      , D.fieldset'
                          [ D.legend' [D.text "Java"]
                          , D.div'
                              [ D.label
                                  [D.htmlFor "java-binary"]
                                  [D.text "Binary"]
                              , D.input
                                  [ D.name "java-binary"
                                  , D.placeholder "/usr/bin/java"
                                  , D.onChange \e -> do
                                    let state' = state # nodeWebkit.._java .~ e.target.value
                                    runFn3 wtfIsUpWithEvents writeState props.saveSettings state'
                                  , D.value $ state^.nodeWebkit.._java
                                  ]
                                  []
                              ]
                          ]
                      ]
                  ]
              , D.div
                  [D.className $ "content" ++ activate SlamDataTab state.active]
                  [ D.h6' [D.text "SlamEngine server to connect to"]
                  , D.form'
                      [D.fieldset'
                          [ D.legend' [D.text "SlamEngine server"]
                          , D.div'
                              [ D.label
                                  [D.htmlFor "server-location"]
                                  [D.text "Location"]
                              , D.input
                                  [ D.name "server-location"
                                  , D.placeholder "http://localhost"
                                  , D.onChange \e -> do
                                    let state' = state # sdServer.._location .~ e.target.value
                                    runFn3 wtfIsUpWithEvents writeState props.saveSettings state'
                                  , D.value $ state^.sdServer.._location
                                  ]
                                  []
                              ]
                          , D.div'
                              [ D.label
                                  [D.htmlFor "server-port"]
                                  [D.text "Post"]
                              , D.input
                                  [ D.name "server-port"
                                  , D.placeholder "8080"
                                  , D.onChange \e -> do
                                    let state' = state # sdServer.._port .~ e.target.value
                                    runFn3 wtfIsUpWithEvents writeState props.saveSettings state'
                                  , D.value $ show $ state^.sdServer.._port
                                  ]
                                  []
                              ]
                          ]
                      ]
                  ]
              ]
          ]
      ]

  foreign import wtfIsUpWithEvents
    "function wtfIsUpWithEvents(write, save, state) {\
    \  write(state);\
    \  save({sdConfig: state.settings.sdConfig, seConfig: state.settings.seConfig})();\
    \  return function() {\
    \    return state;\
    \  };\
    \}" :: forall a b c d. Fn3 a b c d

  foreign import parseInt :: Fn2 String Number Number

  -- Use the props to set up the state.
  -- Anti-pattern or not, this is the only thing that makes sense.
  initialState :: forall eff. ReadProps (SettingsProps eff) {} SettingsState
  initialState = getProps >>= \props ->
    pure { active: SlamEngineTab
         , settings: props.settings
         }

  activate :: forall a. (Eq a) => a -> a -> String
  activate x y | x == y = " active"
  activate _ _          = ""