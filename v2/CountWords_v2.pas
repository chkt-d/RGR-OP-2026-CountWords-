PROGRAM CountWords(INPUT, OUTPUT);

USES WordUtils, StatsTree;

VAR
  Stats, FinalStats: StatsType;
  Word: StrPtr; 
  F, OutF: TEXT;
  TempF: BinStatsFile;                                                                              
  
BEGIN {CountWords}
  InitStats(Stats);
  ASSIGN(F, 'TEXT.txt'); 
  RESET(F);
  ASSIGN(TempF, 'TempStats.bin'); 
  REWRITE(TempF);
  WHILE ReadWord(F, Word)
  DO
    BEGIN
      NormaliseWord(Word);
      UpdateStats(Stats, Word);
      DisposeWord(Word);
      
      IF StatsIsFull(Stats)
      THEN
        FlushStatsToBinary(TempF, Stats)
    END;
  FlushStatsToBinary(TempF, Stats);
  CLOSE(TempF);
  
  InitStats(FinalStats);
  LoadBinaryToStats(TempF, FinalStats);
  CLOSE(TempF);
  
  ASSIGN(OutF, 'Statistics.txt');       
  REWRITE(OutF);
  PrintStats(OutF, FinalStats);
  
  DisposeStats(FinalStats);
  CLOSE(F);
  CLOSE(OutF);
END {CountWords}.
