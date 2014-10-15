{-# LANGUAGE OverloadedStrings #-}
-- |
-- Module      : Web.Stripe.Charge
-- Copyright   : (c) David Johnson, 2014
-- Maintainer  : djohnson.m@gmail.com
-- Stability   : experimental
-- Portability : POSIX
module Web.Stripe.Charge
    ( -- * API
      ---- * Create Charges
      chargeCustomer
    , createCharge
    , chargeCardByToken
    , chargeCard
      ---- * Get Charge(s)
    , getCharge
    , getChargeExpandable
    , getCharges
    , getChargesExpandable
    , getCustomerCharges
    , getCustomerChargesExpandable
      ---- * Update Charge
    , updateCharge
      ---- * Capture Charge
    , captureCharge
      -- * Types
    , Charge       (..)
    , TokenId      (..)
    , ChargeId     (..)
    , CustomerId   (..)
    , Currency     (..)
    , CardNumber   (..)
    , CVC          (..)
    , ExpMonth     (..)
    , ExpYear      (..)
    , StripeList   (..)
    , Email (..)
    , Description
    , StatementDescription
    , Amount
    , Capture
    ) where

import           Web.Stripe.Client.Internal (Method (GET, POST), Stripe,
                                             StripeRequest (..), callAPI,
                                             getParams, toMetaData, toText, toExpandable,
                                             (</>))

import           Web.Stripe.Types           (Amount, CVC (..), Capture,
                                             CardNumber (..), Charge (..),
                                             ChargeId (..), Currency (..),
                                             CustomerId (..), Description,
                                             EndingBefore, ExpMonth (..),
                                             ExpYear (..), Limit, MetaData,
                                             Email (..), StartingAfter,
                                             StatementDescription(..), ExpandParams,
                                             StripeList (..), TokenId (..))
import           Web.Stripe.Types.Util

------------------------------------------------------------------------------
-- | Charge `Customer``s by `CustomerId`
chargeCustomer
    :: CustomerId   -- ^ The ID of the customer to be charged
    -> Currency     -- ^ Required, 3-letter ISO Code
    -> Amount       -- ^ Required, Integer value of 100 represents $1
    -> Maybe Description -- ^ Optional, default is null
    -> Stripe Charge
chargeCustomer customerId currency amount description =
    createCharge amount currency description (Just customerId)
    Nothing Nothing Nothing False
    Nothing Nothing Nothing Nothing []

------------------------------------------------------------------------------
-- | Charge a card by a `Token`
chargeCardByToken
    :: TokenId    -- ^ The Token representative of a credit card
    -> Currency   -- ^ Required, 3-letter ISO Code
    -> Amount     -- ^ Required, Integer value of 100 represents $1
    -> Maybe Description -- ^ Optional, default is null
    -> Stripe Charge
chargeCardByToken tokenId currency amount description =
    createCharge amount currency description Nothing (Just tokenId)
    Nothing Nothing True Nothing Nothing Nothing Nothing []

------------------------------------------------------------------------------
-- | Charge a card by `CardNumber`
chargeCard
    :: CardNumber        -- ^ Required, Credit Card Number
    -> ExpMonth          -- ^ Required, Expiration Month (i.e. 09)
    -> ExpYear           -- ^ Required, Expiration Year (i.e. 2018)
    -> CVC               -- ^ Required, CVC Number (i.e. 000)
    -> Currency          -- ^ Required, 3-letter ISO Code
    -> Amount            -- ^ Required, Integer value of 100 represents $1
    -> Maybe Description -- ^ Optional, default is null
    -> Stripe Charge
chargeCard cardNumber expMonth expYear cvc currency amount description =
    createCharge amount currency description
    Nothing Nothing Nothing Nothing True
    (Just cardNumber) (Just expMonth)
    (Just expYear) (Just cvc) []

------------------------------------------------------------------------------
-- | Base method for creating a `Charge`
createCharge
    :: Amount             -- ^ Required, Integer value of 100 represents $1
    -> Currency           -- ^ Required, 3-letter ISO Code
    -> Maybe Description  -- ^ Optional, default is nullo
    -> Maybe CustomerId   -- ^ Optional, either CustomerId or TokenId has to be specified
    -> Maybe TokenId      -- ^ Optional, either CustomerId or TokenId has to be specified
    -> Maybe StatementDescription -- ^ Optional, Arbitrary string to include on CC statements
    -> Maybe Email        -- ^ Optional, Arbitrary string to include on CC statements
    -> Capture            -- ^ Optional, default is True
    -> Maybe CardNumber
    -> Maybe ExpMonth
    -> Maybe ExpYear
    -> Maybe CVC
    -> MetaData
    -> Stripe Charge
createCharge
    amount
    (Currency currency)
    description
    customerid
    tokenId
    statementDescription
    receiptEmail
    capture
    cardNumber
    expMonth
    expYear
    cvc'
    metadata    = callAPI request
  where request = StripeRequest POST url params
        url     = "charges"
        params  = toMetaData metadata ++ getParams [
                     ("amount", toText `fmap` Just amount)
                   , ("customer", (\(CustomerId cid) -> cid) `fmap` customerid)
                   , ("currency", Just currency)
                   , ("card", (\(TokenId tokenid) -> tokenid) `fmap` tokenId)
                   , ("description", description)
                   , ("statement_description", (\(StatementDescription x) -> x) `fmap` statementDescription)
                   , ("receipt_email", (\(Email email) -> email) `fmap` receiptEmail)
                   , ("capture", (\x -> if x then "true" else "false") `fmap` Just capture)
                   , ("card[number]", (\(CardNumber c) -> toText c) `fmap` cardNumber)
                   , ("card[exp_month]", (\(ExpMonth m) -> toText m) `fmap` expMonth)
                   , ("card[exp_year]", (\(ExpYear y) -> toText y) `fmap` expYear)
                   , ("card[cvc]", (\(CVC c) -> toText c) `fmap` cvc')
                  ]

------------------------------------------------------------------------------
-- | Retrieve a `Charge` by `ChargeId`
getCharge
    :: ChargeId -- ^ The `Charge` to retrive
    -> Stripe Charge
getCharge chargeid = getChargeExpandable chargeid []

------------------------------------------------------------------------------
-- | Retrieve a `Charge` by `ChargeId` with `ExpandParams`
getChargeExpandable
    :: ChargeId     -- ^ The `Charge` retrive
    -> ExpandParams -- ^ The `ExpandParams` to retrive
    -> Stripe Charge
getChargeExpandable
    chargeid
    expandParams = callAPI request
  where request = StripeRequest GET url params
        url     = "charges" </> getChargeId chargeid
        params  = toExpandable expandParams

------------------------------------------------------------------------------
-- | Retrieve all `Charge`s
getCharges
    :: Limit                    -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter ChargeId   -- ^ Paginate starting after the following CustomerID
    -> EndingBefore ChargeId    -- ^ Paginate ending before the following CustomerID
    -> Stripe (StripeList Charge)
getCharges
    limit
    startingAfter
    endingBefore =
      getChargesExpandable limit startingAfter endingBefore []

------------------------------------------------------------------------------
-- | Retrieve all `Charge`s
getChargesExpandable
    :: Limit                    -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter ChargeId   -- ^ Paginate starting after the following CustomerID
    -> EndingBefore ChargeId    -- ^ Paginate ending before the following CustomerID
    -> ExpandParams             -- ^ Get Charges with `ExpandParams`
    -> Stripe (StripeList Charge)
getChargesExpandable
    limit
    startingAfter
    endingBefore
    expandParams = callAPI request
  where request = StripeRequest GET url params
        url     = "charges"
        params  = getParams [
            ("limit", toText `fmap` limit )
          , ("starting_after", (\(ChargeId x) -> x) `fmap` startingAfter)
          , ("ending_before", (\(ChargeId x) -> x) `fmap` endingBefore)
          ] ++ toExpandable expandParams


------------------------------------------------------------------------------
-- | Retrieve all `Charge`s for a specified `Customer`
getCustomerCharges
    :: CustomerId
    -> Limit                    -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter ChargeId   -- ^ Paginate starting after the following CustomerID
    -> EndingBefore ChargeId    -- ^ Paginate ending before the following CustomerID
    -> Stripe (StripeList Charge)
getCustomerCharges
    customerid
    limit
    startingAfter
    endingBefore =
      getCustomerChargesExpandable customerid limit
        startingAfter endingBefore []

------------------------------------------------------------------------------
-- | Retrieve all `Charge`s for a specified `Customer` with `ExpandParams`
getCustomerChargesExpandable
    :: CustomerId
    -> Limit                    -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter ChargeId   -- ^ Paginate starting after the following CustomerID
    -> EndingBefore ChargeId    -- ^ Paginate ending before the following CustomerID
    -> ExpandParams             -- ^ Get `Customer` `Charge`s with `ExpandParams`
    -> Stripe (StripeList Charge)
getCustomerChargesExpandable
    customerid
    limit
    startingAfter
    endingBefore
    expandParams = callAPI request
  where request = StripeRequest GET url params
        url     = "charges"
        params  = getParams [
            ("customer", Just $ getCustomerId customerid )
          , ("limit", toText `fmap` limit )
          , ("starting_after", (\(ChargeId x) -> x) `fmap` startingAfter)
          , ("ending_before", (\(ChargeId x) -> x) `fmap` endingBefore)
          ] ++ toExpandable expandParams

------------------------------------------------------------------------------
-- | A `Charge` to be updated
updateCharge
    :: ChargeId    -- ^ The `Charge` to update
    -> Description -- ^ The `Charge` Description to update
    -> MetaData    -- ^ The `Charge` Description to update
    -> Stripe Charge
updateCharge
    chargeid
    description
    metadata    = callAPI request
  where request = StripeRequest POST url params
        url     = "charges" </> getChargeId chargeid
        params  = toMetaData metadata ++ getParams [
                   ("description", Just description)
                  ]

------------------------------------------------------------------------------
-- | a `Charge` to be captured
captureCharge
    :: ChargeId           -- ^ The Charge to capture
    -> Maybe Amount       -- ^ If Nothing the entire charge will be captured, otherwise the remaining will be refunded
    -> Maybe Email -- ^ Email address to send this charge's receipt to
    -> Stripe Charge
captureCharge
    chargeid
    amount
    receiptEmail = callAPI request
  where request  = StripeRequest POST url params
        url      = "charges" </> getChargeId chargeid </> "capture"
        params   = getParams [
                     ("amount", toText `fmap` amount)
                   , ("receipt_email", (\(Email email) -> email) `fmap` receiptEmail)
                   ]
