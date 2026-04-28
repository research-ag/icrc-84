/// ICRC-84 type definitions and helper utilities.
///
/// ICRC-84 is the deposit/withdrawal standard for ICRC-1/2 tokens used by
/// financial-service canisters (e.g. DEXes). This module re-exports the
/// Motoko-typed view of the standard's Candid interface as the actor type
/// `ICRC84`.  It also provides two helpers, `toSubaccount` and `toPrincipal`,
/// that implement the deposit-account derivation prescribed by the standard.
///
/// See the standard's prose specification (icrc-84.md) for the semantic
/// contract of every method and field referenced here.
///
/// ```motoko name=import
/// import ICRC84 "mo:icrc-84";
/// ```

import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Nat8 "mo:core/Nat8";
import Principal "mo:core/Principal";

module {
  type Subaccount = Blob;

  /// Converts `Principal` to ICRC-1 `Subaccount`.
  ///
  /// The principal's Blob representation is up to 29 bytes long.
  /// It is placed right-aligned into the 32 bytes of the Subaccount,
  /// prepended with a length byte and then left-padded with zero bytes.
  ///
  /// The result is the deposit-account subaccount of the user identified
  /// by `p`, as defined in the "Deposit accounts" section of the ICRC-84
  /// standard. The returned `Blob` is always exactly 32 bytes long.
  ///
  /// Traps if the Blob representation of `p` is longer than 29 bytes.
  /// All valid IC principals satisfy this bound.
  public func toSubaccount(p : Principal) : Subaccount {
    let bytes = Blob.toArray(p.toBlob());
    let size = bytes.size();

    assert size <= 29;

    Array.tabulate<Nat8>(
      32,
      func(i : Nat) : Nat8 {
        if (i + size < 31) {
          0;
        } else if (i + size == 31) {
          Nat8.fromNat(size);
        } else {
          bytes[i + size - 32];
        };
      },
    ) |> Blob.fromArray(_);
  };

  /// Converts the ICRC-1 `Subaccount` back to `Principal`.
  ///
  /// This is the inverse of `toSubaccount`. It expects a 32-byte blob
  /// whose layout is: a run of zero bytes, a length byte
  /// `n` with `1 <= n <= 29`, followed by exactly `n` bytes of principal
  /// payload that fills the remainder of the 32-byte blob.
  ///
  /// Returns `?Principal` reconstructed from the embedded payload, or
  /// `null` when the blob does not match the expected layout (i.e. it is
  /// all zeros, or the length byte is inconsistent with the position of
  /// the payload).
  ///
  /// Traps if `subaccount` is not exactly 32 bytes long.
  public func toPrincipal(subaccount : Subaccount) : ?Principal {
    let bytes = Blob.toArray(subaccount);
    assert bytes.size() == 32;

    let (start, size) = do {
      var i = 0;
      label L while (i < 32) {
        if (bytes[i] != 0) break L;
        i += 1;
      };
      if (i == 32) return null;
      (i + 1, bytes[i].toNat());
    };

    if (start + size != 32) return null;
    Array.tabulate(size, func(i : Nat) : Nat8 = bytes[start + i])
    |> Blob.fromArray(_)
    |> ?Principal.fromBlob(_);
  };

  /// Per-token configuration parameters returned by `icrc84_token_info`.
  ///
  /// All amounts are in the smallest unit of the corresponding ICRC-1
  /// token (the same unit as the ledger's `Balance`/`Amount`).
  ///
  /// - `allowance_fee`: fee charged by the service for each successful
  ///   deposit made via ICRC-2 allowance (`icrc84_deposit`).
  /// - `deposit_fee`: fee charged by the service for each consolidation
  ///   of funds from a user's deposit account into the service's main
  ///   account (i.e. for each "batch" of direct transfers detected via
  ///   `icrc84_notify`).
  /// - `withdrawal_fee`: fee charged by the service for each successful
  ///   withdrawal triggered via `icrc84_withdraw`.
  ///
  /// These fees may, but need not, equal the underlying ICRC-1 ledger
  /// transfer fee. They may change over time.
  public type TokenInfo = {
    allowance_fee : Nat;
    deposit_fee : Nat;
    withdrawal_fee : Nat;
  };

  /// Argument record of `icrc84_notify`.
  ///
  /// `token` is the ICRC-1 ledger principal identifying which token's
  /// deposit account of the caller should be inspected for new deposits.
  public type NotifyArgs = { token : Principal };

  /// Result of `icrc84_notify`.
  ///
  /// On success (`#Ok`):
  /// - `deposit_inc`: incremental deposit amount detected since the last
  ///   known tracked deposit balance. Zero if no new deposit was found.
  /// - `credit_inc`: incremental credit applied to the caller as a result
  ///   of this call. May be smaller than `deposit_inc` because of
  ///   `deposit_fee`, but does not have to be.
  /// - `credit`: absolute credit balance of the caller for `token` after
  ///   the new deposit (if any) has been credited.
  ///
  /// On failure (`#Err`):
  /// - `#CallLedgerError`: the downstream call to the ICRC-1 ledger
  ///   failed; `message` describes the underlying async error.
  /// - `#NotAvailable`: `notify` is currently blocked for this caller and
  ///   token (typically because a concurrent `notify` for the same pair
  ///   is in flight). The caller should retry later.
  ///
  /// Note: a call to `icrc84_notify` for an unsupported token does not
  /// surface here; the service rejects the call with the async error
  /// `canister_reject` and message `"UnknownToken"`.
  public type NotifyResponse = {
    #Ok : {
      deposit_inc : Nat;
      credit_inc : Nat;
      credit : Int;
    };
    #Err : {
      #CallLedgerError : { message : Text };
      #NotAvailable : { message : Text };
    };
  };

  /// Argument record of `icrc84_deposit` (allowance-based deposit).
  ///
  /// - `token`: ICRC-1 ledger principal of the token being deposited.
  /// - `amount`: amount to draw from the allowance into the service.
  ///   Any underlying ledger transfer fee is charged on top, on the
  ///   `from` account's side.
  /// - `from`: ICRC-1 account from which the funds are drawn. The spender of
  ///   the allowance must be the service canister's account with
  ///   subaccount `toSubaccount(caller)`
  /// - `expected_fee`: must equal the current `allowance_fee` from the
  ///   token's `TokenInfo`; otherwise the call returns
  ///   `#Err(#BadFee)`. Pass `null` to skip the check.
  public type DepositArgs = {
    token : Principal;
    amount : Nat;
    from : { owner : Principal; subaccount : ?Blob };
    expected_fee : ?Nat;
  };

  /// Result of `icrc84_deposit` (allowance-based deposit).
  ///
  /// On success (`#Ok`):
  /// - `txid`: transaction id on the underlying ICRC-1 ledger of the
  ///   transfer that drew the funds.
  /// - `credit_inc`: incremental credit applied to the caller as a
  ///   result of this call.
  /// - `credit`: absolute credit balance after `credit_inc` has been
  ///   applied.
  ///
  /// On failure (`#Err`):
  /// - `#AmountBelowMinimum`: `amount` is not strictly greater than the
  ///   sum of fees that would be deducted.
  /// - `#CallLedgerError`: the inter-canister call to the ICRC-2 ledger
  ///   failed entirely (e.g. the ledger does not support ICRC-2, or the
  ///   call trapped); `message` describes the async error.
  /// - `#TransferError`: the call went through but the ICRC-2
  ///   `transfer_from` was rejected (e.g. insufficient allowance or
  ///   insufficient funds); `message` describes the ledger error.
  /// - `#BadFee`: the supplied `expected_fee` does not match the actual
  ///   `allowance_fee`; the current value is returned in `expected_fee`.
  public type DepositResponse = {
    #Ok : { txid : Nat; credit_inc : Nat; credit : Int };
    #Err : {
      #AmountBelowMinimum : {};
      #CallLedgerError : { message : Text };
      #TransferError : { message : Text };
      #BadFee : { expected_fee : Nat };
    };
  };

  /// Argument record of `icrc84_withdraw`.
  ///
  /// - `to`: destination ICRC-1 account that receives the transfer. The
  ///   `subaccount`, if present, must be exactly 32 bytes long;
  ///   otherwise the service rejects the call with the async error
  ///   `canister_reject` and message `"InvalidSubaccount"`.
  /// - `amount`: amount to deduct from the caller's credit balance for
  ///   `token`. The amount actually received by `to` will be smaller by
  ///   the withdrawal fee.
  /// - `token`: ICRC-1 ledger principal of the token to withdraw.
  /// - `expected_fee`: must equal the current `withdrawal_fee` from the
  ///   token's `TokenInfo`; otherwise the call returns
  ///   `#Err(#BadFee)`. Pass `null` to skip the check.
  public type WithdrawArgs = {
    to : { owner : Principal; subaccount : ?Blob };
    amount : Nat;
    token : Principal;
    expected_fee : ?Nat;
  };

  /// Result of `icrc84_withdraw`.
  ///
  /// On success (`#Ok`):
  /// - `txid`: transaction id on the underlying ICRC-1 ledger of the
  ///   withdrawal transfer.
  /// - `amount`: amount actually received by the destination account.
  ///   This is generally less than the requested `amount` because the
  ///   `withdrawal_fee` has been deducted.
  ///
  /// On failure (`#Err`):
  /// - `#BadFee`: the supplied `expected_fee` does not match the actual
  ///   `withdrawal_fee`; the current value is returned in `expected_fee`.
  /// - `#CallLedgerError`: the downstream call to the ICRC-1 ledger
  ///   failed with an async error; `message` describes it.
  /// - `#InsufficientCredit`: the caller's credit balance for `token` is
  ///   below the requested `amount`.
  /// - `#AmountBelowMinimum`: the requested `amount` is not strictly
  ///   greater than the sum of fees that would be deducted.
  public type WithdrawResponse = {
    #Ok : {
      txid : Nat;
      amount : Nat;
    };
    #Err : {
      #BadFee : { expected_fee : Nat };
      #CallLedgerError : { message : Text };
      #InsufficientCredit : {};
      #AmountBelowMinimum : {};
    };
  };

  /// Motoko actor interface of an ICRC-84 service.
  ///
  /// This mirrors the Candid interface declared in `icrc-84.did` and lets
  /// client canisters statically type calls to a service. The full
  /// semantic contract of each method (preconditions, idempotency,
  /// concurrency behaviour, async-error messages such as `"UnknownToken"`
  /// and `"InvalidSubaccount"`) is specified in the ICRC-84 standard
  /// document and is not repeated on the individual fields below.
  ///
  /// The member functions fall into the following categories:
  ///
  /// Public queries:
  /// - `icrc84_supported_tokens`
  /// - `icrc84_token_info`
  ///
  /// Private queries (caller is identified and used implicitly):
  /// - `icrc84_query`
  ///
  /// Update calls:
  /// - `icrc84_notify`
  /// - `icrc84_deposit`
  /// - `icrc84_withdraw`
  public type ICRC84 = actor {
    /// Returns the list of ICRC-1 ledger principals supported by the
    /// service. Public query.
    icrc84_supported_tokens : shared query () -> async [Principal];

    /// Returns the per-token configuration (`TokenInfo`) for the given
    /// token. Public query. Throws `canister_reject` with message
    /// `"UnknownToken"` if `token` is not supported.
    icrc84_token_info : shared query (Principal) -> async TokenInfo;

    /// Returns the caller's credit balance and tracked deposit balance
    /// for each requested token. An empty argument vector means "all
    /// supported tokens". The result preserves the relationship between
    /// each requested token and its `(credit, tracked_deposit)` pair.
    /// `tracked_deposit = null` indicates that a concurrent downstream
    /// call would make the value unreliable; the caller should retry.
    /// Throws `canister_reject` with message `"UnknownToken"` if any
    /// requested token is not supported. Private query (returns the
    /// caller's data).
    icrc84_query : shared query ([Principal]) -> async ([(
      Principal,
      {
        credit : Int;
        tracked_deposit : ?Nat;
      },
    )]);

    /// Notifies the service about a direct deposit into the caller's
    /// deposit account for `args.token`. Triggers a downstream balance
    /// query on the ICRC-1 ledger. See `NotifyResponse` for outcomes.
    icrc84_notify : shared (NotifyArgs) -> async NotifyResponse;

    /// Performs an allowance-based deposit (ICRC-2 `transfer_from`) into
    /// the service on behalf of the caller. See `DepositArgs` and
    /// `DepositResponse` for argument and outcome details.
    icrc84_deposit : shared (DepositArgs) -> async DepositResponse;

    /// Withdraws the requested `amount` of `token` from the caller's
    /// credit balance to the destination account `to`. See `WithdrawArgs`
    /// and `WithdrawResponse` for argument and outcome details.
    icrc84_withdraw : shared (WithdrawArgs) -> async WithdrawResponse;
  };

};
