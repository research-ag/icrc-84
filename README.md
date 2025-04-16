[![mops](https://oknww-riaaa-aaaam-qaf6a-cai.raw.ic0.app/badge/mops/icrc-84)](https://mops.one/icrc-84)
[![documentation](https://oknww-riaaa-aaaam-qaf6a-cai.raw.ic0.app/badge/documentation/icrc-84)](https://mops.one/icrc-84/docs)

# ICRC-84

ICRC standard for deposits and withdrawals from financial services

## Standard Spec

The specification can be found [here](icrc-84.md)

## Implementation

The module currently contains:

### Conversion functions

The functions to embed a Principal to and from an ICRC-1 subaccount (32 bytes) are:

* `toSubaccount : Principal -> Subaccount`
* `toPrincipal : Subaccount -> ?Principal`

### Argument and return types

* `TokenInfo`
* `NotifyArgs` and `NotifyResponse`
* `DepositArgs` and `DepositResponse`
* `WithdrawArgs` and `WithdrawResponse`

### ICRC84 actor type definition

The type `ICRC84` can be used as actor type on the caller side effortlessly.

To declare actor type with ICRC84 and custom functions, you can use:

```motoko
  let canister : (ICRC84.ICRC84 and actor {
    custom_func : shared () -> async ();
  }) = actor (icrc84CanisterId);
```