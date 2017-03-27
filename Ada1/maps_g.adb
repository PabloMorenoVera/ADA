with Ada.Text_IO;
with Ada.Unchecked_Deallocation;

package body Maps_G is

   procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);


   procedure Get (M       : Map;
                  Key     : in  Key_Type;
                  Value   : out Value_Type;
                  Success : out Boolean) is
      P_Aux : Cell_A;
   begin
      P_Aux := M.P_First;
      Success := False;
      while not Success and P_Aux /= null Loop
         if P_Aux.Key = Key then
            Value := P_Aux.Value;
            Success := True;
         end if;
         P_Aux := P_Aux.Next;
      end loop;
   end Get;


   procedure Put (M     : in out Map;
                  Key   : Key_Type;
                  Value : Value_Type;
                  Success : out Boolean) is

      P_Aux : Cell_A;
      Found : Boolean;

   begin
      -- Si ya existe Key, cambiamos su Value
      P_Aux := M.P_First;
      Found := False;
      Success := True;
      while not Found and P_Aux /= null loop
         if P_Aux.Key = Key then
            P_Aux.Value := Value;
            Found := True;
         end if;
         P_Aux := P_Aux.Next;
      end loop;
      -- Si no hemos encontrado Key añadimos al principio
      if not Found then
         if M.Length = 0 then
            M.P_First := new Cell'(Key, Value, M.P_First,Previous => Null);
            M.P_First.Next := Null;
            M.P_First.Previous := Null;
            M.P_First.Key := Key;
            M.P_First.Value := Value;
         else
            P_Aux := M.P_First;
            M.P_First := new Cell'(Key, Value, M.P_First,Previous => Null);
            M.P_First.Next := P_Aux;
            P_Aux.Previous := M.P_First;
            M.P_First.Key := Key;
            M.P_First.Value := Value;
         end if;
         M.Length := M.Length + 1;
      end if;
      if M.Length = Max_Length then
         Success := False;
      end if;
   end Put;



   procedure Delete (M      : in out Map;
                     Key     : in  Key_Type;
                     Success : out Boolean) is
      P_Current  : Cell_A;
      P_Previous : Cell_A;
   begin
      Success := False;
      P_Previous := null;
      P_Current  := M.P_First;
      while not Success and P_Current /= null  loop
         if P_Current.Key = Key then
            Success := True;
            M.Length := M.Length - 1;
            if P_Previous /= null then
               P_Previous.Next := P_Current.Next;
            end if;
            if M.P_First = P_Current then
               M.P_First := M.P_First.Next;
            end if;
            Free (P_Current);
         else
            P_Previous := P_Current;
            P_Current := P_Current.Next;
         end if;
      end loop;

   end Delete;

   function Get_Keys (M : Map) return Keys_Array_Type is

      Keys_Array : Keys_Array_Type;
      P_Aux : Cell_A;
      j : Natural;
      Salir: Boolean;

   begin

      --Inicializamos el array.

      for i in 1..Max_Length loop
         Keys_Array(i) := Null_Key;
      end loop;

      P_Aux := M.P_First;
      j := 1;
      Salir := False;

      --Introducimos los keys en el array.
      while not Salir loop
         if P_Aux = Null then
            Salir := True;
         else
            Keys_Array(j) := P_Aux.Key;
            P_Aux := P_Aux.Next;
            j := j + 1;
            end if;
      end loop;

      return Keys_Array;

   end Get_Keys;

   function Get_Values (M: Map) return Values_Array_Type is

      Values_Array: Values_Array_Type;
      P_Aux : Cell_A;
      j : Natural;
      Salir: Boolean;

   begin

      --Inicializamos el array.

      for i in 1..Max_Length loop
         Values_Array(i) := Null_Value;
      end loop;

      P_Aux := M.P_First;
      j := 1;
      Salir := False;

      --Introducimos los values en el array.

      while not Salir loop
         if P_Aux = Null then
            Salir := True;
         else
            Values_Array(j) := P_Aux.Value;
            P_Aux := P_Aux.Next;
            j := j + 1;
            end if;
      end loop;

      return Values_Array;

   end Get_Values;

   function Map_Length (M : Map) return Natural is
   begin
      return M.Length;
   end Map_Length;

   procedure Print_Map (M : Map) is
      P_Aux : Cell_A;
   begin
      P_Aux := M.P_First;

      Ada.Text_IO.Put_Line ("Map");
      Ada.Text_IO.Put_Line ("===");

      while P_Aux /= null loop
         Ada.Text_IO.Put_Line (Key_To_String(P_Aux.Key) & " " &
                                 VAlue_To_String(P_Aux.Value));
         P_Aux := P_Aux.Next;
      end loop;
   end Print_Map;

end Maps_G;
