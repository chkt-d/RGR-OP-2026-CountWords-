PROGRAM CountWords(INPUT, OUTPUT);

USES WordUtils, StatsManager;

VAR
  F, OutF: TEXT;                                                                            
  
BEGIN {CountWords}
  InitStatsSystem(Sys);
  ASSIGN(F, 'TEXT.txt'); 
  RESET(F);

  WHILE ReadWord(F, Word)
  DO
    BEGIN
      NormaliseWord(Word);
      UpdateStatsSystem(Sys, Word);
      DisposeWord(Word);
    END;
  CLOSE(F);

  ASSIGN(OutF, 'Statistics.txt');       
  REWRITE(OutF);
  PrintFinalStats(Sys, OutF);
  CLOSE(OutF);
  DoneStatsSystem(Sys)
END {CountWords}.
