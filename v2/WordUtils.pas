UNIT WordUtils;

INTERFACE

TYPE
  StrPtr = ^StrNode;

  StrNode = RECORD
    Ch: CHAR;
    Next: StrPtr
  END;

FUNCTION ReadWord(VAR InFile: TEXT; VAR Word: StrPtr): BOOLEAN;
PROCEDURE NormaliseWord(Word: StrPtr);
PROCEDURE DisposeWord(VAR Word: StrPtr);
PROCEDURE CopyWord(Source: StrPtr; VAR Dest: StrPtr);
FUNCTION CompareTwoWords(FirstWord, SecondWord: StrPtr): INTEGER;
PROCEDURE PrintWord(VAR OutFile: TEXT; Word: StrPtr);
PROCEDURE AppendChar(VAR Word: StrPtr; Ch: CHAR);

IMPLEMENTATION

PROCEDURE InitWord(VAR Word: StrPtr);
{Устанавливает указатель слова в NIL, делая слово пустым перед чтением или копированием}
BEGIN {InitWord}
  Word := NIL
END; {InitWord}
 
PROCEDURE AppendChar(VAR Word: StrPtr; Ch: CHAR);
{Создаёт новый узел с символом Ch и добавляет его в конец списка символов слова}
VAR
  NewChar, Cur: StrPtr;
BEGIN {AppendChar}
  NEW(NewChar);
  NewChar^.Ch := Ch;
  NewChar^.Next := NIL;
  IF Word = NIL
  THEN
    Word := NewChar
  ELSE
    BEGIN
      Cur := Word;
      WHILE Cur^.Next <> NIL
      DO
        Cur := Cur^.Next;
      Cur^.Next := NewChar
    END
END; {AppendChar}

PROCEDURE CopyWord(Source: StrPtr; VAR Dest: StrPtr);
{Создаёт независимую копию слова Source, последовательно копируя его символы в Dest}
BEGIN {CopyWord}
  Dest := NIL;
  WHILE Source <> NIL
  DO
    BEGIN
      AppendChar(Dest, Source^.Ch);
      Source := Source^.Next
    END
END; {CopyWord}

FUNCTION IsEmptyWord(Word: StrPtr): BOOLEAN;
{Проверяет, является ли слово пустым, то есть не содержит ни одного символа}
BEGIN {IsEmptyWord}
  IsEmptyWord := Word = NIL
END; {IsEmptyWord}
 
FUNCTION CharOrder(Ch: CHAR): INTEGER;
{Возвращает условный вес символа для сравнения.
 Используется для корректного расположения буквы 'ё' между 'е' и 'ж'}
BEGIN {CharOrder}
  IF Ch = 'ё'
  THEN 
    CharOrder := ORD('е') + 1
  ELSE
    IF (Ch > 'е') AND (Ch <= 'я')
    THEN
      CharOrder := ORD(Ch) + 1
    ELSE
      CharOrder := ORD(Ch) 
END; {CharOrder}
 
FUNCTION CompareTwoWords(FirstWord, SecondWord: StrPtr): INTEGER;
{Лексикографически сравнивает два слова посимвольно.
 Возвращает -1, если первое слово меньше второго,
 0, если слова равны, и 1, если первое слово больше второго}
VAR
  Cur1, Cur2: StrPtr;
BEGIN {CompareTwoWords}
  Cur1 := FirstWord;
  Cur2 := SecondWord;
  WHILE (Cur1 <> NIL) AND (Cur2 <> NIL) AND (Cur1^.Ch = Cur2^.Ch)
  DO
    BEGIN
      Cur1 := Cur1^.Next;
      Cur2 := Cur2^.Next
    END;
  IF Cur1 = NIL 
  THEN
    IF Cur2 = NIL
    THEN 
      CompareTwoWords := 0
    ELSE
      CompareTwoWords := -1
  ELSE
    IF Cur2 = NIL
    THEN
      CompareTwoWords := 1
    ELSE
      IF CharOrder(Cur1^.Ch) < CharOrder(Cur2^.Ch)
      THEN
        CompareTwoWords := -1
      ELSE
        CompareTwoWords := 1
END; {CompareTwoWords}

PROCEDURE DisposeWord(VAR Word: StrPtr);
{Освобождает память, занятую списком символов слова,
 и после завершения устанавливает Word в NIL}
VAR
  Temp: StrPtr;
BEGIN {DisposeWord}
  WHILE Word <> NIL
  DO
    BEGIN
      Temp := Word;
      Word := Word^.Next;
      DISPOSE(Temp)
    END
END; {DisposeWord}

//------------------------------------

FUNCTION IsLetter(Ch: CHAR): BOOLEAN;
{Проверяет, является ли символ буквой русского или латинского алфавита}
BEGIN {IsLetter}
  IsLetter := ((Ch >= 'A') AND (Ch <= 'Z')) OR ((Ch >= 'a') AND (Ch <= 'z')) OR
              ((Ch >= 'А') AND (Ch <= 'Я')) OR ((Ch >= 'а') AND (Ch <= 'я')) OR
              (Ch = 'Ё') OR (Ch = 'ё')
END; {IsLetter}

FUNCTION IsWordCh(Ch: CHAR): BOOLEAN;
{Проверяет, может ли символ быть обычной частью слова.
 Дефис здесь не обрабатывается, так как его допустимость зависит от соседних символов.}
BEGIN {IsWordCh}
  IsWordCh := IsLetter(Ch)
END; {IsWordCh}

FUNCTION ReadWord(VAR InFile: TEXT; VAR Word: StrPtr): BOOLEAN;
{Считывает из файла следующее слово.
 Дефис временно запоминается и добавляется в слово только тогда,
 когда после него встречается буква}
VAR
  Ch: CHAR;
  Found, ContinueReading, DashInStash: BOOLEAN;
BEGIN {ReadWord}
  InitWord(Word);
  Found := FALSE;
  WHILE (NOT EOF(InFile)) AND (NOT Found)
  DO
    BEGIN
      READ(InFile, Ch);
      IF IsWordCh(Ch)
      THEN
        BEGIN
          Found := TRUE;
          AppendChar(Word, Ch)
        END
    END;
  ContinueReading := Found;
  DashInStash := FALSE;
  WHILE ContinueReading AND (NOT EOF(InFile))
  DO
    BEGIN
      READ(InFile, Ch);
      IF Ch = '-' 
      THEN
        IF DashInStash
        THEN
          ContinueReading := FALSE
        ELSE
          DashInStash := TRUE
      ELSE
        IF IsWordCh(Ch)
        THEN
          BEGIN
            IF DashInStash
            THEN
              BEGIN
                DashInStash := FALSE;
                AppendChar(Word, '-')
              END;
            AppendChar(Word, Ch)
          END
        ELSE
          ContinueReading := FALSE
    END;
  ReadWord := Found
END; {ReadWord} 

FUNCTION LowerChar(Ch: CHAR): CHAR;
{Преобразует одну заглавную латинскую или русскую букву в строчную.
 Остальные символы возвращаются без изменений}
BEGIN {LowerChar}
  IF (Ch >= 'A') AND (Ch <= 'Z')
  THEN
    LowerChar := CHR(ORD(Ch) + ORD('a') - ORD('A'))
  ELSE
    IF ((Ch >= 'А') AND (Ch <= 'Я'))
    THEN 
      LowerChar := CHR(ORD(Ch) + ORD('а') - ORD('А'))
     ELSE
       IF (Ch = 'Ё')
       THEN
         LowerChar := 'ё'
       ELSE 
         LowerChar := Ch 
END; {LowerChar}

PROCEDURE NormaliseWord(Word: StrPtr);
{Проходит по всем символам слова и заменяет каждый символ его строчным вариантом}
VAR
  Cur: StrPtr;
BEGIN {NormaliseWord}
  Cur := Word;
  WHILE Cur <> NIL
  DO
    BEGIN
      Cur^.Ch := LowerChar(Cur^.Ch);
      Cur := Cur^.Next
    END
END; {NormaliseWord}

PROCEDURE PrintWord(VAR OutFile: TEXT; Word: StrPtr);
{Выводит в файл все символы одного слова}
VAR
  Cur: StrPtr;
BEGIN {PrintWord}
  Cur := Word;
  WHILE Cur <> NIL
  DO
    BEGIN
      WRITE(OutFile, Cur^.Ch);
      Cur := Cur^.Next
    END
END; {PrintWord}

END.
