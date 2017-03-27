--Pablo Moreno Vera.
--Doble Grado Teleco + ADE.

with Types;

package Tipo_Mensajes is

   type Message_Type is (Init, Reject, Confirm, Writer, Logout, Ack);

   P_Buffer_Main: Types.Buffer_A_T;
   P_Buffer_Handler: Types.Buffer_A_T;


end Tipo_Mensajes;
