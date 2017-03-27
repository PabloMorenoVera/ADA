--PAblo Moreno Vera
--Doble Grado Teleco + ADE.

with Lower_Layer_UDP;
with Ada.Unchecked_Deallocation;


package Types is

   package LLU renames Lower_Layer_UDP;

   type Seq_N_T is mod Integer'Last;

   type Mess_Id_T is record
      EP: LLU.End_Point_Type;
      Seq: Seq_N_T;
   end record;

   type Destination_T is record
      Ep: LLU.End_Point_Type := null;
      Retries : Natural := 0;
   end record;

   type Destinations_T is array (1..10) of Destination_T;

   type Buffer_A_T is access LLU.Buffer_Type;

   type Value_T is record
      EP_H_Creat: LLU.End_Point_Type;
      Seq_N: Seq_N_T;
      P_Buffer: Buffer_A_T;
   end record;

   Prompt: Boolean := False;
   Seq_N_Adelantado: Seq_N_T;

   procedure Free is new Ada.Unchecked_Deallocation (LLU.Buffer_Type, Buffer_A_T);

   end Types;
