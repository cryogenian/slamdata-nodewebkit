module SlamData.App (app) where

  import Control.Monad.Eff

  import React

  import SlamData.App.Menu
  import SlamData.App.Workspace
  import SlamData.Types (SaveSettings(), Settings())

  import qualified React.DOM as D

  app :: forall eff
      .  { settings :: Settings
         , saveSettings :: SaveSettings eff
         }
      -> UI
  app = mkUI spec {getInitialState = pure {settingsVisible: false}} $ do
    state <- readState
    props <- getProps
    pure $ D.div'
      [ menu {showSettings: deferred $ showSettings true}
      , workspace { settings: props.settings
                  , saveSettings: props.saveSettings
                  , showSettings: state.settingsVisible
                  , hideSettings: deferred $ showSettings false
                  }
      ]

  type AppState = {settingsVisible :: Boolean}

  showSettings :: forall eff props state result
               .  Boolean
               -> Eff (r :: ReadStateEff AppState, w :: WriteStateEff AppState | eff) AppState
  showSettings bool = do
    state <- readState
    writeState state{settingsVisible = bool}
