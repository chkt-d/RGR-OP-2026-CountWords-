PROGRAM CountWords(INPUT, OUTPUT);

USES WordUtils, StatsTree;

VAR
  Stats: StatsType;
  Word: StrPtr; 
  F, OutF: TEXT;
  MainTempF, ChunkTempF, MergeTempF: BinStatsFile;                                                                              
  
BEGIN {CountWords}
  InitStats(Stats);
  ASSIGN(F, 'TEXT.txt'); 
  RESET(F);
  ASSIGN(MainTempF, 'MainTemp.bin');
  ASSIGN(ChunkTempF, 'ChunkTemp.bin');
  ASSIGN(MergeTempF, 'MergeTemp.bin');
  REWRITE(MainTempF);
  CLOSE(MainTempF);

  WHILE ReadWord(F, Word)
  DO
    BEGIN
      NormaliseWord(Word);
      UpdateStats(Stats, Word);
      DisposeWord(Word);
      IF StatsIsFull(Stats)
      THEN
        BEGIN
          REWRITE(ChunkTempF);
          FlushStatsToBinary(ChunkTempF, Stats);
          CLOSE(ChunkTempF);
          MergeBinaryStats(MainTempF, ChunkTempF, MergeTempF);
          CopyBinaryFile(MergeTempF, MainTempF)
        END
    END;
  IF Stats.Root <> NIL
  THEN
    BEGIN
      REWRITE(ChunkTempF);
      FlushStatsToBinary(ChunkTempF, Stats);
      CLOSE(ChunkTempF);
      MergeBinaryStats(MainTempF, ChunkTempF, MergeTempF);
      CopyBinaryFile(MergeTempF, MainTempF)
    END;

  ASSIGN(OutF, 'Statistics.txt');       
  REWRITE(OutF);
  PrintBinaryStats(MainTempF, OutF);

  CLOSE(F);
  CLOSE(OutF);
  
  REWRITE(MainTempF);
  CLOSE(MainTempF);

  REWRITE(ChunkTempF);
  CLOSE(ChunkTempF);

  REWRITE(MergeTempF);
  CLOSE(MergeTempF)
END {CountWords}.
