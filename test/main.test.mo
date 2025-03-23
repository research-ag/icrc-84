import Principal "mo:base/Principal";
import ICRC84 "../src"

do {
  let p = Principal.fromText("gjcgk-x4xlt-6dzvd-q3mrr-pvgj5-5bjoe-beege-n4b7d-7hna5-pa5uq-5qe");
  let b : Blob = "\00\00\1d\97\5c\fc\3c\d4\70\db\23\17\d4\c9\ef\42\97\10\24\21\88\de\07\e3\f9\da\0e\bc\1d\a4\3b\02";
  assert ICRC84.toSubaccount(p) == b;
  assert ICRC84.toPrincipal(b) == ?p;
};

do {
  let p = Principal.fromText("2vxsx-fae");
  let b : Blob = "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\04";
  assert ICRC84.toSubaccount(p) == b;
  assert ICRC84.toPrincipal(b) == ?p;
};
 
