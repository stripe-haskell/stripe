{-# LANGUAGE OverloadedStrings #-}
-- |
-- Module      : Web.Stripe.Card
-- Copyright   : (c) David Johnson, 2014
-- Maintainer  : djohnson.m@gmail.com
-- Stability   : experimental
-- Portability : POSIX
module Web.Stripe.Card
    ( -- * API
      -- ** Customers
      -- *** Create Customer Card
      createCustomerCard
    , createCustomerCardByToken
      -- *** Get Customer Card(s)
    , getCustomerCard
    , getCustomerCardExpandable
    , getCustomerCards
    , getCustomerCardsExpandable
      -- *** Update Customer Card
    , updateCustomerCard
      -- *** Delete Card
    , deleteCustomerCard
      -- ** Recipients
      -- *** Create Recipient Card
    , createRecipientCard
    , createRecipientCardByToken
      -- *** Get Recipient Card(s)
    , getRecipientCard
    , getRecipientCardExpandable
    , getRecipientCards
    , getRecipientCardsExpandable
      -- *** Updated Recipient Card
    , updateRecipientCard
      -- *** Delete Recipient Card
    , deleteRecipientCard
      -- * Types
    , Brand           (..)
    , Card            (..)
    , RecipientCard   (..)
    , CardId          (..)
    , RecipientCardId (..)
    , CardNumber      (..)
    , ExpMonth        (..)
    , ExpYear         (..)
    , CVC             (..)
    , Name
    , AddressLine1    (..)
    , AddressLine2    (..)
    , AddressCity     (..)
    , AddressCountry  (..)
    , AddressState    (..)
    , AddressZip      (..)
    , RecipientId     (..)
    ) where

import           Control.Applicative        ((<$>))
import           Data.Aeson                 (FromJSON)
import           Web.Stripe.Client.Internal
import           Web.Stripe.Types
import           Web.Stripe.Types.Util 

------------------------------------------------------------------------------
-- | Base request function for `Card` creation, good for making custom create `Card` functions
createCardBase
  :: FromJSON a
  => URL                  -- ^ The `Recipient` or `Customer` on which to make the `Card` value can be "recipients" or "customers" only
  -> ID                   -- ^ The `RecipientId` or `CustomerId` for which the `Card` can be made
  -> Maybe TokenId        -- ^ The `TokenId` to be used for `Card` creation
  -> Maybe CardNumber     -- ^ `CardNumber` for `Card` creation
  -> Maybe ExpMonth       -- ^ Expiration Month for `Card` creation
  -> Maybe ExpYear        -- ^ Expiration Year for `Card` creation
  -> Maybe CVC            -- ^ CVC for `Card` creation
  -> Maybe Name           -- ^ Name of `Recipient` or `Customer` to be used for `Card`
  -> Maybe AddressCity    -- ^ City associated with `Card`
  -> Maybe AddressCountry -- ^ Country associated with `Card`
  -> Maybe AddressLine1   -- ^ Address Line 1 associated with `Card`
  -> Maybe AddressLine2   -- ^ Address Line 2 associated with `Card`
  -> Maybe AddressState   -- ^ Address State 2 associated with `Card`
  -> Maybe AddressZip     -- ^ Address Zip associated with `Card`
  -> MetaData             -- ^ MetaData for `Card`
  -> Stripe a
createCardBase
    requestType
    requestId
    tokenid
    cardNumber
    expMonth
    expYear
    cvc
    name
    addressCity
    addressCountry
    addressLine1
    addressLine2
    addressState
    addressZip
    metadata    = callAPI request
  where request = StripeRequest POST url params
        url     = requestType </> requestId </> "cards"
        params  = toMetaData metadata ++ getParams [
                     ("card", (\(TokenId x) -> x) <$> tokenid)
                   , ("card[number]", (\(CardNumber x) -> x) <$> cardNumber)
                   , ("card[exp_month]", (\(ExpMonth x) -> toText x) <$> expMonth)
                   , ("card[exp_year]", (\(ExpYear x) -> toText x) <$> expYear)
                   , ("card[cvc]", (\(CVC x) -> x) <$> cvc)
                   , ("name", name)
                   , ("address_city", (\(AddressCity x) -> x) <$> addressCity)
                   , ("address_country", (\(AddressCountry x) -> x) <$> addressCountry)
                   , ("address_line1", (\(AddressLine1 x) -> x) <$> addressLine1 )
                   , ("address_line2", (\(AddressLine2 x) -> x) <$> addressLine2 )
                   , ("address_state", (\(AddressState x) -> x) <$> addressState )
                   , ("address_zip", (\(AddressZip x) -> x) <$> addressZip )
                  ]

------------------------------------------------------------------------------
-- | Create a `Customer` card using a `Token`
createCustomerCardByToken
    :: CustomerId -- ^ The Customer to which the card will be added
    -> TokenId    -- ^ The Token representative of the card
    -> Stripe Card
createCustomerCardByToken
    customerid
    tokenid = createCardBase "customers" (getCustomerId customerid) (Just tokenid)
              Nothing Nothing Nothing
              Nothing Nothing Nothing
              Nothing Nothing Nothing
              Nothing Nothing []

------------------------------------------------------------------------------
-- | Create a `Recipient` card using a `Token`
createRecipientCardByToken
    :: RecipientId -- ^ The Customer to which the card will be added
    -> TokenId     -- ^ The Token representative of the card
    -> Stripe RecipientCard
createRecipientCardByToken
    recipientid
    tokenid = createCardBase "customers" (getRecipientId recipientid) (Just tokenid)
              Nothing Nothing Nothing
              Nothing Nothing Nothing
              Nothing Nothing Nothing
              Nothing Nothing []

------------------------------------------------------------------------------
-- | Create a `Customer` card by `CardNumber`
createCustomerCard
    :: CustomerId -- ^ `Customer` to which the card will be added
    -> CardNumber -- ^ `Card` digits
    -> ExpMonth   -- ^ `Card` expiration month
    -> ExpYear    -- ^ `Card` expiration year
    -> CVC        -- ^ `Card` cvc number
    -> Stripe Card
createCustomerCard
    customerid
    cardNumber
    expMonth
    expYear
    cvc = createCardBase "customers" (getCustomerId customerid) Nothing
              (Just cardNumber) (Just expMonth) (Just expYear)
              (Just cvc) Nothing Nothing
              Nothing Nothing Nothing
              Nothing Nothing []

------------------------------------------------------------------------------
-- | Create a `Recipient` `Card` by `CardNumber`
createRecipientCard
    :: RecipientId -- ^ `Recipient` to which the card will be added
    -> CardNumber  -- ^ `Card` digits
    -> ExpMonth    -- ^ `Card` expiration month
    -> ExpYear     -- ^ `Card` expiration year
    -> CVC         -- ^ `Card` cvc number
    -> Stripe RecipientCard
createRecipientCard
    recipientid
    cardNumber
    expMonth
    expYear
    cvc = createCardBase "recipients" (getRecipientId recipientid) Nothing
              (Just cardNumber) (Just expMonth) (Just expYear)
              (Just cvc) Nothing Nothing
              Nothing Nothing Nothing
              Nothing Nothing []

------------------------------------------------------------------------------
-- | Update a `Card`, any fields not specified will remain the same
updateCardBase
    :: FromJSON a
    => URL                  -- ^ The `Recipient` or `Customer` on which to make the `Card` value can be "recipients" or "customers" only
    -> ID                   -- ^ The `RecipientId` or `CustomerId` for which the `Card` can be made
    -> CardId               -- ^ The `CardId` associated with the `Card` to be updated
    -> Maybe Name           -- ^ Name of `Recipient` or `Customer` to be used for `Card`
    -> Maybe AddressCity    -- ^ City associated with `Card`
    -> Maybe AddressCountry -- ^ Country associated with `Card`
    -> Maybe AddressLine1   -- ^ Address Line 1 associated with `Card`
    -> Maybe AddressLine2   -- ^ Address Line 2 associated with `Card`
    -> Maybe AddressState   -- ^ Address State 2 associated with `Card`
    -> Maybe AddressZip     -- ^ Address Zip associated with `Card`
    -> MetaData             -- ^ MetaData for `Card`
    -> Stripe a
updateCardBase
    requestType
    requestId
    cardid
    name
    addressCity
    addressCountry
    addressLine1
    addressLine2
    addressState
    addressZip 
    metadata    = callAPI request
  where request = StripeRequest POST url params
        url     = requestType </> requestId </> "cards" </> getCardId cardid
        params  = toMetaData metadata ++ getParams [
                     ("name", name)
                   , ("address_city", (\(AddressCity x) -> x) <$> addressCity)
                   , ("address_country", (\(AddressCountry x) -> x) <$> addressCountry)
                   , ("address_line1", (\(AddressLine1 x) -> x) <$> addressLine1 )
                   , ("address_line2", (\(AddressLine2 x) -> x) <$> addressLine2 )
                   , ("address_state", (\(AddressState x) -> x) <$> addressState )
                   , ("address_zip", (\(AddressZip x) -> x) <$> addressZip )
                   ]

------------------------------------------------------------------------------
-- | Update a `Customer` `Card`
updateCustomerCard
    :: CustomerId           -- ^ `CustomerId` associated with the `Card` to be updated
    -> CardId               -- ^ The `CardId` associated with the `Card` to be updated
    -> Maybe Name           -- ^ Name of `Recipient` or `Customer` to be used for `Card`
    -> Maybe AddressCity    -- ^ City associated with `Card`
    -> Maybe AddressCountry -- ^ Country associated with `Card`
    -> Maybe AddressLine1   -- ^ Address Line 1 associated with `Card`
    -> Maybe AddressLine2   -- ^ Address Line 2 associated with `Card`
    -> Maybe AddressState   -- ^ Address State 2 associated with `Card`
    -> Maybe AddressZip     -- ^ Address Zip associated with `Card`
    -> MetaData             -- ^ MetaData for `Card`
    -> Stripe Card
updateCustomerCard
    customerid  = updateCardBase "customers" (getCustomerId customerid)

------------------------------------------------------------------------------
-- | Update a `Recipient` `Card`
updateRecipientCard
    :: RecipientId          -- ^ `RecipientId` associated with the `Card` to be updated
    -> CardId               -- ^ The `CardId` associated with the `Card` to be updated
    -> Maybe Name           -- ^ Name of `Recipient` or `Customer` to be used for `Card`
    -> Maybe AddressCity    -- ^ City associated with `Card`
    -> Maybe AddressCountry -- ^ Country associated with `Card`
    -> Maybe AddressLine1   -- ^ Address Line 1 associated with `Card`
    -> Maybe AddressLine2   -- ^ Address Line 2 associated with `Card`
    -> Maybe AddressState   -- ^ Address State 2 associated with `Card`
    -> Maybe AddressZip     -- ^ Address Zip associated with `Card`
    -> MetaData             -- ^ MetaData for `Card`
    -> Stripe Card
updateRecipientCard
    recipientid  = updateCardBase "recipients" (getRecipientId recipientid)

------------------------------------------------------------------------------
-- | Base Request for retrieving cards from either a `Customer` or `Recipient`
getCardBase
    :: FromJSON a
    => URL          -- ^ The type of the request to support (recipient or customer)
    -> ID           -- ^ `CustomerId` or `RecipientId` of the `Card` to retrieve
    -> ID           -- ^ `CardId` or `RecipientCardId` of the `Card` or `RecipientCard` to retrieve
    -> ExpandParams -- ^ `ExpandParams` of the `Card`
    -> Stripe a
getCardBase
    requestType
    requestId
    cardid
    expandParams = callAPI request
  where request = StripeRequest GET url params
        url     = requestType </> requestId </> "cards" </> cardid
        params  = toExpandable expandParams

------------------------------------------------------------------------------
-- | Get card by `CustomerId` and `CardId`
getCustomerCard
    :: CustomerId -- ^ `CustomerId` of the `Card` to retrieve
    -> CardId     -- ^ `CardId` of the card to retrieve
    -> Stripe Card
getCustomerCard
    customerid cardid = getCustomerCardExpandable customerid cardid []

------------------------------------------------------------------------------
-- | Get card by `CustomerId` and `CardId` with `ExpandParams`
getCustomerCardExpandable
    :: CustomerId   -- ^ `CustomerId` of the `Card` to retrieve
    -> CardId       -- ^ `CardId` of the card to retrieve
    -> ExpandParams -- ^ `CardId` of the card to retrieve
    -> Stripe Card
getCustomerCardExpandable
    customerid cardid expandParams =
      getCardBase "customers" (getCustomerId customerid) (getCardId cardid) expandParams

------------------------------------------------------------------------------
-- | Get card by `RecipientId` and `CardId`
getRecipientCard
    :: RecipientId     -- ^ `RecipientId` of the `Card` to retrieve
    -> RecipientCardId -- ^ `CardId` of the `Recipient` `Card` to retrieve
    -> Stripe RecipientCard
getRecipientCard
  recipientid
  cardid = getRecipientCardExpandable recipientid cardid []

------------------------------------------------------------------------------
-- | Get card by `RecipientId` and `CardId`
getRecipientCardExpandable
    :: RecipientId     -- ^ `RecipientId` of the `Card` to retrieve
    -> RecipientCardId -- ^ `CardId` of the `Recipient` `Card` to retrieve
    -> ExpandParams    -- ^ `ExpandParams` of the `Recipient` `Card` to retrieve
    -> Stripe RecipientCard
getRecipientCardExpandable
    recipientid
    cardid
    expandParams
      = getCardBase "recipients" (getRecipientId recipientid)
          (getRecipientCardId cardid) expandParams

------------------------------------------------------------------------------
-- | Base Request for retrieving `Customer` cards
getCustomerCardsBase
    :: CustomerId -- ^ `CustomerId` of the `Card` to retrieve
    -> Maybe Limit -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter CardId -- ^ Paginate starting after the following `CardId`
    -> EndingBefore CardId  -- ^ Paginate ending before the following `CardId`
    -> ExpandParams  -- ^ Expansion on `Card`
    -> Stripe (StripeList Card)
getCustomerCardsBase
    customerid
    limit
    startingAfter
    endingBefore
    expandParams = callAPI request
  where request = StripeRequest GET url params
        url     = "customer" </> getCustomerId customerid </> "cards"
        params  = getParams [
            ("limit", toText `fmap` limit )
          , ("starting_after", (\(CardId x) -> x) `fmap` startingAfter)
          , ("ending_before", (\(CardId x) -> x) `fmap` endingBefore)
          ] ++ toExpandable expandParams 

------------------------------------------------------------------------------
-- | Base Request for retrieving `Customer` or `Recipient` cards
getRecipientCardsBase
    :: RecipientId -- ^ `RecipientId` of the `Card` to retrieve
    -> Maybe Limit -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter RecipientCardId -- ^ Paginate starting after the following `CardId`
    -> EndingBefore RecipientCardId  -- ^ Paginate ending before the following `CardId`
    -> ExpandParams  -- ^ Expansion on `Card`
    -> Stripe (StripeList RecipientCard)
getRecipientCardsBase
    recipientid
    limit
    startingAfter
    endingBefore
    expandParams = callAPI request
  where request = StripeRequest GET url params
        url     = "recipient" </> getRecipientId recipientid </> "cards"
        params  = getParams [
            ("limit", toText `fmap` limit )
          , ("starting_after", (\(RecipientCardId x) -> x) `fmap` startingAfter)
          , ("ending_before", (\(RecipientCardId x) -> x) `fmap` endingBefore)
          ] ++ toExpandable expandParams 


------------------------------------------------------------------------------
-- | Retrieve all cards associated with a `Customer`
getCustomerCards
    :: CustomerId           -- ^ The `CustomerId` associated with the cards
    -> Maybe Limit          -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter CardId -- ^ Paginate starting after the following `CardId`
    -> EndingBefore CardId  -- ^ Paginate ending before the following `CardId`
    -> Stripe (StripeList Card)
getCustomerCards
    customerid
    limit
    startingAfter
    endingBefore
    = getCustomerCardsExpandable customerid limit startingAfter endingBefore []

------------------------------------------------------------------------------
-- | Retrieve all cards associated with a `Customer`
getCustomerCardsExpandable
    :: CustomerId           -- ^ The `CustomerId` associated with the cards
    -> Maybe Limit          -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter CardId -- ^ Paginate starting after the following `CardId`
    -> EndingBefore CardId  -- ^ Paginate ending before the following `CardId`
    -> ExpandParams         -- ^ Expansion on `Card`
    -> Stripe (StripeList Card)
getCustomerCardsExpandable
    customerid
    limit
    startingAfter
    endingBefore
    expandParams =
      getCustomerCardsBase customerid
        limit startingAfter endingBefore expandParams

------------------------------------------------------------------------------
-- | Retrieve all cards associated with a `Recipient`
getRecipientCards
    :: RecipientId -- ^ The `RecipientId` associated with the cards
    -> Maybe Limit -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter RecipientCardId -- ^ Paginate starting after the following `CardId`
    -> EndingBefore RecipientCardId  -- ^ Paginate ending before the following `CardId`
    -> Stripe (StripeList RecipientCard)
getRecipientCards
    recipientid
    limit
    startingAfter
    endingBefore =
      getRecipientCardsExpandable recipientid limit
        startingAfter endingBefore []

------------------------------------------------------------------------------
-- | Retrieve all cards associated with a `Recipient`
getRecipientCardsExpandable
    :: RecipientId -- ^ The `RecipientId` associated with the cards
    -> Maybe Limit -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter RecipientCardId -- ^ Paginate starting after the following `CardId`
    -> EndingBefore RecipientCardId -- ^ Paginate ending before the following `CardId`
    -> ExpandParams -- ^ Expansion on `Card`
    -> Stripe (StripeList RecipientCard)
getRecipientCardsExpandable
    recipientid
    limit
    startingAfter
    endingBefore
    expandParams =
      getRecipientCardsBase recipientid
        limit startingAfter endingBefore expandParams

------------------------------------------------------------------------------
-- | Base request for `Card` removal from a `Customer` or `Recipient`
deleteCardBase
    :: URL    -- ^ The type of the request to support (`Recipient` or `Customer`)
    -> ID     -- ^ `CustomerId` or `RecipientId` of the `Card` to retrieve
    -> CardId -- ^ `CardId` associated with `Card` to be deleted
    -> Stripe StripeDeleteResult
deleteCardBase
    requestType
    requestId
    cardid = callAPI request
  where request = StripeRequest DELETE url params
        url     = requestType </> requestId </> "cards" </> getCardId cardid
        params  = []

------------------------------------------------------------------------------
-- | Removes a card from a `Customer`
deleteCustomerCard
    :: CustomerId -- ^ The `CustomerId` associated with the `Card` to be removed
    -> CardId     -- ^ The `CardId` of the `Card` to be removed
    -> Stripe StripeDeleteResult
deleteCustomerCard
    customerid = deleteCardBase "customers" (getCustomerId customerid)

------------------------------------------------------------------------------
-- | Removes a card from a `Customer`
deleteRecipientCard
    :: RecipientId -- ^ The `RecipientId` associated with the `Card` to be removed
    -> CardId      -- ^ The `CardId` of the `Card` to be removed
    -> Stripe StripeDeleteResult
deleteRecipientCard
    recipientid = deleteCardBase "recipients" (getRecipientId recipientid)
