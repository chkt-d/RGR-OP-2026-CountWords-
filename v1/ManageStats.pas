UNIT ManageStats;

INTERFACE

USES DataTypes;
  
VAR
  Stats: WordPtr;  

{Статистика и операции со списком}
PROCEDURE InitStats(VAR Stats: WordPtr); {Инициализирует пустой список статистики}
PROCEDURE UpdateStats(VAR Stats: WordPtr; Word: StrPtr); {Добавляет слово в статистику}
{Процедура вывода}
PROCEDURE PrintStats(VAR OutFile: TEXT; Stats: WordPtr); {Выводит статистику в заданный файл}

IMPLEMENTATION

USES WordUtils;

PROCEDURE InitStats(VAR Stats: WordPtr);
{Устанавливает указатель списка статистики в NIL, делая список пустым}
BEGIN {InitStats}
  Stats := NIL
END; {InitStats}

PROCEDURE CreateWordNode(Word: StrPtr; VAR Node: WordPtr);
{Создаёт новый узел статистики:
 копирует в него слово, устанавливает счётчик в 1 и очищает ссылку на следующий узел}
BEGIN {CreateWordNode}
  NEW(Node);
  CopyWord(Word, Node^.Word);
  Node^.Count := 1;
  Node^.Next := NIL
END; {CreateWordNode}

PROCEDURE UpdateStats(VAR Stats: WordPtr; Word: StrPtr);
{Ищет слово в отсортированном списке статистики. Если слово найдено, увеличивает его счётчик.
 Если слово отсутствует, вставляет новый узел в нужное место списка}
VAR
  Prev, Cur, NewNode: WordPtr;
  CompResult: INTEGER;
BEGIN {UpdateStats}
  Prev := NIL;
  Cur := Stats;
  WHILE (Cur <> NIL) AND (CompareTwoWords(Word, Cur^.Word) = 1)
  DO
    BEGIN
      Prev := Cur;
      Cur := Cur^.Next
    END;
    
  IF Cur <> NIL
  THEN
    CompResult := CompareTwoWords(Word, Cur^.Word)
  ELSE
    CompResult := -1;
     
  IF (Cur <> NIL) AND (CompResult = 0)
  THEN
    Cur^.Count := Cur^.Count + 1
  ELSE
    BEGIN
      CreateWordNode(Word, NewNode);
      NewNode^.Next := Cur;
      IF Prev = NIL
      THEN
        Stats := NewNode
      ELSE
        Prev^.Next := NewNode
    END
END; {UpdateStats}

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

PROCEDURE PrintStats(VAR OutFile: TEXT; Stats: WordPtr);
{Проходит по списку статистики и выводит каждое слово вместе с количеством вхождений}
VAR
  Cur: WordPtr;
BEGIN {PrintStats}
  Cur := Stats;
  WHILE Cur <> NIL
  DO
    BEGIN
      PrintWord(OutFile, Cur^.Word);
      WRITE(OutFile, ' ');
      WRITELN(OutFile, Cur^.Count);
      Cur := Cur^.Next
    END;
END; {PrintStats} 

END.
