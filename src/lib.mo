import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";

module {
  type Subaccount = Blob;

  /// Converts `Principal` to ICRC-1 `Subaccount`.
  ///
  /// The principal's Blob representation is up to 29 bytes long.
  /// It is placed right-aligned into the 32 bytes of the Subaccount,
  /// prepended with a length byte and then left-padded with zero bytes.
  public func toSubaccount(p : Principal) : Subaccount {
    let bytes = Blob.toArray(Principal.toBlob(p));
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

  /// Converts the ICRC1 `Subaccount` back to `Principal`.
  ///
  /// The conversion can fail when the format is not as expected.
  /// In this case `null` is returned.
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
      (i + 1, Nat8.toNat(bytes[i]));
    };

    if (start + size != 32) return null;
    Array.tabulate(size, func(i : Nat) : Nat8 = bytes[start + i])
    |> Blob.fromArray(_)
    |> ?Principal.fromBlob(_);
  };
};
