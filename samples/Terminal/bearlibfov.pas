unit bearlibfov;

interface

uses ctypes;

const
  BeaRLibFOVLib = 'BeaRLibFOV.dll';


    type

      fov_callback = procedure(map_id, x, y: Integer; opaque: Pointer); cdecl;

  function fov_calc_cb(map_id, opacity_layer, x, y, radius: Integer; callback: fov_callback; opaque: Pointer): Integer;
    	cdecl; external BeaRLibFOVLib;
  function fov_calc(map_id, opacity_layer, visibility_layer, x, y, radius: Integer): Integer;
    	cdecl; external BeaRLibFOVLib;

implementation

end.	
