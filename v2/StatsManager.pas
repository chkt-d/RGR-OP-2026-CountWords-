UNIT StatsManager;

INTERFACE

USES DataTypes;

TYPE
  StatsSystem = RECORD
                  Stats: StatsType;
                  MainFile: BinStatsFile;
                  ChunkFile: BinStatsFile;
                  MergeFile: BinStatsFile
                END;        

VAR 
  Sys: StatsSystem;

PROCEDURE InitStatsSystem(VAR System: StatsSystem);
PROCEDURE UpdateStatsSystem(VAR System: StatsSystem; Word: StrPtr);
PROCEDURE PrintFinalStats(VAR System: StatsSystem; VAR OutFile: TEXT);
PROCEDURE DoneStatsSystem(VAR System: StatsSystem);

IMPLEMENTATION

USES AVLTree, BinFiles;

PROCEDURE InitStatsSystem(VAR System: StatsSystem);
BEGIN
  InitStats(System.Stats);

  ASSIGN(System.MainFile, 'main.bin');
  ASSIGN(System.ChunkFile, 'chunk.bin');
  ASSIGN(System.MergeFile, 'merge.bin');

  REWRITE(System.MainFile);
  CLOSE(System.MainFile)
END;

PROCEDURE FlushCurrentStats(VAR System: StatsSystem);
BEGIN
  REWRITE(System.ChunkFile);
  FlushStatsToBinary(System.ChunkFile, System.Stats);
  CLOSE(System.ChunkFile);
  DisposeStats(System.Stats);
  MergeBinaryStats(System.MainFile, System.ChunkFile, System.MergeFile);
  CopyBinaryFile(System.MergeFile, System.MainFile)
END;

PROCEDURE UpdateStatsSystem(VAR System: StatsSystem; Word: StrPtr);
BEGIN
  UpdateStats(System.Stats, Word);
  IF StatsIsFull(System.Stats)
  THEN
    FlushCurrentStats(System)
END;

PROCEDURE PrintFinalStats(VAR System: StatsSystem; VAR OutFile: TEXT);
BEGIN
  IF System.Stats.NodeCount > 0
  THEN
    FlushCurrentStats(System);
  PrintBinaryStats(System.MainFile, OutFile)
END;

PROCEDURE ClearBinaryFile(VAR F: BinStatsFile);
BEGIN
  REWRITE(F);
  CLOSE(F)
END;

PROCEDURE DoneStatsSystem(VAR System: StatsSystem);
BEGIN
  DisposeStats(System.Stats);
  ClearBinaryFile(System.MainFile);
  ClearBinaryFile(System.ChunkFile);
  ClearBinaryFile(System.MergeFile)
END;

END.
