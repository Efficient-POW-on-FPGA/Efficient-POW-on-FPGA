package vhpi_access is

   function receive_byte return integer;
    attribute foreign of receive_byte :
      function is "VHPIDIRECT receive_byte";

  procedure send_byte(f : integer);
    attribute foreign of send_byte :
      procedure is "VHPIDIRECT send_byte";

end vhpi_access;

package body vhpi_access is
  function receive_byte return integer is
  begin
    assert false report "VHPI" severity failure;
  end receive_byte;
  procedure send_byte(f : integer) is
  begin
    assert false report "VHPI" severity failure;
  end send_byte;
end vhpi_access;
