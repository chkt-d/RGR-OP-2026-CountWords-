UNIT DataTypes;

INTERFACE

TYPE
  StrPtr = ^StrNode;
  StrNode = RECORD
    Ch: CHAR;
    Next: StrPtr
  END;

TYPE
  WordPtr = ^WordNode;
  WordNode = RECORD
    Word: StrPtr;
    Count: INTEGER;
    Next: WordPtr
  END;

END.
