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
BEGIN
  StatsIsFull := Stats.NodeCount >= MaxTreeNodes
END;

FUNCTION Max(A, B: INTEGER): INTEGER;
BEGIN
  IF A > B
  THEN 
    Max := A
  ELSE
    Max := B
END;

FUNCTION NodeHeight(Node: TreePtr): INTEGER;
BEGIN
  IF Node = NIL
  THEN 
    NodeHeight := 0
  ELSE
    NodeHeight := Node^.Height
END;

PROCEDURE UpdateHeight(Node: TreePtr);
BEGIN
  IF Node <> NIL
  THEN
    Node^.Height := Max(NodeHeight(Node^.Left), NodeHeight(Node^.Right)) + 1
END;

FUNCTION BalanceFactor(Node: TreePtr): INTEGER;
BEGIN
  IF Node = NIL
  THEN
    BalanceFactor := 0
  ELSE
    BalanceFactor := NodeHeight(Node^.Left) - NodeHeight(Node^.Right) 
END;

PROCEDURE InitStats(VAR Stats: StatsType);
BEGIN
  Stats.Root := NIL;
  Stats.NodeCount := 0
END;

PROCEDURE CreateWordNode(Word: StrPtr; Count: LONGINT; VAR Node: TreePtr);
BEGIN
  NEW(Node);
  CopyWord(Word, Node^.Word);
  Node^.Count := Count;
  Node^.Left := NIL;
  Node^.Right := NIL;
  Node^.Height := 1
END;

FUNCTION RotateRight(Y: TreePtr): TreePtr;
VAR
  X, T2: TreePtr;
BEGIN
  X := Y^.Left;
  T2 := X^.Right;
  X^.Right := Y;
  Y^.Left := T2;
  UpdateHeight(Y);
  UpdateHeight(X);
  RotateRight := X
END;

FUNCTION RotateLeft(X: TreePtr): TreePtr;
VAR
  Y, T2: TreePtr;
BEGIN
  Y := X^.Right;
  T2 := Y^.Left;
  Y^.Left := X;
  X^.Right := T2;
  UpdateHeight(X);
  UpdateHeight(Y);
  RotateLeft := Y
END;

FUNCTION BalanceNode(Node: TreePtr): TreePtr;
VAR
  Balance: INTEGER;
BEGIN
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
END;

PROCEDURE InsertNode(VAR Root: TreePtr; Word: StrPtr; Count: LONGINT; VAR NodeCount: LONGINT);
VAR
  CompResult: INTEGER;
BEGIN
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
    END
END;

PROCEDURE UpdateStats(VAR Stats: StatsType; Word: StrPtr);
BEGIN
  InsertNode(Stats.Root, Word, 1, Stats.NodeCount)
END;

PROCEDURE WordToBinRecord(Word: StrPtr; Count: LONGINT; VAR Rec: BinWord);
VAR
  I: INTEGER;
  Cur: StrPtr;
BEGIN
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
END;

PROCEDURE BinRecordToWord(Rec: BinWord; VAR Word: StrPtr);
VAR
  I: INTEGER;
BEGIN
  Word := NIL;
  
  FOR I := 1 TO Rec.Len
  DO
    AppendChar(Word, Rec.Chars[I])
END;

PROCEDURE AddWordCount(VAR Stats: StatsType; Word: StrPtr; Count: LONGINT);
BEGIN
  InsertNode(Stats.Root, Word, Count, Stats.NodeCount)
END;

PROCEDURE LoadBinaryToStats(VAR TempFile: BinStatsFile; VAR Stats: StatsType);
VAR
  Rec: BinWord;
  Word: StrPtr;
BEGIN
  RESET(TempFile);
  WHILE NOT EOF (TempFile)
  DO
    BEGIN
      READ(TempFile, Rec);
      BinRecordToWord(Rec, Word);
      AddWordCount(Stats, Word, Rec.Count);
      DisposeWord(Word)
    END
END;

PROCEDURE FlushTreeToBinary(VAR TempFile: BinStatsFile; Root: TreePtr);
VAR
  Rec: BinWord;
BEGIN
  IF Root <> NIL
  THEN
    BEGIN
      FlushTreeToBinary(TempFile, Root^.Left);
      WordToBinRecord(Root^.Word, Root^.Count, Rec);
      WRITE(TempFile, Rec);
      FlushTreeToBinary(TempFile, Root^.Right)
    END
END;

PROCEDURE PrintTree(VAR OutFile: TEXT; Root: TreePtr);
BEGIN
  IF Root <> NIL
  THEN
    BEGIN
      PrintTree(OutFile, Root^.Left);
      PrintWord(OutFile, Root^.Word);
      WRITE(OutFile, ' ');
      WRITELN(OutFile, Root^.Count);
      PrintTree(OutFile, Root^.Right)
    END
END;

PROCEDURE PrintStats(VAR OutFile: TEXT; Stats: StatsType);
BEGIN
  PrintTree(OutFile, Stats.Root)
END;

PROCEDURE DisposeTree(VAR Root: TreePtr);
BEGIN
  IF Root <> NIL
  THEN
    BEGIN
      DisposeTree(Root^.Left);
      DisposeTree(Root^.Right);
      DisposeWord(Root^.Word);
      DISPOSE(Root);
      Root := NIL
    END
END;

PROCEDURE DisposeStats(VAR Stats: StatsType);
BEGIN
  DisposeTree(Stats.Root);
  Stats.NodeCount := 0
END;

PROCEDURE FlushStatsToBinary(VAR TempFile: BinStatsFile; VAR Stats: StatsType);
BEGIN
  FlushTreeToBinary(TempFile, Stats.Root);
  DisposeStats(Stats)
END;

END.
