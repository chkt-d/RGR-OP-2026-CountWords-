UNIT StatsTree;

INTERFACE

USES WordUtils;

CONST
  MaxTreeNodes = 1000;
  MaxBinWordLen = 255;
  
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
  
PROCEDURE LoadBinaryToStats(VAR TempFile: BinStatsFile; VAR Stats: StatsType);
PROCEDURE InitStats(VAR Stats: StatsType); 
PROCEDURE UpdateStats(VAR Stats: StatsType; Word: StrPtr); 
PROCEDURE DisposeStats(VAR Stats: StatsType); 
PROCEDURE PrintStats(VAR OutFile: TEXT; Stats: StatsType);
PROCEDURE FlushStatsToBinary(VAR TempFile: BinStatsFile; VAR Stats: StatsType); 
FUNCTION StatsIsFull(Stats: StatsType): BOOLEAN;
  
IMPLEMENTATION

FUNCTION StatsIsFull(Stats: StatsType): BOOLEAN;
BEGIN {StatsIsFull} 
  StatsIsFull := Stats.NodeCount >= MaxTreeNodes
END {StatsIsFull};

FUNCTION Max(A, B: INTEGER): INTEGER;
BEGIN {Max}
  IF A > B
  THEN 
    Max := A
  ELSE
    Max := B
END {Max};

FUNCTION NodeHeight(Node: TreePtr): INTEGER;
BEGIN {NodeHeight}
  IF Node = NIL
  THEN 
    NodeHeight := 0
  ELSE
    NodeHeight := Node^.Height
END {NodeHeight};

PROCEDURE UpdateHeight(Node: TreePtr);
BEGIN {UpdateHeight}
  IF Node <> NIL
  THEN
    Node^.Height := Max(NodeHeight(Node^.Left), NodeHeight(Node^.Right)) + 1
END {UpdateHeight};

FUNCTION BalanceFactor(Node: TreePtr): INTEGER;
BEGIN {BalanceFactor}
  IF Node = NIL
  THEN
    BalanceFactor := 0
  ELSE
    BalanceFactor := NodeHeight(Node^.Left) - NodeHeight(Node^.Right) 
END {BalanceFactor};

PROCEDURE InitStats(VAR Stats: StatsType);
BEGIN
  Stats.Root := NIL;
  Stats.NodeCount := 0
END;

PROCEDURE CreateWordNode(Word: StrPtr; Count: LONGINT; VAR Node: TreePtr);
BEGIN {CreateWordNode}
  NEW(Node);
  CopyWord(Word, Node^.Word);
  Node^.Count := Count;
  Node^.Left := NIL;
  Node^.Right := NIL;
  Node^.Height := 1
END {CreateWordNode};

FUNCTION RotateRight(Y: TreePtr): TreePtr;
VAR
  X, T2: TreePtr;
BEGIN {RotateRight}
  X := Y^.Left;
  T2 := X^.Right;
  X^.Right := Y;
  Y^.Left := T2;
  UpdateHeight(Y);
  UpdateHeight(X);
  RotateRight := X
END {RotateRight};

FUNCTION RotateLeft(X: TreePtr): TreePtr;
VAR
  Y, T2: TreePtr;
BEGIN {RotateLeft}
  Y := X^.Right;
  T2 := Y^.Left;
  Y^.Left := X;
  X^.Right := T2;
  UpdateHeight(X);
  UpdateHeight(Y);
  RotateLeft := Y
END {RotateLeft};

FUNCTION BalanceNode(Node: TreePtr): TreePtr;
VAR
  Balance: INTEGER;
BEGIN {BalanceNode}
  UpdateHeight(Node);
  Balance := BalanceFactor(Node);
  IF Balance > 1
  THEN
    BEGIN
      IF BalanceFactor(Node^.Left) < 0
      THEN
        Node^.Left := RotateLeft(Node^.Left);
      BalanceNode := RotateRight(Node)
    END
  ELSE
    IF Balance < -1
    THEN
      BEGIN
        IF BalanceFactor(Node^.Right) > 0
        THEN
          Node^.Right := RotateRight(Node^.Right);
        BalanceNode := RotateLeft(Node)
      END
    ELSE
      BalanceNode := Node
END {BalanceNode};

PROCEDURE InsertNode(VAR Root: TreePtr; Word: StrPtr; Count: LONGINT; VAR NodeCount: LONGINT);
VAR
  CompResult: INTEGER;
BEGIN {InsertNode}
  IF Root = NIL
  THEN
    BEGIN
      CreateWordNode(Word, Count, Root);
      NodeCount := NodeCount + 1
    END
  ELSE
    BEGIN
      CompResult := CompareTwoWords(Word, Root^.Word);
      CASE CompResult OF
        -1: InsertNode(Root^.Left, Word, Count, NodeCount);
        0: Root^.Count := Root^.Count + Count;
        1: InsertNode(Root^.Right, Word, Count, NodeCount)
      END;
      Root := BalanceNode(Root)
    END {InsertNode}
END;

PROCEDURE UpdateStats(VAR Stats: StatsType; Word: StrPtr);
BEGIN {UpdateStats}
  InsertNode(Stats.Root, Word, 1, Stats.NodeCount)
END; {UpdateStats}

PROCEDURE WordToBinRecord(Word: StrPtr; Count: LONGINT; VAR Rec: BinWord);
VAR
  I: INTEGER;
  Cur: StrPtr;
BEGIN {WordToBinRecord}
  Rec.Len := 0;
  Rec.Count := Count;
  
  Cur := Word;
  FOR I := 1 TO MaxBinWordLen
  DO
    BEGIN
      IF (Cur <> NIL)
      THEN
        BEGIN
          Rec.Len := I;
          Rec.Chars[I] := Cur^.Ch;
          Cur := Cur^.Next
        END
      ELSE
        Rec.Chars[I] := ' '
    END
END {WordToBinRecord};

PROCEDURE BinRecordToWord(Rec: BinWord; VAR Word: StrPtr);
VAR
  I: INTEGER;
BEGIN {BinRecordToWord}
  Word := NIL;
  
  FOR I := 1 TO Rec.Len
  DO
    AppendChar(Word, Rec.Chars[I])
END {BinRecordToWord};

PROCEDURE AddWordCount(VAR Stats: StatsType; Word: StrPtr; Count: LONGINT);
BEGIN {AddWordCount}
  InsertNode(Stats.Root, Word, Count, Stats.NodeCount)
END {AddWordCount};

PROCEDURE LoadBinaryToStats(VAR TempFile: BinStatsFile; VAR Stats: StatsType);
VAR
  Rec: BinWord;
  Word: StrPtr;
BEGIN {LoadBinaryToStats}
  RESET(TempFile);
  WHILE NOT EOF (TempFile)
  DO
    BEGIN
      READ(TempFile, Rec);
      BinRecordToWord(Rec, Word);
      AddWordCount(Stats, Word, Rec.Count);
      DisposeWord(Word)
    END
END; {LoadBinaryToStats}

PROCEDURE FlushTreeToBinary(VAR TempFile: BinStatsFile; Root: TreePtr);
VAR
  Rec: BinWord;
BEGIN {FlushTreeToBinary}
  IF Root <> NIL
  THEN
    BEGIN
      FlushTreeToBinary(TempFile, Root^.Left);
      WordToBinRecord(Root^.Word, Root^.Count, Rec);
      WRITE(TempFile, Rec);
      FlushTreeToBinary(TempFile, Root^.Right)
    END
END {FlushTreeToBinary};

PROCEDURE PrintTree(VAR OutFile: TEXT; Root: TreePtr);
BEGIN {PrintTree}
  IF Root <> NIL
  THEN
    BEGIN
      PrintTree(OutFile, Root^.Left);
      PrintWord(OutFile, Root^.Word);
      WRITE(OutFile, ' ');
      WRITELN(OutFile, Root^.Count);
      PrintTree(OutFile, Root^.Right)
    END
END {PrintTree};

PROCEDURE PrintStats(VAR OutFile: TEXT; Stats: StatsType);
BEGIN {PrintStats}
  PrintTree(OutFile, Stats.Root)
END; {PrintStats}

PROCEDURE DisposeTree(VAR Root: TreePtr);
BEGIN {DisposeTree}
  IF Root <> NIL
  THEN
    BEGIN
      DisposeTree(Root^.Left);
      DisposeTree(Root^.Right);
      DisposeWord(Root^.Word);
      DISPOSE(Root);
      Root := NIL
    END
END {DisposeTree};

PROCEDURE DisposeStats(VAR Stats: StatsType);
BEGIN {DisposeStats}
  DisposeTree(Stats.Root);
  Stats.NodeCount := 0
END; {DisposeStats}

PROCEDURE FlushStatsToBinary(VAR TempFile: BinStatsFile; VAR Stats: StatsType);
BEGIN {FlushStatsToBinary}
  FlushTreeToBinary(TempFile, Stats.Root);
  DisposeStats(Stats)
END; {FlushStatsToBinary}

END.
