--Pablo Moreno Vera.
--Doble Grado Teleco + Ade.

with Lower_Layer_UDP;

package Handlers is
   package LLU renames Lower_Layer_UDP;


   procedure Client_EP_Handler (From: in LLU.End_Point_Type;
                                To: in LLU.End_Point_Type;
                                P_Buffer: access LLU.Buffer_Type);

end Handlers;
