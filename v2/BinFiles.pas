UNIT BinFiles;

INTERFACE

USES DataTypes, Config;

PROCEDURE MergeBinaryStats(VAR MainFile, ChunkFile, MergeFile: BinStatsFile);
PROCEDURE CopyBinaryFile(VAR SourceFile, DestFile: BinStatsFile);
PROCEDURE PrintBinaryStats(VAR BinFile: BinStatsFile; VAR OutFile: TEXT); 

IMPLEMENTATION

USES WordUtils;

FUNCTION CompareBinWords(First, Second: BinWord): INTEGER;
VAR
  I: INTEGER;
BEGIN
  I := 1;
  WHILE (I <= First.Len) AND (I <= Second.Len) AND (First.Chars[I] = Second.Chars[I])
  DO
    I := I + 1;
  IF (I > First.Len) AND (I > Second.Len)
  THEN
    CompareBinWords := 0
  ELSE
    IF (I > First.Len)
    THEN
      CompareBinWords := -1
    ELSE
      IF (I > Second.Len)
      THEN
        CompareBinWords := 1
      ELSE
        IF CharOrder(First.Chars[I]) > CharOrder(Second.Chars[I])
        THEN
          CompareBinWords := 1
        ELSE
          CompareBinWords := -1
END;

PROCEDURE BinRecordToWord(Rec: BinWord; VAR Word: StrPtr);
VAR
  I: INTEGER;
BEGIN {BinRecordToWord}
  Word := NIL;
  
  FOR I := 1 TO Rec.Len
  DO
    AppendChar(Word, Rec.Chars[I])
END {BinRecordToWord};

PROCEDURE PrintBinWord(VAR OutFile: TEXT; Rec: BinWord);
VAR
  I: INTEGER;
BEGIN {PrintBinWord}
  FOR I := 1 TO Rec.Len
  DO
    WRITE(OutFile, Rec.Chars[I]);
  WRITE(OutFile, ' ');
  WRITELN(OutFile, Rec.Count)
END; {PrintBinWord}

PROCEDURE CopyBinaryFile(VAR SourceFile, DestFile: BinStatsFile);
VAR
  Rec: BinWord;
BEGIN {CopyBinaryFile}
  RESET(SourceFile);
  REWRITE(DestFile);
  WHILE NOT EOF(SourceFile)
  DO
    BEGIN
      READ(SourceFile, Rec);
      WRITE(DestFile, Rec)
    END;
  CLOSE(SourceFile);
  CLOSE(DestFile)
END; {CopyBinaryFile}

PROCEDURE MergeBinaryStats(VAR MainFile, ChunkFile, MergeFile: BinStatsFile);
VAR
  MainRec, ChunkRec, OutRec: BinWord;
  HasMain, HasChunk: BOOLEAN;
  CompResult: INTEGER;
BEGIN {MergeBinaryStats}
  RESET(MainFile);
  RESET(ChunkFile);
  REWRITE(MergeFile);

  HasMain := NOT EOF(MainFile);
  IF HasMain
  THEN
    READ(MainFile, MainRec);

  HasChunk := NOT EOF(ChunkFile);
  IF HasChunk
  THEN
    READ(ChunkFile, ChunkRec);
  WHILE HasMain AND HasChunk
  DO
    BEGIN
      CompResult := CompareBinWords(MainRec, ChunkRec);
      CASE CompResult OF
        -1:
          BEGIN
            WRITE(MergeFile, MainRec);
            HasMain := NOT EOF(MainFile);
            IF HasMain
            THEN
              READ(MainFile, MainRec)
          END;
         0:
          BEGIN
            OutRec := MainRec;
            OutRec.Count := MainRec.Count + ChunkRec.Count;
            WRITE(MergeFile, OutRec);
            HasMain := NOT EOF(MainFile);
            IF HasMain
            THEN
              READ(MainFile, MainRec);
            HasChunk := NOT EOF(ChunkFile);
            IF HasChunk
            THEN
              READ(ChunkFile, ChunkRec)
          END;
         1:
          BEGIN
            WRITE(MergeFile, ChunkRec);
            HasChunk := NOT EOF(ChunkFile);
            IF HasChunk
            THEN
              READ(ChunkFile, ChunkRec)
          END
      END
    END;

  WHILE HasMain
  DO
    BEGIN
      WRITE(MergeFile, MainRec);
      HasMain := NOT EOF(MainFile);
      IF HasMain
      THEN
        READ(MainFile, MainRec)
    END;
  WHILE HasChunk
  DO
    BEGIN
      WRITE(MergeFile, ChunkRec);
      HasChunk := NOT EOF(ChunkFile);
      IF HasChunk
      THEN
        READ(ChunkFile, ChunkRec)
    END;
  CLOSE(MainFile);
  CLOSE(ChunkFile);
  CLOSE(MergeFile)
END; {MergeBinaryStats}

PROCEDURE PrintBinaryStats(VAR BinFile: BinStatsFile; VAR OutFile: TEXT);
VAR
  Rec: BinWord;
BEGIN {PrintBinaryStats}
  RESET(BinFile);
  WHILE NOT EOF(BinFile)
  DO
    BEGIN
      READ(BinFile, Rec);
      PrintBinWord(OutFile, Rec)
    END;
  CLOSE(BinFile)
END; {PrintBinaryStats}

END.
