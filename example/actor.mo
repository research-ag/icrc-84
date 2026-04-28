import Runtime "mo:core/Runtime";

import Lib "../src";

// an actor file to test library ICRC84 against did declaration.
// if it implements something differently from library type, it won't compile with an error about "_check" variable type
// if it implements something differently from did file, github action would fail since produced did file won't match the original one
persistent actor class Actor() = self {

  transient let _check : Lib.ICRC84 = self;

  public shared query func icrc84_supported_tokens() : async [Principal] = async [];

  public shared query func icrc84_token_info(_ : Principal) : async Lib.TokenInfo {
    Runtime.trap("STUB");
  };

  public shared query func icrc84_query(_ : [Principal]) : async [(
    Principal,
    {
      credit : Int;
      tracked_deposit : ?Nat;
    },
  )] = async [];

  public shared func icrc84_notify(_ : { token : Principal }) : async Lib.NotifyResponse {
    Runtime.trap("STUB");
  };

  public shared func icrc84_deposit(_ : Lib.DepositArgs) : async Lib.DepositResponse {
    Runtime.trap("STUB");
  };

  public shared func icrc84_withdraw(_ : Lib.WithdrawArgs) : async Lib.WithdrawResponse {
    Runtime.trap("STUB");
  };
};
