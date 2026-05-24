PROGRAM CountWords(INPUT, OUTPUT);
USES WordUtils, ManageStats;

VAR
  F, OutF: TEXT;                                                                              
  
BEGIN
  InitStats(Stats);
  ASSIGN(F, 'TEXT.txt');
  RESET(F);
  WHILE ReadWord(F, Word)
  DO
    BEGIN
      NormaliseWord(Word);
      UpdateStats(Stats, Word);
      DisposeWord(Word)
    END;
  ASSIGN(OutF, 'Statistics.txt');
  REWRITE(OutF);
  PrintStats(OutF, Stats);
  CLOSE(F);
  CLOSE(OutF);
END.
