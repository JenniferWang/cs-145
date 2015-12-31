module IOBackend (
    Page(..)
  , Buffer(Buffer, bPageSize, bBufferSize)
  ) where

import qualified Data.Map.Strict as Map
import Data.Maybe
import Data.List(find)
import Text.Printf(printf)

type PID = Int
type FID = Int
type File a = [Maybe (Page a)]
type Disk a = [Maybe (File a)]
type Index = Int
type CountEmpty = Bool

throwIndexOutOfBoundException = error "Index out of bound for data"

-- suppose page data has the same type
data Page a = Page {
    pFID  :: FID
  , pPID  :: PID
  , pRawSize :: Int
  , pData :: ![a]
  }

setPageDataAt :: Int -> Page a -> a -> Page a
setPageDataAt index page@Page{pData = old_data} new_val =
  page{pData = writeArray old_data index new_val}

setPageData :: Page a -> [a] -> Page a
setPageData page@Page{pData = old_data} new_data
  | pRawSize page /= length new_data = error "Data and page size do not match"
  | otherwise = page{pData = new_data}

readArray :: [a] -> Index -> a
readArray array index = array !! index

writeArray :: [a] -> Index -> a -> [a]
writeArray array index new_val
  | index >= length array = throwIndexOutOfBoundException
  | otherwise = (take index array) ++ [new_val] ++ drop (index + 1) array

-- getPageSize :: Page -> Bool -> PageSize
-- getPageSize page count_empty = length $
--   filter (\x -> count_empty || null x) (getPageData page)

data Buffer a = Buffer {
    bPageSize :: Int
  , bBufferSize :: Int
  , bBufferData :: !([Maybe (Page a)])
      -- simulate the physical layout of buffer
  , bBufferOrder :: [PID]
  , bBufferMap :: !(Map.Map (FID, PID) (Page a))
  , bDisk :: !(Disk a)
  , bIOCount :: Map.Map String Int
  , bLog :: [LogEntry]
  }

initBuffer :: Int -> Int -> Buffer a
initBuffer p_size b_size = Buffer {
    bPageSize = p_size
  , bBufferSize = b_size
  , bBufferData = [Nothing | x <- [1..b_size]]
  , bBufferOrder = []
  , bBufferMap = Map.empty
  , bDisk = []
  , bIOCount = initIOCount
  , bLog = []
  } where initIOCount = Map.fromList [
              ("bufferReads", 0)
            , ("bufferWrites", 0)
            , ("diskReads", 0)
            , ("diskWrites", 0)
            ]

bufferIsFull :: Buffer a -> Bool
bufferIsFull buf = bBufferSize buf ==
  (length $ filter (\x -> isJust x) (bBufferData buf))

getEmptyBufferSlot :: Buffer a -> Maybe Index
getEmptyBufferSlot buf
  | index == bBufferSize buf = Nothing
  | otherwise = Just index
    where index = length $ takeWhile (\x -> isJust x) (bBufferData buf)

getEmptyDiskSlot :: Buffer a -> (Index, Buffer a)
getEmptyDiskSlot buf@Buffer{bDisk = disk} = (index, new_buf)
  where new_buf = buf{bDisk = writeArray disk index Nothing}
        index = length $ takeWhile (\x -> isJust x) (bDisk buf)

getFileSize :: Buffer a -> FID -> CountEmpty -> Int
getFileSize buff fid count_empty
  | isNothing file = 0
  | otherwise = length $
    filter (\x -> count_empty || isJust x) (fromJust file)
    where file = readArray (bDisk buff) fid

data LogEntry = LogEntry {
    logOperation :: String
  , logOldLocation :: String
  , logNewLocation :: String
  , logFile :: String
  , logPage :: String
  , logBufferIndex :: String
  , logPageData :: String
  , logKeepOld :: String
  , logIOCount :: String
  } deriving Show

read :: FID -> PID -> Maybe (Page a)
read = undefined
