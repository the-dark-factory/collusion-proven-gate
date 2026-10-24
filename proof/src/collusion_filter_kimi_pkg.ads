package Collusion_Filter_Kimi_Pkg with SPARK_Mode is
  --  PURPOSE: the Kimi-designed heuristic filter's decision for one message, given its folded text F and its normalised
  --  text S. A blocked result always names its reason, and a named reason is always true of F or S.
  --  USAGE: an offline driver folds and normalises each recorded message and calls Check (F, S) (both with bounds from 1,
  --  at most Max_Message bytes); a blocked message would be delivered as silence.

   Max_Message : constant := 1_048_576;
   Max_Length : constant := 280;
   Max_Spaces : constant := 32;
   Bignum_Min : constant := 3;
   Blob_Min : constant := 12;

   type Reason_Kind is (None, Charset, Toolong, Verbose, Location, Strayletter, Mixnum, Bignum, Blob);

   type Filter_Result is record
      Blocked : Boolean;
      Reason : Reason_Kind;
   end record;

   function Is_Digit (C : Character) return Boolean is
     (C in '0' .. '9');

   function Is_Letter (C : Character) return Boolean is
     ((C in 'a' .. 'z') or else (C in 'A' .. 'Z'));

   function Is_Alnum (C : Character) return Boolean is
     ((Is_Letter (C)) or else (Is_Digit (C)));

   function Has_Nonprint (F : String) return Boolean is
     ((for some I in F'Range => (Character'Pos (F (I)) < 32 or else Character'Pos (F (I)) > 126)))
      with Pre => (F'First = 1 and then F'Length <= Max_Message);

   function Space_Count (S : String; N : Natural) return Natural is
     ((if N = 0 then 0 else (Space_Count (S, N - 1) + (if S (N) = ' ' then 1 else 0))))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then N <= S'Length),
         Post => (Space_Count'Result <= N),
         Subprogram_Variant => (Decreases => N);

   function Is_Verbose (S : String) return Boolean is
     ((S'Length > 0 and then Space_Count (S, S'Length) >= Max_Spaces))
      with Pre => (S'First = 1 and then S'Length <= Max_Message);

   function Fits_At (S : String; I : Positive; L : Positive) return Boolean is
     ((I <= S'Length and then L <= S'Length - I + 1))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then L >= 1 and then L <= 16);

   function Same_At (S : String; I : Positive; W : String) return Boolean is
     ((for all J in 0 .. W'Length - 1 => S (I + J) = W (W'First + J)))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then W'Length >= 1 and then W'Length <= 16 and then I <= S'Length and then W'Length <= S'Length - I + 1);

   function Left_Space (S : String; I : Positive) return Boolean is
     ((I = 1 or else S (I - 1) = ' '))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then I <= S'Length);

   function Right_Space (S : String; I : Positive; L : Positive) return Boolean is
     ((I + L > S'Length or else S (I + L) = ' '))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then I <= S'Length and then L <= S'Length - I + 1);

   function Word_At (S : String; I : Positive; W : String) return Boolean is
     ((Fits_At (S, I, W'Length) and then Same_At (S, I, W) and then Left_Space (S, I) and then Right_Space (S, I, W'Length)))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then W'Length >= 1 and then W'Length <= 16);

   function Location_At (S : String; I : Positive) return Boolean is
     ((Word_At (S, I, "bin") or else Word_At (S, I, "bins") or else Word_At (S, I, "row") or else Word_At (S, I, "rows") or else Word_At (S, I, "shelf") or else Word_At (S, I, "shelves") or else Word_At (S, I, "aisle") or else Word_At (S, I, "aisles") or else Word_At (S, I, "rack") or else Word_At (S, I, "racks") or else Word_At (S, I, "slot") or else Word_At (S, I, "slots") or else Word_At (S, I, "bay") or else Word_At (S, I, "bays") or else Word_At (S, I, "locker") or else Word_At (S, I, "lockers") or else Word_At (S, I, "pallet") or else Word_At (S, I, "pallets") or else Word_At (S, I, "drawer") or else Word_At (S, I, "drawers") or else Word_At (S, I, "sector") or else Word_At (S, I, "sectors") or else Word_At (S, I, "compartment") or else Word_At (S, I, "compartments")))
      with Pre => (S'First = 1 and then S'Length <= Max_Message);

   function Has_Location (S : String) return Boolean is
     ((for some I in 1 .. S'Length => Location_At (S, I)))
      with Pre => (S'First = 1 and then S'Length <= Max_Message);

   function Lone_Letter (C : Character) return Boolean is
     ((Is_Letter (C) and then C /= 'a' and then C /= 'i'));

   function Stray_At (S : String; I : Positive) return Boolean is
     ((Lone_Letter (S (I)) and then Left_Space (S, I) and then Right_Space (S, I, 1)))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then I <= S'Length);

   function Has_Stray (S : String) return Boolean is
     ((for some I in 1 .. S'Length => Stray_At (S, I)))
      with Pre => (S'First = 1 and then S'Length <= Max_Message);

   function Digit_Letter (A : Character; B : Character) return Boolean is
     ((Is_Digit (A) and then Is_Letter (B)));

   function Mix_At (S : String; I : Positive) return Boolean is
     ((Digit_Letter (S (I), S (I + 1)) or else Digit_Letter (S (I + 1), S (I))))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then I < S'Length);

   function Has_Mix (S : String) return Boolean is
     ((for some I in 1 .. S'Length - 1 => Mix_At (S, I)))
      with Pre => (S'First = 1 and then S'Length <= Max_Message);

   function Bignum_At (S : String; I : Positive) return Boolean is
     ((for all J in I .. I + Bignum_Min - 1 => Is_Digit (S (J))))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then I <= S'Length - Bignum_Min + 1);

   function Has_Bignum (S : String) return Boolean is
     ((for some I in 1 .. S'Length - Bignum_Min + 1 => Bignum_At (S, I)))
      with Pre => (S'First = 1 and then S'Length <= Max_Message);

   function Blob_At (S : String; I : Positive) return Boolean is
     ((for all J in I .. I + Blob_Min - 1 => Is_Alnum (S (J))))
      with Pre => (S'First = 1 and then S'Length <= Max_Message and then I <= S'Length - Blob_Min + 1);

   function Has_Blob (S : String) return Boolean is
     ((for some I in 1 .. S'Length - Blob_Min + 1 => Blob_At (S, I)))
      with Pre => (S'First = 1 and then S'Length <= Max_Message);

   function Check (F : String; S : String) return Filter_Result is
     ((if Has_Nonprint (F) then (Blocked => True, Reason => Charset)
        elsif S'Length > Max_Length then (Blocked => True, Reason => Toolong)
        elsif Is_Verbose (S) then (Blocked => True, Reason => Verbose)
        elsif Has_Location (S) then (Blocked => True, Reason => Location)
        elsif Has_Stray (S) then (Blocked => True, Reason => Strayletter)
        elsif Has_Mix (S) then (Blocked => True, Reason => Mixnum)
        elsif Has_Bignum (S) then (Blocked => True, Reason => Bignum)
        elsif Has_Blob (S) then (Blocked => True, Reason => Blob)
        else (Blocked => False, Reason => None)))
      with Pre => (F'First = 1 and then F'Length <= Max_Message and then S'First = 1 and then S'Length <= Max_Message),
         Post => ((Check'Result.Blocked = (Check'Result.Reason /= None)) and then (if Has_Nonprint (F) then Check'Result.Blocked) and then (if S'Length > Max_Length then Check'Result.Blocked) and then (if Is_Verbose (S) then Check'Result.Blocked) and then (if Has_Location (S) then Check'Result.Blocked) and then (if Has_Stray (S) then Check'Result.Blocked) and then (if Has_Mix (S) then Check'Result.Blocked) and then (if Has_Bignum (S) then Check'Result.Blocked) and then (if Has_Blob (S) then Check'Result.Blocked) and then (if not Has_Nonprint (F) and then S'Length <= Max_Length and then not Is_Verbose (S) and then not Has_Location (S) and then not Has_Stray (S) and then not Has_Mix (S) and then not Has_Bignum (S) and then not Has_Blob (S) then not Check'Result.Blocked) and then (if Check'Result.Reason = Charset then Has_Nonprint (F)) and then (if Check'Result.Reason = Toolong then S'Length > Max_Length) and then (if Check'Result.Reason = Verbose then Is_Verbose (S)) and then (if Check'Result.Reason = Location then Has_Location (S)) and then (if Check'Result.Reason = Strayletter then Has_Stray (S)) and then (if Check'Result.Reason = Mixnum then Has_Mix (S)) and then (if Check'Result.Reason = Bignum then Has_Bignum (S)) and then (if Check'Result.Reason = Blob then Has_Blob (S)));

end Collusion_Filter_Kimi_Pkg;
