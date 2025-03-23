[![mops](https://oknww-riaaa-aaaam-qaf6a-cai.raw.ic0.app/badge/mops/icrc-84)](https://mops.one/icrc-84)
[![documentation](https://oknww-riaaa-aaaam-qaf6a-cai.raw.ic0.app/badge/documentation/icrc-84)](https://mops.one/icrc-84/docs)

# ICRC-84

ICRC standard for deposits and withdrawals from financial services

## Standard Spec

The specification can be found [here](icrc-84.md)

## Implementation

The module currently only contains the conversion functions to embed a Principal to and from an ICRC-1 subaccount (32 bytes).

The functions are:

* `toSubaccount : Principal -> Subaccount`
* `toPrincipal : Subaccount -> ?Principal`

