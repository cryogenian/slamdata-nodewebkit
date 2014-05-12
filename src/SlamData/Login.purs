module SlamData.Login (loginForm) where

  import Control.Monad.Eff

  import qualified Data.Array as A
  import Data.String

  import React
  import React.DOM

  -- | Something to tell us if we've got a new user or an existing user.
  data NewOrExisting = New | Existing

  instance eqNewOrExisting :: Eq NewOrExisting where
    (==) New      New      = true
    (==) Existing Existing = true
    (==) _        _        = false

    (/=) noe      noe'     = not (noe == noe')

  instance showNewOrExisting :: Show NewOrExisting where
    show New      = "NewAccount"
    show Existing = "ExistingAccount"

  loginForm :: {} -> UI
  loginForm = mkUI spec {getInitialState = pure { newAccount: Existing }} do
    state <- readState
    pure $ form {}
      [ fieldset {}
          [ legend {} [ text "Login to SlamData" ]
          , row [ large6 $ newOrExisting { newAccount: state.newAccount
                                         , onChangeNew: handle changeNew
                                         }
                , large6 demo
                ]
          , information { newAccount: state.newAccount }
          , row [ large6 $ div {} []
                , large6 $ createOrLogin { newAccount: state.newAccount }
                ]
          ]
      ]

  newOrExisting :: forall e. { newAccount :: NewOrExisting , onChangeNew :: e } -> UI
  newOrExisting = mkUI spec do
    props <- getProps
    let radioWithLabel {labelText = l, value = v} =
        p {} [ input { attrType: "radio"
                     , checked: props.newAccount == v
                     , id: show v
                     , name: "new-or-existing"
                     , onChange: handle $ newAccountChanged v
                     }
                     []
             , label { htmlFor: show v }
                     [ text l ]
             ]
    pure $ div {}
      [ radioWithLabel { labelText: "I have an existing account."
                       , value: Existing
                       }
      , radioWithLabel { labelText: "I need to create a new account."
                       , value: New
                       }
      ]
    where
      newAccountChanged val = do
        props <- getProps
        pure $ props.onChangeNew { newAccount: val }

  demo :: UI
  demo =
    button { className: "right secondary" }
      [ text "Try Demo!" ]

  information :: { newAccount :: NewOrExisting } -> UI
  information = mkUI spec do
    props <- getProps
    let info = if isNew props.newAccount then [alwaysInfo, newInfo] else [alwaysInfo]
    pure $ div {} info

  alwaysInfo :: UI
  alwaysInfo =
    div {}
      [ row $ large6 <$> [ validationText { label: "Email" }
                         , validationText { label: "Password" }
                         ]
      ]

  newInfo :: UI
  newInfo =
    div {}
      [ row $ large6 <$> [ validationText { label: "Name" }
                         , validationText { label: "Confirm Password" }
                         , validationText { label: "Company" }
                         , validationText { label: "Title" }
                         ]
      ]

  validationText :: { label :: String } -> UI
  validationText = mkUI spec do
    props <- getProps
    pure $ div {}
      [ label { htmlFor: toLower props.label }
              [ text props.label ]
      , input { attrType: "text"
              , id: toLower props.label
              }
              []
      ]

  createOrLogin :: { newAccount :: NewOrExisting } -> UI
  createOrLogin = mkUI spec do
    props <- getProps
    let buttonText = if isNew props.newAccount then "Create Account" else "Login"
    pure $ div {}
      [ div {} []
      , button { className: "right" }
               [ text buttonText ]
      ]

  -- | Helper functions.

  row :: [UI] -> UI
  row uis = div { className: "row" } uis

  large6 :: UI -> UI
  large6 ui = div { className: "large-6 columns" } [ ui ]

  isNew :: NewOrExisting -> Boolean
  isNew New = true
  isNew _   = false

  -- We have to cheat for now with the type,
  -- otherwise we don't get the correct context in jsland.
  -- This is something that needs to be fixed in purescript-react
  foreign import changeNew
    "function changeNew(state) {\
    \  React.writeState(state);\
    \}" :: forall a eff. Eff eff a

  -- This should be in `React`
  foreign import getDOMNode
    "function getDOMNode(x) {\
    \  return x.getDOMNode();\
    \}" :: forall a b. a -> b
