module SlamData.App.Workspace.Notebook
  ( NotebookProps()
  , NotebookState()
  , notebooks
  ) where

  import Control.Lens ((^.), (..))
  import Control.Reactive.Timer (Timer())

  import Data.Array ((\\), head, length, null, snoc)
  import Data.Function (mkFn2, mkFn3)
  import Data.Maybe (Maybe(..))

  import DOM (DOM())

  import Node.UUID (runUUID, v4)

  import React (coerceThis, createClass, eventHandler, spec)
  import React.Types (Component(), ComponentClass(), React(), ReactThis(), This())

  import SlamData.App.Workspace.Notebook.Settings (settings)
  import SlamData.App.Workspace.Notebook.Block (block)
  import SlamData.Components
    ( actionButton
    , closeIcon
    , newNotebookIcon
    , markdownIcon
    , sqlIcon
    , visualIcon
    )
  import SlamData.Helpers (activate)
  import SlamData.Lens (_ident, _notebookRec)
  import SlamData.Types
    ( SlamDataRequest()
    , SlamDataState()
    , SlamDataEventTy(..)
    )
  import SlamData.Types.Workspace.Notebook (Notebook(..), NotebookID(..))
  import SlamData.Types.Workspace.Notebook.Block (Block(), BlockType(..))

  import qualified React.DOM as D

  type NotebookProps eff =
    { request :: SlamDataRequest eff
    , state   :: SlamDataState
    }
  type NotebookState =
    { active     :: Maybe NotebookID
    , settingsId :: NotebookID
    }

  notebooks :: forall eff. ComponentClass (NotebookProps eff) NotebookState
  notebooks = createClass spec
    { displayName = "Notebooks"
    , shouldComponentUpdate = mkFn3 \this props state -> pure $
      this.props.state.notebooks /= props.state.notebooks ||
      -- this.props.state.settings /= props.state.settings ||
      this.props.state.showSettings /= props.state.showSettings ||
      this.state.active /= state.active
    , componentWillReceiveProps = mkFn2 \this props ->
      let oldBooks = this.props.state.notebooks in
      let newBooks = props.state.notebooks in
      if props.state.showSettings && not this.props.state.showSettings then
        pure $ this.setState this.state{active = Just this.state.settingsId}
      else if length newBooks > length oldBooks then
        let active = (flip (^.) (_notebookRec.._ident)) <$> head (newBooks \\ oldBooks)
        in pure $ this.setState this.state{active = active}
      else if length newBooks < length oldBooks then
        let active = (flip (^.) (_notebookRec.._ident)) <$> head newBooks
        in pure $ this.setState this.state{active = active}
      else
        pure unit
    , getInitialState = \this -> pure
      {settingsId: NotebookID $ runUUID v4, active: Nothing :: Maybe NotebookID}
    , render = \this -> do
      let settings = if this.props.state.showSettings then [settingsTab this] else []
      let tabs = reifyTabs (coerceThis this) <$> this.props.state.notebooks ++ settings
      let tabs' = tabs `snoc` createNotebookButton (coerceThis this)
      let content = reifyContent (coerceThis this) <$> this.props.state.notebooks ++ settings
      pure $ D.div {className: "slamdata-panel"}
        [ D.dl {className: "tabs"} tabs'
        , D.div {className: "tabs-content"} content
        ]
    }

  settingsTab :: forall fields. This (state :: NotebookState | fields) -> Notebook
  settingsTab this = Notebook
    { ident: this.state.settingsId
    , blocks: []
    , name: "Settings"
    , path: ""
    }

  createNotebookButton :: forall eff fields state
                       .  ReactThis fields (NotebookProps eff) NotebookState
                       -> Component
  createNotebookButton this = D.dd {className: "tab"}
    [D.div {}
      [D.a { id: "add-notebook"
           , onClick: eventHandler this \this -> pure $
              this.props.request CreateNotebook
           }
        [newNotebookIcon]
      ]
    ]

  reifyTabs :: forall fields eff props
            .  This ( state :: NotebookState
                    , props :: {request :: SlamDataRequest eff | props}
                    , setState :: NotebookState -> Unit
                    | fields
                    )
            -> Notebook
            -> Component
  reifyTabs this (Notebook nb) | nb.ident == this.state.settingsId =
    D.dd {className: "tab" ++ activate (Just nb.ident) this.state.active}
      [D.a { id: "notebook-Settings"
           , onClick: eventHandler this \this _ -> pure $
              this.setState this.state{active = Just nb.ident}
           }
        [ D.rawText nb.name
        , D.i { className: "fa fa-times"
              , onClick: eventHandler this \this _ -> do
                pure $ if this.state.active == Just nb.ident then
                    this.setState this.state{active = Nothing}
                  else
                    unit
                this.props.request HideSettings
              }
          []
        ]
      ]
  reifyTabs this (Notebook nb) =
    D.dd {className: "tab" ++ activate (Just nb.ident) this.state.active}
      [D.a {onClick: eventHandler this \this _ -> pure $
              this.setState this.state{active = Just nb.ident}
           }
        [ D.rawText nb.name
        , D.i { className: "fa fa-times"
              , onClick: eventHandler this \this _ -> do
                pure $ if this.state.active == Just nb.ident then
                    this.setState this.state{active = Nothing}
                  else
                    unit
                this.props.request $ CloseNotebook nb.ident
              }
          []
        ]
      ]

  reifyContent :: forall fields eff
               .  ReactThis fields (NotebookProps eff) NotebookState
               -> Notebook
               -> Component
  reifyContent this (Notebook nb) | nb.ident == this.state.settingsId =
    D.div {className: "content" ++ activate (Just nb.ident) this.state.active}
      [settings {request: this.props.request, state: this.props.state} []
      ]
  reifyContent this (Notebook nb) =
    D.div {className: "content" ++ activate (Just nb.ident) this.state.active}
      [ D.div {className: "toolbar button-bar"}
        [internalActions this nb.ident]
      , D.hr {} []
      , D.div {className: "actual-content"}
        (reifyBlock this nb.ident <$> nb.blocks)
      ]

  reifyBlock :: forall fields eff
             .  ReactThis fields (NotebookProps eff) NotebookState
             -> NotebookID
             -> Block
             -> Component
  reifyBlock this ident b =
    block {block: b, notebookID: ident, request: this.props.request} []

  internalActions :: forall eff fields
                  .  ReactThis fields (NotebookProps eff) NotebookState
                  -> NotebookID
                  -> Component
  internalActions this ident = D.ul {className: "button-group"}
    [ actionButton this (CreateBlock ident Markdown) (blockIcon Markdown)
    , actionButton this (CreateBlock ident SQL)      (blockIcon SQL)
    , actionButton this (CreateBlock ident Visual)   (blockIcon Visual)
    ]

  blockIcon :: BlockType -> Component
  blockIcon Markdown = markdownIcon
  blockIcon SQL      = sqlIcon
  blockIcon Visual   = visualIcon
