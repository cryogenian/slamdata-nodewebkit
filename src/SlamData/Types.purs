module SlamData.Types where

  import Data.Maybe (Maybe(..))
  import qualified Data.Map as M

  -- TODO: These ports should be their own type, not strings.

  type Settings =
    { sdConfig :: SlamDataConfig
    , seConfig :: Maybe SlamEngineConfig
    }

  type SlamDataConfig =
    { server :: {location :: String, port :: String}
    , nodeWebkit :: {java :: Maybe String}
    }

  type SlamEngineConfig =
    { mountings :: M.Map String Mounting
    , server :: {port :: String}
    }

  type Mounting =
    {mongodb :: { connectionUri :: String
                , database :: String
                }
    }

  type SaveSettings eff = Settings -> Control.Monad.Eff.Eff (fsWrite :: FSWrite | eff) Unit

  -- TODO: Move this to the appropriate library.
  foreign import data FS :: *
  foreign import data FSWrite :: !
  type FilePath = String
