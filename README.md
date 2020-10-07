# GrowthDeFi V1 Core

This repository contains the source code for the GrowthDeFi smart contracts
(Version 1) and related support code for testing and monitoring the contracts.

## Repository Organization

* [/contracts/](contracts). This folder is where the smart contract source code
  resides.
* [/docker/](docker). This folder contains docker and/or docker-compose files
  that help setting up and running a ganache-cli service for testing and
  development.
* [/migrations/](migrations). This folder hosts the relevant set of Truffle
  migration scripts used to publish the smart contracts to the blockchain.
* [/stress-test/](stress-test). This folder contains code to assist in stress
  testing the core contract functionality by performing a sequence of random
  operations.
* [/telegram-bot/](telegram-bot). This folder contains code to assist in
  monitoring the smart contract health/vitals in real time via Telegram
  notifications.
* [/test/](test). This folder contains a set of relevant unit tests for Truffle
  written in Solidity.

## Source Code

The smart contracts are written in Solidity and the source code is organized in
the following folder structure:

* [/contracts/](contracts). This folder has the core functionality with the main
  contract hierarchy and supporting functionality. This is further described
  in detail below.
* [/contracts/interop/](contracts/interop). This folder contains the minimal
  interoperability interfaces to other services such as Aave, Compound, Curve,
  DyDx, etc.
* [/contracts/modules/](contracts/modules). This folder contains a set of
  libraries organized as modules each abstracting a specific functionality.
  These are compile-time libraries with internal functions, they do not serve
  the purpose of organizing the code into runtime (public) libraries. As
  Solidity libraries usually work, the code is assumed to execute via delegate
  calls in the context of the caller contract. _Some of the provided functionaly
  may not be currently used but is kept as part of the code base as it was
  useful in the past and may be useful in the future._
* [/contracts/network/](contracts/network). In this folder we have a simple
  and helpful library to declare static properties such as the current network
  (mainnet, ropsten, etc), well-known useful contract addresses for each
  supported network, as well as some global definitions that are handy for
  debugging during development.

The [/contracts/](contracts) folder contains basically 10 groups of files as
presented below. Their actual functionality is described in the next section.

* *Interface files*, such as [GToken.sol](contracts/GToken.sol),
  [GCToken.sol](contracts/GCToken.sol), and
  [GExchange.sol](contracts/GExchange.sol) that describe the available public
  interface to the smart contracts.
  [GToken.sol](contracts/GToken.sol) is the general interface for the GrowthDeFi
  V1 tokens (refered to as gTokens) and [GCToken.sol](contracts/GCToken.sol) is
  an extension of that interface to decribe the GrowthDeFi V1 tokens based on
  Compound cTokens (and refered to as gcTokens).
  [GExchange.sol](contracts/GExchange.sol) is a simple interface for an external
  contract specialized in token conversion, which allows for the replacement
  and customization of the conversion service provider used by gTokens at any
  given point in time.
* *Abstract contract files* that provide the basis implementation of shared
  functionality for their respective interface. These are basically
  [GTokenBase.sol](contracts/GTokenBase.sol) for gTokens and
  [GCTokenBase.sol](contracts/GCTokenBase.sol) for gcTokens.
  Note that gTokens extend the ERC-20 specification and we use the
  [OpenZeppelin](https://openzeppelin.com/) library as basis for their
  implementation. Besides the ERC-20 related functionality we also make use
  of OpenZeppelin's Ownable to guard admin-only public functions and
  ReentrancyGuard to conservatively guard all public functions against reentrancy.
* *Concrete contract files* that derive from the abstract contract files by
  filling in the specific details purposedly left open. These provide the
  final/leaf contracts in the gTokens hierarchy. At the moment these comprise
  the two types of gcTokens implementated in two flavors, Type 1 gcTokens
  [GCTokenType1.sol](contracts/GCTokenType1.sol) and Type 2 gcTokens
  [GCTokenType2.sol](contracts/GCTokenType2.sol). _Note that the Type 2 is
  currently under development and should not yet be regarded as final._
* *Component contract (public) libraries* that provide core functionality
  implementation. Besides properly encapsulating the functionality they also
  allow working around the contract size limitations of the EVM.
  These are [GLiquidityPoolManager.sol](contracts/GLiquidityPoolManager.sol)
  for liquidity pool management/handling;
  [GCLeveragedReserveManager.sol](contracts/GCLeveragedReserveManager.sol) for
  leveraged reserve management/handling where flash loans are used to maintain
  the desired leverage level over lending/borrowing of the reserve of cTokens
  (used by Type 1 gcTokens);
  [GCDelegatedReserveManager.sol](contracts/GCDelegatedReserveManager.sol) for
  delegated reserve management/handling where borrowing is employed to mint
  Type 1 gcTokens that are used to maintain and grow the cToken reserve
  (used by Type 2 gcTokens);
* *A single entrypoint file* [GTokens.sol](contracts/GTokens.sol) that succinctly declares
  all the available gTokens: gcDAI, gcUSDC, gcUSDT (of Type 1) and gcETH,
  gcWBTC, gcBAT, gcZRX and gcUNI (of Type 2). _Note that the Type 2 is
  currently under development and should not yet be regarded as final._
* *A public library* [G.sol](contracts/G.sol) that compiles and serve as
  entrypoint to all the relevant functions available under the
  [modules](contracts/modules) folder. This library exists mostly to work
  around the EVM limitation of contract sizes, but it also provide a concise
  standardized and neat reference to library code.
* *Two handy libraries* that hoist gToken and gcToken minting/burning
  calculations, [GFormulae](contracts/GFormulae.sol) and
  [GCFormulae](contracts/GCFormulae.sol) respectively. These provide a set of
  pure (in the Solidity sense) functions.
* *A contract that helps abstract FlashLoans callbacks*
  [GFlashBorrower.sol](contracts/GFlashBorrower.sol) for both Aave and DyDx.
  This class is used by Type 1 tokens to perform flash loans and efficiently
  maintain the desired leverage level.
* *Two, and possibly more, exchange implementations* deriving from
  [GExchange.sol](contracts/GExchange.sol) to handle token conversion,
  such as [GUniswapV2Exchange.sol](contracts/GUniswapV2Exchange.sol),
  [GSushiswapExchange.sol](contracts/GSushiswapExchange.sol). _Possibly more
  providers or more sophisticated routing maybe be added on the future._
* *The reference implementation of the GRO token* is available on
  [GrowthToken.sol](contracts/GrowthToken.sol).

## High-Level Smart Contract Functionality

## Building and Testing

