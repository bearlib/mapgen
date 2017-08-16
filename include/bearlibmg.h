#ifndef BEARLIBMG_H
#define BEARLIBMG_H

#include <stdint.h>

/*
 * Map generation algorithms
 */
typedef enum {
  G_ANT_NEST = 1,
  G_CAVES = 2,
  G_VILLAGE = 3,
  G_LAKES = 4,
  G_LAKES2 = 5,
  G_TOWER = 6,
  G_HIVE = 7,
  G_CITY = 8,
  G_MOUNTAIN=9,
  G_FOREST = 10,
  G_SWAMP = 11,
  G_RIFT=12,
  G_TUNDRA=13,
  G_BROKEN_CITY=14,
  G_BROKEN_VILLAGE=15,
  G_MAZE=16,
  G_CASTLE = 17,
  G_WILDERNESS = 18,
  G_NICE_DUNGEON = 19
} TMapGeneratorEnum;

typedef uint32_t TMapGenerator;

/*
 * Cell types
 */
typedef enum {
  TILE_CAVE_WALL=0,
  TILE_GROUND=1,
  TILE_WATER = 2,
  TILE_TREE = 3,
  TILE_MOUNTAIN = 4,
  TILE_ROAD=6,
  TILE_HOUSE_WALL = 7,
  TILE_HOUSE_FLOOR = 8,
  TILE_GRASS = 9,
  TILE_EMPTY = 10,

  TILE_CORRIDOR = 11,
  TILE_SMALLROOM = 12,
  TILE_BIGROOM = 13,
  TILE_ROOMWALL = 14,
  TILE_DOOR=15
} TCellTypeEnum;
typedef uint32_t TCellType;

/*
 * Coordinates type
 */
typedef int32_t TCoord;

/*
 * Callback function that is called for each cell on map
 */
typedef void (*TMapCallback)(TCoord x, TCoord y, TCellType cell, void* opaque);

/*
 * Handle of generation parameters object
 */
typedef void* TGeneratorParamsHandle;

/*
 * Handle of rooms data object
 */
typedef void* TRoomsDataHandle;


#if defined(_WIN32)
#  define MAPGEN_API __declspec(dllimport)
#else
#  define MAPGEN_API
#endif

#ifdef __cplusplus
extern "C" {
#endif


MAPGEN_API void mg_generate(int32_t map_id, int32_t layer, TMapGenerator typ, uint32_t seed, TGeneratorParamsHandle params, TRoomsDataHandle rooms_data);
MAPGEN_API void mg_generate_cb(TCoord size_x, TCoord size_y, TMapGenerator typ, uint32_t seed, TMapCallback callback, void *opaque, TGeneratorParamsHandle params, TRoomsDataHandle rooms_data);

MAPGEN_API TGeneratorParamsHandle mg_params_create(TMapGenerator typ);
MAPGEN_API void mg_params_delete(TGeneratorParamsHandle params);
MAPGEN_API void mg_params_set(TGeneratorParamsHandle params, char* param, int32_t value);
MAPGEN_API void mg_params_setf(TGeneratorParamsHandle params, char* param, float value);
MAPGEN_API int32_t mg_params_get(TGeneratorParamsHandle params, char* param);
MAPGEN_API float mg_params_getf(TGeneratorParamsHandle params, char* param);
MAPGEN_API float mg_params_setstr(TGeneratorParamsHandle params, char* param, char* value);

MAPGEN_API TRoomsDataHandle mg_roomsdata_create(TMapGenerator typ);
MAPGEN_API void mg_roomsdata_delete(TRoomsDataHandle rooms);
MAPGEN_API int32_t mg_roomsdata_count(TRoomsDataHandle rooms);
MAPGEN_API void mg_roomsdata_position(TRoomsDataHandle rooms, int32_t room_index, TCoord *ax0, TCoord *ay0, TCoord *awidth, TCoord *aheight);
MAPGEN_API int32_t mg_roomsdata_linkscount(TRoomsDataHandle rooms, int32_t room_index);
MAPGEN_API int32_t mg_roomsdata_getlink(TRoomsDataHandle rooms, int32_t room_index, int32_t link_index);

#ifdef __cplusplus
} /* End of extern "C" */
#endif

#endif // BEARLIBMG_H
