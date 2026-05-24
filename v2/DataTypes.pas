UNIT DataTypes;

INTERFACE

USES WordUtils, Config;

TYPE
  TreePtr = ^TreeNode;

  TreeNode = RECORD
    Word: StrPtr;
    Count: LONGINT;
    Right: TreePtr;
    Left: TreePtr;
    Height: INTEGER
  END;

  StatsType = RECORD
    Root: TreePtr;
    NodeCount: LONGINT;
  END;

  BinWord = RECORD
              Len: INTEGER;
              Chars: ARRAY [1..MaxBinWordLen] OF CHAR;
              Count: LONGINT
            END;

  BinStatsFile = FILE OF BinWord;

END.
