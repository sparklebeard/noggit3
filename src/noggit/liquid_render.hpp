// This file is part of Noggit3, licensed under GNU General Public License (version 3).

#pragma once


#include <noggit/map_chunk_headers.hpp>
#include <noggit/MPQ.h>
#include <noggit/TextureManager.h>
#include <math/vector_4d.hpp>
#include <math/vector_2d.hpp>
#include <opengl/shader.hpp>

#include <string>
#include <vector>
#include <memory>


struct liquid_layer_ubo_data
{
  int liquid_type;
  int array_id;
  int id_start_in_array;
  int texture_count;
  math::vector_4d param; // only x,y are used, rest is padding
};

class liquid_render
{
public:
  liquid_render();

  opengl::program const& shader_program() const
  {
    return program;
  }

  // false when GL_ARB_shader_draw_parameters isn't supported (eg: macOS),
  // chunks must then be drawn one by one with the draw_id_fallback uniform set
  bool use_draw_parameters() const { return _use_draw_parameters; }

  liquid_layer_ubo_data ubo_data(int liquid_id);
  void bind_arrays();
  int array_count() const { return _texture_arrays.size(); }
private:

  // must be declared before program, it's used to build the vertex shader
  bool _use_draw_parameters;

  opengl::program program;

  std::map<int, int> _liquid_id_types;
  std::map<int, math::vector_2d> _float_param_by_liquid_id;

  std::map<int, liquid_layer_ubo_data> _liquids_ubo_data;
  // todo: make sure it doesn't go over the shader's array size
  std::vector<opengl::texture_array> _texture_arrays;
  std::vector<GLint> _arrays_format;
  std::map<int, int> _textures_used_per_array;

  // most liquids have 30 textures
  static constexpr int textures_per_array = 60;
};
