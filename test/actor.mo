import Prim "mo:prim";

import Lib "../src";

// an actor file to test library ICRC84 against did declaration.
// if it implements something differently from library type, it won't compile with an error about "_check" variable type
// if it implements something differently from did file, github action would fail since produced did file won't match the original one
actor class Actor() = self {

  let _check : Lib.ICRC84 = self;

  public shared query func icrc84_supported_tokens() : async [Principal] = async [];

  public shared query func icrc84_token_info(_ : Principal) : async Lib.TokenInfo {
    Prim.trap("STUB");
  };

  public shared query func icrc84_query(_ : [Principal]) : async [(
    Principal,
    {
      credit : Int;
      tracked_deposit : ?Nat;
    },
  )] = async [];

  public shared func icrc84_notify(_ : { token : Principal }) : async Lib.NotifyResponse {
    Prim.trap("STUB");
  };

  public shared func icrc84_deposit(_ : Lib.DepositArgs) : async Lib.DepositResponse {
    Prim.trap("STUB");
  };

  public shared func icrc84_withdraw(_ : Lib.WithdrawArgs) : async Lib.WithdrawResponse {
    Prim.trap("STUB");
  };
};
